import SwiftUI

// 6 — How did you hear
struct HearAboutScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    let options = ["TikTok", "Pinterest", "Content Creator", "Instagram", "Friend", "Family", "Other"]
    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.cream.ignoresSafeArea()

            // Decorative cut-out bleeding from the bottom-right
            Image("life8")
                .resizable().scaledToFill()
                .frame(width: 440, height: 440)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .center))
                .offset(x: 96, y: 150)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    BackButton(action: vm.back)
                    Spacer()
                    StepProgress(value: Step.hearAbout.progress ?? 0).frame(width: 132)
                    Spacer()
                    Color.clear.frame(width: 38, height: 38)
                }
                .padding(.horizontal, 20).padding(.top, 6)

                Display(lead: "How did ", emph: "you", tail: " hear\nabout Her75?", size: 32, align: .leading)
                    .padding(.horizontal, 24).padding(.top, 28)

                VStack(alignment: .leading, spacing: 22) {
                    ForEach(options, id: \.self) { o in
                        Button {
                            Haptics.select(); vm.hearAbout = o
                        } label: {
                            HStack(spacing: 16) {
                                CheckCircle(on: vm.hearAbout == o, size: 28)
                                Text(o).font(.sans(18, .medium)).foregroundStyle(AppColor.ink)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28).padding(.top, 34)

                Spacer(minLength: 24)

                PrimaryButton(title: "Continue", enabled: vm.hearAbout != nil) { vm.next() }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
            }
        }
    }
}

// 7 — Why complete a challenge (staggered raised / flat cards)
struct WhyScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    func sel(_ s: String) -> Bool { vm.why.contains(s) }
    func toggle(_ s: String) { if vm.why.contains(s) { vm.why.remove(s) } else { vm.why.insert(s) } }

    var body: some View {
        Scaffold(progress: Step.why.progress, onBack: vm.back) {
            VStack(spacing: 24) {
                Display(lead: "Why do you\nwant to ", emph: "complete", tail: " a\nchallenge?", size: 30)

                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 18) {
                        WhyCard(image: "fit4", label: "Become\nmy best self", raised: true,
                                selected: sel("Become my best self"), imageHeight: 150) { toggle("Become my best self") }
                        WhyCard(image: "life2", label: "Feel confident", raised: false,
                                selected: sel("Feel confident"), imageHeight: 150) { toggle("Feel confident") }
                    }
                    VStack(spacing: 18) {
                        WhyCard(image: "life6", label: "Reset\nmy life", raised: false,
                                selected: sel("Reset my life"), imageHeight: 196) { toggle("Reset my life") }
                        WhyCard(image: "fit5", label: "Build\ndiscipline", raised: true,
                                selected: sel("Build discipline"), imageHeight: 150) { toggle("Build discipline") }
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "Continue", enabled: !vm.why.isEmpty) { vm.next() }
        }
    }
}

struct WhyCard: View {
    var image: String
    var label: String
    var raised: Bool
    var selected: Bool
    var imageHeight: CGFloat
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.select(); action()
        } label: {
            if raised {
                VStack(spacing: 12) {
                    img(corner: 14)
                    footerRow
                }
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(selected ? AppColor.ink : AppColor.line, lineWidth: selected ? 2 : 1))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
            } else {
                VStack(spacing: 12) {
                    img(corner: 18)
                    footerRow
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func img(corner: CGFloat) -> some View {
        Image(image).resizable().scaledToFill()
            .frame(height: imageHeight).frame(maxWidth: .infinity).clipped()
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(!raised && selected ? AppColor.ink : .clear, lineWidth: 2))
    }

    private var footerRow: some View {
        HStack(spacing: 10) {
            CheckCircle(on: selected, size: 24)
            Text(label).font(.sans(15, .semibold)).foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, raised ? 2 : 4)
    }
}

// 8 — Ideal day (radial-glow cards, label below)
struct IdealDayScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    let opts: [(String, RadialGradient)] = [
        ("Early mornings,\nstructured", Auras.sunrise),
        ("Flexible,\nbut consistent", Auras.sky),
        ("Balanced — work\nhard, rest too", Auras.ember),
        ("Gentle reset,\nstart fresh", Auras.fresh),
    ]
    var body: some View {
        Scaffold(progress: Step.idealDay.progress, onBack: vm.back) {
            VStack(spacing: 24) {
                Display(lead: "What does your\n", emph: "ideal", tail: " day look like?", size: 28)
                HStack(alignment: .top, spacing: 16) {
                    column([0, 2])
                    column([1, 3])
                }
            }
        } footer: {
            PrimaryButton(title: "Continue", enabled: vm.idealDay != nil) { vm.next() }
        }
    }
    private func column(_ idx: [Int]) -> some View {
        VStack(spacing: 22) {
            ForEach(idx, id: \.self) { i in
                IdealCard(gradient: opts[i].1, label: opts[i].0, selected: vm.idealDay == opts[i].0) {
                    vm.idealDay = opts[i].0
                }
            }
        }
    }
}

