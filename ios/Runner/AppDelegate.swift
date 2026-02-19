import Flutter
import UIKit
import UserNotifications
import FaceTecSDK

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var facetecSDKInstance: FaceTecSDKInstance?
  private var verifyResult: FlutterResult?
  private var currentVerifyProcessor: FaceTecVerifyProcessor?
  private var sessionEndpointUrl: String = ""
  private var useTestingAPI: Bool = true
  private var deviceKey: String = ""

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let channel = FlutterMethodChannel(name: "com.luvoo/facetec", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "initialize":
        self.handleInitialize(call: call, result: result)
      case "verify":
        self.handleVerify(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let deviceKey = args["deviceKey"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "deviceKey required", details: nil))
      return
    }
    sessionEndpointUrl = (args["sessionEndpointUrl"] as? String) ?? "https://api.facetec.com/api/v4/biometrics/process-request"
    useTestingAPI = (args["isProduction"] as? Bool) == false
    self.deviceKey = deviceKey

    FaceTec.sdk.setBundleForFaceTecImages(Bundle(for: FaceTec.self))
    let processor = FaceTecSessionRequestProcessorImpl(
      endpointUrl: sessionEndpointUrl,
      useTestingAPI: useTestingAPI,
      deviceKey: deviceKey,
      onSuccess: { [weak self] sdkInstance in
        DispatchQueue.main.async {
          self?.facetecSDKInstance = sdkInstance
          result(nil)
        }
      },
      onError: { [weak self] error in
        DispatchQueue.main.async {
          self?.facetecSDKInstance = nil
          result(FlutterError(code: "INIT_FAILED", message: error, details: nil))
        }
      }
    )

    FaceTec.sdk.initializeWithSessionRequest(
      deviceKeyIdentifier: deviceKey,
      sessionRequestProcessor: processor,
      completion: processor
    )
  }

  private func handleVerify(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard let sdkInstance = self.facetecSDKInstance else {
        result(["success": false, "error": "FaceTec not initialized. Call initialize first."])
        return
      }
      guard let fromVC = self.topViewController(from: self.window?.rootViewController) else {
        result(["success": false, "error": "No view controller to present from"])
        return
      }

      self.verifyResult = result
      let processor = FaceTecVerifyProcessor(
        endpointUrl: self.sessionEndpointUrl,
        useTestingAPI: self.useTestingAPI,
        deviceKey: self.deviceKey,
        onExit: { [weak self] sessionStatus in
          DispatchQueue.main.async {
            guard let self = self else { return }
            let success = (sessionStatus == .sessionCompleted)
            let statusMsg = self.statusMessage(sessionStatus)
            self.verifyResult?(["success": success, "error": success ? nil : statusMsg, "status": sessionStatus.rawValue])
            self.verifyResult = nil
            self.currentVerifyProcessor = nil
          }
        }
      )
      self.currentVerifyProcessor = processor

      let customization = FaceTecCustomization()
      customization.guidanceCustomization.retryScreenIdealImage = nil
      FaceTec.sdk.setCustomization(customization)
      let facetecVC = sdkInstance.start3DLiveness(with: processor)
      fromVC.present(facetecVC, animated: true)
    }
  }

  private func statusMessage(_ s: FaceTecSessionStatus) -> String {
    switch s {
    case .sessionCompleted: return "Success"
    case .userCancelledFaceScan: return "User cancelled"
    case .requestAborted: return "Session API failed (check API URL/headers)"
    case .lockedOut: return "Locked out"
    case .cameraError: return "Camera error"
    case .cameraPermissionsDenied: return "Camera permission denied"
    default: return "Verification failed (code: \(s.rawValue))"
    }
  }

  private func topViewController(from root: UIViewController?) -> UIViewController? {
    guard let root = root else { return nil }
    if let presented = root.presentedViewController {
      return topViewController(from: presented)
    }
    if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
      return topViewController(from: visible)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(from: selected)
    }
    return root
  }
}

// MARK: - Init session request processor
private class FaceTecSessionRequestProcessorImpl: NSObject, FaceTecSessionRequestProcessor, FaceTecInitializeCallback {
  private let endpointUrl: String
  private let useTestingAPI: Bool
  private let deviceKey: String
  private let onSuccess: (FaceTecSDKInstance) -> Void
  private let onError: (String) -> Void
  private var sessionRequestCallback: FaceTecSessionRequestProcessorCallback?
  private var lastApiError: String?

  init(endpointUrl: String, useTestingAPI: Bool, deviceKey: String, onSuccess: @escaping (FaceTecSDKInstance) -> Void, onError: @escaping (String) -> Void) {
    self.endpointUrl = endpointUrl
    self.useTestingAPI = useTestingAPI
    self.deviceKey = deviceKey
    self.onSuccess = onSuccess
    self.onError = onError
  }

