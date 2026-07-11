import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AevraStore
    @State private var showReset = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Profile").font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("Account and preferences.").foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                VStack(spacing: 16) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Name", text: $store.profile.name)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 130)
                    }
                    Divider().overlay(.white.opacity(0.06))
                    row("Local Save", "Active", .green)
                    row("Windows Sync", "Prototype", .orange)
                    row("Version", "0.1.0", .secondary)
                }
                .padding()
                .aevraGlass(intensity: store.profile.glassIntensity)

                Button("Reset Demo Data", role: .destructive) {
                    showReset = true
                }
                .buttonStyle(.bordered)
                .confirmationDialog("Reset Aevra?", isPresented: $showReset) {
                    Button("Reset", role: .destructive) { store.reset() }
                }

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
    }

    private func row(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(color)
        }
    }
}
