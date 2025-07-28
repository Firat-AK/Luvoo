import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> signOut() async {
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
  }) {
    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final allUsers = snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()))
              .toList();
          
          return allUsers.where((user) {
            print('[DEBUG] Filtering user: ${user.name} (${user.gender}, age: ${user.age})');
            print('[DEBUG] Your preferences: interestedIn=$interestedIn, ageRange=$ageRange, maxDistance=$maxDistance');
            
            // Filter by gender preference
            if (interestedIn != null && interestedIn != 'all') {
              if (interestedIn == 'male' && user.gender != 'male') {
                print('[DEBUG] Filtered out ${user.name} - gender mismatch');
                return false;
              }
              if (interestedIn == 'female' && user.gender != 'female') {
                print('[DEBUG] Filtered out ${user.name} - gender mismatch');
                return false;
              }
            }
            
            // Filter by age range
            if (ageRange != null && ageRange.length == 2) {
              final userAge = user.age;
              if (userAge < ageRange[0] || userAge > ageRange[1]) {
                print('[DEBUG] Filtered out ${user.name} - age $userAge not in range $ageRange');
                return false;
              }
            }
            
            // Filter by interests (if both users have interests)
            if (interests != null && interests.isNotEmpty && user.interests.isNotEmpty) {
              final commonInterests = interests.toSet().intersection(user.interests.toSet());
              if (commonInterests.isEmpty) {
                print('[DEBUG] Filtered out ${user.name} - no common interests');
                return false;
              }
            }
            
            print('[DEBUG] User ${user.name} passed all filters');
            return true;
          }).toList();
        });
  }

  // Get users who have liked me
  Stream<List<UserModel>> getUsersWhoLikedMe(String currentUserId) {
    return _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          final likedUserIds = snapshot.docs
              .map((doc) => doc.data()['fromUserId'] as String)
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
          final snapshotB = await _firestore
              .collection('matches')
              .where('isActive', isEqualTo: true)
              .where('userB', isEqualTo: userId)
              .get();
          
          final allDocs = [...snapshotA.docs, ...snapshotB.docs];
          final uniqueDocs = {for (var doc in allDocs) doc.id: doc}.values.toList();
          
          return uniqueDocs.map((doc) => MatchModel.fromJson(doc.data())).toList();
        });
  }

  // Get new matches for a user (for notifications)
  Stream<List<MatchModel>> getNewMatches(String userId) {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    return _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
        .snapshots()
        .asyncMap((snapshot) async {
          final matches = <MatchModel>[];
          for (final doc in snapshot.docs) {
            final match = MatchModel.fromJson(doc.data());
            if (match.userA == userId || match.userB == userId) {
              matches.add(match);
            }
          }
          return matches;
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

  Future<void> dislikeUser(String currentUserId, String dislikedUserId) async {
    print('DislikeUser called: $currentUserId -> $dislikedUserId');
    await _firestore.collection('dislikes').add({
      'userId': currentUserId,
      'dislikedUserId': dislikedUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('DislikeUser Firestore write completed');
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
        .map((snapshot) {
          print('[DEBUG] Found ${snapshot.docs.length} chats for user $userId');
          final chats = snapshot.docs
              .map((doc) {
                final data = doc.data();
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
              })
              .toList();
          
          // lastMessageTime'e göre sırala (null olanları en sona koy)
          chats.sort((a, b) {
            final aTime = a['lastMessageTime'];
            final bTime = b['lastMessageTime'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // En yeni önce
          });
          
          return chats;
        })
        .handleError((error) {
          print('[ERROR] Error getting chats: $error');
          return <Map<String, dynamic>>[];
        });
  }

  Future<void> sendChatMessage(String chatId, String senderId, String text) async {
    final messageId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;
    final now = FieldValue.serverTimestamp();
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set({
      'id': messageId,
      'chatId': chatId, // Chat ID'yi ekle
      'senderId': senderId,
      'text': text,
      'timestamp': now,
      'isRead': false,
    });
    // Chat dokümanını güncelle
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
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
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              print('[DEBUG] Message data: ' + data.toString());
              data['chatId'] = chatId;
              // Null korumaları
              data['id'] ??= doc.id;
              data['senderId'] ??= '';
              data['text'] ??= '';
              if (data['timestamp'] == null) {
                data['timestamp'] = FieldValue.serverTimestamp();
              }
              return MessageModel.fromJson(data);
            })
            .toList());
  }

  FirebaseAuth get auth => _auth;
} 