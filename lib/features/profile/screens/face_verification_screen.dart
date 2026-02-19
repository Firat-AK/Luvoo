import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/facetec_service.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/core/theme/app_theme.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';

class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  ConsumerState<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends ConsumerState<FaceVerificationScreen> {
  bool _isVerifying = false;
  String? _message;

  Future<void> _verifyFace() async {
    setState(() {
      _isVerifying = true;
      _message = null;
    });
    try {
      final result = await FaceTecService().verifyLiveness();
      if (!mounted) return;
      if (result.success) {
        final userId = ref.read(authProvider).value?.id;
        if (userId != null) {
          await ref.read(firebaseServiceProvider).updateUserFields(userId, {'faceVerified': true});
        }
        setState(() {
          _isVerifying = false;
          _message = 'Face verified successfully!';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face verified!'), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } else {
        setState(() {
          _isVerifying = false;
          _message = result.error ?? 'Verification failed or was cancelled.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _message = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Verify Face',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.face_retouching_natural,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Face Verification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Verify your identity with a quick selfie. '
                'FaceTec will ensure you\'re a real person.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _message!,
                    style: TextStyle(color: Colors.orange[300], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verifyFace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Start Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
