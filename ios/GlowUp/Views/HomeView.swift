import SwiftUI

/// Tab 1 — "Today". The daily glow checklist: compact header, progress, habits, Complete Day.
struct HomeView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var appeared: Bool = false
    @State private var expandedHabit: String?
    @State private var showCelebration: Bool = false

    private var accent: Color { viewModel.selectedChallenge?.themeColor ?? Theme.pink }

    /// Balanced pastel palette so each task gets its own color, evenly distributed.
    private let habitPalette: [Color] = [
        Theme.pink, Theme.waterBlue, Theme.sageGreen, Theme.lavender, Theme.warmGold, Theme.pinkDeep
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                compactHeader
                dailyProgressCard
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                habitTrackSection
                completeDaySection
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 120)
            }
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .overlay {
            if showCelebration { celebrationOverlay }
        }
        .sensoryFeedback(.success, trigger: showCelebration)
        .onAppear {
            viewModel.refreshDailyHabitsIfNeeded()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Compact header

    private var compactHeader: some View {
        VStack(spacing: 10) {
            HStack {
                streakPill
                Spacer()
                bellButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text(viewModel.selectedChallenge?.name ?? "Your Challenge")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 24)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("Day")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(viewModel.currentDay)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
                Text("of \(viewModel.totalDays)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            .lineLimit(1)
            .fixedSize()

            Text("\(viewModel.daysLeft) days left")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.pink)
            Text("\(viewModel.currentStreak) day streak")
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

    // MARK: - Daily progress card

    private var dailyProgressCard: some View {
        let pct = viewModel.dailyCompletionFraction
        let left = viewModel.habitsRemainingToday
        return HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Theme.progressTrack, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(LinearGradient(colors: [accent, accent.opacity(0.7)], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 3) {
                Text(left == 0 ? "All habits complete" : "\(left) habit\(left == 1 ? "" : "s") left today")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(viewModel.completedHabitCountToday)/\(viewModel.activeHabits.count) done today")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "flame.fill").font(.system(size: 16)).foregroundStyle(Theme.pink)
                Text("\(viewModel.currentStreak)").font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text("streak").font(.system(size: 10)).foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(18)
        .glassCard()
    }

    // MARK: - Habit checklist

    private var habitTrackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S HABITS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            ForEach(Array(viewModel.activeHabits.enumerated()), id: \.element.id) { index, habit in
                ChallengeHabitCard(
                    habit: habit,
                    viewModel: viewModel,
                    accent: habitPalette[index % habitPalette.count],
                    isExpanded: expandedHabit == habit.id,
                    onExpand: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            expandedHabit = expandedHabit == habit.id ? nil : habit.id
                        }
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5).delay(Double(index) * 0.06), value: appeared)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Complete Day

    private var completeDaySection: some View {
        let canComplete = viewModel.allRequiredHabitsComplete
        let alreadyDone = viewModel.isTodayComplete
        return Button {
            guard canComplete, !alreadyDone else { return }
            viewModel.completeDay()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showCelebration = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.easeOut(duration: 0.4)) { showCelebration = false }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: alreadyDone ? "checkmark.seal.fill" : (canComplete ? "checkmark.circle.fill" : "circle.dashed"))
                Text(alreadyDone ? "Day \(viewModel.currentDay) Complete" : (canComplete ? "Complete Day" : "Complete remaining habits"))
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(canComplete || alreadyDone ? .white : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                if alreadyDone {
                    LinearGradient(colors: [Theme.sageGreen, Theme.sageGreen.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                } else if canComplete {
                    LinearGradient(colors: [Theme.pink, Theme.pinkDeep], startPoint: .leading, endPoint: .trailing)
                } else {
                    Theme.progressTrack
                }
            }
            .clipShape(.rect(cornerRadius: 18))
            .shadow(color: (canComplete && !alreadyDone) ? Theme.pink.opacity(0.4) : .clear, radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!canComplete || alreadyDone)
        .animation(.easeInOut(duration: 0.25), value: canComplete)
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.softPink).frame(width: 110, height: 110)
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(LinearGradient(colors: [Theme.pinkDeep, Theme.pink], startPoint: .top, endPoint: .bottom))
                }
                Text("Day \(viewModel.currentDay) complete")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Your glow is building. ✨")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.pink)
                    Text("\(viewModel.currentStreak) day streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Capsule().fill(Theme.softPink))
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 28).fill(.white))
            .shadow(color: Theme.pink.opacity(0.25), radius: 24, y: 10)
            .padding(40)
            .transition(.scale.combined(with: .opacity))
        }
    }
}
