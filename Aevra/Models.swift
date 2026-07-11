import Foundation

enum AevraMode: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case school = "School"
    case trading = "Trading"
    case evening = "Evening"
    case night = "Night"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .morning: "sun.max.fill"
        case .school: "books.vertical.fill"
        case .trading: "chart.line.uptrend.xyaxis"
        case .evening: "sunset.fill"
        case .night: "moon.stars.fill"
        }
    }
}

struct AevraTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isComplete = false
}

struct AevraProfile: Codable, Equatable {
    var name = "Alex"
    var accentIndex = 0
    var glassIntensity = 0.72
    var smartSuggestions = true
}
