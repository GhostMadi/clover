import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pushChannel: FlutterMethodChannel?
  private var lastApnsError: String?
  private var lastApnsTokenLen: Int = 0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Mapbox telemetry: выкл. до создания карты (меньше шума / лагов EventsService на cold start).
    UserDefaults.standard.set(false, forKey: "MGLMapboxMetricsEnabled")

    // Firebase ДО APNs. registerForRemoteNotifications — после плагинов
    // (didInitializeImplicitFlutterEngine), иначе токен может не попасть в Messaging.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "clover/push_apns",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "gone", message: nil, details: nil))
        return
      }
      switch call.method {
      case "reregister":
        self.lastApnsError = nil
        UIApplication.shared.registerForRemoteNotifications()
        result(nil)
      case "status":
        #if targetEnvironment(simulator)
        let simulator = true
        #else
        let simulator = false
        #endif
        result([
          "simulator": simulator,
          "lastError": self.lastApnsError as Any,
          "tokenLen": self.lastApnsTokenLen,
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    pushChannel = channel

    UIApplication.shared.registerForRemoteNotifications()
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    lastApnsError = nil
    lastApnsTokenLen = deviceToken.count
    // Debug entitlement = development → sandbox; Release/TestFlight = production.
    #if DEBUG
    Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
    #else
    Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
    #endif
    NSLog("[Push] APNs ok · len=%d", deviceToken.count)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    lastApnsError = error.localizedDescription
    lastApnsTokenLen = 0
    NSLog("[Push] APNs fail · %@", error.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  /// Показ push, пока приложение на экране (иначе iOS глотает banner).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
}
