import SwiftUI

/// Detail screen shown when a user taps a challenge before starting it.
/// Fully dynamic from the passed-in `Challenge`.
struct ChallengeDetailView: View {
    let challenge: Challenge

    /// `true` when viewing the challenge you're already doing (from inside the
    /// app) — the bottom bar becomes a simple "Done" instead of "Start".
    var isActive: Bool = false

    /// Called when the user commits to this challenge (or taps Done when active).
    var onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 28) {
                        titleBlock
                        dailyHabitsSection
                        rulesSection
                        metricsSection
                        Color.clear.frame(height: 132)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            bottomBar
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            heroImage
                .frame(height: 320)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottom) { heroFade }

            joinedPill
                .padding(20)
        }
        .overlay(alignment: .topLeading) { backButton }
        .overlay(alignment: .topTrailing) { difficultyPill }
    }

    @ViewBuilder
    private var heroImage: some View {
        if challenge.imageLayout == .collage, challenge.imageSlots.count >= 4 {
            heroCollage
        } else {
            heroSingle
        }
    }

    private var heroSingle: some View {
        ZStack {
            Rectangle().fill(pastelGradient)
            if let name = challenge.imageSlots.first?.assetName {
                Image(name).resizable().aspectRatio(contentMode: .fill)
            } else {
                placeholderGlyph
            }
        }
    }

    private var heroCollage: some View {
        GeometryReader { geo in
            let w = (geo.size.width - 3) / 2
            let h = (geo.size.height - 3) / 2
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    collageCell(0).frame(width: w, height: h)
                    collageCell(1).frame(width: w, height: h)
                }
                HStack(spacing: 3) {
                    collageCell(2).frame(width: w, height: h)
                    collageCell(3).frame(width: w, height: h)
                }
            }
        }
    }

    private func collageCell(_ index: Int) -> some View {
        ZStack {
            Rectangle().fill(
                LinearGradient(
                    colors: [
                        challenge.themeColor.opacity(0.30 - Double(index) * 0.03),
                        challenge.themeColor.opacity(0.12),
                        Theme.softPink
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            if let slot = challenge.imageSlots[safe: index], let name = slot.assetName {
                Image(name).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(challenge.themeColor.opacity(0.5))
            }
        }
        .clipped()
    }

    private var pastelGradient: LinearGradient {
        LinearGradient(
            colors: [
                challenge.themeColor.opacity(0.34),
                challenge.themeColor.opacity(0.16),
                Theme.softPink
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var placeholderGlyph: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(challenge.themeColor.opacity(0.7))
            Text("Add your artwork")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(challenge.themeColor.opacity(0.7))
        }
    }

    private var heroFade: some View {
        LinearGradient(
            colors: [Theme.background.opacity(0), Theme.background],
            startPoint: .top, endPoint: .bottom
        )
        .frame(height: 70)
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 42, height: 42)
                .background(Circle().fill(.white.opacity(0.92)))
                .overlay(Circle().stroke(.white, lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.leading, 20)
        .padding(.top, 60)
    }

    private var difficultyPill: some View {
        HStack(spacing: 6) {
            Circle().fill(challenge.difficulty.dotColor).frame(width: 7, height: 7)
            Text(challenge.difficulty.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(.white.opacity(0.92)))
        .overlay(Capsule().stroke(.white, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .padding(.trailing, 20)
        .padding(.top, 62)
    }

    private var joinedPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "person.2.fill").font(.system(size: 11, weight: .semibold))
            Text(challenge.joinedLabel).font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.94)))
        .overlay(Capsule().stroke(.white, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    // MARK: - Title block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(challenge.name)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 10) {
                metaChip(icon: "calendar", text: challenge.durationLabel)
                metaChip(icon: "flame.fill", text: challenge.difficulty.rawValue)
            }

            Text(challenge.description)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            tagWrap(challenge.focusTags)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(challenge.themeColor)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Theme.softPink))
        .overlay(Capsule().stroke(Theme.subtleBorder, lineWidth: 1))
    }

    // MARK: - Daily habits

    private var dailyHabitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("What you’ll do daily", subtitle: "\(challenge.dailyHabits.count) habits, every day")

            VStack(spacing: 0) {
                ForEach(Array(challenge.dailyHabits.enumerated()), id: \.element.id) { index, habit in
                    habitRow(habit)
                    if index < challenge.dailyHabits.count - 1 {
                        Divider().background(Theme.subtleBorder).padding(.leading, 60)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(softCard)
        }
    }

    private func habitRow(_ habit: DailyHabit) -> some View {
        HStack(spacing: 13) {
            ZStack {
                Circle().fill(challenge.themeColor.opacity(0.14)).frame(width: 40, height: 40)
                Image(systemName: habit.icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(challenge.themeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(habit.explanation)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            typeBadge(habit.type)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func typeBadge(_ type: HabitTaskType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: type.glyph).font(.system(size: 9, weight: .bold))
            Text(type.label).font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundStyle(type.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(type.tint.opacity(0.13)))
    }

    // MARK: - Rules

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Challenge rules", subtitle: nil)

            VStack(spacing: 12) {
                ForEach(Array(challenge.rules.enumerated()), id: \.offset) { index, rule in
                    ruleRow(number: index + 1, text: rule)
                }
            }
            .padding(16)
            .background(softCard)
        }
    }

    private func ruleRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(challenge.themeColor.opacity(0.14)).frame(width: 26, height: 26)
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(challenge.themeColor)
            }
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Tracked metrics

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Your progress will track", subtitle: "See these in your Progress tab")

            let columns = [GridItem(.adaptive(minimum: 150), spacing: 10, alignment: .leading)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(challenge.trackedMetrics, id: \.self) { metric in
                    metricChip(metric)
                }
            }
        }
    }

    private func metricChip(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(challenge.themeColor)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(softCard)
    }

    // MARK: - Shared bits

    private func sectionHeader(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var softCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.subtleBorder, lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func tagWrap(_ tags: [String]) -> some View {
        let columns = [GridItem(.adaptive(minimum: 74), spacing: 8, alignment: .leading)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(challenge.themeColor)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(challenge.themeColor.opacity(0.13)))
                    .overlay(Capsule().stroke(challenge.themeColor.opacity(0.24), lineWidth: 1))
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button {
                onStart()
            } label: {
                Text(isActive ? "Done" : "Start Challenge")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background {
                        LinearGradient(
                            colors: [Theme.pink, Theme.pinkDeep],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    }
                    .clipShape(.rect(cornerRadius: 18))
                    .shadow(color: Theme.pink.opacity(0.4), radius: 14, y: 6)
            }
            .buttonStyle(.plain)

            if !isActive {
                Button { dismiss() } label: {
                    Text("Choose another challenge")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.pinkDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
    }
}

// Safe array subscript used by the collage cells.
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
