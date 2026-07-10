//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by v on 2024/12/2.
//

import Foundation
import NetworkExtension
import Network
import Tm
import SystemConfiguration
import OSLog
let XTunnelErrorDomain: String = "XTunnelErrorDomain"

public enum XTunnelError: Error {
    case invalidOptions
    case badConfiguration
    case cannotGetFd
    case xCreateFailed
    case xStartFailed
    case writeToTunFailed
    case nilArgument
    case redirectErrorFailed
    case noXConfig
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var x: X_darwinX?
    // used to get fd
    private let CTLIOCGINFO: UInt = 0xc064_4e03
    private let monitor = NWPathMonitor(prohibitedInterfaceTypes: [NWInterface.InterfaceType.other])
    
    private static var defaultSharedDirectory: URL! {
        #if os(macOS)
            let groupIdentifier = "K4FDLB3LLD.com.5vnetwork.x"
        #else
        // if this is invalid, the containerURL method returns nil
        let groupIdentifier = "group.com.5vnetwork.x"
        #endif
        return FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier: groupIdentifier
            )
    }

    private func getConfigPath() -> URL {
        return PacketTunnelProvider.defaultSharedDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("config", isDirectory: false)
    }

    override func startTunnel(
        options: [String: NSObject]?
    ) async throws {
        
        nsLog(msg: "startTunnel log")
        nsLog(msg: "options: \(String(describing: options))")
        nsLog(
            msg:
                "protocolConfiguration \(String(describing: (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration))"
        )
        nsLog(
            msg: PacketTunnelProvider.defaultSharedDirectory
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Caches", isDirectory: true)
                .appendingPathComponent("stderr.log").relativePath)
        
        monitor.pathUpdateHandler = { path in
            self.setDefaultNIC(path: path)
        }
        monitor.start(queue: DispatchQueue.global())
        setDefaultNIC(path: monitor.currentPath)

        ///Users//Library/Group Containers/K4FDLB3LLD.com.5vnetwork.x/Library/Caches/stderr.log
        ////private/var/mobile/Containers/Shared/AppGroup//Library/Caches/stderr.log
        var map: [String: NSObject]? = options
        // TODO: Read configuration by loadAllFromPreferences
        if map == nil {
            let protocolConfiguration =
                protocolConfiguration as! NETunnelProviderProtocol
            map =
                protocolConfiguration.providerConfiguration?["options"]
                as? [String: NSObject]
            map?["config"] = nil
        }

        // On Demand may wrap options as ["VendorData": ["options": ...]]
        if let vendorData = map?["VendorData"] as? NSDictionary {
            map = vendorData["options"] as? [String: NSObject]
        }

        guard let map else {
            throw fatalError(errorStr: "startTunnel no options")
        }

        nsLog(msg: "map: \(String(describing: map))")
        
        var enable6 = true
        // four only
        if map["tun46Setting"] as? NSNumber == 0 {
            enable6 = false
        } else if map["tun46Setting"] as? NSNumber == 1 {
            enable6 = true
        } else {
            let turnOnByApp = options != nil
            if turnOnByApp {
                enable6 = map["defaultNicSupport6"] as! NSNumber as! Bool
            } else {
                var enableIpv6: ObjCBool = false
                var error: NSError?
                X_darwinHasNICHavingGlobalIPv6Address(&enableIpv6, &error)
                if error == nil {
                    enable6 = enableIpv6.boolValue
                }
            }
        }

        let settings = try getNetworkSetting(map: map, enableIpv6: enable6)

        nsLog(msg: "networkSetting \(String(describing: settings))")
        try await setTunnelNetworkSettings(settings)

        let fd = getFd()
        if fd != nil {
            let tunName = interfaceName(tunnelFileDescriptor: fd!)
            nsLog(msg: "fd is \(fd!) tun name is \(tunName ?? "")")
        }

        var error: NSError?

        // x config
        var config = map["config"] as? Data
        if config == nil {
            do {
                config = try Data(contentsOf: getConfigPath())
                nsLog(msg: "\(String(describing: config!))")
            } catch {
                throw fatalError(errorStr: "no x config")

            }
        }

        let useFd = map["useFd"] as! NSNumber as! Bool
        x = X_darwinNew(
            config  ,
            Interface(
                packetTunnelProvider: self,
                isDebug: false,
                useFD: useFd,
                logger: Self.logger),
            enable6,
            nil,
            &error)
        if let error {
            throw fatalError(
                errorStr: "failed to create x: \(error.localizedDescription)")
        }
        do {
            try x!.start()
        } catch {
            throw fatalError(
                errorStr: "failed to start x: \(error.localizedDescription)")
        }
        
        if #available(iOSApplicationExtension 18.0, *) {
            nsLog(msg: virtualInterface?.name ?? "aaa")
        } else {
            // Fallback on earlier versions
        }
    }

    private func setDefaultNIC(path: Network.NWPath) {
        self.nsLog(msg: "path: \(path.debugDescription)")
        if path.status == .satisfied {
            let first = path.availableInterfaces.first { NWInterface in
                !NWInterface.name.contains("utun")
            }
            if first != nil {
                X_darwinUpdateDefaultRouteInterface(first!.name, first!.index)
            }
            path.availableInterfaces.forEach { NWInterface in
                self.nsLog(msg: "available nic \(NWInterface.name)")
            }
            path.gateways.forEach { NWEndpoint in
                self.nsLog(msg: "available gateway \(NWEndpoint.debugDescription)")
            }
            self.nsLog(msg: "path support ipv6: \(path.supportsIPv6)")
            self.nsLog(msg: "path constrained: \(path.isConstrained)")
            self.nsLog(msg: "path expensive: \(path.isExpensive)")
        } else {
            self.nsLog(msg: "unsatisfied \(path.unsatisfiedReason)")
        }
    }
    
    private func getNetworkSetting(map: [String: NSObject], enableIpv6: Bool) throws
        -> NEPacketTunnelNetworkSettings
    {
        let settings = NEPacketTunnelNetworkSettings(
            tunnelRemoteAddress: "127.0.0.1"
        )
        settings.mtu = map["mtu"] as? NSNumber ?? NSNumber(value: 1500)

        var dnsServers = [String]()
        let dnsServers4 = map["dnsServers4"] as? NSArray as? [String]
        if dnsServers4 != nil {
            dnsServers.append(contentsOf: dnsServers4!)
        }
        let dnsServers6 = map["dnsServers6"] as? NSArray as? [String]
        if enableIpv6 && dnsServers6 != nil {
            dnsServers.append(contentsOf: dnsServers6!)
        }
        if (dnsServers.count > 0)
        {
            settings.dnsSettings = NEDNSSettings(servers: dnsServers)
            settings.dnsSettings!.matchDomains = [""]
            settings.dnsSettings!.matchDomainsNoSearch = true

        }

        if let ipv4Addresses = map["ipv4Addresses"] as? NSArray as? [String] {
            if let ipv4SubnetMasks = map["ipv4SubnetMasks"] as? NSArray
                as? [String]
            {
                settings.ipv4Settings = NEIPv4Settings(
                    addresses: ipv4Addresses, subnetMasks: ipv4SubnetMasks)
            } else {
                throw fatalError(errorStr: "invalid ipv4 subnet mask")
            }
            if let ipv4IncludedRoutes = map["ipv4IncludedRoutes"] as? NSArray
                as? [[String: String]]
            {
                settings.ipv4Settings!.includedRoutes = ipv4IncludedRoutes.map {
                    route in
                    NEIPv4Route(
                        destinationAddress: route["destinationAddress"]!,
                        subnetMask: route["subnetMask"]!
                    )
                }
                //                settings.ipv4Settings!.includedRoutes = [
                //                    NEIPv4Route.default()
                //                ]
            }
            if let ipv4ExcludedRoutes = map["ipv4ExcludedRouteAddresses"]
                as? NSArray
                as? [[String: String]]
            {
                settings.ipv4Settings!.excludedRoutes = ipv4ExcludedRoutes.map {
                    route in
                    NEIPv4Route(
                        destinationAddress: route["destinationAddress"]!,
                        subnetMask: route["subnetMask"]!
                    )
                }
            }
        }
        
        if enableIpv6 {
            if let ipv6Addresses = map["ipv6Addresses"] as? NSArray as? [String] {
                if let ipv6NetworkPrefixLengths = map["ipv6NetworkPrefixLengths"]
                    as? NSArray as? [Int]
                {
                    settings.ipv6Settings = NEIPv6Settings(
                        addresses: ipv6Addresses,
                        networkPrefixLengths: ipv6NetworkPrefixLengths.map {
                            NSNumber(value: $0)
                        }
                    )
                } else {
                    throw fatalError(errorStr: "invalid ipv6 network prefix length")
                }
                if let ipv6IncludedRoutes = map["ipv6IncludedRoutes"] as? NSArray
                    as? [[String: Any]]
                {
                    settings.ipv6Settings!.includedRoutes = ipv6IncludedRoutes.map {
                        route in
                        NEIPv6Route(
                            destinationAddress: route["destinationAddress"]
                            as! String,
                            networkPrefixLength: (route["networkPrefixLength"]
                                                  as! Int64) as NSNumber
                        )
                    }
                }
                if let ipv6ExcludedRoutes = map["ipv6ExcludedRoutes"] as? NSArray
                    as? [[String: Any]]
                {
                    settings.ipv6Settings!.excludedRoutes = ipv6ExcludedRoutes.map {
                        route in
                        NEIPv6Route(
                            destinationAddress: route["destinationAddress"]
                            as! String,
                            networkPrefixLength: (route["networkPrefixLength"]
                                                  as! Int64) as NSNumber
                        )
                    }
                }
            }}
        return settings
    }

    private func fatalError(errorStr: String) -> Error {
        nsLog(msg: errorStr)
        let err = NSError(domain: errorStr, code: 0)
        cancelTunnelWithError(err)
        return err
    }

    // Use os_log for PacketTunnel extension logging
    // macOS 26+ redacts NSLog, so we use os_log with public formatting
    private static let logger = Logger(
        subsystem: "com.5vnetwork.x.PacketTunnel",
        category: "PacketTunnel"
    )
    
    public func nsLog(msg: String) {
        // Use privacy: .public to prevent <private> redaction in Console.app
        // This marks the message as public so it won't be redacted
        #if DEBUG
            Self.logger.info("\(msg, privacy: .public)")
        #endif
    }

    func getFd() -> Int32? {
        var fd =
            packetFlow.value(forKeyPath: "socket.fileDescriptor")
            as? Int32
        if fd != nil {
            nsLog(msg: "getFd first method works!")
            return fd
        }

        fd = X_darwinGetFd()
        if fd! > 0 {
            return fd
        }
        return nil

    }

    public func interfaceName(tunnelFileDescriptor: Int32) -> String? {
        var buffer = [UInt8](repeating: 0, count: Int(IFNAMSIZ))

        return buffer.withUnsafeMutableBufferPointer { mutableBufferPointer in
            guard let baseAddress = mutableBufferPointer.baseAddress else {
                return nil
            }

            var ifnameSize = socklen_t(IFNAMSIZ)
            let result = getsockopt(
                tunnelFileDescriptor,
                2 /* SYSPROTO_CONTROL */,
                2 /* UTUN_OPT_IFNAME */,
                baseAddress,
                &ifnameSize)

            if result == 0 {
                return String(cString: baseAddress)
            } else {
                return nil
            }
        }
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        nsLog(msg: "stopTunnel reason: \(reason)")
        do {
            try x?.close()
            x = nil
        } catch {
            nsLog(msg: "close x failed: \(error)")
        }
        completionHandler()
    }

    override func handleAppMessage(
        _ messageData: Data, completionHandler: ((Data?) -> Void)?
    ) {
        nsLog(msg: "handleAppMessage")

        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }

    override func wake() {
        // Add code here to wake up.
    }
    
    func resetNetworkSetting(enable6: Bool)  throws {
        nsLog(msg: "reset network setting: \(enable6.description)")
        let protocolConfiguration =
            protocolConfiguration as! NETunnelProviderProtocol
        let map : [String: NSObject]? =
            protocolConfiguration.providerConfiguration?["options"]
            as? [String: NSObject]
        guard let map else {
            throw fatalError(errorStr: "no providerConfigurations")
        }
        let settings = try getNetworkSetting(map: map, enableIpv6: enable6)
        nsLog(msg: "networkSetting \(String(describing: settings))")
        setTunnelNetworkSettings(settings) { error in
            if error != nil {
                self.nsLog(msg: error?.localizedDescription ?? "")
                self.cancelTunnelWithError(error)
            }
        }
    }
}

