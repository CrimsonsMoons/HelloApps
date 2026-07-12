import SwiftUI

@main
struct AevraApp: App {
    @StateObject private var store = AevraStore()
    @StateObject private var timer = FocusTimer()
    @StateObject private var pcReceiver = PCNotificationReceiver.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(timer)
                .environmentObject(pcReceiver)
                .task { await pcReceiver.start() }
                .preferredColorScheme(.dark)
        }
    }
}
