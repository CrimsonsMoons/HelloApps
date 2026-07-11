import XCTest
@testable import Aevra

final class AevraTests: XCTestCase {
    @MainActor
    func testDefaultTasksExist() {
        let store = AevraStore()
        XCTAssertFalse(store.currentTasks.isEmpty)
    }

    @MainActor
    func testAddingTask() {
        let store = AevraStore()
        let before = store.currentTasks.count
        store.addTask("Test task")
        XCTAssertEqual(store.currentTasks.count, before + 1)
    }

    @MainActor
    func testTimerFormatting() {
        let timer = FocusTimer()
        timer.configure(minutes: 15)
        XCTAssertEqual(timer.formattedTime, "15:00")
    }
}