class Interface: NSObject, X_darwinInterfaceProtocol {
    private let packetTunnelProvider: PacketTunnelProvider
    private let isDebug: Bool
    private let useFD: Bool
    private let logger: Logger
    
    init(
        packetTunnelProvider: PacketTunnelProvider,
        isDebug: Bool, useFD: Bool,
        logger: Logger
    ) {
        self.packetTunnelProvider = packetTunnelProvider
        self.isDebug = isDebug
        self.useFD = useFD
        self.logger = logger
    }

    func useFd() -> Bool {
        return useFD
    }

    func getFd(_ ret0_: UnsafeMutablePointer<Int32>?) throws {
        let fd = packetTunnelProvider.getFd()
        if fd == nil {
            throw XTunnelError.cannotGetFd as NSError
        }
        if ret0_ == nil {
            throw XTunnelError.nilArgument as NSError
        }
        ret0_!.pointee = fd!
    }

    func getTunName() -> String {
        packetTunnelProvider.nsLog(msg: "getTunName")
        if #available(iOSApplicationExtension 18.0, *) {
            return packetTunnelProvider.virtualInterface?.name ?? ""
        } else {
            return ""
        }
    }
    
    func nsLog(msg: String) {
        // Use privacy: .public to prevent <private> redaction in Console.app
        // This marks the message as public so it won't be redacted
        #if DEBUG
            self.logger.info("\(msg, privacy: .public)")
        #endif
    }
    
    func setTunSupport6(_ support6: Bool) throws {
        try packetTunnelProvider.resetNetworkSetting(enable6: support6)
    }

    /// Use SystemConfiguration
    /// Similar process can be done in mac terminal:
    ///   1. scutil
    ///   2. list State:/Network/Service/.*/DNS
    ///   3. show State:/Network/Service/[SERVICEID]/DNS
    func getDnsServers(forInterface p0: String?) -> (any X_darwinStringsProtocol)? {
        // Define types for each of the calls of interest
        // Use Unmanaged for proper memory management of dynamically loaded functions
        typealias TSCDynamicStoreCreate = @convention (c) (_ allocator: CFAllocator?, _ name: CFString, _ callout: SystemConfiguration.SCDynamicStoreCallBack?, _ context: UnsafeMutablePointer<SCDynamicStoreContext>?) -> Unmanaged<SCDynamicStore>?
        typealias TSCDynamicStoreCopyValue = @convention (c) (_ store: SCDynamicStore?, _ key: CFString) -> Unmanaged<CoreFoundation.CFPropertyList>?
        typealias TSCDynamicStoreCopyKeyList = @convention (c) (_ store: SCDynamicStore?, _ key: CFString) -> Unmanaged<CFArray>?
        
        // Get a handle to the library, the flag `RT_NOLOAD` will limit this
        // to already loaded libraries
        let hLibrary = dlopen("/System/Library/Frameworks/SystemConfiguration.framework/SystemConfiguration", RTLD_NOLOAD);

        // Load addresses of the functions from the library
        let MySCDynamicStoreCreate = unsafeBitCast(dlsym(hLibrary, "SCDynamicStoreCreate"), to: TSCDynamicStoreCreate.self)
        let MySCDynamicStoreCopyValue = unsafeBitCast(dlsym(hLibrary, "SCDynamicStoreCopyValue"), to: TSCDynamicStoreCopyValue.self)
        let MySCDynamicStoreCopyKeyList = unsafeBitCast(dlsym(hLibrary, "SCDynamicStoreCopyKeyList"), to: TSCDynamicStoreCopyKeyList.self)
        
        // takeRetainedValue() transfers ownership to Swift's ARC for automatic memory management
        guard let dynamicStore = MySCDynamicStoreCreate(nil, "DNSQuery" as CFString, nil, nil)?.takeRetainedValue() else {
            return nil
        }
        
        // Get all network services
        let servicesKey4 = "State:/Network/Service/[^/]+/IPv4" as CFString
        guard let servicesCFArray4 = MySCDynamicStoreCopyKeyList(dynamicStore, servicesKey4)?.takeRetainedValue() else {
            return nil
        }
        nsLog(msg: "servicesCFArray4: \(String(describing: servicesCFArray4))")
        nsLog(msg: "servicesCFArray4: \(String(describing:  CFArrayGetCount(servicesCFArray4)))")
        
        let servicesKey6 = "State:/Network/Service/[^/]+/IPv6" as CFString
        guard let servicesCFArray6 = MySCDynamicStoreCopyKeyList(dynamicStore, servicesKey6)?.takeRetainedValue() else {
            return nil
        }
        nsLog(msg: "servicesCFArray6: \(String(describing: servicesCFArray6))")
        nsLog(msg: "servicesCFArray6: \(String(describing:  CFArrayGetCount(servicesCFArray6)))")
        
        guard let  services4 = servicesCFArray4 as? [String] else {
            return nil
        }
        guard let  services6 = servicesCFArray6 as? [String] else {
            return nil
        }
        let services = services4 + services6
        
        nsLog(msg: "services: \(services)")
        
        var serviceOfInterest = ""
        for service in services {
            if let serviceInfo = MySCDynamicStoreCopyValue(dynamicStore, service as CFString)?.takeRetainedValue() as? [String: Any],
               let device = serviceInfo["InterfaceName"] as? String, device == p0 {
                serviceOfInterest = service
            }
        }
        if serviceOfInterest.isEmpty {
            return nil
        }
        
        var serviceID = serviceOfInterest.replacingOccurrences(of: "State:/Network/Service/", with: "")
                            .replacingOccurrences(of: "/IPv4", with: "")
        serviceID = serviceID.replacingOccurrences(of: "/IPv6", with: "")
        
        nsLog(msg: "serviceID \(String(serviceID))")
        
//        var dnsKey: String?
        let dnsKey = "State:/Network/Service/\(serviceID)/DNS" as CFString

        // Retrieve DNS configuration
        guard let dnsInfo = MySCDynamicStoreCopyValue(dynamicStore, dnsKey)?.takeRetainedValue() as? [String: Any],
              let nameservers = dnsInfo["ServerAddresses"] as? [String] else {
            nsLog(msg: "Failed to retrieve DNS nameservers")
            nsLog(msg: "dnsInfo: \(String(describing: MySCDynamicStoreCopyValue(dynamicStore, dnsKey)?.takeRetainedValue()))")
            return nil
        }
        
        
        return Strings(strings: nameservers)
    }
}

