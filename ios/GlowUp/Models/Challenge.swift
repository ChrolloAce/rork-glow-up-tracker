import SwiftUI

/// How a challenge card's image area should be rendered until real artwork is supplied.
nonisolated enum ImageSlotLayout: String, Codable, Sendable {
    case hero        // one large hero image
    case collage     // a 4-image collage
    case illustration // soft illustrated artwork
    case gradient    // pastel placeholder gradient only
}

/// A single image placeholder slot. `assetName` is nil until the user supplies artwork.
nonisolated struct ImageSlot: Codable, Sendable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var assetName: String? = nil
    var caption: String? = nil
}

nonisolated enum ChallengeDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner = "Beginner"
    case beginnerIntermediate = "Beginner / Intermediate"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var dotColor: Color {
        switch self {
        case .beginner: return Color(red: 0.557, green: 0.769, blue: 0.627) // sage
        case .beginnerIntermediate: return Color(red: 0.788, green: 0.659, blue: 0.298) // warm gold
        case .intermediate: return Color(red: 0.96, green: 0.62, blue: 0.38) // warm orange
        case .advanced: return Color(red: 0.86, green: 0.38, blue: 0.50) // pink deep
        }
    }
}

/// A reusable, data-driven challenge definition. Add new entries to
/// `ChallengeCatalog.popular` to surface new challenges — the UI is fully dynamic.
nonisolated struct Challenge: Identifiable, Codable, Sendable, Hashable {
    var id: String
    var name: String
    var durationDays: Int
    var difficulty: ChallengeDifficulty
    var description: String
    var joinedCount: Int
    var focusTags: [String]
    var habitPreview: [String]
    var imageSlots: [ImageSlot]
    var imageLayout: ImageSlotLayout
    /// Hex-free theme color stored as RGB components for Codable safety.
    var themeRGB: [Double]

    var themeColor: Color {
        guard themeRGB.count == 3 else { return Color(red: 0.96, green: 0.56, blue: 0.66) }
        return Color(red: themeRGB[0], green: themeRGB[1], blue: themeRGB[2])
    }

    var durationLabel: String { "\(durationDays) days" }

    var joinedLabel: String {
        if joinedCount >= 1000 {
            let thousands = Double(joinedCount) / 1000.0
            let formatted = String(format: "%.1f", thousands)
                .replacingOccurrences(of: ".0", with: "")
            return "+\(formatted)k joined"
        }
        return "+\(joinedCount) joined"
    }
}

nonisolated enum ChallengeCatalog {
    static let popular: [Challenge] = [
        Challenge(
            id: "75-soft",
            name: "75 Soft",
            durationDays: 75,
            difficulty: .beginner,
            description: "A softer discipline challenge focused on movement, water, clean eating, reading, and consistency.",
            joinedCount: 12400,
            focusTags: ["Wellness", "Movement", "Hydration"],
            habitPreview: ["Water", "Movement", "Steps", "Clean Eating", "Reading"],
            imageSlots: [ImageSlot(caption: "Soft mornings")],
            imageLayout: .hero,
            themeRGB: [0.86, 0.60, 0.68] // dusty rose
        ),
        Challenge(
            id: "75-medium",
            name: "75 Medium",
            durationDays: 75,
            difficulty: .intermediate,
            description: "A balanced challenge for users who want stronger discipline without going fully extreme.",
            joinedCount: 8200,
            focusTags: ["Discipline", "Fitness", "Nutrition"],
            habitPreview: ["Workout", "Steps", "Water", "No Sugar", "Reading", "Progress Photo"],
            imageSlots: [ImageSlot(), ImageSlot(), ImageSlot(), ImageSlot()],
            imageLayout: .collage,
            themeRGB: [0.70, 0.62, 0.88] // lavender
        ),
        Challenge(
            id: "75-hard",
            name: "75 Hard",
            durationDays: 75,
            difficulty: .advanced,
            description: "A strict transformation challenge built around workouts, water, diet, reading, and daily progress photos.",
            joinedCount: 15600,
            focusTags: ["Discipline", "Fitness", "Mental Toughness"],
            habitPreview: ["Workout 1", "Workout 2", "Water", "Diet", "Reading", "Progress Photo"],
            imageSlots: [ImageSlot(caption: "Transformation")],
            imageLayout: .hero,
            themeRGB: [0.86, 0.38, 0.50] // pink deep
        ),
        Challenge(
            id: "glow-up",
            name: "Glow Up Challenge",
            durationDays: 75,
            difficulty: .beginnerIntermediate,
            description: "A beauty and wellness challenge focused on skincare, hydration, clean eating, sleep, and feeling radiant.",
            joinedCount: 21300,
            focusTags: ["Skin", "Beauty", "Wellness"],
            habitPreview: ["AM Skincare", "PM Skincare", "Water", "Lymphatic", "Clean Eating", "Sleep"],
            imageSlots: [ImageSlot(), ImageSlot(), ImageSlot(), ImageSlot()],
            imageLayout: .collage,
            themeRGB: [0.96, 0.56, 0.66] // pink
        ),
        Challenge(
            id: "clean-eating",
            name: "Clean Eating Challenge",
            durationDays: 30,
            difficulty: .beginnerIntermediate,
            description: "A whole-food reset designed to reduce cravings, improve energy, and build cleaner eating habits.",
            joinedCount: 9800,
            focusTags: ["Whole Foods", "Cravings", "Nutrition"],
            habitPreview: ["Whole Foods", "No Added Sugar", "Protein", "Water", "Craving Check-In"],
            imageSlots: [ImageSlot(caption: "Fresh & whole")],
            imageLayout: .illustration,
            themeRGB: [0.557, 0.769, 0.627] // sage green
        ),
        Challenge(
            id: "sugar-free",
            name: "Sugar Free Challenge",
            durationDays: 30,
            difficulty: .beginner,
            description: "A simple reset for cutting added sugar, reducing cravings, and building better food choices.",
            joinedCount: 7100,
            focusTags: ["Sugar Free", "Cravings", "Energy"],
            habitPreview: ["No Added Sugar", "Water", "Whole Foods", "Craving Log", "Protein"],
            imageSlots: [ImageSlot(caption: "Sweet freedom")],
            imageLayout: .gradient,
            themeRGB: [0.96, 0.62, 0.38] // warm orange
        )
    ]
}
