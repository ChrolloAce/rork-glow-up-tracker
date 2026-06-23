import SwiftUI

// MARK: - Buttons

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var filled: Bool = true
    var fullWidth: Bool = false
    var enabled: Bool = true
    var action: () -> Void

    private var bg: Color { filled ? (enabled ? AppColor.ink : Color(hex: "E6E2DA")) : .clear }
    private var fg: Color { filled ? (enabled ? AppColor.paper : Color(hex: "AAA59C")) : AppColor.ink }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).font(.sans(16, .semibold))
            }
            .padding(.horizontal, fullWidth ? 0 : 32)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 52)
            .foregroundStyle(fg)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(AppColor.ink.opacity(filled ? 0 : 0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
    }
}

/// Round checkbox used across selection screens.
struct CheckCircle: View {
    var on: Bool
    var size: CGFloat = 26
    var body: some View {
        ZStack {
            Circle().stroke(on ? AppColor.ink : AppColor.line, lineWidth: 2).frame(width: size, height: size)
            if on {
                Circle().fill(AppColor.ink).frame(width: size, height: size)
                Image(systemName: "checkmark").font(.system(size: size * 0.42, weight: .bold)).foregroundStyle(.white)
            }
        }
    }
}

/// White floating join pill (sits on a challenge strip's top edge).
struct JoinPill: View {
    var count: Int
    var body: some View {
        Text("+\(count.formatted()) joined")
            .font(.sans(12, .semibold))
            .foregroundStyle(AppColor.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct BackButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.sans(15, .semibold))
                .foregroundStyle(AppColor.ink)
                .frame(width: 38, height: 38)
                .background(AppColor.paper)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColor.line, lineWidth: 1))
        }
    }
}

// MARK: - Progress bar

struct StepProgress: View {
    var value: Double // 0...1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColor.line)
                Capsule().fill(AppColor.ink)
                    .frame(width: max(6, geo.size.width * value))
            }
        }
        .frame(height: 4)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: value)
    }
}

// MARK: - Scaffold

struct Scaffold<Content: View, Footer: View>: View {
    var showBack: Bool = true
    var progress: Double? = nil
    var onBack: () -> Void = {}
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if showBack {
                    BackButton(action: onBack)
                } else {
                    Color.clear.frame(width: 38, height: 38)
                }
                Spacer()
                if let p = progress {
                    StepProgress(value: p).frame(width: 132)
                }
                Spacer()
                Color.clear.frame(width: 38, height: 38)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                content()
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }

            VStack(spacing: 10) { footer() }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .background(AppColor.cream.ignoresSafeArea())
    }
}

// MARK: - Staggered appear (smoothness)

struct AppearFade: ViewModifier {
    var delay: Double
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) { shown = true }
            }
    }
}
extension View {
    func fadeUp(_ delay: Double = 0) -> some View { modifier(AppearFade(delay: delay)) }
}

// MARK: - Join badge

