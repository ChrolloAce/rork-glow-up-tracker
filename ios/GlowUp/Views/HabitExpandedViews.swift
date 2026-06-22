import SwiftUI

struct WaterExpandedView: View {
    let viewModel: GlowViewModel

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.softPink)
                    .frame(height: 140)

                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Theme.waterBlue.opacity(0.5))
                        .frame(height: 140 * viewModel.waterOz / 101)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(height: 140)

                Text("\(String(format: "%.1f", viewModel.waterOz)) oz")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }

            Button { } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Water")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .adaptiveGlassTinted(Theme.waterBlue, in: .rect(cornerRadius: 25))
            }

            Button { } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Mark as Done")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .adaptiveGlass(in: .rect(cornerRadius: 22))
            }
        }
    }
}

struct LymphExpandedView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                tabButton("Face Routine", tag: 0)
                tabButton("Body Routine", tag: 1)
            }

            let steps = selectedTab == 0 ? viewModel.lymphFaceSteps : viewModel.lymphBodySteps
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(spacing: 12) {
                    Circle()
                        .fill(step.done ? Theme.sageGreen : Theme.softPink)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if step.done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    Text(step.name)
                        .font(.system(size: 15, weight: step.done ? .regular : .semibold))
                        .foregroundStyle(step.done ? Theme.textTertiary : Theme.textPrimary)
                    Spacer()
                }
            }

            HStack {
                Spacer()
                Text("🔥 \(viewModel.habitStreaks[.lymphatic] ?? 0) day streak")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.pink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.pink.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private func tabButton(_ title: String, tag: Int) -> some View {
        Button {
            withAnimation(.snappy) { selectedTab = tag }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selectedTab == tag ? .white : Theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == tag ? Theme.sageGreen : Theme.softPink)
                .clipShape(Capsule())
        }
    }
}

struct WeightExpandedView: View {
    let viewModel: GlowViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Button { } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.pink)
                        .frame(width: 40, height: 40)
                        .adaptiveGlass(in: Circle())
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(viewModel.currentWeight))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("lbs")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.textSecondary)
                }

                Button { } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.pink)
                        .frame(width: 40, height: 40)
                        .adaptiveGlass(in: Circle())
                }
            }

            Button { } label: {
                Text("Log Today's Weight")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .adaptiveGlassTinted(Theme.pink, in: .rect(cornerRadius: 25))
            }

            MiniLineChart(data: viewModel.weightHistory, color: Theme.lavender, goalValue: viewModel.goalWeight)
                .frame(height: 80)
        }
    }
}

struct StepsExpandedView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var selectedIndex: Int = 6
    @State private var selectionTrigger: Int = 0
    @State private var goalTrigger: Int = 0

    private var selectedSteps: Int {
        Int(viewModel.weeklySteps[selectedIndex])
    }

    private var progress: Double {
        min(Double(selectedSteps) / viewModel.stepGoal, 1.0)
    }

    private var isToday: Bool { selectedIndex == viewModel.todayStepIndex }

    private var dateLabel: String {
        let date = viewModel.weeklyStepDates[selectedIndex]
        if isToday { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(dateLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .contentTransition(.opacity)

            ZStack {
                Circle()
                    .stroke(Theme.progressTrack, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.pink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy, value: progress)
                VStack(spacing: 2) {
                    Text("\(selectedSteps)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: Double(selectedSteps)))
                        .animation(.snappy, value: selectedSteps)
                    Text("/ \(Int(viewModel.stepGoal))")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                    if Double(selectedSteps) >= viewModel.stepGoal {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Goal hit")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Theme.pink)
                        .padding(.top, 2)
                    }
                }
            }
            .frame(width: 140, height: 140)

            WeekBarChart(
                data: viewModel.weeklySteps,
                accent: Theme.pink,
                todayIndex: viewModel.todayStepIndex,
                selectedIndex: $selectedIndex,
                goal: viewModel.stepGoal
            )
            .frame(height: 80)
        }
        .sensoryFeedback(.selection, trigger: selectionTrigger)
        .sensoryFeedback(.success, trigger: goalTrigger)
        .onChange(of: selectedIndex) { _, _ in selectionTrigger += 1 }
        .onChange(of: viewModel.stepCount) { _, newValue in
            viewModel.syncStepsHabitCompletion()
            if Double(newValue) >= viewModel.stepGoal { goalTrigger += 1 }
        }
        .onAppear {
            selectedIndex = viewModel.todayStepIndex
            viewModel.syncStepsHabitCompletion()
        }
    }
}

struct SkincareExpandedView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                tabButton("AM Routine", tag: 0)
                tabButton("PM Routine", tag: 1)
            }

            let steps = selectedTab == 0 ? viewModel.skincareAMSteps : viewModel.skincarePMSteps
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(spacing: 12) {
                    Circle()
                        .fill(step.done ? Theme.dustyRose : Theme.softPink)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if step.done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    Text(step.name)
                        .font(.system(size: 15, weight: step.done ? .regular : .semibold))
                        .foregroundStyle(step.done ? Theme.textTertiary : Theme.textPrimary)
                    Spacer()
                }
            }

            HStack(spacing: 6) {
                ForEach(viewModel.habitMetrics) { metric in
                    VStack(spacing: 3) {
                        Text("\(Int(metric.value))%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(metric.shortName)
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(metric.color.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
    }

    private func tabButton(_ title: String, tag: Int) -> some View {
        Button {
            withAnimation(.snappy) { selectedTab = tag }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selectedTab == tag ? .white : Theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == tag ? Theme.dustyRose : Theme.softPink)
                .clipShape(Capsule())
        }
    }
}

struct MiniLineChart: View {
    let data: [Double]
    let color: Color
    var goalValue: Double? = nil

    var body: some View {
        GeometryReader { geo in
            let minVal = (data.min() ?? 0) - 2
            let maxVal = (data.max() ?? 1) + 2
            let range = maxVal - minVal
            let stepX = geo.size.width / CGFloat(max(data.count - 1, 1))

            ZStack {
                Path { path in
                    for (i, val) in data.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - (val - minVal) / range)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if let goal = goalValue {
                    let y = geo.size.height * (1 - (goal - minVal) / range)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Theme.textTertiary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                if let last = data.last {
                    let x = CGFloat(data.count - 1) * stepX
                    let y = geo.size.height * (1 - (last - minVal) / range)
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct WeekBarChart: View {
    let data: [Double]
    let accent: Color
    var todayIndex: Int? = nil
    var selectedIndex: Binding<Int>? = nil
    var goal: Double? = nil

    private var dayLabels: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return formatter.string(from: date)
        }
    }

    var body: some View {
        let maxVal = max(data.max() ?? 1, goal ?? 0)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<min(data.count, 7), id: \.self) { i in
                let isSelected = selectedIndex?.wrappedValue == i
                let isToday = todayIndex == i
                let hitGoal = (goal.map { data[i] >= $0 }) ?? false

                Button {
                    selectedIndex?.wrappedValue = i
                } label: {
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Theme.progressTrack)
                                .frame(height: 56)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isSelected ? accent : (isToday ? accent.opacity(0.85) : accent.opacity(0.45)))
                                .frame(height: max(4, CGFloat(data[i] / maxVal) * 56))
                        }
                        .overlay(alignment: .top) {
                            if hitGoal {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(Circle().fill(accent))
                                    .offset(y: -6)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
                                .frame(height: 56)
                        )

                        Text(dayLabels[i])
                            .font(.system(size: 10, weight: isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? accent : Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(selectedIndex == nil)
            }
        }
        .animation(.snappy, value: selectedIndex?.wrappedValue)
    }
}
