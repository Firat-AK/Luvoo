import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/core/widgets/app_button.dart';
import 'package:luvoo/core/widgets/app_text_field.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/models/user_model.dart';

final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(firebaseServiceProvider).getUser(userId);
});

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _likeUser(String? comment) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(firebaseServiceProvider).likeUser(
            currentUser.id,
            widget.userId,
            comment: comment,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile liked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  void _showLikeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Like Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a comment (optional)'),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Comment',
              hint: 'Write something nice...',
              controller: _commentController,
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _likeUser(_commentController.text.trim());
            },
            child: const Text('Like'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? const Icon(Icons.person, size: 80)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.age} years old • ${user.gender}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (user.bio != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    user.bio!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 32),
                AppButton(
                  text: 'Like Profile',
                  onPressed: _showLikeDialog,
                  isLoading: _isLoading,
                  icon: const Icon(Icons.favorite),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
} 