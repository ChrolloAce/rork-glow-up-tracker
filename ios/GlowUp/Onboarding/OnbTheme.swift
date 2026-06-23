import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let r, g, b: UInt64
        switch s.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

// MARK: - Palette

enum AppColor {
    static let cream    = Color(hex: "F4F1EA")
    static let paper    = Color(hex: "FBFAF6")
    static let ink      = Color(hex: "1A1A18")
    static let inkSoft  = Color(hex: "8C887E")
    static let line     = Color(hex: "E6E1D6")
    static let chipYellow   = Color(hex: "F2EBC8")
    static let chipGreen    = Color(hex: "DCE8D2")
    static let chipLavender = Color(hex: "E4DEEC")
    static let chipPeach    = Color(hex: "F3DECB")
    static let chipBlue     = Color(hex: "D6E2EA")
}

// MARK: - Gradient presets (mood cards)

enum Moods {
    static let warm   = LinearGradient(colors: [Color(hex: "F4B14A"), Color(hex: "E8643C")], startPoint: .top, endPoint: .bottom)
    static let calm   = LinearGradient(colors: [Color(hex: "BFD6C8"), Color(hex: "8FB9D6")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let ember  = LinearGradient(colors: [Color(hex: "F06A3A"), Color(hex: "C0341F")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let sage   = LinearGradient(colors: [Color(hex: "C9D6B8"), Color(hex: "9FB089")], startPoint: .top, endPoint: .bottom)

    static func radial(_ colors: [Color]) -> RadialGradient {
        RadialGradient(colors: colors, center: .center, startRadius: 4, endRadius: 90)
    }
}

// MARK: - Fonts

enum PF {
    static let medium       = "PlayfairDisplay-Medium"
    static let semibold     = "PlayfairDisplay-SemiBold"
    static let bold         = "PlayfairDisplay-Bold"
    static let mediumItalic = "PlayfairDisplay-MediumItalic"
    static let semiItalic   = "PlayfairDisplay-SemiBoldItalic"
    static let boldItalic   = "PlayfairDisplay-BoldItalic"
}

extension Font {
    /// Editorial serif — Playfair Display.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = PF.bold
        case .semibold:             name = PF.semibold
        default:                    name = PF.medium
        }
        return .custom(name, size: size)
    }
    static func serifItalic(_ size: CGFloat, bold: Bool = true) -> Font {
        .custom(bold ? PF.boldItalic : PF.mediumItalic, size: size)
    }
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Display headline (Playfair roman + true italic emphasis)

enum DisplayWeight { case semibold, bold }

struct Display: View {
    var lead: String = ""
    var emph: String = ""
    var tail: String = ""
    var size: CGFloat = 34
    var align: TextAlignment = .center
    var weight: DisplayWeight = .bold

    var body: some View {
        let roman = weight == .bold ? PF.bold : PF.semibold
        let ital  = weight == .bold ? PF.boldItalic : PF.semiItalic
        (Text(lead).font(.custom(roman, size: size))
            + Text(emph).font(.custom(ital, size: size))
            + Text(tail).font(.custom(roman, size: size)))
            .foregroundStyle(AppColor.ink)
            .multilineTextAlignment(align)
            .lineSpacing(3)
            .tracking(0.1)
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred()
    }
    static func select() {
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
}
