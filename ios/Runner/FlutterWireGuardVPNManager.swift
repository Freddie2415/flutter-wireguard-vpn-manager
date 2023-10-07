//
//  VPNManager.swift
//  Runner
//
//  Created by Фаррух Хамракулов on 07/10/23.
//

import Foundation
import NetworkExtension
import WireGuardKit

class FlutterWireGuardVPNManager {
    
    static func connect(serverAddress: String, wgQuickConfig: String, completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences{ tunnelManagersInSettings, error in
            if let error = error {
                NSLog("Error (loadAllFromPreferences): \(error)")
                completion(false)
                return
            }
            let preExistingTunnelManager = tunnelManagersInSettings?.first
            let tunnelManager = preExistingTunnelManager ?? NETunnelProviderManager()
            
            let protocolConfiguration = NETunnelProviderProtocol()
            
            protocolConfiguration.providerBundleIdentifier = "net.caspians.testapp.WireGuardNE"
            protocolConfiguration.serverAddress = serverAddress
            protocolConfiguration.providerConfiguration = [
                "wgQuickConfig": wgQuickConfig
            ]
            
            tunnelManager.protocolConfiguration = protocolConfiguration
            tunnelManager.isEnabled = true
            
            tunnelManager.saveToPreferences { error in
                if let error = error {
                    NSLog("Error (saveToPreferences): \(error)")
                    completion(false)
                } else {
                    tunnelManager.loadFromPreferences { error in
                        if let error = error {
                            NSLog("Error (loadFromPreferences): \(error)")
                            completion(false)
                        } else {
                            NSLog("Starting the tunnel")
                            if let session = tunnelManager.connection as? NETunnelProviderSession {
                                do {
                                    try session.startTunnel(options: nil)
                                    completion(true)
                                } catch {
                                    NSLog("Error (startTunnel): \(error)")
                                    completion(false)
                                }
                            } else {
                                NSLog("tunnelManager.connection is invalid")
                                completion(false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    static func disconnect(completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { tunnelManagersInSettings, error in
            if let error = error {
                NSLog("Error (loadAllFromPreferences): \(error)")
                completion(false)
                return
            }
            
            if let tunnelManager = tunnelManagersInSettings?.first {
                guard let session = tunnelManager.connection as? NETunnelProviderSession else {
                    NSLog("tunnelManager.connection is invalid")
                    completion(false)
                    return
                }
                switch session.status {
                case .connected, .connecting, .reasserting:
                    NSLog("Stopping the tunnel")
                    session.stopTunnel()
                    completion(true)
                default:
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    static func getStatus(completion: @escaping (Int) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences{ tunnelManagersInSettings, error in
            if let error = error {
                completion(0)
                return
            }
            
            if let tunnelManager = tunnelManagersInSettings?.first {
                guard let session = tunnelManager.connection as? NETunnelProviderSession else {
                    NSLog("tunnelManager.connection is invalid")
                    completion(0)
                    return
                }
                
                completion(session.status.rawValue)
            }
        }
    }
}