class Strings: NSObject, X_darwinStringsProtocol {
    private let strings : [String]
    
    init(strings: [String]) {
        self.strings = strings
    }
    
    func get(_ index: Int) -> String {
        return strings[index]
    }
    
    func len() -> Int {
        return strings.count
    }
}


//
//class Logger: NSObject, X_darwinLoggerProtocol {
//    private let packetTunnelProvider: PacketTunnelProvider
//    init(packetTunnelProvider: PacketTunnelProvider) {
//        self.packetTunnelProvider = packetTunnelProvider
//    }
//
//    func log(_ p0: String?) {
//        if let p0 {
//            packetTunnelProvider.nsLog(msg: p0)
//        }
//    }
//}
//
//class Tun: NSObject, X_darwinTunProtocol {
//    private let packetTunnelProvider: PacketTunnelProvider
//    private var packets: [Data] = []
//
//    init(packetTunnelProvider: PacketTunnelProvider) {
//        self.packetTunnelProvider = packetTunnelProvider
//    }
//
//    func readPacket() throws -> Data {
//        // If we have cached packets, return the first one
//        if !packets.isEmpty {
//            let packet = packets.removeFirst()
//            return packet
//        }
//
//        // Read new packets
//        let semaphore = DispatchSemaphore(value: 0)
//        var newPackets: [Data] = []
//
//        packetTunnelProvider.packetFlow.readPackets { (packets, protocols) in
//            newPackets = packets
//            semaphore.signal()
//        }
//
//        // Wait indefinitely until packets are available
//        semaphore.wait()
//
//        // Cache remaining packets
//        if newPackets.count > 1 {
//            packets = Array(newPackets.dropFirst())
//        }
//
//        // Return first packet (we know there's at least one packet at this point)
//        return newPackets[0]
//    }
//
//    func writePacket(_ p0: Data?, p1: Int) throws {
//        packetTunnelProvider.nsLog(msg: "writePacket")
//        guard let packet = p0 else {
//            packetTunnelProvider.nsLog(msg: "writePacket has no data")
//            return
//        }
//
//        // Write the packet
//        let success = packetTunnelProvider.packetFlow.writePackets(
//            [packet], withProtocols: [NSNumber(value: Int32(p1))])
//        if !success {
//            packetTunnelProvider.nsLog(msg: "writePacket failed")
//            throw XTunnelError.writeToTunFailed as NSError
//        }
//    }
//}
//
