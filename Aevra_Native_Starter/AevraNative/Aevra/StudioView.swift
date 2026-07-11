import SwiftUI

struct StudioView: View {
    @EnvironmentObject private var store: AevraStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Studio").font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("Personalize the Aevra experience.").foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                VStack(spacing: 18) {
                    HStack {
                        Text("Glass Intensity")
                        Spacer()
                        Text("\(Int(store.profile.glassIntensity * 100))%").foregroundStyle(.secondary)
                    }
                    Slider(value: $store.profile.glassIntensity, in: 0.25...1.0)

                    Toggle("Smart Suggestions", isOn: $store.profile.smartSuggestions)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accent")
                        HStack {
                            ForEach(AevraTheme.accents.indices, id: \.self) { index in
                                Button {
                                    store.profile.accentIndex = index
                                } label: {
                                    Circle()
                                        .fill(AevraTheme.accents[index])
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle().stroke(.white, lineWidth: store.profile.accentIndex == index ? 3 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .aevraGlass(intensity: store.profile.glassIntensity)

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
    }
}
