import UIKit
import Flutter
import GoogleMaps
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    //Google Maps API key
    GMSServices.provideAPIKey("AIzaSyAFGuq9qZc6xGWB6S5NHZgpyExhUldiwjU")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
