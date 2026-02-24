/// Agora Video Calling configuration.
///
/// Token is now fetched dynamically from Cloud Function getAgoraToken (no static token needed).
/// Set in Firebase: AGORA_APP_ID and AGORA_APP_CERTIFICATE (see BACKEND_SETUP.md).
class AgoraConfig {
  AgoraConfig._();

  /// Your Agora App ID from console.agora.io (must match the one used in Cloud Function).
  static const String appId = '74cdb290521446929f29c0faea4c127d';

  /// Legacy static token – not used; app uses getAgoraToken from backend.
  static const String token = '';
}