struct JoinBadge: View {
    var count: Int
    var body: some View {
        Text("+\(count.formatted()) joined")
            .font(.sans(11, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.35), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Image catalog

struct Tile: Identifiable {
    let id = UUID()
    var image: String
    var height: CGFloat
}

enum Collage {
    static let fit  = (1...10).map { "fit\($0)" }
    static let life = (1...8).map { "life\($0)" }
    static let food = (1...10).map { "food\($0)" }

    /// Interleaved blend so collages mix fitness / lifestyle / food.
    static let mixed: [String] = {
        var out: [String] = []
        let m = max(fit.count, life.count, food.count)
        for i in 0..<m {
            if i < fit.count  { out.append(fit[i]) }
            if i < food.count { out.append(food[i]) }
            if i < life.count { out.append(life[i]) }
        }
        return out
    }()

    static func names(_ n: Int, seed: Int) -> [String] {
        (0..<n).map { mixed[(seed * 3 + $0) % mixed.count] }
    }

    static func tiles(_ n: Int, seed: Int) -> [Tile] {
        let heights: [CGFloat] = [128, 158, 104, 172, 138]
        return names(n, seed: seed).enumerated().map { i, name in
            Tile(image: name, height: heights[(i + seed) % heights.count])
        }
    }

    // Solid accent colors for avatars
    static let palette: [Color] = [
        Color(hex: "C9B79A"), Color(hex: "A9C0B2"), Color(hex: "D9A57E"),
        Color(hex: "B3A9C4"), Color(hex: "C2BA9E"), Color(hex: "C99B96"),
    ]
}

/// A single rounded watercolor tile.
struct ImageTile: View {
    var name: String
    var height: CGFloat? = nil
    var corner: CGFloat = 14
    var body: some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(.black.opacity(0.06), lineWidth: 0.5))
    }
}

struct CollageTile: View {
    var tile: Tile
    var body: some View { ImageTile(name: tile.image, height: tile.height) }
}

/// Three-column scrapbook collage of real watercolors.
struct CollageGrid: View {
    var count: Int = 9
    var seed: Int = 0
    var body: some View {
        let tiles = Collage.tiles(count, seed: seed)
        HStack(alignment: .top, spacing: 8) {
            ForEach(0..<3, id: \.self) { col in
                VStack(spacing: 8) {
                    ForEach(Array(tiles.enumerated()).filter { $0.offset % 3 == col }, id: \.element.id) { item in
                        CollageTile(tile: item.element)
                    }
                }
            }
        }
    }
}

// MARK: - Chips / tags

struct TagChip: View {
    var text: String
    var color: Color
    var body: some View {
        Text(text)
            .font(.sans(13, .medium))
            .foregroundStyle(AppColor.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color, in: Capsule())
    }
}

// MARK: - Selection rows / cards

struct RadioRow: View {
    var label: String
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.select(); action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(selected ? AppColor.ink : AppColor.line, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if selected { Circle().fill(AppColor.ink).frame(width: 12, height: 12) }
                }
                Text(label).font(.sans(17, .regular)).foregroundStyle(AppColor.ink)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

struct IconOption: View {
    var symbol: String
    var label: String
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.select(); action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(AppColor.ink)
                    .frame(width: 46, height: 46)
                    .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColor.line, lineWidth: 1))
                Text(label).font(.sans(16, .medium)).foregroundStyle(AppColor.ink)
                Spacer()
                ZStack {
                    Circle().stroke(selected ? AppColor.ink : AppColor.line, lineWidth: 1.5).frame(width: 22, height: 22)
                    if selected { Circle().fill(AppColor.ink).frame(width: 12, height: 12) }
                }
            }
            .padding(12)
            .background(AppColor.paper.opacity(selected ? 1 : 0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(selected ? AppColor.ink : AppColor.line, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct ImageOptionCard: View {
    var image: String
    var label: String
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.select(); action()
        } label: {
            VStack(spacing: 0) {
                Image(image)
                    .resizable().scaledToFill()
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipped()
                HStack(spacing: 8) {
                    ZStack {
                        Circle().stroke(selected ? AppColor.ink : AppColor.line, lineWidth: 1.5).frame(width: 18, height: 18)
                        if selected { Circle().fill(AppColor.ink).frame(width: 9, height: 9) }
                    }
                    Text(label).font(.sans(14, .medium)).foregroundStyle(AppColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(10)
            }
            .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(selected ? AppColor.ink : AppColor.line, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct MoodCard: View {
    var gradient: LinearGradient
    var label: String
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.select(); action()
        } label: {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(gradient)
                    .frame(height: 92)
                HStack(spacing: 8) {
                    ZStack {
                        Circle().stroke(selected ? AppColor.ink : AppColor.line, lineWidth: 1.5).frame(width: 18, height: 18)
                        if selected { Circle().fill(AppColor.ink).frame(width: 9, height: 9) }
                    }
                    Text(label).font(.sans(13, .medium)).foregroundStyle(AppColor.ink).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
            .padding(12)
            .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(selected ? AppColor.ink : AppColor.line, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task row (challenge detail)

struct TaskRow: View {
    var index: Int
    var color: Color
    var text: String
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.sans(15, .bold))
                .foregroundStyle(AppColor.ink)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(text).font(.sans(15, .regular)).foregroundStyle(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Image(systemName: "pencil").font(.sans(13)).foregroundStyle(AppColor.inkSoft)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppColor.line, lineWidth: 1))
    }
}

// MARK: - OnbChallenge list card

struct OnbChallengeCard: View {
    var challenge: OnbChallenge
    var selected: Bool = false
    var action: () -> Void = {}
    var body: some View {
        Button {
            Haptics.select(); action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        ForEach(Collage.names(3, seed: challenge.seed), id: \.self) { name in
                            Image(name).resizable().scaledToFill()
                                .frame(height: 78).frame(maxWidth: .infinity).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    JoinBadge(count: challenge.joined).padding(8)
                }
                HStack {
                    Text(challenge.name).font(.serif(20)).foregroundStyle(AppColor.ink)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColor.ink)
                    }
                }
            }
            .padding(10)
            .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(selected ? AppColor.ink : AppColor.line, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}
