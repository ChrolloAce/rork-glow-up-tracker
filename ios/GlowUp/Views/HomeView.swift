import SwiftUI

/// Tab 1 — "Today". A fixed header (avatar + big day + tick ruler) sits on white,
/// and a rounded-top white container holding the checklist scrolls up over it
/// (parallax sheet) with a soft strap shadow along its top edge.
struct HomeView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var appeared: Bool = false
    @State private var expandedHabit: String?
    @State private var showCelebration: Bool = false
    @State private var showAvatarPicker: Bool = false
    @State private var showStats: Bool = false
    @State private var scrolledDay: Int?

    /// Primary accent — ink black. Light blue is the secondary accent / shadow tint.
    private let accent = Theme.ink
    private let blue = Theme.glowBlue

    private var day: Int { scrolledDay ?? viewModel.currentDay }

    private enum DayState { case today, past, future }
    private var dayState: DayState {
        if day > viewModel.currentDay { return .future }
        if day < viewModel.currentDay { return .past }
        return .today
    }

    var body: some View {
        GeometryReader { outer in
            // One scroll view: header is normal (interactive) content; the sheet
            // rises over it via a parallax offset so the ruler/percent always work.
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .visualEffect { content, proxy in
                            let minY = proxy.frame(in: .scrollView).minY
                            return content.offset(y: minY < 0 ? -minY * 0.45 : 0)
                        }
                        .zIndex(0)

                    taskContainer
                        .frame(minHeight: outer.size.height, alignment: .top)
                        .zIndex(1)
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.white.ignoresSafeArea())
        .overlay {
            if showCelebration { celebrationOverlay }
        }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView(selected: $viewModel.avatarURL, isFirstLaunch: false)
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
        .onAppear {
            viewModel.refreshDailyHabitsIfNeeded()
            if scrolledDay == nil { scrolledDay = viewModel.currentDay }
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Fixed header (avatar → big day → tick ruler)

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                streakPill
                Spacer()
                percentButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            avatar

            Text("\(day)")
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.25), value: day)
                .lineLimit(1)
                .fixedSize()

            dayRuler
        }
        .padding(.bottom, 18)
    }

    private var avatar: some View {
        Button { showAvatarPicker = true } label: {
            Circle()
                .fill(Theme.softPink)
                .frame(width: 88, height: 88)
                .overlay {
                    Group {
                        if AvatarCatalog.isLocal(viewModel.avatarURL) {
                            Image(viewModel.avatarURL).resizable().aspectRatio(contentMode: .fill)
                        } else {
                            AsyncImage(url: URL(string: viewModel.avatarURL)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Circle().fill(Theme.softPink)
                                }
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Circle())
                .overlay(Circle().stroke(blue.opacity(0.45), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").font(.system(size: 11)).foregroundStyle(blue)
            Text("\(viewModel.currentStreak) day streak")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .adaptiveGlass(in: Capsule())
    }

    // MARK: - Tiny progress ring + popover

    private var percentButton: some View {
        let pct = viewModel.dailyCompletionFraction
        return Button { showStats = true } label: {
            ZStack {
                Circle().stroke(Theme.progressTrack, lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(blue, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(pct * 100))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 38, height: 38)
            .padding(5)
            .adaptiveGlass(in: Circle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showStats) {
            statsPopover.presentationCompactAdaptation(.popover)
        }
    }

    private var statsPopover: some View {
        let pct = viewModel.dailyCompletionFraction
        let left = viewModel.habitsRemainingToday
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Theme.progressTrack, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: pct)
                        .stroke(blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(pct * 100))%").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Text(left == 0 ? "All habits complete" : "\(left) habit\(left == 1 ? "" : "s") left today")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(viewModel.completedHabitCountToday)/\(viewModel.activeHabits.count) done today")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(18)
        .frame(width: 240)
    }

    // MARK: - Day ruler (tick lines, snap-per-day, haptic per day)

    private var dayRuler: some View {
        GeometryReader { geo in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(1...max(viewModel.totalDays, 1), id: \.self) { d in
                        tickMark(d)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, geo.size.width / 2 - 8, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledDay, anchor: .center)
            .scrollIndicators(.hidden)
            .overlay(alignment: .top) { centerMarker }
        }
        .frame(height: 46)
        .sensoryFeedback(.selection, trigger: scrolledDay)
    }

    private func tickMark(_ d: Int) -> some View {
        let isSelected = d == day
        let isToday = d == viewModel.currentDay
        let isCompleted = viewModel.isDayComplete(d)
        let major = isToday || d % 5 == 0 || d == 1 || d == viewModel.totalDays
        let color: Color = isSelected ? accent
            : isToday ? accent
            : isCompleted ? accent.opacity(0.55)
            : Theme.textTertiary.opacity(0.35)
        return RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: isSelected ? 3 : 2, height: major ? 30 : 18)
            .frame(width: 16, height: 46)
            .id(d)
    }

    private var centerMarker: some View {
        Image(systemName: "triangle.fill")
            .font(.system(size: 8))
            .foregroundStyle(blue)
            .rotationEffect(.degrees(180))
            .frame(maxWidth: .infinity)
    }

    // MARK: - Task sheet container (rounded top + strap shadow)

    private var taskContainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch dayState {
            case .today:  todayHabits
            case .past:   pastDayView
            case .future: futureDayView
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                .fill(Color.white)
        )
        // Subtle strap shadow on the TOP edge only — caster sits behind the white
        // fill so the bottom blends into the screen with no shadow.
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                .fill(Color.white)
                .frame(height: 38)
                .shadow(color: Theme.glowBlue.opacity(0.16), radius: 7, x: 0, y: -1)
        }
    }

    // MARK: - Day states (today / past / future)

    @ViewBuilder private var todayHabits: some View {
        Text("TODAY'S HABITS")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.textTertiary)
            .tracking(1.5)
            .padding(.top, 22)

        ForEach(Array(viewModel.activeHabits.enumerated()), id: \.element.id) { index, habit in
            ChallengeHabitCard(
                habit: habit,
                viewModel: viewModel,
                accent: accent,
                isExpanded: expandedHabit == habit.id,
                onExpand: {
                    withAnimation(.easeOut(duration: 0.22)) {
                        expandedHabit = expandedHabit == habit.id ? nil : habit.id
                    }
                }
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: appeared)
        }

        completeDaySection
            .padding(.top, 18)
    }

    private var futureDayView: some View {
        VStack(spacing: 14) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(blue)
                .padding(.bottom, 2)
            Text("Day \(day) isn't here yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("This day unlocks when you reach it.\nStay present — one day at a time. ✨")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            goToTodayButton
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 12)
    }

    private var pastDayView: some View {
        let done = viewModel.isDayComplete(day)
        return VStack(spacing: 14) {
            Image(systemName: done ? "checkmark.seal.fill" : "calendar.badge.clock")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(done ? Theme.sageGreen : Theme.textTertiary)
                .padding(.bottom, 2)
            Text("Day \(day)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(done
                 ? "You showed up and completed this day. 💛"
                 : "This day has already passed.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            goToTodayButton
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 12)
    }

    private var goToTodayButton: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                scrolledDay = viewModel.currentDay
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .bold))
                Text("Go to Today")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(height: 50)
            .background(Capsule().fill(accent))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: day)
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
                    Capsule().fill(Theme.sageGreen)
                } else if canComplete {
                    Capsule().fill(accent)
                } else {
                    Capsule().fill(Theme.progressTrack)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!canComplete || alreadyDone)
        .animation(.easeInOut(duration: 0.25), value: canComplete)
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.softPink).frame(width: 110, height: 110)
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(accent)
                }
                Text("Day \(viewModel.currentDay) complete")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Your glow is building. ✨")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundStyle(accent)
                    Text("\(viewModel.currentStreak) day streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Capsule().fill(Theme.softPink))
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 28).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.subtleBorder, lineWidth: 1))
            .padding(40)
            .transition(.scale.combined(with: .opacity))
        }
    }
}


extension View {
    /// Flat white card: hairline border, no shadow.
    func flatCard(radius: CGFloat = 22) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: radius).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Theme.subtleBorder, lineWidth: 1))
    }
}
