import SwiftUI

enum AevraTheme {
    static let accents: [Color] = [
        Color(red: 0.47, green: 0.73, blue: 1.0),
        Color(red: 0.68, green: 0.57, blue: 1.0),
        Color(red: 0.44, green: 0.88, blue: 0.63),
        Color(red: 1.0, green: 0.78, blue: 0.43)
    ]

    static let background = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.15, blue: 0.23),
            Color(red: 0.04, green: 0.06, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassCardModifier: ViewModifier {
    var intensity: Double

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.55 + intensity * 0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.11), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 24, y: 14)
    }
}

extension View {
    func aevraGlass(intensity: Double = 0.72) -> some View {
        modifier(GlassCardModifier(intensity: intensity))
    }
}
