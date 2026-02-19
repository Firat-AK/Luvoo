package com.luvoo.luvoo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val CHANNEL = "com.luvoo/facetec"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "initialize" -> {
          // FaceTec SDK init will go here once SDK is added
          result.success(null)
        }
        "verify" -> {
          // FaceTec liveness - placeholder until SDK is added
          // TODO: Call FaceTec SDK createSession/startLiveness
          result.success(mapOf(
            "success" to false,
            "error" to "FaceTec SDK not yet added. See FACETEC_SETUP.md"
          ))
        }
        else -> result.notImplemented()
      }
    }
  }
}