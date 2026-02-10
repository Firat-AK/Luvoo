import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/core/services/location_service.dart';
import 'package:luvoo/core/widgets/liquid_glass.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/models/user_model.dart';
import 'package:luvoo/features/discovery/screens/interested_in_me_page.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:luvoo/models/match_model.dart';

final discoveryUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(authProvider).value;
  final preferences = ref.watch(userPreferencesProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firebaseServiceProvider).getFilteredDiscoveryUsers(
    user.id,
    interestedIn: preferences.interestedIn,
    ageRange: preferences.ageRange,
    maxDistance: preferences.maxDistance,
    interests: preferences.interests,
    myLatitude: user.latitude,
    myLongitude: user.longitude,
  );
});

final newMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firebaseServiceProvider).getNewMatches(user.id);
});

final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    return UserPreferencesNotifier(ref.read(firebaseServiceProvider), null);
  }
  return UserPreferencesNotifier(ref.read(firebaseServiceProvider), user);
});

class UserPreferences {
  final String interestedIn;
  final List<int> ageRange;
  final int maxDistance;
  final List<String> interests;

  const UserPreferences({
    this.interestedIn = 'all',
    this.ageRange = const [18, 100],
    this.maxDistance = 50,
    this.interests = const [],
  });

  UserPreferences copyWith({
    String? interestedIn,
    List<int>? ageRange,
    int? maxDistance,
    List<String>? interests,
  }) {
    return UserPreferences(
      interestedIn: interestedIn ?? this.interestedIn,
      ageRange: ageRange ?? this.ageRange,
      maxDistance: maxDistance ?? this.maxDistance,
      interests: interests ?? this.interests,
    );
  }
}

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final FirebaseService _firebaseService;
  final UserModel? _user;

  UserPreferencesNotifier(this._firebaseService, this._user) 
      : super(const UserPreferences()) {
    if (_user != null) {
      _loadPreferences();
    }
  }

  void _loadPreferences() {
    if (_user == null) return;
    state = UserPreferences(
      interestedIn: _user!.interestedIn,
      ageRange: _user!.ageRange,
      maxDistance: _user!.maxDistance,
      interests: _user!.interests,
    );
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    if (_user == null) return;
    
    state = preferences;
    
    final updatedUser = _user!.copyWith(
      interestedIn: preferences.interestedIn,
      ageRange: preferences.ageRange,
      maxDistance: preferences.maxDistance,
      interests: preferences.interests,
    );
    
    await _firebaseService.updateUser(updatedUser);
  }
}

class DiscoveryFeedScreen extends ConsumerStatefulWidget {
  const DiscoveryFeedScreen({super.key});

  @override
  ConsumerState<DiscoveryFeedScreen> createState() => _DiscoveryFeedScreenState();
}

class _DiscoveryFeedScreenState extends ConsumerState<DiscoveryFeedScreen> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DiscoverBody(),
      const InterestedInMePage(),
    ];
    return pages[_selectedIndex];
  }
}

class _DiscoverBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DiscoverBody> createState() => _DiscoverBodyState();
}

class _DiscoverBodyState extends ConsumerState<_DiscoverBody> {
  late List<SwipeItem> _swipeItems;
  late MatchEngine _matchEngine;
  int _currentIndex = 0;
  bool _showFilters = false;
  List<String> _lastUserIds = []; // Avoid resetting when same users rebuild

  @override
  void initState() {
    super.initState();
    _swipeItems = [];
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
    _refreshLocationOnOpen();
  }

