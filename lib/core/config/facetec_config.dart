/// FaceTec configuration.
/// Device Key from dev.facetec.com → Account Info & Encryption Keys
class FaceTecConfig {
  FaceTecConfig._();

  static const String deviceKeyIdentifier = 'dOijCXMr4A4FPL2oEzKoaAR2FlBCv1eP';

  /// Test mode: uses FaceTec's Test API. Set false when you have production Server SDK.
  static const bool isProductionMode = false;

  /// v10 Testing API: https://api.facetec.com/api/v4/biometrics (dev.facetec.com → API → Testing API)
  /// Production: kendi backend'in (FaceTec Server SDK).
  static const String sessionEndpointUrl =
      'https://api.facetec.com/api/v4/biometrics/process-request';
}
