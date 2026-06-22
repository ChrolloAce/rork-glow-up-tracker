import SwiftUI

struct ContentView: View {
    @State private var viewModel = GlowViewModel()
    @State private var showOnboardingAvatar: Bool = false
    @State private var showChallengeSelection: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView(viewModel: viewModel)
            }

            Tab("Beauty", systemImage: "calendar", value: 1) {
                BeautyCalendarView(viewModel: viewModel)
            }

            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: 2) {
                GlowProgressView(viewModel: viewModel)
            }

            Tab("Community", systemImage: "trophy.fill", value: 3) {
                CommunityView(viewModel: viewModel)
            }

            Tab("Profile", systemImage: "person.fill", value: 4) {
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
                    onContinue: { showChallengeSelection = false }
                )
            }
            .interactiveDismissDisabled()
        }
    }
}