  func onSessionRequest(sessionRequestBlob: String, sessionRequestCallback: FaceTecSessionRequestProcessorCallback) {
    self.sessionRequestCallback = sessionRequestCallback
    postSessionRequest(sessionRequestBlob: sessionRequestBlob) { [weak self] responseBlob in
      DispatchQueue.main.async {
        if let blob = responseBlob {
          self?.sessionRequestCallback?.processResponse(blob)
        } else {
          self?.sessionRequestCallback?.abortOnCatastrophicError()
        }
        self?.sessionRequestCallback = nil
      }
    }
  }

  func onFaceTecExit(sessionResult: FaceTecSessionResult) {
    // Not used for init
  }

  func onFaceTecSDKInitializeSuccess(sdkInstance: FaceTecSDKInstance) {
    onSuccess(sdkInstance)
  }

  func onFaceTecSDKInitializeError(error: FaceTecInitializationError) {
    let msg = lastApiError ?? FaceTec.sdk.description(for: error)
    onError(msg)
  }

  private func postSessionRequest(sessionRequestBlob: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: endpointUrl) else {
      completion(nil)
      return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if useTestingAPI {
      let key = deviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
      request.setValue(key, forHTTPHeaderField: "X-Device-Key")
      request.setValue(FaceTec.sdk.getTestingAPIHeader(), forHTTPHeaderField: "X-User-Agent")
    }
    let body: [String: Any] = ["requestBlob": sessionRequestBlob]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      if let error = error {
        self?.lastApiError = "Network error: \(error.localizedDescription)"
        DispatchQueue.main.async { completion(nil) }
        return
      }
      let httpResponse = response as? HTTPURLResponse
      let statusCode = httpResponse?.statusCode ?? 0
      if statusCode != 200 {
        let bodyStr = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        self?.lastApiError = "API error: status=\(statusCode) body=\(bodyStr.prefix(300))"
        DispatchQueue.main.async { completion(nil) }
        return
      }
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let blob = json["responseBlob"] as? String ?? json["sessionResponseBlob"] as? String ?? json["sessionToken"] as? String ?? String(data: data, encoding: .utf8) else {
        let bodyStr = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        self?.lastApiError = "Parse error: no responseBlob. body=\(bodyStr.prefix(300))"
        DispatchQueue.main.async { completion(nil) }
        return
      }
      DispatchQueue.main.async { completion(blob) }
    }.resume()
  }
}

// MARK: - Verify (liveness) session processor
private class FaceTecVerifyProcessor: NSObject, FaceTecSessionRequestProcessor {
  private let endpointUrl: String
  private let useTestingAPI: Bool
  private let deviceKey: String
  private let onExit: (FaceTecSessionStatus) -> Void
  private var sessionRequestCallback: FaceTecSessionRequestProcessorCallback?

  init(endpointUrl: String, useTestingAPI: Bool, deviceKey: String, onExit: @escaping (FaceTecSessionStatus) -> Void) {
    self.endpointUrl = endpointUrl
    self.useTestingAPI = useTestingAPI
    self.deviceKey = deviceKey
    self.onExit = onExit
  }

  func onSessionRequest(sessionRequestBlob: String, sessionRequestCallback: FaceTecSessionRequestProcessorCallback) {
    self.sessionRequestCallback = sessionRequestCallback
    postSessionRequest(sessionRequestBlob: sessionRequestBlob) { [weak self] responseBlob in
      DispatchQueue.main.async {
        if let blob = responseBlob {
          self?.sessionRequestCallback?.processResponse(blob)
        } else {
          self?.sessionRequestCallback?.abortOnCatastrophicError()
        }
        self?.sessionRequestCallback = nil
      }
    }
  }

  func onFaceTecExit(sessionResult: FaceTecSessionResult) {
    onExit(sessionResult.sessionStatus)
  }

  private func postSessionRequest(sessionRequestBlob: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: endpointUrl) else {
      completion(nil)
      return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if useTestingAPI {
      let key = deviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
      request.setValue(key, forHTTPHeaderField: "X-Device-Key")
      request.setValue(FaceTec.sdk.getTestingAPIHeader(), forHTTPHeaderField: "X-User-Agent")
    }
    let body: [String: Any] = ["requestBlob": sessionRequestBlob]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        print("[FaceTec] Session request error: \(error.localizedDescription)")
        DispatchQueue.main.async { completion(nil) }
        return
      }
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let blob = json["responseBlob"] as? String ?? json["sessionResponseBlob"] as? String ?? json["sessionToken"] as? String ?? String(data: data, encoding: .utf8) else {
        DispatchQueue.main.async { completion(nil) }
        return
      }
      DispatchQueue.main.async { completion(blob) }
    }.resume()
  }
}
