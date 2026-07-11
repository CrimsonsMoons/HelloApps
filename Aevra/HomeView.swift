import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AevraStore
    @EnvironmentObject private var timer: FocusTimer
    @Binding var selection: Int

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                topCards
                overview
                suggestion
                quickActions
                nextUp
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .foregroundStyle(.secondary)
                Text(store.profile.name)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text("Have a great day! ☀️")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 46, height: 46)
                .overlay(Text(String(store.profile.name.prefix(1))).fontWeight(.bold))
        }
    }

    private var topCards: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "sun.max.fill").font(.title2)
                Text("72°").font(.system(size: 48, weight: .light))
                Text("San Antonio")
                Text("Sunny • H:88° L:62°").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                LinearGradient(colors: [.blue.opacity(0.52), .pink.opacity(0.18)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                Text(Date.now.formatted(.dateTime.month(.wide).day()))
                    .font(.title3.bold())
                Divider().overlay(.white.opacity(0.12))
                Text("2 Events Today").font(.caption)
                Text("10:00 AM  Math Class").font(.caption2).foregroundStyle(.secondary)
                Text("1:30 PM   Study Session").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .aevraGlass(intensity: store.profile.glassIntensity)
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Overview").font(.headline)
            HStack {
                metric("\(store.remainingCount)", "Tasks Remaining")
                Spacer()
                ZStack {
                    Circle().stroke(.white.opacity(0.12), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: store.completion)
                        .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(store.completion * 100))%").font(.caption.bold())
                }
                .frame(width: 76, height: 76)
                Spacer()
                metric("\(store.focusedMinutes)m", "Focused Today")
            }
        }
        .padding()
        .aevraGlass(intensity: store.profile.glassIntensity)
    }

    private var suggestion: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile").font(.title2)
            VStack(alignment: .leading) {
                Text("Start with your highest priority").fontWeight(.semibold)
                Text("A 25-minute focus session can keep you on schedule.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .aevraGlass(intensity: store.profile.glassIntensity)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions").font(.headline)
            HStack {
                action("scope", "Focus") { selection = 1; timer.start() }
                action("note.text", "Notes") {}
                action("doc.viewfinder", "Scan") {}
                action("bell.fill", "Remind") {
                    Task { await NotificationManager.scheduleTestNotification() }
                }
            }
        }
        .padding()
        .aevraGlass(intensity: store.profile.glassIntensity)
    }

    private var nextUp: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Up").font(.headline)
            HStack {
                Image(systemName: "book.closed.fill")
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading) {
                    Text("Math Homework").fontWeight(.semibold)
                    Text("Due in 2h 45m").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("High Priority")
                    .font(.caption2)
                    .foregroundStyle(.pink)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.pink.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .aevraGlass(intensity: store.profile.glassIntensity)
    }

    private func metric(_ value: String, _ title: String) -> some View {
        VStack(alignment: .leading) {
            Text(value).font(.title.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func action(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.09))
                    .clipShape(Circle())
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var accent: Color {
        AevraTheme.accents[store.profile.accentIndex % AevraTheme.accents.count]
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "Good Morning," : hour < 18 ? "Good Afternoon," : "Good Evening,"
    }
}
