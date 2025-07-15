import Flutter
import UIKit
import Firebase
import UserNotifications
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("GOOGLE_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
