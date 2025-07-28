import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/core/widgets/app_text_field.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/models/message_model.dart';
import 'package:luvoo/models/user_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(firebaseServiceProvider).getChatMessages(chatId);
});

final chatUsersProvider = FutureProvider.family<List<UserModel?>, String>((ref, chatId) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  final chat = await firebaseService.getChat(chatId);
  if (chat == null) return [null, null];
  
  final users = List<String>.from(chat['users']);
  final user1 = await firebaseService.getUser(users[0]);
  final user2 = await firebaseService.getUser(users[1]);
  
  return [user1, user2];
});

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(firebaseServiceProvider).sendChatMessage(
        widget.chatId,
        currentUser.id,
        text,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final chatUsersAsync = ref.watch(chatUsersProvider(widget.chatId));
    final currentUser = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/main'),
        ),
        title: chatUsersAsync.when(
          data: (users) {
            final otherUser = users.firstWhere(
              (user) => user?.id != currentUser?.id,
              orElse: () => null,
            );
            
            if (otherUser == null) {
              return const Text('Chat', style: TextStyle(color: Colors.black));
            }
            
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: otherUser.photoUrl != null
                      ? NetworkImage(otherUser.photoUrl!)
                      : null,
                  child: otherUser.photoUrl == null
                      ? const Icon(Icons.person, size: 20, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  otherUser.name ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
          loading: () => const Text('Loading...', style: TextStyle(color: Colors.black)),
          error: (_, __) => const Text('Chat', style: TextStyle(color: Colors.black)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group messages by date
                final groupedMessages = <String, List<MessageModel>>{};
                for (final message in messages) {
                  final dateKey = _formatDate(message.timestamp);
                  groupedMessages.putIfAbsent(dateKey, () => []).add(message);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: groupedMessages.length * 2, // Date + messages
                  itemBuilder: (context, index) {
                    final dateIndex = index ~/ 2;
                    final isDate = index % 2 == 0;
                    final date = groupedMessages.keys.elementAt(dateIndex);
                    final messagesForDate = groupedMessages[date]!;

                    if (isDate) {
                      // Date separator
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Messages for this date
                      return Column(
                        children: messagesForDate.map((message) {
                          final isMe = message.senderId == currentUser?.id;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.purple : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(18).copyWith(
                                        bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                                      ),
                                    ),
                                    child: Text(
                                      message.text,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                                    child: Text(
                                      _formatTime(message.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
          // Modern input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Add media button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Gift button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Message input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Your message',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.grey,
                            size: 20,
                          ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 