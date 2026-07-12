import SwiftUI

struct LiveView: View {
    @EnvironmentObject private var store: AevraStore
    @EnvironmentObject private var timer: FocusTimer
    @EnvironmentObject private var pcReceiver: PCNotificationReceiver
    @State private var showCode = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Live").font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("Activities, connections and alerts.").foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PC Connect").font(.headline)
                            Text("Automatic Wi-Fi + Bluetooth fallback")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        connectionBadge
                    }

                    HStack(spacing: 10) {
                        connectionTile(
                            icon: "wifi",
                            title: "Wi-Fi",
                            value: pcReceiver.wifiOnline ? "Ready" : "Offline",
                            active: pcReceiver.wifiOnline
                        )
                        connectionTile(
                            icon: "wave.3.right",
                            title: "Bluetooth",
                            value: pcReceiver.bluetoothOnline ? "Ready" : "Offline",
                            active: pcReceiver.bluetoothOnline
                        )
                    }

                    Divider().overlay(.white.opacity(0.12))

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pairing code").font(.caption).foregroundStyle(.secondary)
                            Text(showCode ? pcReceiver.pairingCode : "••••••")
                                .font(.system(size: 25, weight: .bold, design: .monospaced))
                        }
                        Spacer()
                        Button(showCode ? "Hide" : "Show") { showCode.toggle() }
                            .buttonStyle(.bordered)
                        Button("New") {
                            pcReceiver.pairingCode = String(Int.random(in: 100000...999999))
                            showCode = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(.black)
                    }

                    Text("Enter this code once in the Windows app. Aevra will be discovered automatically—no IP address needed.")
                        .font(.caption).foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "info.circle")
                        Text(pcReceiver.status)
                            .lineLimit(2)
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button("Restart connections") { pcReceiver.restart() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .aevraGlass(intensity: store.profile.glassIntensity)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Focus Session").font(.headline)
                        Spacer()
                        Text(timer.isRunning ? "Active" : "Ready")
                            .foregroundStyle(timer.isRunning ? .green : .secondary)
                    }
                    liveRow("scope", "Focus Timer", "Deep Work Session", timer.formattedTime)
                    liveRow("bell.badge.fill", "Last PC Message", pcReceiver.lastMessage, "")
                }
                .padding()
                .aevraGlass(intensity: store.profile.glassIntensity)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification Lab").font(.headline)
                    Text("Confirm that iPhone notification permission is working.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Send Test Notification") {
                        Task { await NotificationManager.scheduleTestNotification() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .aevraGlass(intensity: store.profile.glassIntensity)

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
    }

    private var connectionBadge: some View {
        let ready = pcReceiver.wifiOnline || pcReceiver.bluetoothOnline
        return Label(ready ? "Ready" : "Starting", systemImage: ready ? "checkmark.circle.fill" : "clock.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(ready ? .green : .orange)
    }

    private func connectionTile(icon: String, title: String, value: String, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title3)
            Text(title).fontWeight(.semibold)
            Text(value).font(.caption).foregroundStyle(active ? .green : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func liveRow(_ icon: String, _ title: String, _ subtitle: String, _ trailing: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading) {
                Text(title).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            Text(trailing).fontWeight(.semibold)
        }
        .padding(12)
        .background(.black.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
