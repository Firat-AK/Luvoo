import 'dart:async';
import 'package:flutter/services.dart';
import 'package:luvoo/core/config/facetec_config.dart';

/// FaceTec liveness verification via native SDK.
/// When [userId] is passed and [FaceTecConfig.sessionProxyBaseUrl] is set, session is sent to our backend for 3D Enrollment so we can later run 3D:2D Profile Pic match.
class FaceTecService {
  static const _channel = MethodChannel('com.luvoo/facetec');

  /// Run FaceTec 3D Liveness. Pass [userId] to use backend proxy (enrollment) for 3D:2D Profile Pic matching.
  Future<({bool success, String? error})> verifyLiveness({String? userId}) async {
    try {
      String sessionUrl = FaceTecConfig.sessionEndpointUrl;
      if (userId != null &&
          userId.isNotEmpty &&
          FaceTecConfig.sessionProxyBaseUrl != null &&
          FaceTecConfig.sessionProxyBaseUrl!.isNotEmpty) {
        sessionUrl =
            '${FaceTecConfig.sessionProxyBaseUrl!}?userId=${Uri.encodeComponent(userId)}';
      }
      await _channel.invokeMethod('initialize', {
        'deviceKey': FaceTecConfig.deviceKeyIdentifier,
        'isProduction': FaceTecConfig.isProductionMode,
        'sessionEndpointUrl': sessionUrl,
      });
      final result = await _channel.invokeMethod<Map>('verify');
      final success = result?['success'] == true;
      final error = result?['error'] as String?;
      return (success: success, error: error);
    } on PlatformException catch (e) {
      return (success: false, error: '${e.code}: ${e.message}');
    }
  }
}
