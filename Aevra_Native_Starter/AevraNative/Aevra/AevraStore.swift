import Foundation
import SwiftUI

@MainActor
final class AevraStore: ObservableObject {
    @Published var selectedMode: AevraMode = .morning { didSet { save() } }
    @Published var profile = AevraProfile() { didSet { save() } }
    @Published var focusedMinutes = 0 { didSet { save() } }
    @Published var tasks: [AevraMode: [AevraTask]] = [:] { didSet { save() } }

    private let saveKey = "aevra.native.state.v1"
    private var isLoading = true

    init() {
        load()
        isLoading = false
    }

    var currentTasks: [AevraTask] {
        tasks[selectedMode] ?? []
    }

    var remainingCount: Int {
        currentTasks.filter { !$0.isComplete }.count
    }

    var completion: Double {
        guard !currentTasks.isEmpty else { return 0 }
        return Double(currentTasks.filter(\.isComplete).count) / Double(currentTasks.count)
    }

    func toggle(_ task: AevraTask) {
        guard let index = tasks[selectedMode]?.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[selectedMode]?[index].isComplete.toggle()
    }

    func addTask(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks[selectedMode, default: []].append(AevraTask(title: trimmed))
    }

    func deleteTask(_ task: AevraTask) {
        tasks[selectedMode]?.removeAll { $0.id == task.id }
    }

    func addFocusMinutes(_ minutes: Int) {
        focusedMinutes += max(0, minutes)
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        applyDefaults()
        save()
    }

    private func applyDefaults() {
        selectedMode = .morning
        profile = AevraProfile()
        focusedMinutes = 0
        tasks = [
            .morning: [
                AevraTask(title: "Review today's schedule", isComplete: true),
                AevraTask(title: "Morning workout", isComplete: true),
                AevraTask(title: "Meditate"),
                AevraTask(title: "Healthy breakfast"),
                AevraTask(title: "Plan my day")
            ],
            .school: [
                AevraTask(title: "Check class schedule"),
                AevraTask(title: "Finish Algebra assignment"),
                AevraTask(title: "Review notes"),
                AevraTask(title: "Pack school bag")
            ],
            .trading: [
                AevraTask(title: "Check economic calendar"),
                AevraTask(title: "Review market bias"),
                AevraTask(title: "Set risk limit"),
                AevraTask(title: "Journal session")
            ],
            .evening: [
                AevraTask(title: "Finish homework"),
                AevraTask(title: "Prepare clothes"),
                AevraTask(title: "Charge devices")
            ],
            .night: [
                AevraTask(title: "Set alarm"),
                AevraTask(title: "Enable sleep focus"),
                AevraTask(title: "Wind down")
            ]
        ]
    }

    private struct PersistedState: Codable {
        var selectedMode: AevraMode
        var profile: AevraProfile
        var focusedMinutes: Int
        var tasks: [AevraMode: [AevraTask]]
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let decoded = try? JSONDecoder().decode(PersistedState.self, from: data)
        else {
            applyDefaults()
            return
        }

        selectedMode = decoded.selectedMode
        profile = decoded.profile
        focusedMinutes = decoded.focusedMinutes
        tasks = decoded.tasks
    }

    private func save() {
        guard !isLoading else { return }
        let state = PersistedState(
            selectedMode: selectedMode,
            profile: profile,
            focusedMinutes: focusedMinutes,
            tasks: tasks
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }
}
