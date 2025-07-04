import UIKit
import Flutter
import WatchConnectivity
//import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var watchSession: WCSession?
    
    private lazy var flutterMethodChannel: FlutterMethodChannel = {
        let controller = window?.rootViewController as! FlutterViewController
        return FlutterMethodChannel(
            name: "com.sashkyn.kekable",
            binaryMessenger: controller.binaryMessenger
        )
    }()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        GeneratedPluginRegistrant.register(with: self)
        
        //WorkmanagerPlugin.registerTask(withIdentifier: "update-today-minds")
        //UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*60)) // Each 1 hour.
        
        // MARK: Activation Apple Watch Session
        if WCSession.isSupported() {
            watchSession = WCSession.default
            watchSession?.delegate = self
            watchSession?.activate()
        }
        
        // MARK: Registation method channel
        
        flutterMethodChannel.setMethodCallHandler { [weak self] call, result in
            let methodArguments = call.arguments
            
            guard let watchSession = self?.watchSession,
                  watchSession.isPaired,
                  var messageData = (methodArguments as? Array<Any>)?.first as? [String: Any] else {
//                result("watch not paired")
                return
            }
            
            guard watchSession.isReachable else {
//                result("watch not reachable")
                return
            }
            
            // INFO: Добавляем название метода в параметры сообщения
            messageData["method"] = call.method
            
            watchSession.sendMessage(
                messageData,
                replyHandler: nil,
                errorHandler: { error in result(error) }
            )
            
//            result(())
        }
        
        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
  }
}

extension AppDelegate: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("AppDelegate WC: activationDidCompleteWith - \(activationState)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("AppDelegate WC: sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("AppDelegate WC: sessionDidDeactivate")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("AppDelegate WC: session didReceiveMessage - \(message)")
        
        guard let methodName = message["method"] as? String else {
            return
        }
        
        var arguments: [String: Any] = message
        arguments.removeValue(forKey: "method")
        
        flutterMethodChannel.invokeMethod(methodName, arguments: arguments)
    }
}
