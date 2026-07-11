import SwiftUI

struct FlowView: View {
    @EnvironmentObject private var store: AevraStore
    @EnvironmentObject private var timer: FocusTimer
    @State private var newTask = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                modePicker
                taskCard
                timerCard
                quote
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Flow").font(.system(size: 38, weight: .bold, design: .rounded))
                Text("Your day in focus.").foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(AevraMode.allCases) { mode in
                    Button(mode.rawValue) { store.selectedMode = mode }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 13).padding(.vertical, 8)
                        .background(store.selectedMode == mode ? .white : .white.opacity(0.06))
                        .foregroundStyle(store.selectedMode == mode ? .black : .secondary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(store.selectedMode.rawValue) Routine").font(.headline)
                Spacer()
                Image(systemName: store.selectedMode.symbol)
            }

            ForEach(store.currentTasks) { task in
                HStack {
                    Button {
                        store.toggle(task)
                    } label: {
                        Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isComplete ? accent : .secondary)
                    }
                    Text(task.title)
                        .strikethrough(task.isComplete)
                        .foregroundStyle(task.isComplete ? .secondary : .primary)
                    Spacer()
                    Button(role: .destructive) {
                        store.deleteTask(task)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                Divider().overlay(.white.opacity(0.05))
            }

            HStack {
                TextField("Add a task", text: $newTask)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Button("Add") {
                    store.addTask(newTask)
                    newTask = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
            }
        }
        .padding()
        .aevraGlass(intensity: store.profile.glassIntensity)
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Focus Timer").font(.headline)
                Spacer()
                Text(timer.isRunning ? "Active" : "Ready").foregroundStyle(.secondary)
            }
            HStack {
                Text(timer.formattedTime)
                    .font(.system(size: 42, weight: .light, design: .rounded))
                Spacer()
                Button {
                    timer.toggle()
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .frame(width: 58, height: 58)
                        .background(.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            ProgressView(value: timer.progress).tint(accent)
            HStack {
                durationButton(15)
                durationButton(25)
                durationButton(45)
            }
        }
        .padding()
        .aevraGlass(intensity: store.profile.glassIntensity)
    }

    private var quote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Quote").font(.caption).foregroundStyle(.secondary)
            Text("“Discipline is choosing between what you want now and what you want most.”")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .aevraGlass(intensity: store.profile.glassIntensity)
    }

    private func durationButton(_ minutes: Int) -> some View {
        Button("\(minutes) min") { timer.configure(minutes: minutes) }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.4))
    }

    private var accent: Color {
        AevraTheme.accents[store.profile.accentIndex % AevraTheme.accents.count]
    }
}
