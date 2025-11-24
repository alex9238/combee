/*import Flutter
import UIKit
import flutter_background_service_ios // add this



@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
*/

/*
import UIKit
import Flutter
import flutter_background_service_ios
import CoreLocation


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ✅ Muy importante: el mismo identificador que está en Info.plist
    CLLocationManager().allowsBackgroundLocationUpdates = true

    SwiftFlutterBackgroundServicePlugin.taskIdentifier = "dev.flutter.background.refresh"

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}*/


import UIKit
import Flutter
import flutter_background_service_ios
import CoreLocation
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ✅ Permitir actualizaciones de ubicación en background
        let locationManager = CLLocationManager()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

        // ✅ Configurar identificador para el plugin (coincide con Info.plist)
        SwiftFlutterBackgroundServicePlugin.taskIdentifier = "dev.flutter.background.refresh"

        // ✅ Registrar plugins Flutter
        GeneratedPluginRegistrant.register(with: self)

        // ✅ Solicitar permisos de notificaciones locales
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("⚠️ Error solicitando permisos de notificación: \(error)")
            } else {
                print("🔔 Permiso de notificaciones otorgado: \(granted)")
            }
        }

        // ✅ Configurar como centro de notificaciones
        UNUserNotificationCenter.current().delegate = self

        // ❌ NO registrar BGTaskScheduler manualmente
        // El plugin flutter_background_service_ios se encarga de registrar la tarea
        // si estás usando iOS 13+ y background tasks.
        // Esto evita el crash de "Launch handler already registered"

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
