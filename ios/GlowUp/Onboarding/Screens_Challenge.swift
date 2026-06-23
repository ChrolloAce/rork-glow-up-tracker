import SwiftUI

// 11 — Select your challenge
struct SelectChallengeScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    @State private var tab = 0 // 0 Most Popular, 1 Custom
    var recommended: OnbChallenge { sampleChallenges[0] }
    var rest: [OnbChallenge] { Array(sampleChallenges.dropFirst()) }

    var body: some View {
        Scaffold(progress: Step.selectChallenge.progress, onBack: vm.back) {
            VStack(spacing: 18) {
                Display(lead: "Select\nyour ", emph: "challenge", size: 32)

                // Tabs
                HStack(spacing: 0) {
                    ForEach(["Most Popular", "Custom"], id: \.self) { t in
                        let on = (t == "Most Popular" && tab == 0) || (t == "Custom" && tab == 1)
                        Button {
                            Haptics.select()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { tab = (t == "Most Popular") ? 0 : 1 }
                        } label: {
                            Text(t).font(.sans(14, .semibold))
                                .foregroundStyle(on ? AppColor.paper : AppColor.ink)
                                .frame(maxWidth: .infinity).frame(height: 38)
                                .background(on ? AppColor.ink : .clear, in: Capsule())
                        }
                    }
                }
                .padding(4)
                .background(AppColor.paper, in: Capsule())
                .overlay(Capsule().stroke(AppColor.line, lineWidth: 1))

                // Recommended pick (personalization payoff)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Recommended for you", systemImage: "sparkles")
                        .font(.sans(12, .semibold)).foregroundStyle(AppColor.inkSoft)
                    OnbChallengeCard(challenge: recommended, selected: vm.selectedChallenge == recommended) {
                        vm.selectedChallenge = recommended
                    }
                }

                Text("More challenges").font(.sans(12, .semibold))
                    .foregroundStyle(AppColor.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    ForEach(rest) { c in
                        OnbChallengeCard(challenge: c, selected: vm.selectedChallenge == c) {
                            vm.selectedChallenge = c
                        }
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

// 15 — OnbChallenge detail (editable tasks)
struct ChallengeDetailScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    let chipColors = [AppColor.chipGreen, AppColor.chipBlue, AppColor.chipPeach, AppColor.chipYellow, AppColor.chipLavender]

    var body: some View {
        Scaffold(progress: Step.challengeDetail.progress, onBack: vm.back) {
            VStack(spacing: 18) {
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 6) {
                        ForEach(Collage.names(3, seed: vm.selectedChallenge.seed), id: \.self) { name in
                            Image(name).resizable().scaledToFill()
                                .frame(height: 100).frame(maxWidth: .infinity).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    JoinBadge(count: vm.selectedChallenge.joined + 20000).padding(8)
                }
                Display(lead: vm.selectedChallenge.name, size: 28)

                Button {
                    Haptics.tap()
                } label: {
                    Label("Create Daily Task", systemImage: "plus")
                        .font(.sans(14, .semibold)).foregroundStyle(AppColor.ink)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppColor.line, lineWidth: 1))
                }

                VStack(spacing: 10) {
                    ForEach(Array(vm.selectedChallenge.tasks.enumerated()), id: \.offset) { i, t in
                        TaskRow(index: i + 1, color: chipColors[i % chipColors.count], text: t)
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "Validate") { vm.next() }
        }
    }
}
