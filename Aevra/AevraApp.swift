import SwiftUI

@main
struct AevraApp: App {
    @StateObject private var store = AevraStore()
    @StateObject private var timer = FocusTimer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(timer)
                .preferredColorScheme(.dark)
        }
    }
}
