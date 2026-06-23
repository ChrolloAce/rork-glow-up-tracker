import SwiftUI

private func four(_ seed: Int) -> [String] { Collage.names(4, seed: seed) }

// MARK: - 1 · Choose your challenge (film-strip list)

struct Welcome1: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            VStack(spacing: 28) {
                BeforeAfterShowcase()
                    .frame(height: 420)
                    .fadeUp(0.05)
                Display(lead: "Start your\n", emph: "75 day", tail: " glow up", size: 36).fadeUp(0.16)
            }
        } footer: {
            PrimaryButton(title: "Get Started") { vm.next() }
            Text("Already have an account?")
                .font(.sans(13)).underline()
                .foregroundStyle(AppColor.inkSoft)
        }
    }
}

// MARK: - Before / After auto-slider (3D card carousel)

struct BAPair: Identifiable {
    let id = UUID()
    let before: String
    let after: String
    let label: String
}

/// A stack of glossy before/after cards. The reveal slider auto-sweeps back and
/// forth, the card holds a subtle live 3D tilt, and every few seconds it flips
/// to the next pair — which replays the same sweep.
struct BeforeAfterShowcase: View {
    private let pairs: [BAPair] = [
        BAPair(before: "life4", after: "fit1",  label: "Day 1  →  Day 75"),
        BAPair(before: "food5", after: "fit5",  label: "Day 1  →  Day 75"),
        BAPair(before: "life2", after: "life6", label: "Day 1  →  Day 75"),
    ]
    @State private var index = 0
    @State private var split: CGFloat = 0.24
    @State private var tilt = false

    var body: some View {
        ZStack {
            ForEach(Array(pairs.enumerated()), id: \.element.id) { i, pair in
                if i == index {
                    BeforeAfterCard(pair: pair, split: split)
                        .transition(.asymmetric(
                            insertion: .modifier(active: CardFlip(angle: 90, trailing: false),
                                                 identity: CardFlip(angle: 0, trailing: false)),
                            removal: .modifier(active: CardFlip(angle: -90, trailing: true),
                                               identity: CardFlip(angle: 0, trailing: true))))
                }
            }
        }
        .rotation3DEffect(.degrees(tilt ? 5 : -5),
                          axis: (x: 0.4, y: 1, z: 0), perspective: 0.6)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { split = 0.78 }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { tilt = true }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
                    index = (index + 1) % pairs.count
                }
            }
        }
    }
}

private struct CardFlip: ViewModifier {
    var angle: Double
    var trailing: Bool
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0),
                              anchor: trailing ? .trailing : .leading, perspective: 0.55)
            .opacity(angle == 0 ? 1 : 0)
    }
}

struct BeforeAfterCard: View {
    var pair: BAPair
    var split: CGFloat
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Image(pair.after).resizable().scaledToFill().frame(width: w, height: h).clipped()
                Image(pair.before).resizable().scaledToFill().frame(width: w, height: h).clipped()
                    .mask(alignment: .leading) { Rectangle().frame(width: w * split) }
            }
            .overlay(alignment: .topLeading)  { baTag("BEFORE", dark: true).padding(12) }
            .overlay(alignment: .topTrailing) { baTag("AFTER",  dark: false).padding(12) }
            .overlay {
                ZStack {
                    Rectangle().fill(.white).frame(width: 3, height: h)
                    Circle().fill(.white).frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                        .overlay(Image(systemName: "arrow.left.arrow.right")
                            .font(.sans(13, .bold)).foregroundStyle(AppColor.ink))
                }
                .position(x: w * split, y: h / 2)
            }
            .overlay(alignment: .bottom) {
                Text(pair.label).font(.sans(13, .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(.black.opacity(0.32), in: Capsule())
                    .padding(.bottom, 14)
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.white.opacity(0.65), lineWidth: 1))
            .shadow(color: .black.opacity(0.20), radius: 26, y: 18)
        }
    }
}

