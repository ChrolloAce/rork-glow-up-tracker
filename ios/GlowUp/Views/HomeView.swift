import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var appeared: Bool = false
    @State private var dayAnimated: Int = 0
    @State private var expandedCard: HabitCategory?
    @State private var selectedDayIndex: Int? = 0
    @State private var dayScrollTrigger: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                daySlider
                    .padding(.top, 16)
                quickStatsStrip
                    .padding(.top, 20)
                habitTrackSection
                beautyAppointments
                glowScoreCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
            }
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: selectedDayIndex)
        .sensoryFeedback(.selection, trigger: dayScrollTrigger)
        .onAppear {
            let todayIndex = max(0, viewModel.currentDay - 1)
            selectedDayIndex = todayIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.snappy(duration: 0.4)) {
                    selectedDayIndex = todayIndex
                }
            }
            withAnimation(.easeOut(duration: 1.2)) {
                dayAnimated = viewModel.currentDay
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                appeared = true
            }
        }
    }

    private var heroHeader: some View {
        ZStack {
            Theme.heroGradient
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                HStack {
                    streakPill
                    Spacer()
                    bellButton
                }
                .padding(.horizontal, 20)

                Spacer()

                Text("\(dayAnimated)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.pinkDeep, Theme.pink, Theme.roseGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.pink.opacity(0.25), radius: 30, x: 0, y: 10)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Day \(dayAnimated) of \(viewModel.totalDays)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 16)
            }
            .padding(.top, 8)
        }
        .frame(height: 280)
    }

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.pink)
            Text("\(viewModel.habitStreaks[.skincare] ?? 0) day streak")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .adaptiveGlass(in: Capsule())
    }

    private var bellButton: some View {
        Button { } label: {
            Image(systemName: "bell.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.pink)
                .frame(width: 36, height: 36)
                .adaptiveGlass(in: Circle())
        }
    }

    private var daySlider: some View {
        VStack(spacing: 8) {
            HStack {
                Text(selectedDateLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.2)
                Spacer()
                if let selectedDayIndex, selectedDayIndex != viewModel.currentDay - 1 {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.snappy(duration: 0.4)) {
                            self.selectedDayIndex = viewModel.currentDay - 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("Jump to Today")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Theme.pink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.pink.opacity(0.12), in: Capsule())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .animation(.snappy, value: selectedDayIndex)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 8) {
                    ForEach(0..<viewModel.totalDays, id: \.self) { index in
                        dayCell(index: index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedDayIndex)
            .onChange(of: selectedDayIndex) { oldValue, newValue in
                if oldValue != newValue {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dayScrollTrigger += 1
                }
                if let newValue {
                    withAnimation(.snappy(duration: 0.35)) {
                        dayAnimated = newValue + 1
                    }
                }
            }
            .contentMargins(.horizontal, 20)
            .scrollIndicators(.hidden)
        }
    }

    private func dayCell(index: Int) -> some View {
        let dayNum = index + 1
        let isSelected = index == (selectedDayIndex ?? 0)
        let isCompleted = index < viewModel.currentDay - 1
        let isCurrent = index == viewModel.currentDay - 1

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.snappy(duration: 0.3)) {
                selectedDayIndex = index
            }
            dayScrollTrigger += 1
        } label: {
            VStack(spacing: 4) {
                Text(isCurrent ? "TODAY" : " ")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(isCurrent ? (isSelected ? Color.white : Theme.pink) : Color.clear)

                VStack(spacing: 4) {
                    Text("\(dayNum)")
                        .font(.system(size: isSelected ? 18 : 14, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(dayNumberColor(isSelected: isSelected, isCurrent: isCurrent, isCompleted: isCompleted))

                    dayIndicator(isSelected: isSelected, isCurrent: isCurrent, isCompleted: isCompleted)
                }
                .frame(width: 44, height: 50)
                .background { dayCellBackground(isSelected: isSelected, isCurrent: isCurrent) }
            }
        }
    }

    private func dayNumberColor(isSelected: Bool, isCurrent: Bool, isCompleted: Bool) -> Color {
        if isSelected { return .white }
        if isCurrent { return Theme.pink }
        if isCompleted { return Theme.pink }
        return Theme.textTertiary
    }

    @ViewBuilder
    private func dayIndicator(isSelected: Bool, isCurrent: Bool, isCompleted: Bool) -> some View {
        if isCurrent {
            Circle()
                .fill(isSelected ? Color.white : Theme.pink)
                .frame(width: 5, height: 5)
        } else if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : Theme.pink.opacity(0.7))
        } else {
            Circle()
                .fill(Theme.textTertiary.opacity(0.25))
                .frame(width: 5, height: 5)
        }
    }

    @ViewBuilder
    private func dayCellBackground(isSelected: Bool, isCurrent: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.pink)
        } else if isCurrent {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.pink, lineWidth: 1.5)
                .background(Theme.pink.opacity(0.08), in: .rect(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.pink.opacity(0.15), lineWidth: 1)
        }
    }

    private var selectedDateLabel: String {
        let dayOffset = (selectedDayIndex ?? (viewModel.currentDay - 1))
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Calendar.current.startOfDay(for: viewModel.startDate)) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date).uppercased()
    }

    private var quickStatsStrip: some View {
        HStack(spacing: 10) {
            QuickStatPill(icon: "drop.fill", iconColor: Theme.waterBlue, value: "\(String(format: "%.1f", viewModel.waterOz))", unit: "oz", label: "Water")
            QuickStatPill(icon: "figure.walk", iconColor: Theme.pink, value: "\(viewModel.stepCount)", unit: nil, label: "Steps")
            QuickStatPill(icon: "leaf.fill", iconColor: Theme.sageGreen, value: "Done", unit: "✓", label: "Lymphatic")
        }
        .padding(.horizontal, 20)
    }

    private var habitTrackSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.habits.enumerated()), id: \.element.id) { index, habit in
                ExpandableHabitCard(
                    habit: habit,
                    viewModel: viewModel,
                    isExpanded: expandedCard == habit.category,
                    onToggle: { viewModel.toggleHabit(habit) },
                    onExpand: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            expandedCard = expandedCard == habit.category ? nil : habit.category
                        }
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5).delay(Double(index) * 0.08), value: appeared)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var beautyAppointments: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THIS WEEK'S BEAUTY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(viewModel.beautyAppointments, id: \.0) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.2)
                                .frame(width: 7, height: 7)
                            Text(item.0)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .adaptiveGlass(in: Capsule())
                    }

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            viewModel.selectedTab = 1
                        }
                    } label: {
                        Text("View All →")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.pink)
                    }
                }
            }
            .contentMargins(.horizontal, 20)
            .scrollIndicators(.hidden)
        }
        .padding(.top, 24)
    }

    private var glowScoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.pink)
                Text("Today's Glow Score")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button { } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.pink)
                        .frame(width: 28, height: 28)
                        .adaptiveGlass(in: Circle())
                }
            }

            GlowScoreGauge(score: viewModel.glowScore)

            HStack(spacing: 6) {
                ForEach(viewModel.habitMetrics) { metric in
                    VStack(spacing: 5) {
                        Image(systemName: metric.category.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(metric.color)
                        Text("\(Int(metric.value))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(metric.shortName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(metric.color.opacity(0.25))
                            .frame(height: 3)
                            .overlay(alignment: .leading) {
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(metric.color)
                                        .frame(width: geo.size.width * (metric.value / 100), height: 3)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .glassCard(tinted: true)
        .padding(.top, 24)
    }
}

struct ExpandableHabitCard: View {
    let habit: Habit
    let viewModel: GlowViewModel
    let isExpanded: Bool
    let onToggle: () -> Void
    let onExpand: () -> Void
    @State private var checkTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                leftSlab
                centerContent
                rightSection
            }
            .frame(minHeight: 82)

            if isExpanded {
                expandedContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard(accent: habit.category.slabColor)
    }

    private var leftSlab: some View {
        Button(action: onExpand) {
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22)
                    .fill(habit.category.slabColor.opacity(0.9))

                VStack(spacing: 4) {
                    if habit.category.hasReminder {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 16, height: 16)
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(habit.category.slabColor)
                            }
                            Spacer()
                        }
                        .padding(.leading, 6)
                        .padding(.top, 6)
                    }

                    Spacer()

                    Image(systemName: habit.category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 2)

                    Spacer()

                    if habit.category.hasReminder {
                        Color.clear.frame(height: 16)
                    }
                }
            }
            .frame(width: 72)
        }
    }

    private var centerContent: some View {
        Button(action: onExpand) {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.category.rawValue)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                subtitleText
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 82)
        }
    }

    private var subtitleText: some View {
        Group {
            switch habit.category {
            case .water:
                HStack(spacing: 0) {
                    Text("\(String(format: "%.1f", habit.currentValue))")
                        .foregroundStyle(Theme.waterBlue)
                    Text(" / \(Int(habit.goalValue)) oz")
                        .foregroundStyle(Theme.textSecondary)
                }
                .font(.system(size: 13))
            case .steps:
                HStack(spacing: 0) {
                    Text("\(Int(habit.currentValue))")
                        .foregroundStyle(Theme.pink)
                    Text(" / \(Int(habit.goalValue)) steps")
                        .foregroundStyle(Theme.textSecondary)
                }
                .font(.system(size: 13))
            default:
                Text(habit.category.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var rightSection: some View {
        VStack(spacing: 6) {
            if !isExpanded {
                statusPill
            }

            Button {
                checkTrigger += 1
                onToggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(habit.isCompleted ? Theme.pink : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(habit.isCompleted ? Color.clear : Theme.pink.opacity(0.3), lineWidth: 1.2)
                        )
                        .frame(width: 46, height: 46)

                    if habit.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: checkTrigger)
        }
        .padding(.trailing, 14)
    }

    private var statusPill: some View {
        Group {
            if !habit.isCompleted, habit.progress > 0 {
                Text("\(Int(habit.progress * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.pink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.pink.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        switch habit.category {
        case .water: WaterExpandedView(viewModel: viewModel)
        case .lymphatic: LymphExpandedView(viewModel: viewModel)
        case .weight: WeightExpandedView(viewModel: viewModel)
        case .steps: StepsExpandedView(viewModel: viewModel)
        case .skincare: SkincareExpandedView(viewModel: viewModel)
        }
    }
}

struct QuickStatPill: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                if let unit {
                    Text(unit)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .glassCard(radius: 16, accent: iconColor)
    }
}

struct GlowScoreGauge: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Theme.progressTrack, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(135))

            Circle()
                .trim(from: 0, to: 0.75 * Double(score) / 100.0)
                .stroke(
                    LinearGradient(
                        colors: [Theme.pinkDeep, Theme.pink, Theme.pinkLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(135))

            VStack(spacing: 2) {
                Text("Radiant")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(score)%")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(height: 170)
        .padding(.vertical, 4)
    }
}
