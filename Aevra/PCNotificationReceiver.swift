// BUILD FIX FOR PCNotificationReceiver.swift
//
// Apply these changes to the existing file in:
// Aevra/PCNotificationReceiver.swift
//
// 1) Add this import near the other imports:
import Darwin

// 2) Replace the existing newConnectionHandler block:
//
// newListener.newConnectionHandler = { [weak self] connection in
//     self?.receiveTCP(connection)
// }
//
// with:
//
// newListener.newConnectionHandler = { [weak self] connection in
//     Task { @MainActor [weak self] in
//         self?.receiveTCP(connection)
//     }
// }

// 3) Add this method INSIDE PCNotificationReceiver, before its final closing brace:

private static func wifiAddress() -> String? {
    var interfaceAddresses: UnsafeMutablePointer<ifaddrs>?

    guard getifaddrs(&interfaceAddresses) == 0,
          let firstAddress = interfaceAddresses else {
        return nil
    }

    defer {
        freeifaddrs(interfaceAddresses)
    }

    var result: String?

    for pointer in sequence(
        first: firstAddress,
        next: { $0.pointee.ifa_next }
    ) {
        let interface = pointer.pointee

        guard let addressPointer = interface.ifa_addr else {
            continue
        }

        let family = addressPointer.pointee.sa_family
        guard family == UInt8(AF_INET) else {
            continue
        }

        let interfaceName = String(cString: interface.ifa_name)

        // en0 is normally Wi-Fi on a physical iPhone.
        guard interfaceName == "en0" else {
            continue
        }

        var hostname = [CChar](
            repeating: 0,
            count: Int(NI_MAXHOST)
        )

        let status = getnameinfo(
            addressPointer,
            socklen_t(addressPointer.pointee.sa_len),
            &hostname,
            socklen_t(hostname.count),
            nil,
            0,
            NI_NUMERICHOST
        )

        if status == 0 {
            result = String(cString: hostname)
            break
        }
    }

    return result
}