enum Auras {
    static let sunrise = RadialGradient(gradient: Gradient(stops: [
        .init(color: Color(hex: "F7EAB8"), location: 0.0),
        .init(color: Color(hex: "EE7038"), location: 0.42),
        .init(color: Color(hex: "E0481F"), location: 0.5),
        .init(color: Color(hex: "F1D086"), location: 0.78),
        .init(color: Color(hex: "F6E6AE"), location: 1.0)]), center: .center, startRadius: 0, endRadius: 110)
    static let sky = RadialGradient(gradient: Gradient(colors: [
        Color(hex: "EAF1F6"), Color(hex: "9CC4E0"), Color(hex: "4F86C6"), Color(hex: "2C4D86")]),
        center: .center, startRadius: 2, endRadius: 130)
    static let ember = RadialGradient(gradient: Gradient(colors: [
        Color(hex: "F6C24A"), Color(hex: "F0822E"), Color(hex: "DC5A1B"), Color(hex: "C8470F")]),
        center: .center, startRadius: 2, endRadius: 140)
    static let fresh = RadialGradient(gradient: Gradient(colors: [
        Color(hex: "57C247"), Color(hex: "9FDB86"), Color(hex: "DAF1D0"), Color(hex: "F1F8EC")]),
        center: .center, startRadius: 2, endRadius: 140)
}

struct IdealCard: View {
    var gradient: RadialGradient
    var label: String
    var selected: Bool
    var action: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(gradient)
                .frame(height: 152)
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(selected ? AppColor.ink : .clear, lineWidth: 2.5))
            HStack(spacing: 10) {
                CheckCircle(on: selected, size: 24)
                Text(label).font(.sans(15, .medium)).foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 2)
        }
        .contentShape(Rectangle())
        .onTapGesture { Haptics.select(); action() }
    }
}

// 9 — Biggest challenge (object cut-outs, label below)
struct BiggestChallengeScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    func sel(_ s: String) -> Bool { vm.biggest.contains(s) }
    func toggle(_ s: String) { if vm.biggest.contains(s) { vm.biggest.remove(s) } else { vm.biggest.insert(s) } }

    var body: some View {
        Scaffold(progress: Step.biggestChallenge.progress, onBack: vm.back) {
            VStack(spacing: 28) {
                Display(lead: "What's your biggest\n", emph: "challenge", tail: " right now?", size: 27)
                HStack(alignment: .top, spacing: 8) {
                    VStack(spacing: 30) {
                        ChallengeIconCard(label: "Staying\nconsistent\nwith workouts",
                                          selected: sel("workouts")) { toggle("workouts") } icon: { Text("🧘‍♀️").font(.system(size: 76)) }
                        ChallengeIconCard(label: "Sleep &\nenergy levels",
                                          selected: sel("sleep")) { toggle("sleep") } icon: { Text("😴").font(.system(size: 76)) }
                    }
                    VStack(spacing: 30) {
                        ChallengeIconCard(label: "Eating better,\nless junk",
                                          selected: sel("eating")) { toggle("eating") } icon: { Text("🥑").font(.system(size: 76)) }
                        ChallengeIconCard(label: "Mental clarity\n& focus",
                                          selected: sel("mental")) { toggle("mental") } icon: { DNDToggle() }
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "Continue", enabled: !vm.biggest.isEmpty) { vm.next() }
        }
    }
}

struct ChallengeIconCard<Icon: View>: View {
    var label: String
    var selected: Bool
    var action: () -> Void
    @ViewBuilder var icon: Icon
    var body: some View {
        VStack(spacing: 16) {
            icon.frame(height: 116).frame(maxWidth: .infinity)
            HStack(spacing: 10) {
                CheckCircle(on: selected, size: 24)
                Text(label).font(.sans(15, .medium)).foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { Haptics.select(); action() }
    }
}

/// iOS-style "Do Not Disturb" focus pill.
struct DNDToggle: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "moon.fill").font(.system(size: 14))
                .foregroundStyle(Color(hex: "6E64E6"))
                .frame(width: 30, height: 30).background(.white, in: Circle())
            VStack(alignment: .leading, spacing: -1) {
                Text("Do Not").font(.sans(14, .semibold))
                Text("Disturb").font(.sans(14, .semibold))
                Text("On").font(.sans(12)).foregroundStyle(.white.opacity(0.55))
            }
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 13).padding(.vertical, 11)
        .background(Color(hex: "4A3B30"), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

// Minimal loader / transition screen (text + animated rule)
struct LoaderScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var lead: String
    var emph: String
    var tail: String
    var subtitle: String? = nil
    @State private var fill = false

    var body: some View {
        ZStack {
            AppColor.cream.ignoresSafeArea()
            VStack(spacing: 22) {
                Display(lead: lead, emph: emph, tail: tail, size: 30)
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.line).frame(width: 190, height: 2)
                    Capsule().fill(AppColor.ink).frame(width: fill ? 190 : 12, height: 2)
                }
                if let s = subtitle {
                    Text(s).font(.sans(13)).foregroundStyle(AppColor.inkSoft)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7)) { fill = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { vm.next() }
        }
    }
}
