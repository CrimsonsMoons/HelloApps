import Foundation
import Network
import CoreBluetooth
import UserNotifications
import UIKit

@MainActor
final class PCNotificationReceiver: NSObject, ObservableObject {
    static let shared = PCNotificationReceiver()

    static let tcpPort: NWEndpoint.Port = 4747
    static let discoveryPort: NWEndpoint.Port = 4748
    static let serviceUUID = CBUUID(string: "A3E90001-4B4F-4D3A-9A11-57F2D7A9E001")
    static let messageUUID = CBUUID(string: "A3E90002-4B4F-4D3A-9A11-57F2D7A9E001")

    @Published var wifiOnline = false
    @Published var bluetoothOnline = false
    @Published var bluetoothState = "Starting…"
    @Published var status = "Starting receiver…"
    @Published var lastMessage = "No PC messages yet"
    @Published var localIPAddress: String?
    @Published var pairingCode: String {
        didSet {
            let clean = String(pairingCode.filter(\.isNumber).prefix(8))
            if clean != pairingCode { pairingCode = clean; return }
            UserDefaults.standard.set(clean, forKey: "pcPairingCode")
            refreshBluetoothAdvertisement()
        }
    }

    private var tcpListener: NWListener?
    private var discoveryListener: NWListener?
    private var peripheralManager: CBPeripheralManager?
    private var messageCharacteristic: CBMutableCharacteristic?
    private let networkQueue = DispatchQueue(label: "com.aevra.pcnotify.network", qos: .userInitiated)
    private var started = false

    override private init() {
        pairingCode = UserDefaults.standard.string(forKey: "pcPairingCode") ?? String(Int.random(in: 100000...999999))
        super.init()
        UserDefaults.standard.set(pairingCode, forKey: "pcPairingCode")
    }

    func start() async {
        guard !started else { return }
        started = true
        _ = await NotificationManager.requestPermission()
        localIPAddress = Self.wifiAddress()
        startTCP()
        startDiscovery()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func restart() {
        tcpListener?.cancel()
        discoveryListener?.cancel()
        tcpListener = nil
        discoveryListener = nil
        wifiOnline = false
        status = "Restarting receiver…"
        startTCP()
        startDiscovery()
        refreshBluetoothAdvertisement()
    }

    private func startTCP() {
        do {
            let listener = try NWListener(using: .tcp, on: Self.tcpPort)
            tcpListener = listener
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self else { return }
                    switch state {
                    case .ready:
                        self.wifiOnline = true
                        self.status = "Ready for PC notifications"
                    case .failed(let error):
                        self.wifiOnline = false
                        self.status = "Wi-Fi receiver error: \(error.localizedDescription)"
                    case .cancelled:
                        self.wifiOnline = false
                    default: break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.receiveTCP(connection)
            }
            listener.start(queue: networkQueue)
        } catch {
            status = "Could not start Wi-Fi receiver: \(error.localizedDescription)"
        }
    }

    private func receiveTCP(_ connection: NWConnection) {
        connection.start(queue: networkQueue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, _, error in
            guard let self else { connection.cancel(); return }
            guard error == nil, let data else { connection.cancel(); return }
            Task { @MainActor in
                let response = await self.process(data: data, transport: "Wi-Fi")
                connection.send(content: Data((response + "\n").utf8), completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
    }

    private func startDiscovery() {
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        do {
            let listener = try NWListener(using: params, on: Self.discoveryPort)
            discoveryListener = listener
            listener.newConnectionHandler = { [weak self] connection in
                guard let self else { return }
                connection.start(queue: self.networkQueue)
                connection.receiveMessage { data, _, _, _ in
                    guard let data, String(data: data, encoding: .utf8)?.hasPrefix("AEVRA_DISCOVER") == true else {
                        connection.cancel(); return
                    }
                    Task { @MainActor in
                        let reply = DiscoveryReply(
                            name: UIDevice.current.name,
                            pairingHint: String(self.pairingCode.suffix(2)),
                            tcpPort: Int(Self.tcpPort.rawValue)
                        )
                        let encoded = try? JSONEncoder().encode(reply)
                        connection.send(content: encoded, completion: .contentProcessed { _ in connection.cancel() })
                    }
                }
            }
            listener.start(queue: networkQueue)
        } catch {
            status = "Discovery error: \(error.localizedDescription)"
        }
    }

    private func process(data: Data, transport: String) async -> String {
        do {
            let packet = try JSONDecoder().decode(PCPacket.self, from: data)
            guard packet.pairingCode == pairingCode else {
                status = "Rejected a \(transport) request with the wrong pairing code"
                return "ERROR wrong-pairing-code"
            }
            if packet.type == "ping" {
                status = "\(transport) connection test succeeded"
                return "OK pong"
            }
            guard packet.type == "notify", !packet.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return "ERROR invalid-message"
            }
            await NotificationManager.scheduleImmediateNotification(
                title: packet.title.isEmpty ? "Aevra PC" : packet.title,
                body: packet.message
            )
            lastMessage = packet.message
            status = "Received through \(transport)"
            return "OK delivered"
        } catch {
            status = "Invalid \(transport) message"
            return "ERROR invalid-json"
        }
    }

    private func refreshBluetoothAdvertisement() {
        guard let peripheralManager, peripheralManager.state == .poweredOn else { return }
        peripheralManager.stopAdvertising()
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID],
            CBAdvertisementDataLocalNameKey: "Aevra-\(pairingCode.suffix(2))"
        ])
    }
}

extension PCNotificationReceiver: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            switch peripheral.state {
            case .poweredOn:
                bluetoothOnline = true
                bluetoothState = "Bluetooth ready"
                let characteristic = CBMutableCharacteristic(
                    type: Self.messageUUID,
                    properties: [.write, .writeWithoutResponse],
                    value: nil,
                    permissions: [.writeable]
                )
                messageCharacteristic = characteristic
                let service = CBMutableService(type: Self.serviceUUID, primary: true)
                service.characteristics = [characteristic]
                peripheral.removeAllServices()
                peripheral.add(service)
                refreshBluetoothAdvertisement()
            case .poweredOff:
                bluetoothOnline = false
                bluetoothState = "Bluetooth is off"
            case .unauthorized:
                bluetoothOnline = false
                bluetoothState = "Bluetooth permission denied"
            case .unsupported:
                bluetoothOnline = false
                bluetoothState = "Bluetooth unsupported"
            default:
                bluetoothOnline = false
                bluetoothState = "Bluetooth unavailable"
            }
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        Task { @MainActor in
            for request in requests {
                guard request.characteristic.uuid == Self.messageUUID, let value = request.value else {
                    peripheral.respond(to: request, withResult: .requestNotSupported)
                    continue
                }
                let response = await process(data: value, transport: "Bluetooth")
                peripheral.respond(to: request, withResult: response.hasPrefix("OK") ? .success : .unlikelyError)
            }
        }
    }
}

private struct PCPacket: Codable {
    let type: String
    let pairingCode: String
    let title: String
    let message: String
}

private struct DiscoveryReply: Codable {
    let name: String
    let pairingHint: String
    let tcpPort: Int
}
