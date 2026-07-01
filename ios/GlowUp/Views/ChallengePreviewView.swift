import SwiftUI

/// Animated intro/preview shown every time a user starts (or switches to) a
/// challenge. It celebrates the choice and previews what the challenge involves
/// before dropping them into the app.
///
/// Artwork: uses the challenge's first `imageSlot.assetName` when supplied
/// (drop a per-challenge illustration into the asset catalog and set the name).
/// Until then it shows an animated gradient + glyph so the screen still feels
/// alive.
struct ChallengePreviewView: View {
    let challenge: Challenge
    var onBegin: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var artIn = false
    @State private var titleIn = false
    @State private var habitsIn = false
    @State private var ctaIn = false
    @State private var shimmer = false

    private var accent: Color { challenge.themeColor }

    var body: some View {
        ZStack {
            // Soft themed backdrop
            LinearGradient(
                colors: [accent.opacity(0.18), Theme.softPink, Color.white],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    artwork
                        .opacity(artIn ? 1 : 0)
                        .scaleEffect(artIn ? 1 : 0.9)
                        .offset(y: artIn ? 0 : 12)

                    VStack(spacing: 10) {
                        Text("YOUR CHALLENGE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(accent)

                        Text(challenge.name)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(challenge.description)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 8)
                    }
                    .opacity(titleIn ? 1 : 0)
                    .offset(y: titleIn ? 0 : 14)

                    metaPills
                        .opacity(titleIn ? 1 : 0)
                        .offset(y: titleIn ? 0 : 14)

                    habitList
                        .opacity(habitsIn ? 1 : 0)
                        .offset(y: habitsIn ? 0 : 18)

                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                beginButton
                    .opacity(ctaIn ? 1 : 0)
                    .offset(y: ctaIn ? 0 : 24)
            }
        }
        .onAppear(perform: animateIn)
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) { artIn = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.12)) { titleIn = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.26)) { habitsIn = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) { ctaIn = true }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) { shimmer = true }
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.35), accent.opacity(0.15), Theme.softPink],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            if let asset = challenge.imageSlots.first?.assetName {
                Image(asset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Animated placeholder until the per-challenge illustration is added.
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 70 + CGFloat(i) * 46)
                            .scaleEffect(shimmer ? 1.08 : 0.94)
                            .opacity(shimmer ? 0.2 : 0.6)
                    }
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.white)
                }
            }

            // Top specular shimmer sweep
            LinearGradient(colors: [.white.opacity(0.0), .white.opacity(0.25), .white.opacity(0.0)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 90)
                .rotationEffect(.degrees(18))
                .offset(x: shimmer ? 220 : -220)
                .blendMode(.overlay)
        }
        .frame(height: 240)
        .clipShape(.rect(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.5), lineWidth: 1))
        .shadow(color: accent.opacity(0.25), radius: 18, y: 10)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 5) {
                Image(systemName: "person.2.fill").font(.system(size: 10, weight: .semibold))
                Text(challenge.joinedLabel).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(Capsule().fill(.white.opacity(0.92)))
            .padding(12)
        }
    }

    private var metaPills: some View {
        HStack(spacing: 10) {
            pill(icon: "calendar", text: challenge.durationLabel)
            pill(icon: "circle.fill", text: challenge.difficulty.rawValue, dot: challenge.difficulty.dotColor)
        }
    }

    private func pill(icon: String, text: String, dot: Color? = nil) -> some View {
        HStack(spacing: 6) {
            if let dot {
                Circle().fill(dot).frame(width: 8, height: 8)
            } else {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(accent)
            }
            Text(text).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(Capsule().fill(.white))
        .overlay(Capsule().stroke(Theme.subtleBorder, lineWidth: 1))
    }

    private var habitList: some View {
        let habits = challenge.dailyHabits.isEmpty
            ? challenge.habitPreview.map { ($0, "circle.fill") }
            : challenge.dailyHabits.map { ($0.name, $0.icon) }
        return VStack(alignment: .leading, spacing: 10) {
            Text("WHAT YOU'LL DO DAILY")
                .font(.system(size: 11, weight: .bold)).tracking(1.5)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(habits.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 12) {
                    Image(systemName: item.1)
                        .font(.system(size: 14))
                        .foregroundStyle(accent)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(accent.opacity(0.12)))
                    Text(item.0)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var beginButton: some View {
        Button {
            let gen = UIImpactFeedbackGenerator(style: .medium); gen.impactOccurred()
            onBegin()
        } label: {
            HStack(spacing: 8) {
                Text("Begin Day 1")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule().fill(LinearGradient(colors: [Theme.pink, Theme.pinkDeep],
                                              startPoint: .leading, endPoint: .trailing))
            )
            .shadow(color: Theme.pink.opacity(0.4), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }
}
