import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AevraStore
    @EnvironmentObject private var timer: FocusTimer
    @State private var selection = 0

    var body: some View {
        ZStack {
            AevraTheme.background.ignoresSafeArea()

            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 320)
                .blur(radius: 70)
                .offset(x: 150, y: -330)

            TabView(selection: $selection) {
                HomeView(selection: $selection).tag(0)
                FlowView().tag(1)
                StudioView().tag(2)
                LiveView().tag(3)
                ProfileView().tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                Spacer()
                CustomTabBar(selection: $selection)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: selection)
    }

    private var accent: Color {
        AevraTheme.accents[store.profile.accentIndex % AevraTheme.accents.count]
    }
}

private struct CustomTabBar: View {
    @Binding var selection: Int
    let items = [
        ("house.fill", "Home"),
        ("rectangle.3.group.fill", "Flow"),
        ("sparkles", "Studio"),
        ("dot.radiowaves.left.and.right", "Live"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        HStack {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    selection = index
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: items[index].0)
                            .font(.system(size: 19, weight: .semibold))
                            .frame(width: 42, height: 34)
                            .background(selection == index ? .white.opacity(0.13) : .clear)
                            .clipShape(Capsule())
                        Text(items[index].1)
                            .font(.caption2)
                    }
                    .foregroundStyle(selection == index ? .white : .white.opacity(0.48))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(10)
        .aevraGlass()
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}
