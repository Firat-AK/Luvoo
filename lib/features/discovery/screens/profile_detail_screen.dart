import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/core/widgets/app_button.dart';
import 'package:luvoo/core/widgets/app_text_field.dart';
import 'package:luvoo/core/widgets/liquid_glass.dart';
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

  Future<void> _openChat(String otherUserId) async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;
    try {
      final chatId = await ref.read(firebaseServiceProvider).startOrGetChat(
        currentUser.id,
        otherUserId,
      );
      if (mounted) context.push('/chat/$chatId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBlockDialog(String blockedUserId) {
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? You won\'t see each other in discovery, matches, or chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final currentUser = ref.read(authProvider).value;
              if (currentUser == null) return;
              try {
                await ref.read(firebaseServiceProvider).blockUser(
                  currentUser.id,
                  blockedUserId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(
                      content: Text('User blocked.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to block: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String reportedUserId) {
    final reasons = [
      'Fake profile',
      'Inappropriate content',
      'Harassment',
      'Spam',
      'Other',
    ];
    String? selectedReason;
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Report User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this profile?'),
              const SizedBox(height: 16),
              ...reasons.map((r) => RadioListTile<String>(
                title: Text(r, style: const TextStyle(fontSize: 14)),
                value: r,
                groupValue: selectedReason,
                onChanged: (v) => setDialogState(() => selectedReason = v),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedReason == null) return;
                Navigator.pop(dialogContext);
                final currentUser = ref.read(authProvider).value;
                if (currentUser == null) return;
                try {
                  await ref.read(firebaseServiceProvider).reportUser(
                    currentUser.id,
                    reportedUserId,
                    selectedReason!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted. Thank you.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit report: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: const Color(0xFF0B1020),
      body: Stack(
        children: [
          // Gradient background (same as app theme)
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
          userAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(
                  child: Text(
                    'User not found',
                    style: TextStyle(color: Color(0xFFE5E7EB)),
                  ),
                );
              }

              return Stack(
                children: [
                  // Tüm sayfa tek scroll - boşluk kalmaz
                  CustomScrollView(
                    slivers: [
                      // Hero image
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          width: double.infinity,
                          child: (user.primaryPhotoUrl ?? '').isNotEmpty
                              ? (user.photoUrls.length > 1
                                  ? PageView.builder(
                                      itemCount: user.photoUrls.length,
                                      itemBuilder: (_, i) => Image.network(
                                        user.photoUrls[i],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                                      ),
                                    )
                                  : Image.network(
                                      user.primaryPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                                    ))
                              : _photoPlaceholder(),
                        ),
                      ),
                      // İçerik - gradient üzerinde, boşluk yok
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            24,
                            20,
                            24,
                            MediaQuery.of(context).padding.bottom + 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Text(
                              '${user.name}, ${user.age}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF9FAFB),
                              ),
                            ),
                            if (user.gender.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                user.gender,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                            ],
                            if (user.interests.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Interests',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.interests.map((s) => _buildTag(s)).toList(),
                              ),
                            ],
                            if (user.bio != null && user.bio!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user.bio!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFE5E7EB),
                                  height: 1.5,
                                ),
                              ),
                            ],
                            if (user.education != null && user.education!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildDetailRow(Icons.school_outlined, 'Education', user.education!),
                            ],
                            if (user.lookingFor != null && user.lookingFor!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(Icons.favorite_outline, 'Looking for', user.lookingFor!),
                            ],
                            if (user.familyPlans != null && user.familyPlans!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(Icons.family_restroom, 'Family plans', user.familyPlans!),
                            ],
                            if (user.exercise != null && user.exercise!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(Icons.fitness_center, 'Exercise', user.exercise!),
                            ],
                            if (user.drinking != null && user.drinking!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(Icons.local_bar_outlined, 'Drinking', user.drinking!),
                            ],
                            if (user.smoking != null && user.smoking!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(Icons.smoking_rooms, 'Smoking', user.smoking!),
                            ],
                            if (user.religion != null && user.religion!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(Icons.volunteer_activism, 'Religion', user.religion!),
                            ],
                            if (user.starSign != null && user.starSign!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(Icons.nightlight_round, 'Star sign', user.starSign!),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: GlassContainer(
                                    borderRadius: BorderRadius.circular(18),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: GestureDetector(
                                      onTap: () => _openChat(user.id),
                                      child: const Center(
                                        child: Text(
                                          'Message',
                                          style: TextStyle(
                                            color: Color(0xFFE5E7EB),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GlassContainer(
                                    borderRadius: BorderRadius.circular(18),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    opacity: 0.14,
                                    child: GestureDetector(
                                      onTap: _showLikeDialog,
                                      child: const Center(
                                        child: Text(
                                          'Like',
                                          style: TextStyle(
                                            color: Color(0xFFE5E7EB),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _showReportDialog(user.id),
                                  child: Text(
                                    'Report',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.70),
                                    ),
                                  ),
                                ),
                                Text(
                                  '  •  ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.50),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showBlockDialog(user.id),
                                  child: Text(
                                    'Block',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.70),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Üst bar overlay
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(18),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFFE5E7EB)),
                              onPressed: () => context.pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: Color(0xFFE5E7EB)),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE5E7EB),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.person, size: 120, color: Colors.grey),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE5E7EB),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 