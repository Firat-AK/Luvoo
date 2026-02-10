import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/models/user_model.dart';
import 'package:luvoo/core/widgets/liquid_glass.dart';
import 'package:intl/intl.dart';
import 'package:luvoo/models/match_model.dart';

final chatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    print('[DEBUG] No authenticated user found in chat list provider');
    return Stream.value([]);
  }
  print('[DEBUG] Current user UID (chat list): \'${user.id}\'');
  return ref.watch(firebaseServiceProvider).getUserChats(user.id);
});

final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(firebaseServiceProvider).getUser(userId);
});

final userMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firebaseServiceProvider).getUserMatches(user.id);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);
    final matchesAsync = ref.watch(userMatchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? null : colorScheme.surface,
      body: Stack(
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
          Column(
            children: [
              // Glass AppBar
              SafeArea(
                bottom: false,
                child:                 GlassAppBar(
                  height: 64,
                  title: Text(
                    'Chats',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Requests (2)',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.search, color: colorScheme.onSurface),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Matches Section (fixed height so chat list gets rest)
                    matchesAsync.when(
                      data: (matches) {
                        if (matches.isNotEmpty) {
                          return Container(
                            height: 120,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Your Matches',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: matches.length,
                                    itemBuilder: (context, index) {
                                      final match = matches[index];
                                      return MatchCard(match: match);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    if (matchesAsync.value?.isNotEmpty == true)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    // Chats Section – takes all remaining space
                    Expanded(
                      child: chatsAsync.when(
                        data: (chats) {
                          if (chats.isEmpty && matchesAsync.value?.isEmpty != false) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'No chats yet',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start matching with people to begin chatting!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton(
                                    onPressed: () => context.go('/main'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Text(
                                      'Find Matches',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: EdgeInsets.only(
                              top: 8,
                              bottom: 8 + MediaQuery.of(context).padding.bottom + 80,
                            ),
                            itemCount: chats.length,
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              return ModernChatCard(chat: chat);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Color(0xFFE5E7EB)),
                        ),
                        error: (error, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error: $error',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MatchCard extends ConsumerWidget {
  final MatchModel match;

  const MatchCard({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    final otherUserId = match.userA == currentUser.id ? match.userB : match.userA;
    final otherUserAsync = ref.watch(userProvider(otherUserId));

    return otherUserAsync.when(
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();

        return Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
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
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.pink, width: 2),
                  ),
                  child: ClipOval(
                    child: (otherUser.primaryPhotoUrl ?? '').isNotEmpty
                        ? Image.network(
                            otherUser.primaryPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                otherUser.name ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class ModernChatCard extends ConsumerWidget {
  final Map<String, dynamic> chat;

  const ModernChatCard({
    super.key,
    required this.chat,
  });

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    final users = List<String>.from(chat['users']);
    final otherUserId = users.firstWhere((id) => id != currentUser.id);
    final otherUserAsync = ref.watch(userProvider(otherUserId));

    return otherUserAsync.when(
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();

        final lastMessage = chat['lastMessage'] as String?;
        final lastMessageTime = chat['lastMessageTime'] as DateTime?;
        final unreadCount = chat['unreadCount'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/chat/${chat['id']}'),
                borderRadius: BorderRadius.circular(22),
                child: Row(
                  children: [
                    // Profile image
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: (otherUser.primaryPhotoUrl ?? '').isNotEmpty
                              ? NetworkImage(otherUser.primaryPhotoUrl!)
                              : null,
                          child: (otherUser.primaryPhotoUrl ?? '').isEmpty
                              ? Icon(Icons.person, size: 32, color: Colors.white.withOpacity(0.6))
                              : null,
                        ),
                        // Online indicator (you can add this later)
                        if (false) // Set to true when you have online status
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Chat info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherUser.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF9FAFB),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (lastMessageTime != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(lastMessageTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: unreadCount > 0 
                                        ? const Color(0xFFA78BFA) 
                                        : Colors.white.withOpacity(0.6),
                                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage ?? 'No messages yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: unreadCount > 0 
                                        ? const Color(0xFFE5E7EB) 
                                        : Colors.white.withOpacity(0.70),
                                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF08111F),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.red,
              child: Icon(Icons.error, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Error loading chat',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 