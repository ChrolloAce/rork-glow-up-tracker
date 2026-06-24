import SwiftUI

struct SelectChallengeView: View {
    @Bindable var viewModel: GlowViewModel

    /// Onboarding context shows a progress indicator + custom dismiss handling.
    var isOnboarding: Bool = false
    /// 0-based step for the small onboarding progress indicator.
    var onboardingStep: Int = 1
    var onboardingTotal: Int = 4
    /// Called once the user taps Continue with a valid selection.
    var onContinue: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Int = 0
    @State private var localSelection: String? = nil
    @State private var detailChallenge: Challenge? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                LiquidSegmented(selected: $tab, options: ["Most Popular", "Custom"])
                    .padding(.horizontal, 20)

                if tab == 0 {
                    popularList
                } else {
                    customState
                }

                Color.clear.frame(height: 28)
            }
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .background(Theme.screenGradient.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $detailChallenge) { challenge in
            ChallengeDetailView(challenge: challenge) {
                startChallenge(challenge.id)
            }
        }
        .onAppear { localSelection = viewModel.selectedChallengeID }
    }

    private func startChallenge(_ id: String) {
        viewModel.selectedChallengeID = id
        onContinue?()
        if !isOnboarding { dismiss() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Theme.softPink))
                        .overlay(Circle().stroke(Theme.subtleBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                if isOnboarding {
                    progressDots
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Select your challenge")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(2)

                Text("Choose the routine that matches the version of you you’re becoming.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<onboardingTotal, id: \.self) { index in
                Capsule()
                    .fill(index == onboardingStep ? Theme.pink : Theme.pinkLight.opacity(0.5))
                    .frame(width: index == onboardingStep ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: onboardingStep)
    }

    // MARK: - Popular list

    private var popularList: some View {
        LazyVStack(spacing: 18) {
            ForEach(ChallengeCatalog.popular) { challenge in
                ChallengeCard(
                    challenge: challenge,
                    isSelected: localSelection == challenge.id
                ) {
                    detailChallenge = challenge
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Custom state

    private var customState: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.softPink)
                        .frame(width: 76, height: 76)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Theme.pink)
                }

                VStack(spacing: 6) {
                    Text("Build your own challenge")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Mix the habits, duration, and focus that fit your life. Your custom routine, your rules.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 12)
                }

                Button {
                    // Custom builder coming soon — intentionally non-functional for now.
                } label: {
                    Text("Create Custom Challenge")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.pinkDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Theme.softPink))
                        .overlay(Capsule().stroke(Theme.pink.opacity(0.4), lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [7, 6])
                            )
                            .foregroundStyle(Theme.pink.opacity(0.35))
                    )
            }
        }
        .padding(.horizontal, 20)
    }

}

// MARK: - Challenge Card

private struct ChallengeCard: View {
    let challenge: Challenge
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                imageArea
                infoArea
            }
            .background(.white)
            .clipShape(.rect(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ? Theme.pink : Theme.subtleBorder,
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white, Theme.pink)
                        .padding(12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .shadow(
                color: isSelected ? Theme.pink.opacity(0.22) : .black.opacity(0.05),
                radius: isSelected ? 16 : 8,
                y: isSelected ? 8 : 4
            )
            .scaleEffect(isSelected ? 1.01 : 1)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
    }

    // MARK: Image placeholder area (flexible: hero / collage / illustration / gradient)

    private var imageArea: some View {
        ZStack(alignment: .topLeading) {
            placeholderContent
                .frame(height: 168)
                .frame(maxWidth: .infinity)
                .clipped()

            joinedPill
                .padding(12)
        }
        .frame(height: 168)
    }

    @ViewBuilder
    private var placeholderContent: some View {
        switch challenge.imageLayout {
        case .collage:
            collagePlaceholder
        case .hero, .illustration, .gradient:
            heroPlaceholder
        }
    }

    private var pastelGradient: LinearGradient {
        LinearGradient(
            colors: [
                challenge.themeColor.opacity(0.32),
                challenge.themeColor.opacity(0.14),
                Theme.softPink
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroPlaceholder: some View {
        ZStack {
            Rectangle().fill(pastelGradient)

            if let name = challenge.imageSlots.first?.assetName {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            } else {
                placeholderGlyph(layout: challenge.imageLayout)
            }
        }
    }

    private var collagePlaceholder: some View {
        let slots = challenge.imageSlots
        return GeometryReader { geo in
            let w = (geo.size.width - 3) / 2
            let h = (geo.size.height - 3) / 2
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    collageCell(slots.indices.contains(0) ? slots[0] : nil, index: 0)
                        .frame(width: w, height: h)
                    collageCell(slots.indices.contains(1) ? slots[1] : nil, index: 1)
                        .frame(width: w, height: h)
                }
                HStack(spacing: 3) {
                    collageCell(slots.indices.contains(2) ? slots[2] : nil, index: 2)
                        .frame(width: w, height: h)
                    collageCell(slots.indices.contains(3) ? slots[3] : nil, index: 3)
                        .frame(width: w, height: h)
                }
            }
        }
    }

    private func collageCell(_ slot: ImageSlot?, index: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            challenge.themeColor.opacity(0.28 - Double(index) * 0.03),
                            challenge.themeColor.opacity(0.12),
                            Theme.softPink
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            if let name = slot?.assetName {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(challenge.themeColor.opacity(0.5))
            }
        }
        .clipped()
    }

    private func placeholderGlyph(layout: ImageSlotLayout) -> some View {
        let symbol: String
        let label: String
        switch layout {
        case .illustration:
            symbol = "paintpalette"
            label = "Illustration"
        case .gradient:
            symbol = "sparkles"
            label = "Artwork"
        default:
            symbol = "photo"
            label = "Hero image"
        }
        return VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(challenge.themeColor.opacity(0.65))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(challenge.themeColor.opacity(0.7))
        }
    }

    private var joinedPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 10, weight: .semibold))
            Text(challenge.joinedLabel)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(Capsule().fill(.white.opacity(0.92)))
        .overlay(Capsule().stroke(.white, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    // MARK: Info area

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(challenge.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            Text(challenge.description)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                metaItem(icon: "calendar", text: challenge.durationLabel)
                difficultyItem
            }

            // Focus tags
            FlowTags(tags: challenge.focusTags, color: challenge.themeColor)

            Divider().background(Theme.subtleBorder)

            // Habit preview
            VStack(alignment: .leading, spacing: 8) {
                Text("INCLUDED HABITS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)

                FlowTags(
                    tags: challenge.habitPreview,
                    color: Theme.textSecondary,
                    filled: false
                )
            }
        }
        .padding(18)
    }

    private func metaItem(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(challenge.themeColor)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var difficultyItem: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(challenge.difficulty.dotColor)
                .frame(width: 8, height: 8)
            Text(challenge.difficulty.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Wrapping tag layout

private struct FlowTags: View {
    let tags: [String]
    var color: Color = Theme.pink
    var filled: Bool = true

    private let columns = [GridItem(.adaptive(minimum: 70), spacing: 8, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(filled ? color : Theme.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(
                        Capsule().fill(filled ? color.opacity(0.14) : Theme.softPink)
                    )
                    .overlay(
                        Capsule().stroke(filled ? color.opacity(0.25) : Theme.subtleBorder, lineWidth: 1)
                    )
            }
        }
    }
}
