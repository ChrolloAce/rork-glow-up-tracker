import SwiftUI
import Foundation

enum TreatmentType: String, CaseIterable, Identifiable, Codable, Sendable {
    case nails = "Nails"
    case lashes = "Lashes"
    case shaving = "Shaving"
    case facial = "Facial"
    case hair = "Hair"
    case brows = "Brows"
    case massage = "Massage"
    case waxing = "Waxing"
    case other = "Other"

    var id: String { rawValue }

    var dotColor: Color {
        switch self {
        case .nails: return Color(red: 0.949, green: 0.769, blue: 0.808)
        case .lashes: return Color(red: 0.722, green: 0.659, blue: 0.863)
        case .shaving: return Color(red: 0.373, green: 0.784, blue: 0.910)
        case .facial: return Color(red: 0.910, green: 0.627, blue: 0.565)
        case .hair: return Color(red: 0.788, green: 0.659, blue: 0.298)
        case .brows: return Color(red: 0.769, green: 0.659, blue: 0.510)
        case .massage: return Color(red: 0.557, green: 0.769, blue: 0.627)
        case .waxing: return Color(red: 0.910, green: 0.627, blue: 0.376)
        case .other: return Color(red: 0.682, green: 0.682, blue: 0.745)
        }
    }

    var icon: String {
        switch self {
        case .nails: return "hand.raised.fingers.spread.fill"
        case .lashes: return "eye.fill"
        case .shaving: return "scissors"
        case .facial: return "face.smiling.inverse"
        case .hair: return "comb.fill"
        case .brows: return "eyebrow"
        case .massage: return "hands.sparkles.fill"
        case .waxing: return "flame.fill"
        case .other: return "sparkle"
        }
    }
}

enum RepeatFrequency: String, CaseIterable, Identifiable, Codable, Sendable {
    case none = "None"
    case weekly = "Weekly"
    case biweekly = "Every 2 weeks"
    case monthly = "Monthly"
    case custom = "Custom"

    var id: String { rawValue }
}

enum TreatmentStatus: String, Codable, Sendable {
    case upToDate = "Up to date"
    case dueSoon = "Due soon"
    case overdue = "Overdue"

    var color: Color {
        switch self {
        case .upToDate: return Color(red: 0.557, green: 0.769, blue: 0.627)
        case .dueSoon: return Color(red: 0.788, green: 0.659, blue: 0.298)
        case .overdue: return Color(red: 0.910, green: 0.627, blue: 0.565)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .upToDate: return Color(red: 0.557, green: 0.769, blue: 0.627).opacity(0.2)
        case .dueSoon: return Color(red: 0.788, green: 0.659, blue: 0.298).opacity(0.2)
        case .overdue: return Color(red: 0.910, green: 0.627, blue: 0.565).opacity(0.2)
        }
    }
}

struct BeautyTreatment: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: TreatmentType
    var date: Date
    var time: String
    var notes: String
    var repeatFrequency: RepeatFrequency
}

enum ChecklistCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case face = "Face"
    case body = "Body"
    case hair = "Hair"
    case nails = "Nails"

    var id: String { rawValue }
}

struct ChecklistItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let category: ChecklistCategory
    let status: TreatmentStatus
    let lastDone: String
    let nextDue: String
}
