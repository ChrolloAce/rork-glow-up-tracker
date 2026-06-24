import SwiftUI

/// Tab 2 — "Challenge". The user's challenge rules, calendar, habits, and actions.
/// Replaces the old Beauty tab. Intentionally simple: no mood board / self-care.
struct ChallengeView: View {
    @Bindable var viewModel: GlowViewModel

    @State private var showSwitchConfirm = false
    @State private var showRestartConfirm = false
    @State private var showChallengePicker = false
    @State private var showEditGoals = false
    @State private var currentMonth = Date()

    private let cal = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if viewModel.selectedChallenge != nil {
                    currentChallengeCard
                    rulesCard
                    calendarCard
                    habitListCard
                    actionsCard
                } else {
                    choosePrompt
                }
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .fullScreenCover(isPresented: $showChallengePicker) {
            NavigationStack {
                SelectChallengeView(viewModel: viewModel, isOnboarding: false, onContinue: {})
            }
        }
        .sheet(isPresented: $showEditGoals) { EditGoalsView(viewModel: viewModel) }
        .alert("Switch Challenge?", isPresented: $showSwitchConfirm) {
            Button("Switch", role: .destructive) { showChallengePicker = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Switching starts a fresh Day 1 and clears your current challenge progress.")
        }
        .alert("Restart Challenge?", isPresented: $showRestartConfirm) {
            Button("Restart", role: .destructive) { viewModel.restartChallenge() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This sets your challenge back to Day 1 and clears your progress. Photos are kept.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Challenge")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var choosePrompt: some View {
        Button { showChallengePicker = true } label: {
            HStack {
                Image(systemName: "flag.checkered").foregroundStyle(Theme.pink)
                Text("Choose your challenge").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textTertiary)
            }.padding(18)
        }
        .buttonStyle(.plain)
        .glassCard()
    }

    // MARK: - Current Challenge

    @ViewBuilder
    private var currentChallengeCard: some View {
        if let challenge = viewModel.selectedChallenge {
            VStack(alignment: .leading, spacing: 14) {
                Text(challenge.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Text(challenge.description)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    pill(icon: "calendar", text: "\(challenge.durationDays) days")
                    pill(icon: "flame.fill", text: challenge.difficulty.rawValue)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Day \(viewModel.currentDay) of \(viewModel.totalDays)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(viewModel.daysLeft) days left")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    progressBar(Double(viewModel.currentDay) / Double(max(viewModel.totalDays, 1)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassCard()
        }
    }

    // MARK: - Rules

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenge Rules")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(Array((viewModel.selectedChallenge?.rules ?? []).enumerated()), id: \.offset) { index, rule in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.pink)
                    Text(rule)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassCard()
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Challenge Calendar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.pink) }
                Spacer()
                Text(monthTitle).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.pink) }
            }

            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                    Text(d).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.textTertiary).frame(maxWidth: .infinity)
                }
            }

            daysGrid
            legend
        }
        .padding(18)
        .glassCard()
    }

    private var daysGrid: some View {
        let total = leadingBlanks + daysInMonth
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                if index < leadingBlanks {
                    Color.clear.frame(height: 34)
                } else {
                    dayCell(index - leadingBlanks + 1)
                }
            }
        }
    }

    private func dayCell(_ dayNumber: Int) -> some View {
        let date = cal.date(byAdding: .day, value: dayNumber - 1, to: monthStart) ?? monthStart
        let today = cal.startOfDay(for: Date())
        let start = cal.startOfDay(for: viewModel.startDate)
        let challengeDay = (cal.dateComponents([.day], from: start, to: cal.startOfDay(for: date)).day ?? -1) + 1
        let inChallenge = challengeDay >= 1 && challengeDay <= viewModel.totalDays
        let isToday = cal.isDate(date, inSameDayAs: today)
        let completed = inChallenge && viewModel.isDayComplete(challengeDay)
        let missed = inChallenge && date < today && !completed

        return VStack(spacing: 3) {
            Text("\(dayNumber)")
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : (inChallenge ? Theme.textPrimary : Theme.textTertiary.opacity(0.5)))
                .frame(width: 30, height: 30)
                .background {
                    if isToday { Circle().fill(Theme.pink) }
                    else if completed { Circle().fill(Theme.pink.opacity(0.16)) }
                }
            Circle()
                .fill(completed ? Theme.pink : (missed ? Theme.textTertiary.opacity(0.3) : (inChallenge ? Theme.pinkLight.opacity(0.5) : .clear)))
                .frame(width: 5, height: 5)
        }
        .frame(height: 34)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendDot(Theme.pink, "Completed")
            legendDot(Theme.textTertiary.opacity(0.35), "Missed")
            legendDot(Theme.pinkLight.opacity(0.6), "Upcoming")
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Habit list

    private var habitListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Habits")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(viewModel.activeHabits) { habit in
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(habit.themeColor.opacity(0.15)).frame(width: 36, height: 36)
                        Image(systemName: habit.icon).font(.system(size: 15)).foregroundStyle(habit.themeColor)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(habit.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary).lineLimit(1)
                        Text(goalLabel(habit)).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(habit.type.label)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(habit.type.tint)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(habit.type.tint.opacity(0.13)))
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassCard()
    }

    private func goalLabel(_ habit: DailyHabit) -> String {
        if let goal = habit.goal, let unit = habit.unit { return "\(Int(goal)) \(unit)" }
        switch habit.type {
        case .routine: return "\(habit.subTasks.count) steps"
        case .photo: return "Daily photo"
        case .journal: return "Daily entry"
        default: return "Daily"
        }
    }

    // MARK: - Actions

    private var actionsCard: some View {
        VStack(spacing: 0) {
            actionRow(icon: "arrow.left.arrow.right", label: "Switch Challenge") { showSwitchConfirm = true }
            Divider().opacity(0.4).padding(.leading, 52)
            actionRow(icon: "arrow.counterclockwise", label: "Restart Challenge") { showRestartConfirm = true }
            Divider().opacity(0.4).padding(.leading, 52)
            actionRow(icon: "slider.horizontal.3", label: "Edit Goals") { showEditGoals = true }
        }
        .glassCard()
    }

    private func actionRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Theme.pink).frame(width: 24)
                Text(label).font(.system(size: 16)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 18).padding(.vertical, 15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.pink)
            Text(text).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(Theme.softPink))
        .overlay(Capsule().stroke(Theme.subtleBorder, lineWidth: 1))
    }

    private func progressBar(_ fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.progressTrack).frame(height: 8)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.pink, Theme.pinkDeep], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * min(max(fraction, 0), 1), height: 8)
            }
        }
        .frame(height: 8)
    }

    private var monthStart: Date { cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) ?? currentMonth }
    private var daysInMonth: Int { cal.range(of: .day, in: .month, for: currentMonth)?.count ?? 30 }
    private var leadingBlanks: Int { cal.component(.weekday, from: monthStart) - 1 }
    private var monthTitle: String { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: currentMonth) }
    private func shiftMonth(_ offset: Int) {
        withAnimation(.snappy) { currentMonth = cal.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth }
    }
}
