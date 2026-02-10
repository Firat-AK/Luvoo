import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:luvoo/core/exceptions/auth_exceptions.dart';
import 'package:luvoo/core/services/location_service.dart';
import 'package:luvoo/firebase_options.dart';
import 'package:luvoo/models/user_model.dart';
import 'package:luvoo/models/message_model.dart';
import 'package:luvoo/models/match_model.dart';
import 'package:uuid/uuid.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

class FirebaseService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Auth Methods
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? DefaultFirebaseOptions.ios.iosClientId
            : null,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      try {
        final credentialResult = await _auth.signInWithCredential(credential);
        await _ensureFirestoreUser(credentialResult.user!);
        return credentialResult;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential' && e.email != null) {
          throw AuthAccountExistsException(
            email: e.email!,
            credential: credential,
            providerName: 'Google',
          );
        }
        rethrow;
      }
    } catch (e) {
      if (e is AuthAccountExistsException) rethrow;
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      try {
        final credentialResult = await _auth.signInWithCredential(oauthCredential);
        await _ensureFirestoreUser(
          credentialResult.user!,
          displayName: appleCredential.givenName,
          familyName: appleCredential.familyName,
        );
        return credentialResult;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          final email = e.email ?? appleCredential.email;
          if (email != null) {
            throw AuthAccountExistsException(
              email: email,
              credential: oauthCredential,
              providerName: 'Apple',
            );
          }
        }
        rethrow;
      }
    } catch (e) {
      if (e is AuthAccountExistsException) rethrow;
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Link Google/Apple credential to existing email/password account.
  Future<UserCredential> linkCredentialToExistingAccount({
    required String email,
    required String password,
    required AuthCredential credential,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user!.linkWithCredential(credential);
    await _ensureFirestoreUser(userCredential.user!);
    return userCredential;
  }

  /// Create Firestore user if not exists. Used after Google/Apple sign-in.
  Future<void> _ensureFirestoreUser(
    User firebaseUser, {
    String? displayName,
    String? familyName,
  }) async {
    final existing = await getUser(firebaseUser.uid);
    if (existing != null) return;

    var name = (displayName != null || familyName != null)
        ? '${displayName ?? ''} ${familyName ?? ''}'.trim()
        : (firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User');
    if (name.isEmpty) {
      name = firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User';
    }

    final user = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '${firebaseUser.uid}@placeholder.local',
      name: name,
      gender: '',
      birthday: DateTime.now(),
      createdAt: DateTime.now(),
      interestedIn: 'all',
      ageRange: [18, 100],
      maxDistance: 50,
      interests: [],
      heightRange: [150, 200],
      photoUrl: firebaseUser.photoURL,
      photoUrls: firebaseUser.photoURL != null ? [firebaseUser.photoURL!] : [],
    );
    await createUser(user);
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Permanently delete account. Requires password for email/password users (re-auth).
  /// For Google/Apple, re-auth is done automatically if needed.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    // Re-authenticate (required by Firebase for delete)
    if (user.providerData.any((p) => p.providerId == 'password')) {
      if (password == null || password.isEmpty) {
        throw Exception('Password required to delete account');
      }
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } else if (user.providerData.any((p) => p.providerId == 'google.com')) {
      final googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? DefaultFirebaseOptions.ios.iosClientId
            : null,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    }
    // Apple: re-auth would require another SignInWithApple flow; if delete fails we throw requires-recent-login

    final userId = user.uid;

    // 1. Delete likes (fromUserId or toUserId)
    for (final q in [
      _firestore.collection('likes').where('fromUserId', isEqualTo: userId),
      _firestore.collection('likes').where('toUserId', isEqualTo: userId),
    ]) {
      final snap = await q.get();
      for (final doc in snap.docs) await doc.reference.delete();
    }

    // 2. Delete matches (userA or userB)
    for (final q in [
      _firestore.collection('matches').where('userA', isEqualTo: userId),
      _firestore.collection('matches').where('userB', isEqualTo: userId),
    ]) {
      final snap = await q.get();
      for (final doc in snap.docs) await doc.reference.delete();
    }

    // 3. Delete dislikes, super_likes, user_actions, blocks
    for (final (col, field) in [
      ('dislikes', 'userId'),
      ('super_likes', 'userId'),
      ('user_actions', 'fromUserId'),
    ]) {
      final snap = await _firestore.collection(col).where(field, isEqualTo: userId).get();
      for (final doc in snap.docs) await doc.reference.delete();
    }
    final superLikesToMe = await _firestore.collection('super_likes').where('toUserId', isEqualTo: userId).get();
    for (final doc in superLikesToMe.docs) await doc.reference.delete();
    for (final q in [
      _firestore.collection('blocks').where('blockerId', isEqualTo: userId),
      _firestore.collection('blocks').where('blockedUserId', isEqualTo: userId),
    ]) {
      final snap = await q.get();
      for (final doc in snap.docs) await doc.reference.delete();
    }

    // 4. Delete chats and messages (chats where user is member)
    final chatsSnap = await _firestore.collection('chats').where('users', arrayContains: userId).get();
    for (final chatDoc in chatsSnap.docs) {
      final messagesSnap = await chatDoc.reference.collection('messages').get();
      for (final msgDoc in messagesSnap.docs) await msgDoc.reference.delete();
      await chatDoc.reference.delete();
    }

    // 5. Delete user document
    await _firestore.collection('users').doc(userId).delete();

    // 6. Delete Storage images (profile_images/{userId}*)
    try {
      final list = await _storage.ref().child('profile_images').listAll();
      for (final ref in list.items) {
        if (ref.name.startsWith(userId)) await ref.delete();
      }
    } catch (_) {}

    // 7. Delete Auth user (must succeed; Firestore already wiped)
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Session expired. Please sign out, sign in again, then delete your account from Profile.',
        );
      }
      rethrow;
    }
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // User Methods
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      print('[DEBUG] Firebase updateUser called with data:');
      final userData = user.toJson();
      print('[DEBUG] User data to save: $userData');
      await _firestore.collection('users').doc(user.id).update(userData);
      print('[DEBUG] User updated successfully in Firebase');
    } catch (e) {
      print('[ERROR] Failed to update user in Firebase: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  Future<String> uploadProfileImage(String userId, File image) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple profile images. Returns list of download URLs.
  /// Max 6 photos. Uses profile_images/{userId}_{index}.jpg
  Future<List<String>> uploadProfileImages(String userId, List<File> images) async {
    if (images.isEmpty) return [];
    if (images.length > 6) images = images.sublist(0, 6);

    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      try {
        final ref = _storage.ref().child('profile_images/${userId}_$i.jpg');
        await ref.putFile(images[i]);
        urls.add(await ref.getDownloadURL());
      } catch (e) {
        throw Exception('Failed to upload image $i: $e');
      }
    }
    return urls;
  }

  // Discovery Methods
  Stream<List<UserModel>> getDiscoveryUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList());
  }

  // Get filtered discovery users based on preferences
  Stream<List<UserModel>> getFilteredDiscoveryUsers(String currentUserId, {
    String? interestedIn,
    List<int>? ageRange,
    int? maxDistance,
    List<String>? interests,
    double? myLatitude,
    double? myLongitude,
  }) {
    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          final blockedIds = await getBlockedUserIds(currentUserId);
          final allUsers = <UserModel>[];
          for (final doc in snapshot.docs) {
            try {
              allUsers.add(UserModel.fromJson(doc.data()));
            } catch (e) {
              debugPrint('[Discovery] Parse error for doc ${doc.id}: $e');
            }
          }

          // DEBUG: Log total users and filter results
          final usersWithLoc = allUsers.where((u) => u.latitude != null && u.longitude != null).length;
          debugPrint('[Discovery] Firestore: ${snapshot.docs.length} docs, ${allUsers.length} parsed');
          debugPrint('[Discovery] Your location: lat=$myLatitude, lng=$myLongitude');
          debugPrint('[Discovery] Filters: maxDist=$maxDistance, usersWithLocation=$usersWithLoc');
          
          final filtered = allUsers.where((user) {
            // Filter blocked users
            if (blockedIds.contains(user.id)) return false;
            // Filter paused / incognito – hide from discovery
            if (user.isPaused || user.isIncognito) return false;
            // Filter by gender preference
            if (interestedIn != null && interestedIn != 'all') {
              if (interestedIn == 'male' && user.gender != 'male') return false;
              if (interestedIn == 'female' && user.gender != 'female') return false;
            }
            
            // Filter by age range
            if (ageRange != null && ageRange.length == 2) {
              final userAge = user.age;
              if (userAge < ageRange[0] || userAge > ageRange[1]) return false;
            }
            
            // Filter by distance (when both have location)
            if (maxDistance != null &&
                maxDistance < 100 &&
                myLatitude != null &&
                myLongitude != null &&
                user.latitude != null &&
                user.longitude != null) {
              final distanceKm = LocationService.distanceInKm(
                myLatitude,
                myLongitude,
                user.latitude!,
                user.longitude!,
              );
              if (distanceKm > maxDistance) {
                debugPrint('[Discovery] Filtered out ${user.name}: ${distanceKm.toStringAsFixed(0)} km > $maxDistance');
                return false;
              }
            }
            
            // Filter by interests (if both users have interests)
            if (interests != null && interests.isNotEmpty && user.interests.isNotEmpty) {
              final commonInterests = interests.toSet().intersection(user.interests.toSet());
              if (commonInterests.isEmpty) return false;
            }
            
            return true;
          }).toList();
          debugPrint('[Discovery] After filters: ${filtered.length} users passed');
          return filtered;
        });
  }

  /// Update only the user's location (for quick updates without full profile save).
  Future<void> updateUserLocation(String userId, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  // Get users who have liked me
  Stream<List<UserModel>> getUsersWhoLikedMe(String currentUserId) {
    return _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          final blockedIds = await getBlockedUserIds(currentUserId);
          final likedUserIds = snapshot.docs
              .map((doc) => doc.data()['fromUserId'] as String)
              .where((id) => !blockedIds.contains(id))
              .toSet()
              .toList();
          
          if (likedUserIds.isEmpty) return [];
          
          final users = <UserModel>[];
          for (final userId in likedUserIds) {
            final user = await getUser(userId);
            if (user != null) {
              users.add(user);
            }
          }
          
          return users;
        });
  }

  // Like Methods
  Future<void> likeUser(String fromUserId, String toUserId, {String? comment}) async {
    print('LikeUser called: $fromUserId -> $toUserId');
    try {
      await _firestore.collection('likes').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('LikeUser Firestore write completed');
      
      // Check for mutual like and create match if needed
      await _checkForMutualLike(fromUserId, toUserId);
    } catch (e) {
      print('LikeUser error: $e');
      throw Exception('Failed to like user: $e');
    }
  }

  // Check if two users have mutually liked each other
  Future<void> _checkForMutualLike(String userA, String userB) async {
    try {
      // Check if userB has already liked userA
      final existingLike = await _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: userB)
          .where('toUserId', isEqualTo: userA)
          .get();

      if (existingLike.docs.isNotEmpty) {
        // Mutual like found! Create a match
        print('Mutual like detected! Creating match between $userA and $userB');
        await createMatch(userA, userB);
        
        // Also create a chat for the matched users
        await startOrGetChat(userA, userB);
      }
    } catch (e) {
      print('Error checking for mutual like: $e');
    }
  }

  // Match Methods
  Future<void> createMatch(String userA, String userB) async {
    try {
      final matchId = _uuid.v4();
      final match = MatchModel(
        id: matchId,
        userA: userA,
        userB: userB,
        createdAt: DateTime.now(),
        isActive: true,
      );
      await _firestore.collection('matches').doc(matchId).set(match.toJson());
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  // Get matches for a user
  Stream<List<MatchModel>> getUserMatches(String userId) {
    return _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .where('userA', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshotA) async {
          final blockedIds = await getBlockedUserIds(userId);
          final snapshotB = await _firestore
              .collection('matches')
              .where('isActive', isEqualTo: true)
              .where('userB', isEqualTo: userId)
              .get();
          
          final allDocs = [...snapshotA.docs, ...snapshotB.docs];
          final uniqueDocs = {for (var doc in allDocs) doc.id: doc}.values.toList();
          final matches = uniqueDocs.map((doc) => MatchModel.fromJson(doc.data())).toList();
          return matches.where((m) {
            final other = m.userA == userId ? m.userB : m.userA;
            return !blockedIds.contains(other);
          }).toList();
        });
  }

  // Get new matches for a user (for notifications)
  // userA/userB + isActive ile sorgula, createdAt filtresini uygulama tarafında yap (index gerektirmez)
  Stream<List<MatchModel>> getNewMatches(String userId) {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

    final streamA = _firestore
        .collection('matches')
        .where('userA', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots();
    final streamB = _firestore
        .collection('matches')
        .where('userB', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots();

    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> subA;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> subB;
    final controller = StreamController<List<MatchModel>>();
    var latestA = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var latestB = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    void emit() {
      final seen = <String>{};
      final all = [...latestA, ...latestB];
      final unique = all.where((d) => seen.add(d.id)).toList();
      final matches = unique.map((d) => MatchModel.fromJson(d.data())).toList();
      // Son 1 saatteki match'leri filtrele
      final recent = matches.where((m) => m.createdAt.isAfter(oneHourAgo)).toList();
      controller.add(recent);
    }

    subA = streamA.listen((s) {
      latestA = s.docs;
      emit();
    });
    subB = streamB.listen((s) {
      latestB = s.docs;
      emit();
    });

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream.asyncMap((matches) async {
      final blockedIds = await getBlockedUserIds(userId);
      return matches.where((m) {
        final other = m.userA == userId ? m.userB : m.userA;
        return !blockedIds.contains(other);
      }).toList();
    });
  }

  // Message Methods
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.matchId)
          .collection('messages')
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> getMessages(String matchId) {
    return _firestore
        .collection('messages')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> markMessageAsRead(String matchId, String messageId) async {
    try {
      await _firestore
          .collection('messages')
          .doc(matchId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Block Methods
  Future<void> blockUser(String blockerId, String blockedUserId) async {
    try {
      await _firestore.collection('blocks').add({
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  Future<void> unblockUser(String blockerId, String blockedUserId) async {
    final query = await _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedUserId', isEqualTo: blockedUserId)
        .get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  /// Returns Set of user IDs: users I blocked + users who blocked me.
  Future<Set<String>> getBlockedUserIds(String userId) async {
    final blockerQuery = await _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: userId)
        .get();
    final blockedQuery = await _firestore
        .collection('blocks')
        .where('blockedUserId', isEqualTo: userId)
        .get();
    final blockedByMe = blockerQuery.docs.map((d) => d.data()['blockedUserId'] as String).toSet();
    final blockedMe = blockedQuery.docs.map((d) => d.data()['blockerId'] as String).toSet();
    return {...blockedByMe, ...blockedMe};
  }

  // Report Methods
  Future<void> reportUser(String reporterId, String reportedUserId, String reason, {String? details}) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'details': details ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to report user: $e');
    }
  }

  Future<void> dislikeUser(String currentUserId, String dislikedUserId) async {
    print('DislikeUser called: $currentUserId -> $dislikedUserId');
    await _firestore.collection('dislikes').add({
      'userId': currentUserId,
      'dislikedUserId': dislikedUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('DislikeUser Firestore write completed');
  }

  /// Super like: write to super_likes, then check if the other user already liked/superliked me → match.
  Future<void> superLikeUser(String fromUserId, String toUserId) async {
    await _firestore.collection('super_likes').add({
      'userId': fromUserId,
      'toUserId': toUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _checkForSuperLikeMatch(fromUserId, toUserId);
  }

  /// If toUserId has already liked or superliked fromUserId, create match and chat.
  Future<void> _checkForSuperLikeMatch(String userA, String userB) async {
    try {
      final likeFromB = await _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: userB)
          .where('toUserId', isEqualTo: userA)
          .get();
      final superLikeFromB = await _firestore
          .collection('super_likes')
          .where('userId', isEqualTo: userB)
          .where('toUserId', isEqualTo: userA)
          .get();
      if (likeFromB.docs.isNotEmpty || superLikeFromB.docs.isNotEmpty) {
        await createMatch(userA, userB);
        await startOrGetChat(userA, userB);
      }
    } catch (e) {
      print('Error checking for super like match: $e');
    }
  }

  // Chat Methods (NEW)
  Future<String> startOrGetChat(String myUid, String otherUid) async {
    // Aynı iki kullanıcı arasında bir chat var mı?
    final query = await _firestore
        .collection('chats')
        .where('users', arrayContains: myUid)
        .get();
    for (var doc in query.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(otherUid)) {
        return doc.id; // Chat zaten var
      }
    }
    // Yoksa yeni chat oluştur
    final chatDoc = await _firestore.collection('chats').add({
      'users': [myUid, otherUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
    });
    return chatDoc.id;
  }

  // Get chat by ID
  Future<Map<String, dynamic>?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      // Timestamp'i DateTime'a çevir
      if (data['lastMessageTime'] is Timestamp) {
        data['lastMessageTime'] = (data['lastMessageTime'] as Timestamp).toDate();
      }
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }
      
      return {
        'id': doc.id,
        ...data,
      };
    } catch (e) {
      print('[ERROR] Failed to get chat: $e');
      return null;
    }
  }

  // Debug method to create a test chat
  Future<String> createTestChat(String myUid, String otherUid) async {
    print('[DEBUG] Creating test chat between $myUid and $otherUid');
    try {
      final chatDoc = await _firestore.collection('chats').add({
        'users': [myUid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Test message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      print('[DEBUG] Test chat created with ID: ${chatDoc.id}');
      return chatDoc.id;
    } catch (e) {
      print('[ERROR] Failed to create test chat: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    print('[DEBUG] Getting chats for user: $userId');
    print('[DEBUG] Current auth user: ${_auth.currentUser?.uid}');
    
    if (_auth.currentUser == null) {
      print('[ERROR] No authenticated user found');
      return Stream.value([]);
    }
    
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final blockedIds = await getBlockedUserIds(userId);
          print('[DEBUG] Found ${snapshot.docs.length} chats for user $userId');
          final chats = snapshot.docs
              .map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                if (data['lastMessageTime'] is Timestamp) {
                  data['lastMessageTime'] = (data['lastMessageTime'] as Timestamp).toDate();
                }
                if (data['createdAt'] is Timestamp) {
                  data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
                }
                return {'id': doc.id, ...data};
              })
              .where((chat) {
                final users = List<String>.from(chat['users'] ?? []);
                final other = users.firstWhere((u) => u != userId, orElse: () => '');
                return other.isNotEmpty && !blockedIds.contains(other);
              })
              .toList();
          
          chats.sort((a, b) {
            final aTime = a['lastMessageTime'];
            final bTime = b['lastMessageTime'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          return chats;
        })
        .handleError((error) {
          print('[ERROR] Error getting chats: $error');
          return <Map<String, dynamic>>[];
        });
  }

  /// Upload image for a chat message. Returns download URL.
  Future<String> uploadChatImage(String chatId, String messageId, File imageFile) async {
    final ref = _storage.ref().child('chats/$chatId/messages/$messageId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Upload image and send as a single chat message (one messageId for both storage and doc).
  Future<void> sendChatPhoto(String chatId, String senderId, File imageFile, {String caption = ''}) async {
    final messageId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;
    final imageUrl = await uploadChatImage(chatId, messageId, imageFile);
    final now = FieldValue.serverTimestamp();
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set({
      'id': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'text': caption,
      'imageUrl': imageUrl,
      'timestamp': now,
      'isRead': false,
    });
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': caption.isNotEmpty ? caption : 'Photo',
      'lastMessageTime': now,
    });
  }

  Future<void> sendChatMessage(
    String chatId,
    String senderId,
    String text, {
    String? imageUrl,
  }) async {
    final messageId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': now,
      'isRead': false,
    };
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set(data);
    final lastMessagePreview = imageUrl != null && imageUrl.isNotEmpty
        ? (text.isNotEmpty ? text : 'Photo')
        : text;
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': lastMessagePreview,
      'lastMessageTime': now,
    });
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['chatId'] = chatId;
            data['id'] ??= doc.id;
            data['senderId'] ??= '';
            data['text'] ??= '';
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
            } else if (data['timestamp'] == null) {
              data['timestamp'] = DateTime.now();
            }
            return MessageModel.fromJson(data);
          }).toList();
        });
  }

  /// Set typing state for current user in this chat (debounce on caller side).
  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    try {
      if (isTyping) {
        await _firestore.collection('chats').doc(chatId).update({
          'typing.$userId': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('chats').doc(chatId).update({
          'typing.$userId': FieldValue.delete(),
        });
      }
    } catch (_) {
      // Chat may not exist yet or permission; ignore
    }
  }

  /// Mark chat as read up to now for this user (for read receipts).
  Future<void> setLastRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastReadBy.$userId': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Chat may not exist yet or permission; ignore
    }
  }

  /// Stream chat document including lastReadBy (userId -> DateTime) for read receipts.
  Stream<Map<String, DateTime>> getChatLastReadBy(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <String, DateTime>{};
          final data = doc.data();
          final lastReadBy = data?['lastReadBy'];
          if (lastReadBy is! Map) return <String, DateTime>{};
          final result = <String, DateTime>{};
          for (final entry in lastReadBy.entries) {
            final uid = entry.key as String?;
            if (uid == null) continue;
            if (entry.value is Timestamp) {
              result[uid] = (entry.value as Timestamp).toDate();
            }
          }
          return result;
        });
  }

  /// Stream of typing user ids in this chat. Keys are userId, values are last timestamp.
  /// Consider typing stale after 5 seconds.
  Stream<Map<String, DateTime>> getChatTyping(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return <String, DateTime>{};
          final data = doc.data();
          final typing = data?['typing'];
          if (typing is! Map) return <String, DateTime>{};
          final now = DateTime.now();
          const staleSeconds = 5;
          final result = <String, DateTime>{};
          for (final entry in typing.entries) {
            final uid = entry.key as String?;
            if (uid == null) continue;
            Timestamp? ts;
            if (entry.value is Timestamp) {
              ts = entry.value as Timestamp;
            }
            if (ts != null) {
              final dt = ts.toDate();
              if (now.difference(dt).inSeconds <= staleSeconds) {
                result[uid] = dt;
              }
            }
          }
          return result;
        });
  }

  FirebaseAuth get auth => _auth;
} 