import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:luvoo/core/services/agora_service.dart';
import 'package:luvoo/core/services/firebase_service.dart';
import 'package:luvoo/features/auth/providers/auth_provider.dart';
import 'package:luvoo/core/theme/app_theme.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final bool isInitiator;

  const VideoCallScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.isInitiator = true,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  final _agoraService = AgoraService();
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isJoining = true;
  String? _error;
  StreamSubscription? _callSubscription;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) {
      setState(() {
        _error = 'Not logged in';
        _isJoining = false;
      });
      return;
    }

    final hasPermission = await _agoraService.requestPermissions();
    if (!hasPermission && mounted) {
      setState(() {
        _error = 'Camera and microphone permissions required';
        _isJoining = false;
      });
      return;
    }
    _error = null;

    debugPrint('[VideoCall] Joining channel — chatId: ${widget.chatId}');

    final uid = _agoraService.uidFromUserId(currentUser.id);
    String token;
    try {
      token = await ref.read(firebaseServiceProvider).getAgoraToken(widget.chatId, uid: uid);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not get call token. Make sure Agora is configured in Firebase (AGORA_APP_ID, AGORA_APP_CERTIFICATE). $e';
          _isJoining = false;
        });
      }
      return;
    }

    _callSubscription = ref
        .read(firebaseServiceProvider)
        .listenToCall(widget.chatId)
        .listen((call) {
      if (call != null && call['status'] == 'ended' && mounted) {
        _endCall();
      }
    });

    try {
      await _agoraService.initialize();

      _agoraService.engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                _localUserJoined = true;
                _isJoining = false;
              });
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) {
              setState(() => _remoteUid = remoteUid);
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            if (mounted) {
              setState(() => _remoteUid = null);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            if (mounted) {
              setState(() {
                _error = 'Agora: $msg (code $err). '
                    'Token may be for a different chat or expired – generate a new token for this chat in Agora Console.';
                _isJoining = false;
              });
            }
          },
        ),
      );

      await _agoraService.joinChannel(
        channelId: widget.chatId,
        uid: uid,
        token: token,
      );
      // Show local video immediately (preview already started in joinChannel)
      if (mounted) {
        setState(() => _localUserJoined = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _endCall() async {
    await _callSubscription?.cancel();
    await ref.read(firebaseServiceProvider).endCall(widget.chatId);
    await _agoraService.leaveChannel();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _agoraService.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            Center(
              child: _remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _agoraService.engine,
                        canvas: VideoCanvas(uid: _remoteUid!),
                        connection: RtcConnection(channelId: widget.chatId),
                      ),
                    )
                  : _error != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red[300], fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: () async {
                                await openAppSettings();
                                if (mounted) {
                                  setState(() { _error = null; _isJoining = true; });
                                  _initCall();
                                }
                              },
                              icon: const Icon(Icons.settings, color: Colors.white),
                              label: const Text('Open Settings', style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() { _error = null; _isJoining = true; });
                                _initCall();
                              },
                              child: const Text('Retry', style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        )
                      : _isJoining
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(height: 24),
                                Text(
                                  'Joining call...',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Text(
                              'Waiting for ${widget.otherUserName} to join...',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
            ),
            // Local video (pip)
            if (_localUserJoined)
              Positioned(
                top: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _agoraService.engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: _endCall,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Channel: ${widget.chatId}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // End call button
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
