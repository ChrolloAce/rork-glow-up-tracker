import SwiftUI
import SuperwallKit

// 27 — Congrats
struct CongratsScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            VStack(spacing: 22) {
                Display(lead: "Congrats.\nYou're ready to ", emph: "start", tail: "\nyour challenge", size: 28)
                PhoneMock {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("day one").font(.serif(20))
                        Text("Day 19 • Step 1").font(.sans(11)).foregroundStyle(AppColor.inkSoft)
                        ForEach(Array(vm.selectedChallenge.tasks.prefix(3).enumerated()), id: \.offset) { i, t in
                            HStack(spacing: 10) {
                                Image(systemName: "circle").foregroundStyle(AppColor.inkSoft)
                                Text(t).font(.sans(13)).lineLimit(1)
                            }
                        }
                    }.padding(20)
                }
            }
        } footer: {
            PrimaryButton(title: "Start now") { vm.next() }
        }
        .onAppear { Haptics.success() }
    }
}

// 28 — Paywall
//
// The Superwall paywall (placement "campaign_trigger") is the primary, real
// monetization surface — it presents over this screen. The static layout below
// remains as a visual fallback if no remote paywall is configured / reachable.
struct PaywallScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    @State private var freeTrial = true

    let plans: [(name: String, price: String, sub: String, badge: String?)] = [
        ("Yearly", "$4.17", "/month, billed annually", "Save 72%"),
        ("Monthly", "$14.99", "/month", nil),
        ("Weekly", "$7.99", "/week", nil),
    ]

    /// Present the Superwall campaign. The `feature` block runs once the user is
    /// entitled (subscribed, converts, or the campaign is non-gated / unreachable),
    /// which is our signal to finish onboarding and enter the app.
    private func presentPaywall() {
        Superwall.shared.register(placement: "campaign_trigger") {
            vm.finish()
        }
    }

    var body: some View {
        Scaffold(showBack: true, progress: nil, onBack: vm.back) {
            VStack(spacing: 18) {
                CollageGrid(count: 3, seed: 4).frame(height: 96).clipped()
                JoinBadge(count: 198946)
                Display(lead: "Join 200,000\n", emph: "women", tail: " on their\nglow-up journey", size: 26)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(["Join the community", "Stay accountable with real people", "Build habits that actually stick"], id: \.self) { b in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark").font(.sans(13, .bold)).foregroundStyle(AppColor.ink)
                            Text(b).font(.sans(14)).foregroundStyle(AppColor.ink)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                VStack(spacing: 10) {
                    ForEach(plans, id: \.name) { p in
                        PlanRow(plan: p, selected: vm.plan == p.name) { vm.plan = p.name }
                    }
                }

                Toggle(isOn: $freeTrial) {
                    Text("3-day free trial").font(.sans(14, .medium)).foregroundStyle(AppColor.ink)
                }
                .tint(AppColor.ink)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColor.line, lineWidth: 1))
            }
        } footer: {
            PrimaryButton(title: freeTrial ? "Start free trial" : "Continue") {
                Haptics.success()
                presentPaywall()
            }
            HStack(spacing: 18) {
                Button("Privacy policy") {}
                Button("Restore") { presentPaywall() }
                Button("Terms of service") {}
            }
            .buttonStyle(.plain)
            .font(.sans(11)).foregroundStyle(AppColor.inkSoft)
        }
        .onAppear { presentPaywall() }
    }
}

struct PlanRow: View {
    var plan: (name: String, price: String, sub: String, badge: String?)
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.select(); action()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(selected ? AppColor.ink : AppColor.line, lineWidth: 1.5).frame(width: 22, height: 22)
                    if selected { Circle().fill(AppColor.ink).frame(width: 12, height: 12) }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name).font(.sans(16, .semibold)).foregroundStyle(AppColor.ink)
                    HStack(spacing: 2) {
                        Text(plan.price).font(.sans(15, .bold)).foregroundStyle(AppColor.ink)
                        Text(plan.sub).font(.sans(12)).foregroundStyle(AppColor.inkSoft)
                    }
                }
                Spacer()
                if let b = plan.badge {
                    Text(b).font(.sans(11, .bold)).foregroundStyle(AppColor.ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(AppColor.chipGreen, in: Capsule())
                }
            }
            .padding(14)
            .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(selected ? AppColor.ink : AppColor.line, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}