@ViewBuilder
private func baTag(_ t: String, dark: Bool) -> some View {
    Text(t).font(.sans(11, .bold))
        .foregroundStyle(dark ? .white : AppColor.ink)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(dark ? AnyShapeStyle(.black.opacity(0.35)) : AnyShapeStyle(.white.opacity(0.92)), in: Capsule())
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
    // Dense scrapbook scatter — cut-outs filling every edge around the title.
    let items: [(String, CGFloat, CGFloat, CGFloat, Double)] = [
        ("fit8",     0, -262, 60,  5),  ("fit1",  -118, -224, 70, -9),
        ("food2",  120, -226, 64,  9),  ("life4", -150, -150, 58,  7),
        ("food6",  150, -156, 60, -8),  ("fit3",   -58, -176, 52, -4),
        ("life1",   62, -178, 50,  6),  ("food7", -152,  -34, 62, -6),
        ("life8",  152,  -44, 60,  8),  ("fit4",  -150,   86, 56,  4),
        ("food3",  152,   80, 56, -7),  ("fit5",  -120,  150, 66, -10),
        ("food9",  120,  148, 70,  7),  ("life3",  -56,  168, 54, -7),
        ("fit7",    60,  172, 56,  9),  ("food4", -150,  214, 52,  6),
        ("life6",  150,  214, 54, -9),  ("fit2",    -6,  256, 64,  5),
        ("food1", -112,  268, 54, -6),  ("life5",  112,  268, 56,  8),
        ("fit9",  -150,  300, 48, 10),  ("food5",  150,  300, 48, -10),
        ("life2",    0,  312, 56,  4),
    ]
    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            ZStack {
                ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                    Image(it.0).resizable().scaledToFill()
                        .frame(width: it.3, height: it.3)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white, lineWidth: 2))
                        .rotationEffect(.degrees(it.4))
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                        .offset(x: it.1, y: it.2)
                }
                Display(lead: "Become\n", emph: "“that girl”", size: 36)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(AppColor.cream.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 620)
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

// MARK: - 1b · Community planet (spinning globe, girly white mode)

private enum GlowPink {
    static let soft  = Color(hex: "F8C8DD")
    static let light = Color(hex: "F4A9C9")
    static let mid   = Color(hex: "EC7BA9")
}

struct GlobeScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    @State private var spin = false
    @State private var float = false
    @State private var count = 0
    private let target = 732_212

    // (avatar, xOffset, yOffset, size) — placed across the globe face
    private let pins: [(String, CGFloat, CGFloat, CGFloat)] = [
        ("character_5",  -52, -40, 60),
        ("character_12",  56, -28, 50),
        ("character_23", -34,  46, 52),
        ("character_31",  46,  48, 46),
        ("character_44",   2, -80, 44),
    ]

    var body: some View {
        Scaffold(showBack: false, progress: nil) {
            VStack(spacing: 26) {
                globe.fadeUp(0.05)
                VStack(spacing: 8) {
                    Text(count.formatted())
                        .font(.serif(48, .bold)).foregroundStyle(AppColor.ink)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                    Display(lead: "women changed\ntheir lives with ", emph: "Glow Up", size: 22)
                }
                .fadeUp(0.12)
                statBar.fadeUp(0.18)
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
        .onAppear { animate() }
    }

    private var globe: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [GlowPink.soft.opacity(0.6), .clear],
                                     center: .center, startRadius: 10, endRadius: 175))
                .frame(width: 330, height: 330).blur(radius: 6)

            Circle()
                .fill(RadialGradient(colors: [.white, GlowPink.light, GlowPink.mid],
                                     center: UnitPoint(x: 0.36, y: 0.30), startRadius: 6, endRadius: 175))
                .frame(width: 232, height: 232)
                .overlay(
                    Image(systemName: "globe")
                        .resizable().scaledToFit()
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(10)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                )
                .overlay(
                    Ellipse().fill(.white.opacity(0.45))
                        .frame(width: 120, height: 66).blur(radius: 14)
                        .offset(x: -30, y: -62)
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 1))
                .shadow(color: GlowPink.mid.opacity(0.4), radius: 26, y: 14)

            ForEach(Array(pins.enumerated()), id: \.offset) { i, p in
                AvatarPin(name: p.0, size: p.3)
                    .offset(x: p.1, y: p.2 + (float ? -5 : 5) * (i.isMultiple(of: 2) ? 1 : -1))
            }
        }
        .frame(height: 300)
    }

    private var statBar: some View {
        HStack(spacing: 0) {
            statItem(emoji: "💗", text: "96% Love it")
            Rectangle().fill(AppColor.line).frame(width: 1, height: 34)
            statItem(emoji: "🌸", text: "Worldwide")
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AppColor.line, lineWidth: 1))
    }

    private func statItem(emoji: String, text: String) -> some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 22))
            Text(text).font(.sans(14, .semibold)).foregroundStyle(AppColor.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private func animate() {
        withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) { spin = true }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { float = true }
        let steps = 45
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.028) {
                withAnimation(.snappy) { count = Int(Double(target) * Double(i) / Double(steps)) }
            }
        }
    }
}

struct AvatarPin: View {
    var name: String
    var size: CGFloat
    var body: some View {
        Image(name).resizable().scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            .overlay(alignment: .bottom) {
                Text("Glow").font(.sans(8, .bold)).foregroundStyle(GlowPink.mid)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.white, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                    .offset(y: 8)
            }
    }
}
