import SwiftUI

private func four(_ seed: Int) -> [String] { Collage.names(4, seed: seed) }

// MARK: - 1 · Choose your challenge (film-strip list)

struct Welcome1: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            VStack(spacing: 22) {
                VStack(spacing: 18) {
                    ChallengeStrip(images: four(0), name: "75 Medium", joined: nil)
                    ChallengeStrip(images: four(1), name: "75 Soft", joined: 7506)
                    ChallengeStrip(images: four(2), name: "Better Me", joined: 1852)
                }
                .fadeUp(0.05)
                Display(lead: "Choose\nyour ", emph: "challenge", size: 40).fadeUp(0.16)
            }
        } footer: {
            PrimaryButton(title: "Get Started") { vm.next() }
            Text("Already have an account?")
                .font(.sans(13)).underline()
                .foregroundStyle(AppColor.inkSoft)
        }
    }
}

struct ChallengeStrip: View {
    var images: [String]
    var name: String
    var joined: Int?
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .top) {
                HStack(spacing: 2) {
                    ForEach(images, id: \.self) { n in
                        Image(n).resizable().scaledToFill()
                            .frame(height: 92).frame(maxWidth: .infinity).clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                if let j = joined {
                    JoinPill(count: j).offset(y: -13)
                }
            }
            Text(name).font(.serif(17, .semibold)).foregroundStyle(AppColor.ink)
        }
    }
}

// MARK: - 2 · Your daily to-do, your aesthetic

struct Welcome2: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            VStack(spacing: 22) {
                DailyPhoneMock().fadeUp(0.05)
                Display(lead: "Your daily to-do,\nyour ", emph: "aesthetic.", size: 30).fadeUp(0.16)
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

struct DailyPhoneMock: View {
    private let frameColor = Color(hex: "1B1B1D")
    var body: some View {
        screen
            .frame(width: 286, height: 452)
            .background(Color(hex: "F2EFE9"))
            .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
            .padding(7)
            .background(frameColor)
            .clipShape(RoundedRectangle(cornerRadius: 55, style: .continuous))
            .overlay(alignment: .leading) {
                VStack(spacing: 9) {
                    Capsule().frame(width: 3, height: 24)
                    Capsule().frame(width: 3, height: 40)
                    Capsule().frame(width: 3, height: 40)
                }
                .foregroundStyle(frameColor)
                .offset(x: -2, y: -40)
            }
            .overlay(alignment: .trailing) {
                Capsule().frame(width: 3, height: 60).foregroundStyle(frameColor).offset(x: 2, y: -10)
            }
            .mask(LinearGradient(colors: [.black, .black, .black, .clear], startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.18), radius: 26, y: 16)
            .padding(.top, 6)
    }

    private var screen: some View {
        VStack(spacing: 0) {
            // Status bar + dynamic island
            ZStack {
                Capsule().fill(.black).frame(width: 86, height: 26)
                    .overlay(alignment: .leading) { Circle().fill(Color(hex: "E5483B")).frame(width: 9, height: 9).padding(.leading, 12) }
                HStack {
                    HStack(spacing: 4) {
                        Text("16:19").font(.sans(13, .semibold))
                        Image(systemName: "bell.slash.fill").font(.sans(9))
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "cellularbars"); Image(systemName: "wifi"); Image(systemName: "battery.50")
                    }.font(.sans(11))
                }
                .padding(.horizontal, 20)
                .foregroundStyle(AppColor.ink)
            }
            .padding(.top, 12)

            // App bar
            HStack {
                Image(systemName: "calendar").font(.sans(15))
                    .frame(width: 38, height: 38).background(.white, in: Circle())
                    .overlay(Circle().stroke(AppColor.line, lineWidth: 0.5))
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color(hex: "BFE0A6"))
                        .frame(width: 34, height: 34)
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                    Image(systemName: "checkmark").font(.sans(14, .bold)).foregroundStyle(Color(hex: "3B6B2E"))
                }
                .rotationEffect(.degrees(-8))
                .padding(.trailing, 2)
                Image(systemName: "pencil").font(.sans(15))
                    .frame(width: 38, height: 38).background(.white, in: Circle())
                    .overlay(Circle().stroke(AppColor.line, lineWidth: 0.5))
            }
            .foregroundStyle(AppColor.ink)
            .padding(.horizontal, 18).padding(.top, 14)

            // Day photo + pill
            ZStack(alignment: .bottom) {
                Image("fit1").resizable().scaledToFill()
                    .frame(width: 104, height: 104).clipShape(Circle())
                Text("Day 1").font(.sans(13, .bold)).foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(.white, in: Capsule())
                    .shadow(color: .black.opacity(0.10), radius: 5, y: 2)
                    .offset(y: 15)
            }
            .padding(.top, 16)

            // Tally bars (dark → light)
            HStack(spacing: 3) {
                ForEach(0..<26, id: \.self) { i in
                    Capsule().fill(AppColor.ink.opacity(max(0.06, 0.95 - Double(i) * 0.038)))
                        .frame(width: 2.5, height: i % 3 == 0 ? 20 : 16)
                }
            }
            .padding(.top, 26).padding(.horizontal, 40)

