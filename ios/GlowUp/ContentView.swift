import SwiftUI

struct ContentView: View {
    @State private var viewModel = GlowViewModel()
    @State private var showOnboardingAvatar: Bool = false
    @State private var showChallengeSelection: Bool = false
    @State private var showMoodSetup: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch viewModel.selectedTab {
                case 1: MoodView(viewModel: viewModel)
                case 2: CommunityView(viewModel: viewModel)
                case 3: ProfileView(viewModel: viewModel)
                default: HomeView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlassTabBar(selected: $viewModel.selectedTab)
        }
        .preferredColorScheme(.light)
        .onAppear {
            if !viewModel.hasSelectedAvatar {
                showOnboardingAvatar = true
            } else if !viewModel.hasSelectedChallenge {
                showChallengeSelection = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.saveAll()
            }
        }
        .fullScreenCover(isPresented: $showOnboardingAvatar) {
            AvatarPickerView(
                selected: $viewModel.avatarURL,
                isFirstLaunch: true,
                onConfirm: {
                    viewModel.hasSelectedAvatar = true
                    viewModel.beginJourneyIfNeeded()
                    UserDefaults.standard.set(true, forKey: "hasSelectedAvatar")
                    UserDefaults.standard.set(viewModel.avatarURL, forKey: "selectedAvatarID")
                    UserDefaults.standard.synchronize()
                    if !viewModel.hasSelectedChallenge {
                        showChallengeSelection = true
                    }
                }
            )
            .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $showChallengeSelection) {
            NavigationStack {
                SelectChallengeView(
                    viewModel: viewModel,
                    isOnboarding: true,
                    onboardingStep: 2,
                    onboardingTotal: 4,
                    onContinue: {
                        showChallengeSelection = false
                        if !viewModel.hasCompletedMoodSetup {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showMoodSetup = true }
                        }
                    }
                )
            }
            .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $showMoodSetup) {
            MoodSetupView(viewModel: viewModel) { showMoodSetup = false }
                .interactiveDismissDisabled()
        }
    }
}

/// A floating frosted-glass tab bar with a pink bubble that slides to the
/// selected tab (the closest equivalent to Liquid Glass on this build SDK).
struct GlassTabBar: View {
    @Binding var selected: Int
    @Namespace private var ns

    private let items: [(icon: String, label: String)] = [
        ("checkmark.seal.fill", "Today"),
        ("sparkles", "Mood"),
        ("person.2.fill", "Community"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .soft); gen.impactOccurred()
                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.28)) { selected = i }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: items[i].icon)
                            .font(.system(size: 17, weight: .semibold))
                        Text(items[i].label)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selected == i ? Theme.glowBlue : Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if selected == i { glassBubble }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(BubblePressStyle())
            }
        }
        .padding(5)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().fill(
                        LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                )
        }
        .overlay(
            Capsule().stroke(
                LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            )
        )
        .shadow(color: Theme.glowBlue.opacity(0.22), radius: 18, x: 0, y: 8)
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    /// A glassy "bubble" with a specular highlight that bounces to the selected tab.
    private var glassBubble: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(Capsule().fill(Theme.glowBlue.opacity(0.20)))
            .overlay(
                Capsule().fill(
                    LinearGradient(colors: [.white.opacity(0.7), .clear],
                                   startPoint: .top, endPoint: .center)
                )
            )
            .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 1))
            .shadow(color: Theme.glowBlue.opacity(0.35), radius: 7, x: 0, y: 2)
            .matchedGeometryEffect(id: "tabBubble", in: ns)
    }
}

/// Squishes the tab like a soft bubble when pressed.
struct BubblePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.bouncy(duration: 0.35, extraBounce: 0.3), value: configuration.isPressed)
    }
}
