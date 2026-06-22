import SwiftUI

enum Theme {
    // Core surfaces
    static let background = Color(red: 1.0, green: 0.98, blue: 0.98)
    static let surface = Color.white
    static let softPink = Color(red: 1.0, green: 0.94, blue: 0.94)

    // Text (dark on light)
    static let textPrimary = Color(red: 0.12, green: 0.08, blue: 0.10)
    static let textSecondary = Color(red: 0.45, green: 0.38, blue: 0.40)
    static let textTertiary = Color(red: 0.65, green: 0.58, blue: 0.60)

    // Pink family (primary accent)
    static let pink = Color(red: 0.96, green: 0.56, blue: 0.66)
    static let pinkLight = Color(red: 0.99, green: 0.78, blue: 0.82)
    static let pinkDeep = Color(red: 0.86, green: 0.38, blue: 0.50)
    static let blushPink = Color(red: 0.99, green: 0.84, blue: 0.86)

    // Rose gold (kept for identity)
    static let roseGold = Color(red: 0.88, green: 0.58, blue: 0.52)
    static let roseGoldLight = Color(red: 0.96, green: 0.76, blue: 0.72)
    static let roseGoldDeep = Color(red: 0.72, green: 0.42, blue: 0.40)

    // Supporting accents
    static let mauve = Color(red: 0.70, green: 0.50, blue: 0.60)
    static let warmGold = Color(red: 0.82, green: 0.62, blue: 0.32)
    static let waterBlue = Color(red: 0.40, green: 0.72, blue: 0.92)
    static let lavender = Color(red: 0.70, green: 0.62, blue: 0.88)
    static let sageGreen = Color(red: 0.52, green: 0.76, blue: 0.60)
    static let warmOrange = Color(red: 0.96, green: 0.62, blue: 0.38)
    static let dustyRose = Color(red: 0.86, green: 0.60, blue: 0.68)
    static let taupe = Color(red: 0.78, green: 0.64, blue: 0.52)
    static let champagne = Color(red: 0.98, green: 0.90, blue: 0.82)

    // Utility
    static let muted = textSecondary
    static let subtleBorder = Color(red: 0.95, green: 0.86, blue: 0.88)
    static let glassBackground = Color.white.opacity(0.6)
    static let glassStroke = pink.opacity(0.25)
    static let progressTrack = Color(red: 0.96, green: 0.90, blue: 0.92)

    // Clean white screen background
    static let screenGradient = LinearGradient(
        colors: [Color.white, Color.white],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroGradient = LinearGradient(
        colors: [Color.white, Color.white],
        startPoint: .top,
        endPoint: .bottom
    )

    // Outlined glass card recipe
    static let cardStrokeGradient = LinearGradient(
        colors: [pink.opacity(0.55), pinkLight.opacity(0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassCard: ViewModifier {
    var radius: CGFloat = 22
    var tinted: Bool = false
    var accent: Color? = nil

    func body(content: Content) -> some View {
        let strokeColor = accent ?? Theme.pink
        content
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .fill(.white.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (accent ?? Theme.pink).opacity(tinted ? 0.10 : 0.03),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .clipShape(.rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [strokeColor.opacity(0.55), strokeColor.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )
            )
            .shadow(color: strokeColor.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func glassCard(radius: CGFloat = 22, tinted: Bool = false, accent: Color? = nil) -> some View {
        modifier(GlassCard(radius: radius, tinted: tinted, accent: accent))
    }

    @ViewBuilder
    func adaptiveGlass(in shape: some Shape = .capsule) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self
                .background {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(Color.white.opacity(0.5))
                    }
                }
                .clipShape(shape)
                .overlay(
                    shape.stroke(Theme.pink.opacity(0.3), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    func adaptiveGlassTinted(_ color: Color, in shape: some Shape = .capsule) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(color).interactive(), in: shape)
        } else {
            self
                .background {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(color.opacity(0.35))
                    }
                }
                .clipShape(shape)
                .overlay(
                    shape.stroke(color.opacity(0.55), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    func adaptivePresentationBackground() -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            self.presentationBackground(Theme.background)
        }
    }
}
