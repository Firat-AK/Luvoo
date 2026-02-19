import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/features/chat/screens/video_call_screen.dart';
import 'package:luvoo/core/theme/app_theme.dart';
import 'package:luvoo/routes/app_router.dart';

class IncomingCallOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const IncomingCallOverlay({super.key, required this.child});

  @override
  ConsumerState<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends ConsumerState<IncomingCallOverlay> {
  StreamSubscription? _subscription;
  bool _dialogShown = false;
  String? _lastCalleeId;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenToIncomingCalls(String calleeId) {
    if (_lastCalleeId == calleeId) return;
    _lastCalleeId = calleeId;
    _subscription?.cancel();
    _subscription = ref
        .read(firebaseServiceProvider)
        .listenToIncomingCalls(calleeId)
        .listen((call) {
      if (call == null) {
        if (_dialogShown) {
          final navKey = ref.read(rootNavigatorKeyProvider);
          navKey.currentState?.maybePop();
          _dialogShown = false;
        }
        return;
      }
      if (_dialogShown) return;
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _dialogShown = false;
          return;
        }
        final navKey = ref.read(rootNavigatorKeyProvider);
        final ctx = navKey.currentContext;
        if (ctx == null) {
          _dialogShown = false;
          return;
        }
        _showIncomingCallDialog(ctx, call);
      });
    });
  }

  void _showIncomingCallDialog(BuildContext context, Map<String, dynamic> call) {
    final chatId = call['chatId'] as String? ?? call['id'] as String?;
    final callerName = call['callerName'] as String? ?? 'Someone';
    if (chatId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _IncomingCallDialog(
        chatId: chatId,
        callerName: callerName,
        onAccept: () async {
          _dialogShown = false;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          await ref.read(firebaseServiceProvider).updateCallStatus(chatId, 'active');
          final navCtx = ref.read(rootNavigatorKeyProvider).currentContext;
          if (navCtx != null && navCtx.mounted) {
            GoRouter.of(navCtx).push(
              '/video-call/$chatId',
              extra: {'otherUserName': callerName, 'isInitiator': false},
            );
          }
        },
        onDecline: () async {
          _dialogShown = false;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          await ref.read(firebaseServiceProvider).updateCallStatus(chatId, 'declined');
        },
      ),
    ).then((_) {
      _dialogShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    auth.whenData((user) {
      if (user != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _listenToIncomingCalls(user.id);
        });
      } else {
        _lastCalleeId = null;
        _subscription?.cancel();
      }
    });
    ref.listen(authProvider, (_, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          _listenToIncomingCalls(user.id);
        } else {
          _lastCalleeId = null;
          _subscription?.cancel();
        }
      });
    });

    return widget.child;
  }
}

class _IncomingCallDialog extends StatelessWidget {
  final String chatId;
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingCallDialog({
    required this.chatId,
    required this.callerName,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppTheme.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'Incoming video call',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decline
                  GestureDetector(
                    onTap: onDecline,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(width: 48),
                  // Accept
                  GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call, color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
