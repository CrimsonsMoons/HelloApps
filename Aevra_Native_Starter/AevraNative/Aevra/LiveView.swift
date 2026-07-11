import SwiftUI

struct LiveView: View {
    @EnvironmentObject private var store: AevraStore
    @EnvironmentObject private var timer: FocusTimer

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Live").font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("Activities, widgets and alerts.").foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Focus Session").font(.headline)
                        Spacer()
                        Text(timer.isRunning ? "Active" : "Ready")
                            .foregroundStyle(timer.isRunning ? .green : .secondary)
                    }
                    liveRow("scope", "Focus Timer", "Deep Work Session", timer.formattedTime)
                    liveRow("book.closed.fill", "Math Homework", "Due in 2h 45m", "⚡")
                    liveRow("bolt.fill", "Charging", "80% to Full", "80%")
                }
                .padding()
                .aevraGlass(intensity: store.profile.glassIntensity)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification Lab").font(.headline)
                    Text("Test a real local iOS notification.")
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

    private func liveRow(_ icon: String, _ title: String, _ subtitle: String, _ trailing: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading) {
                Text(title).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(trailing).fontWeight(.semibold)
        }
        .padding(12)
        .background(.black.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
