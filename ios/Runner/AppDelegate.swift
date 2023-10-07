import UIKit
import Flutter
import NetworkExtension
import WireGuardKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var wireguardMethodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        wireguardMethodChannel = FlutterMethodChannel(name: "net.caspians.app/wireguard",
                                                      binaryMessenger: controller.binaryMessenger)

        wireguardMethodChannel?.setMethodCallHandler({ [weak self] call, result in
            if call.method == "connect" {
                if let arguments = call.arguments as? [String: Any],
                   let serverAddress = arguments["serverAddress"] as? String,
                   let wgQuickConfig = arguments["wgQuickConfig"] as? String {
                    self?.connect(serverAddress: serverAddress, wgQuickConfig: wgQuickConfig, result: result)
                } else {
                    result(false)
                }
            } else if call.method == "disconnect" {
                self?.disconnect(result: result)
            } else if call.method == "getStatus" {
                self?.getStatus(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func connect(serverAddress: String, wgQuickConfig: String, result: @escaping FlutterResult) {
        FlutterWireGuardVPNManager.connect(serverAddress: serverAddress, wgQuickConfig: wgQuickConfig) { success in
            result(success)
        }
    }
    
    private func disconnect(result: @escaping FlutterResult) {
        FlutterWireGuardVPNManager.disconnect(){ succes in
            result(succes)
        }
    }
    
    private func getStatus(result: @escaping FlutterResult) {
        FlutterWireGuardVPNManager.getStatus{ status in
            result(status)
        }
    }
}
