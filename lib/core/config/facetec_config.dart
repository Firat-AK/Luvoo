/// FaceTec configuration.
/// Device Key from dev.facetec.com → Account Info & Encryption Keys
class FaceTecConfig {
  FaceTecConfig._();

  static const String deviceKeyIdentifier = 'dOijCXMr4A4FPL2oEzKoaAR2FlBCv1eP';

  /// Test mode: uses FaceTec's Test API. Set false when you have production Server SDK.
  static const bool isProductionMode = false;

  /// Direct FaceTec API (used when sessionProxyBaseUrl is null).
  static const String sessionEndpointUrl =
      'https://api.facetec.com/api/v4/biometrics/process-request';

  /// Our backend proxy for 3D Enrollment + 3D:2D Profile Pic. Set to your processFaceTecSession URL.
  /// Example: https://us-central1-YOUR_PROJECT.cloudfunctions.net/processFaceTecSession
  /// If set, sessionEndpointUrl becomes this + ?userId= so FaceMap is enrolled under userId.
  static const String? sessionProxyBaseUrl =
      'https://us-central1-luvoo-app.cloudfunctions.net/processFaceTecSession';
}
