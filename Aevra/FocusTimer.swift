import Foundation

@MainActor
final class FocusTimer: ObservableObject {
    @Published private(set) var remainingSeconds = 25 * 60
    @Published private(set) var totalSeconds = 25 * 60
    @Published private(set) var isRunning = false

    private var timer: Timer?

    var formattedTime: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    func configure(minutes: Int) {
        stop()
        totalSeconds = max(1, minutes) * 60
        remainingSeconds = totalSeconds
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.stop()
                }
            }
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        stop()
        remainingSeconds = totalSeconds
    }
}
