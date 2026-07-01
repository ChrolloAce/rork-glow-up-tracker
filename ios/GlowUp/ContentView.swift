import SwiftUI

struct ContentView: View {
    @State private var viewModel = GlowViewModel()
    @State private var showOnboardingAvatar: Bool = false
    @State private var showChallengeSelection: Bool = false
    @State private var showMoodSetup: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab("Today", systemImage: "checkmark.seal.fill", value: 0) {
                HomeView(viewModel: viewModel)
            }
            Tab("Mood", systemImage: "sparkles", value: 1) {
                MoodView(viewModel: viewModel)
            }
            Tab("Community", systemImage: "person.2.fill", value: 2) {
                CommunityView(viewModel: viewModel)
            }
            Tab("Profile", systemImage: "person.fill", value: 3) {
                ProfileView(viewModel: viewModel)
            }
        }
        .tint(Theme.pink)
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
