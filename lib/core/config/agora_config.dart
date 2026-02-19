/// Agora Video Calling configuration.
///
/// Setup:
/// 1. Create project at https://console.agora.io/
/// 2. Copy App ID and replace YOUR_AGORA_APP_ID below
/// 3. For dev: enable "Testing mode" in project (token can be empty)
/// 4. For production: implement token server, set token here
///
/// Also run: firebase deploy --only firestore:indexes (for calls collection index)
class AgoraConfig {
  AgoraConfig._();

  /// Your Agora App ID from console.agora.io
  static const String appId = '74cdb290521446929f29c0faea4c127d';

  /// Token: temporary token for channel CCmROKii8lnyitt2BCO9. Regenerate when expired.
  static const String token = '007eJxTYNj2uvmjjnfAk9AV3Ds3XfoblLno1TvxDRUBs9zdvmnNKhNTYDA3SU5JMrI0MDUyNDExszSyTDOyTDZIS0xNNEk2NDJP2fm3O7MhkJGh6LofMyMDBIL4IgzOzrlB/t6ZmRY5eZWZJSVGTs7+lgwMADvDJs8=';
}
