// Copyright (C) 2026 5V Network LLC <5vnetwork@proton.me>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import NetworkExtension
//
//  MacosHostApiImpl.swift
//  Runner
//
//  Created by v on 2025-01-03.
//
import Tm

#if os(macOS)
    import FlutterMacOS
#endif
#if canImport(Cocoa)
    import Cocoa
#endif

#if os(macOS)
    @available(macOSApplicationExtension 11.0, *)
#endif
class DarwinHostApiImpl: DarwinHostApi {

    private let monitor = NWPathMonitor(prohibitedInterfaceTypes: [NWInterface.InterfaceType.other])
    private var flutterApi: DarwinFlutterApi?

    func appGroupPath() throws -> String {
        #if os(iOS)
            let path = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.5vnetwork.x"
            )?
            .relativePath
        #else
            let path = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "K4FDLB3LLD." + Bundle
                    .main.bundleIdentifier!
            )?
            .relativePath
        #endif
        debugPrint(path!)
        if path == nil {
            throw PigeonError(
                code: "nil containerURL",
                message: nil,
                details: nil
            )
        }
        return path!
    }

    func startXApiServer(
        config: FlutterStandardTypedData,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            var error: NSError?
            X_darwinStartApiServer(config.data, &error)
            if error != nil {
                completion(
                    .failure(
                        PigeonError(
                            code: error!.localizedDescription,
                            message: nil,
                            details: nil
                        )
                    )
                )
            } else {
                completion(.success(()))
            }
        }
        self.monitor.pathUpdateHandler = { path in
            self.setDefaultNIC(path: path)
        }
        self.monitor.start(queue: DispatchQueue.global())
    }

    private func setDefaultNIC(path: Network.NWPath) {
        print("path: \(path)")
        if path.status == .satisfied {
            let first = path.availableInterfaces.first { NWInterface in
                !NWInterface.name.contains("utun")
            }
            if first != nil {
                X_darwinUpdateDefaultRouteInterface(first!.name, first!.index)
            }
            path.availableInterfaces.forEach { NWInterface in
                print("available nic \(NWInterface.name)")
            }
            path.gateways.forEach { NWEndpoint in
                print("available gateway \(NWEndpoint.debugDescription)")
            }
            print("path support ipv6: \(path.supportsIPv6)")
            print("path constrained: \(path.isConstrained)")
            print("path expensive: \(path.isExpensive)")
            //                print("lq: \(path.linkQuality)")
        } else {
            print("not satisfied \(path.unsatisfiedReason)")
        }
    }

    func redirectStdErr(
        path: String,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        var error: NSError?
        X_darwinRedirectStderr(path, &error)
        if error != nil {
            completion(
                .failure(
                    PigeonError(
                        code: error!.localizedDescription,
                        message: nil,
                        details: nil
                    )
                )
            )
        } else {
            completion(.success(()))
        }
    }

    func generateTls() throws -> FlutterStandardTypedData {
        var error: NSError?
        var data = X_darwinGenerateTls(&error)
        if error != nil {
            throw PigeonError(
                code: error!.localizedDescription,
                message: nil,
                details: nil
            )
        } else if data == nil {
            throw PigeonError(
                code: "data is null",
                message: nil,
                details: nil
            )
        }
        return FlutterStandardTypedData(bytes: data!)
    }

    func setupShutdownNotification() throws {
        #if os(macOS)
            // Set up NSWorkspace notifications for system events
            let workspace = NSWorkspace.shared
            let notificationCenter = workspace.notificationCenter

            // Listen for system shutdown/restart notifications
            notificationCenter.addObserver(
                forName: NSWorkspace.willPowerOffNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.flutterApi?.onSystemWillShutdown(completion: { _ in })
            }

            notificationCenter.addObserver(
                forName: NSWorkspace.sessionDidResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                // This can indicate logout or restart
                self?.flutterApi?.onSystemWillRestart(completion: { _ in })
            }

            notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.flutterApi?.onSystemWillSleep(completion: { _ in })
            }

            // Also listen for application termination
            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.flutterApi?.onSystemWillShutdown(completion: { _ in })
            }
        #endif
    }

    func setFlutterApi(_ flutterApi: DarwinFlutterApi) {
        self.flutterApi = flutterApi
    }
}
