import 'dart:async';
import 'package:flutter/services.dart';
import 'package:luvoo/core/config/facetec_config.dart';

/// FaceTec liveness verification via native SDK.
class FaceTecService {
  static const _channel = MethodChannel('com.luvoo/facetec');

  /// Run FaceTec 3D Liveness check. Returns (success, errorMessage).
  Future<({bool success, String? error})> verifyLiveness() async {
    try {
      await _channel.invokeMethod('initialize', {
        'deviceKey': FaceTecConfig.deviceKeyIdentifier,
        'isProduction': FaceTecConfig.isProductionMode,
        'sessionEndpointUrl': FaceTecConfig.sessionEndpointUrl,
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