            // Tasks card
            VStack(spacing: 0) {
                MiniTask(img: "food3", text: "Eat clean (no junk food and no alcohol) 🥗", time: nil, done: false)
                Divider().padding(.leading, 74)
                MiniTask(img: "life5", text: "Drink ONLY water 💧", time: "4:19pm", done: true)
                Divider().padding(.leading, 74)
                MiniTask(img: "fit2", text: "Walk 10,000 steps a day", time: "4:19pm", done: true, strike: true)
            }
            .padding(.horizontal, 14).padding(.vertical, 4)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
            .padding(.horizontal, 16).padding(.top, 20)

            Spacer(minLength: 0)
        }
    }
}

struct MiniTask: View {
    var img: String
    var text: String
    var time: String?
    var done: Bool
    var strike: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            Image(img).resizable().scaledToFill().frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(text).font(.sans(13, .medium))
                    .strikethrough(strike, color: AppColor.inkSoft)
                    .foregroundStyle(strike ? AppColor.inkSoft : AppColor.ink)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                if let t = time { Text(t).font(.sans(11)).foregroundStyle(AppColor.inkSoft) }
            }
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.sans(24))
                .foregroundStyle(done ? AppColor.inkSoft.opacity(0.55) : AppColor.inkSoft.opacity(0.5))
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 3 · See your friends' tasks

struct Welcome3: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            VStack(spacing: 26) {
                ZStack {
                    FriendCard(img: "fit1", name: "Maddy").rotationEffect(.degrees(-2)).offset(x: -6, y: 0).zIndex(1)
                    FriendCard(img: "life6", name: "Anna").rotationEffect(.degrees(1.5)).offset(x: 8, y: 162).zIndex(2)
                    FriendCard(img: "fit7", name: "Blake").rotationEffect(.degrees(-0.5)).offset(x: -2, y: 324).zIndex(3)
                }
                .frame(height: 540, alignment: .top)
                .fadeUp(0.05)
                Display(lead: "See your friends'\ntasks and ", emph: "aesthetic.", size: 28).fadeUp(0.16)
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

struct FriendCard: View {
    var img: String
    var name: String
    let tasks = ["Walk 10,000 steps", "Read 10 pages", "Workout", "Follow a strict diet"]
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 8) {
                Image(img).resizable().scaledToFill().frame(width: 84, height: 84).clipShape(Circle())
                VStack(spacing: 1) {
                    Text(name).font(.sans(18, .bold)).foregroundStyle(AppColor.ink)
                    Text("Day 75").font(.sans(13)).foregroundStyle(AppColor.inkSoft)
                }
            }
            .frame(width: 96)
            VStack(alignment: .leading, spacing: 14) {
                ForEach(tasks, id: \.self) { t in
                    HStack(spacing: 12) {
                        Circle().stroke(AppColor.line, lineWidth: 2).frame(width: 26, height: 26)
                        Text(t).font(.sans(15, .semibold)).foregroundStyle(AppColor.ink)
                            .lineLimit(1).fixedSize()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
    }
}

// MARK: - 4 · Become "that girl" (scattered cut-outs)

struct Welcome4: View {
    @EnvironmentObject var vm: OnboardingVM
    let items: [(String, CGFloat, CGFloat, CGFloat, Double)] = [
        ("fit8",   2, -228, 64, 5),   ("fit1", -110, -172, 76, -9),
        ("food2", 112, -178, 72, 9),  ("food6", -118, -74, 66, 8),
        ("life4", 118, -80, 64, -7),  ("food7", -116, 38, 60, -5),
        ("life1", 116, 32, 60, 6),    ("fit5", -114, 122, 70, -10),
        ("life8", 116, 114, 64, 8),   ("food9", -80, 200, 74, 7),
        ("life3", 86, 198, 72, -9),
    ]
    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            ZStack {
                ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                    Image(it.0).resizable().scaledToFill()
                        .frame(width: it.3, height: it.3)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .rotationEffect(.degrees(it.4))
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                        .offset(x: it.1, y: it.2)
                }
                Display(lead: "Become\n", emph: "“that girl”", size: 36)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .fadeUp(0.05)
        } footer: {
            PrimaryButton(title: "I'm ready") { vm.next() }
        }
    }
}

// MARK: - 5 · What's your name?

struct NameScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    @FocusState private var focused: Bool
    let faint = ["life1", "food4", "life5", "food7", "fit3"]

    var body: some View {
        Scaffold(showBack: true, progress: Step.name.progress, onBack: vm.back) {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 16)
                Display(lead: "What's your ", emph: "name?", size: 34, align: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Your name", text: $vm.name)
                    .font(.sans(17))
                    .focused($focused)
                    .padding(.horizontal, 16).padding(.vertical, 15)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(focused ? AppColor.ink.opacity(0.4) : AppColor.line, lineWidth: 1))

                HStack(spacing: 10) {
                    ForEach(faint, id: \.self) { n in
                        Image(n).resizable().scaledToFill().frame(height: 54)
                            .frame(maxWidth: .infinity).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .opacity(0.22).saturation(0.5)
                    }
                }
                .padding(.top, 6)
                Spacer()
            }
        } footer: {
            HStack {
                PrimaryButton(title: "Continue") { vm.next() }
                    .opacity(vm.name.isEmpty ? 0.4 : 1).disabled(vm.name.isEmpty)
                Spacer()
            }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true } }
    }
}

// Reusable phone frame (used by sticker / congrats screens)
struct PhoneMock<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
            .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(AppColor.line, lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
            .padding(.horizontal, 20)
    }
}
