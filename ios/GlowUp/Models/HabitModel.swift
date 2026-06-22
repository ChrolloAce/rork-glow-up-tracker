import SwiftUI

nonisolated enum HabitCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case skincare = "Skincare Routine"
    case water = "Water Intake"
    case lymphatic = "Lymphatic Drainage"
    case steps = "Steps Goal"
    case weight = "Weight Log"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .skincare: return "sparkles"
        case .water: return "drop.fill"
        case .lymphatic: return "arrow.triangle.2.circlepath"
        case .steps: return "figure.walk"
        case .weight: return "scalemass.fill"
        }
    }

    var slabColor: Color {
        switch self {
        case .skincare: return Color(red: 0.831, green: 0.627, blue: 0.690)
        case .water: return Color(red: 0.373, green: 0.784, blue: 0.910)
        case .lymphatic: return Color(red: 0.557, green: 0.769, blue: 0.627)
        case .steps: return Color(red: 0.788, green: 0.659, blue: 0.298)
        case .weight: return Color(red: 0.722, green: 0.659, blue: 0.863)
        }
    }

    var subtitle: String {
        switch self {
        case .skincare: return "Morning & night"
        case .water: return "6.5 / 101 oz"
        case .lymphatic: return "Face + body routine"
        case .steps: return "4,231 / 10,000 steps"
        case .weight: return "Last: 134 lbs · Tap to log"
        }
    }

    var shortName: String {
        switch self {
        case .skincare: return "Skincare"
        case .water: return "Water"
        case .lymphatic: return "Lymph"
        case .steps: return "Steps"
        case .weight: return "Weight"
        }
    }

    var hasReminder: Bool {
        switch self {
        case .skincare, .lymphatic: return true
        default: return false
        }
    }
}

struct Habit: Identifiable, Codable {
    var id: String = UUID().uuidString
    let category: HabitCategory
    var isCompleted: Bool
    var progress: Double
    var currentValue: Double
    var goalValue: Double
}

struct RoutineStep: Identifiable, Codable, Hashable {
    var id: String { name }
    var name: String
    var done: Bool
}