  Future<void> _refreshLocationOnOpen() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final position = await LocationService().getCurrentLocation();
    if (position != null) {
      final user = ref.read(authProvider).value;
      if (user != null) {
        await ref.read(firebaseServiceProvider).updateUserLocation(
          user.id,
          position.latitude,
          position.longitude,
        );
        ref.read(authProvider.notifier).refreshUser();
      }
    }
  }

  void _setupSwipeItems(List<UserModel> users, WidgetRef ref) {
    // Don't reset if we have the same users - prevents MatchEngine reset on auth/location refresh
    final userIds = users.map((u) => u.id).toList();
    if (_lastUserIds.length == userIds.length &&
        _lastUserIds.isNotEmpty &&
        _lastUserIds.first == userIds.first) {
      return;
    }
    _lastUserIds = userIds;

    _swipeItems.clear();
    final currentUser = ref.read(authProvider).value;
    for (final user in users) {
      _swipeItems.add(
        SwipeItem(
          content: user,
          likeAction: () async {
            if (currentUser == null) return;
            await ref.read(firebaseServiceProvider).likeUser(currentUser.id, user.id);
            setState(() {
              _currentIndex++;
            });
            return;
          },
          nopeAction: () async {
            if (currentUser == null) return;
            await ref.read(firebaseServiceProvider).dislikeUser(currentUser.id, user.id);
            setState(() {
              _currentIndex++;
            });
            return;
          },
          superlikeAction: () async {
            if (currentUser == null) return;
            await ref.read(firebaseServiceProvider).superLikeUser(currentUser.id, user.id);
            setState(() {
              _currentIndex++;
            });
            return;
          },
          onSlideUpdate: (region) async {
            return;
          },
        ),
      );
    }
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for new matches
    ref.listen(newMatchesProvider, (previous, next) {
      next.whenData((matches) {
        if (matches.isNotEmpty && previous?.value != matches) {
          // Show match notification
          _showMatchNotification(matches.first);
        }
      });
    });

    final usersAsync = ref.watch(discoveryUsersProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final cardWidth = screenWidth * 0.90;
    final cardHeight = screenHeight * 0.70;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        if (isDark)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1020),
                  Color(0xFF25133A),
                  Color(0xFF0B1020),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        if (!isDark)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: colorScheme.surface,
          ),
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                child: usersAsync.when(
                data: (users) {
                  if (users.isEmpty || _currentIndex >= users.length) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No users found',
                            style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/main'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }
                  _setupSwipeItems(users, ref);
                  return Center(
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: SwipeCards(
                          matchEngine: _matchEngine,
                          itemBuilder: (BuildContext context, int index) {
                            final user = users[index];
                            final currentUser = ref.read(authProvider).value;
                            double? distanceKm;
                            if (currentUser?.latitude != null &&
                                currentUser?.longitude != null &&
                                user.latitude != null &&
                                user.longitude != null) {
                              distanceKm = LocationService.distanceInKm(
                                currentUser!.latitude!,
                                currentUser.longitude!,
                                user.latitude!,
                                user.longitude!,
                              );
                            }
                            return DiscoverUserCard(
                              user: user,
                              distanceKm: distanceKm,
                              onCardTap: () => context.push('/profile/${user.id}'),
                              onLike: () => _matchEngine.currentItem?.like(),
                              onDislike: () => _matchEngine.currentItem?.nope(),
                              onSuperLike: () => _matchEngine.currentItem?.superLike(),
                              onMessage: () async {
                                final currentUser = ref.read(authProvider).value;
                                if (currentUser == null) return;
                                try {
                                  final chatId = await ref.read(firebaseServiceProvider).startOrGetChat(currentUser.id, user.id);
                                  if (context.mounted) {
                                    GoRouter.of(context).push('/chat/$chatId');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to start chat: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              onReplay: null,
                            );
                          },
                          onStackFinished: () {
                            setState(() {});
                          },
                          itemChanged: (SwipeItem item, int index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          upSwipeAllowed: true,
                          fillSpace: true,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
                error: (error, stack) => Center(
                  child: Text('Error: $error', style: TextStyle(color: colorScheme.onSurface))),
                ),
              ),
            ),
          ],
        ),
        
        // Filter popup
        if (_showFilters)
          _buildFiltersPopup(),
        // Rewind – undo last swipe (only UI; card comes back)
        usersAsync.when(
          data: (users) {
            if (users.isEmpty || _currentIndex <= 0) return const SizedBox.shrink();
            return Positioned(
              left: 20,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Material(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.9),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    _matchEngine.rewindMatch();
                    setState(() => _currentIndex--);
                  },
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(Icons.replay, color: colorScheme.primary, size: 28),
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showMatchNotification(MatchModel match) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    // Get the other user's info
    final otherUserId = match.userA == currentUser.id ? match.userB : match.userA;
    final otherUser = await ref.read(firebaseServiceProvider).getUser(otherUserId);
    
    if (otherUser == null) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'It\'s a Match! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${otherUser.name} liked each other!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Keep Swiping'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          final chatId = await ref.read(firebaseServiceProvider).startOrGetChat(currentUser.id, otherUserId);
                          if (context.mounted) {
                            GoRouter.of(context).push('/chat/$chatId');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to start chat: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showExpandedProfile(BuildContext context, UserModel user) {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B1020),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24 + MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: (user.primaryPhotoUrl ?? '').isNotEmpty
                            ? Image.network(
                                user.primaryPhotoUrl!,
                                width: double.infinity,
                                height: 320,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _photoPlaceholder(320),
                              )
                            : _photoPlaceholder(320),
                      ),
                      const SizedBox(height: 20),
                      // Name, age
                      Text(
                        '${user.name ?? ''}, ${user.age}',
                        style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bio
                      if ((user.bio ?? '').isNotEmpty) ...[
                        const Text(
                          'About',
                          style: TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.bio!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Interests
                      if (user.interests.isNotEmpty) ...[
                        const Text(
                          'Interests',
                          style: TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Diğer detaylar (varsa)
                      if (user.education != null || user.exercise != null || user.lookingFor != null) ...[
                        const Text(
                          'Details',
                          style: TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (user.education != null) _detailRow('Education', user.education!),
                        if (user.exercise != null) _detailRow('Exercise', user.exercise!),
                        if (user.lookingFor != null) _detailRow('Looking for', user.lookingFor!),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 16),
                      // Message button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              final chatId = await ref.read(firebaseServiceProvider).startOrGetChat(currentUser.id, user.id);
                              if (context.mounted) {
                                GoRouter.of(context).push('/chat/$chatId');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not start chat: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA78BFA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Send Message'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.white.withOpacity(0.08),
      child: Icon(Icons.person, size: 80, color: Colors.white.withOpacity(0.3)),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPopup() {
    final preferences = ref.watch(userPreferencesProvider);
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () {
                        setState(() {
                          _showFilters = false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Narrow your search',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),
              
              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Basic filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Advanced filters',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Filter Options
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildGenderFilter(preferences),
                      _buildAgeFilter(preferences),
                      _buildDistanceFilter(preferences),
                      _buildInterestsFilter(preferences),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Apply Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showFilters = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderFilter(UserPreferences preferences) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who would you like to date?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  'Women',
                  'female',
                  preferences.interestedIn == 'female',
                  (value) => ref.read(userPreferencesProvider.notifier).updatePreferences(
                    preferences.copyWith(interestedIn: value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGenderOption(
                  'Men',
                  'male',
                  preferences.interestedIn == 'male',
                  (value) => ref.read(userPreferencesProvider.notifier).updatePreferences(
                    preferences.copyWith(interestedIn: value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGenderOption(
                  'Everyone',
                  'all',
                  preferences.interestedIn == 'all',
                  (value) => ref.read(userPreferencesProvider.notifier).updatePreferences(
                    preferences.copyWith(interestedIn: value),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, String value, bool isSelected, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAgeFilter(UserPreferences preferences) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How old are they?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Between ${preferences.ageRange[0]} and ${preferences.ageRange[1]} years old',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(preferences.ageRange[0].toDouble(), preferences.ageRange[1].toDouble()),
            min: 18,
            max: 100,
            divisions: 82,
            labels: RangeLabels(
              preferences.ageRange[0].toString(),
              preferences.ageRange[1].toString(),
            ),
            onChanged: (values) {
              ref.read(userPreferencesProvider.notifier).updatePreferences(
                preferences.copyWith(
                  ageRange: [values.start.round(), values.end.round()],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter(UserPreferences preferences) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How far away are they?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Up to ${preferences.maxDistance} kilometres away',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: preferences.maxDistance.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: '${preferences.maxDistance} km',
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).updatePreferences(
                preferences.copyWith(maxDistance: value.round()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsFilter(UserPreferences preferences) {
    final availableInterests = [
      'Coffee', 'Travel', 'Music', 'Art', 'Sports', 'Fitness',
      'Reading', 'Movies', 'Cooking', 'Photography', 'Dancing',
      'Hiking', 'Gaming', 'Yoga', 'Pets', 'Technology'
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Do they share any of your interests?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableInterests.map((interest) {
              final isSelected = preferences.interests.contains(interest);
              return GestureDetector(
                onTap: () {
                  final newInterests = List<String>.from(preferences.interests);
                  if (isSelected) {
                    newInterests.remove(interest);
                  } else {
                    newInterests.add(interest);
                  }
                  ref.read(userPreferencesProvider.notifier).updatePreferences(
                    preferences.copyWith(interests: newInterests),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class DiscoverUserCard extends StatelessWidget {
  final UserModel user;
  final double? distanceKm;
  final VoidCallback? onCardTap;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperLike;
  final VoidCallback? onMessage;
  final VoidCallback? onReplay;
  const DiscoverUserCard({
    super.key,
    required this.user,
    this.distanceKm,
    this.onCardTap,
    this.onLike,
    this.onDislike,
    this.onSuperLike,
    this.onMessage,
    this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onCardTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              fit: StackFit.expand,
              children: [
                (user.primaryPhotoUrl ?? '').isNotEmpty
                    ? (user.photoUrls.length > 1
                        ? PageView.builder(
                            itemCount: user.photoUrls.length,
                            itemBuilder: (_, i) => Image.network(
                              user.photoUrls[i],
                              height: MediaQuery.of(context).size.height * 0.65,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.network(
                            user.primaryPhotoUrl!,
                            height: MediaQuery.of(context).size.height * 0.65,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ))
                    : Container(
                        height: MediaQuery.of(context).size.height * 0.65,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 120),
                      ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.age} years old${distanceKm != null ? ' • ${distanceKm!.round()} km away' : ''}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.bio ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(Icons.close, Colors.red, onDislike),
                _actionButton(Icons.favorite_border, Colors.pink, onLike),
                _actionButton(Icons.star, const Color(0xFF7C3AED), onSuperLike),
                _actionButton(Icons.message, Colors.blue, onMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
} 