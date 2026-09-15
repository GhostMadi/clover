import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Mapbox telemetry: выкл. до создания карты.
    UserDefaults.standard.set(false, forKey: "MGLMapboxMetricsEnabled")

    // Как qMed: Firebase до APNs.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // firebase_messaging 16.x + UIScene: UNUserNotificationCenter.delegate
    // должен быть выставлен ДО возврата из didFinishLaunching (плагины ещё не
    // зарегистрированы). Иначе APNs/FCM токен часто остаётся пустым.
    FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Как qMed: register после плагинов — токен попадает в Messaging.
    UIApplication.shared.registerForRemoteNotifications()
  }
}
