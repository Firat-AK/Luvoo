import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:luvoo/core/config/agora_config.dart';

class AgoraService {
  RtcEngine? _engine;
  RtcEngine get engine => _engine!;

  bool get isInitialized => _engine != null;

  Future<bool> requestPermissions() async {
    final mic = await Permission.microphone.request();
    final camera = await Permission.camera.request();
    return mic.isGranted && camera.isGranted;
  }

  Future<void> initialize() async {
    if (_engine != null) return;
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> joinChannel({
    required String channelId,
    required int uid,
    String token = AgoraConfig.token,
  }) async {
    if (_engine == null) await initialize();
    await _engine!.enableVideo();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.startPreview();
    await _engine!.joinChannel(
      token: token.isEmpty ? '' : token,
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
  }

  int uidFromUserId(String userId) {
    // Agora uid must be int. Use hash of userId for consistency.
    return userId.hashCode.abs() % 2147483647;
  }
}
