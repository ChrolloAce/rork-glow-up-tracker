import Foundation
import EventKit
import SwiftUI

@MainActor
@Observable
final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let store = EKEventStore()
    private let calendarTitle = "GlowUp Beauty"
    private let enabledKey = "calendarSyncEnabled"

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }
    var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    var lastError: String? = nil

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    private func ensureAuthorized() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        authorizationStatus = status
        switch status {
        case .fullAccess, .writeOnly, .authorized:
            return true
        case .notDetermined:
            return await requestAccess()
        case .denied, .restricted:
            lastError = "Calendar access denied. Enable it in Settings."
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Calendar

    private func glowCalendar() throws -> EKCalendar {
        if let existing = store.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return existing
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = calendarTitle
        cal.cgColor = UIColor(red: 0.949, green: 0.553, blue: 0.694, alpha: 1).cgColor
        cal.source = store.defaultCalendarForNewEvents?.source
            ?? store.sources.first(where: { $0.sourceType == .local })
            ?? store.sources.first!
        try store.saveCalendar(cal, commit: true)
        return cal
    }

    // MARK: - Treatment <-> Event

    private func eventDate(for treatment: BeautyTreatment) -> Date {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: treatment.date)
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        if let parsed = f.date(from: treatment.time) {
            let t = calendar.dateComponents([.hour, .minute], from: parsed)
            comps.hour = t.hour
            comps.minute = t.minute
        } else {
            comps.hour = 9
            comps.minute = 0
        }
        return calendar.date(from: comps) ?? treatment.date
    }

    private func recurrence(for freq: RepeatFrequency) -> EKRecurrenceRule? {
        switch freq {
        case .none, .custom: return nil
        case .weekly:
            return EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
        case .biweekly:
            return EKRecurrenceRule(recurrenceWith: .weekly, interval: 2, end: nil)
        case .monthly:
            return EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)
        }
    }

    @discardableResult
    func upsertEvent(for treatment: BeautyTreatment) async -> String? {
        guard isEnabled else { return treatment.calendarEventID }
        guard await ensureAuthorized() else { return treatment.calendarEventID }

        do {
            let calendar = try glowCalendar()
            let event: EKEvent
            if let id = treatment.calendarEventID, let existing = store.event(withIdentifier: id) {
                event = existing
            } else {
                event = EKEvent(eventStore: store)
                event.calendar = calendar
            }
            let start = eventDate(for: treatment)
            event.title = "\(treatment.type.rawValue) Appointment"
            event.startDate = start
            event.endDate = start.addingTimeInterval(60 * 60)
            event.notes = treatment.notes.isEmpty ? "Beauty appointment via GlowUp." : treatment.notes
            event.recurrenceRules = recurrence(for: treatment.repeatFrequency).map { [$0] }
            try store.save(event, span: .futureEvents, commit: true)
            return event.eventIdentifier
        } catch {
            lastError = error.localizedDescription
            return treatment.calendarEventID
        }
    }

    func deleteEvent(id: String) async {
        guard await ensureAuthorized() else { return }
        guard let event = store.event(withIdentifier: id) else { return }
        try? store.remove(event, span: .futureEvents, commit: true)
    }

    // MARK: - Import existing calendar events

    /// Pull events from the user's calendars over the last 30 / next 180 days
    /// that look like beauty appointments and convert them into BeautyTreatments.
    func importBeautyEvents() async -> [BeautyTreatment] {
        guard await ensureAuthorized() else { return [] }
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let end = Calendar.current.date(byAdding: .day, value: 180, to: now) ?? now
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)

        let f = DateFormatter()
        f.dateFormat = "h:mm a"

        return events.compactMap { event -> BeautyTreatment? in
            let title = (event.title ?? "").lowercased()
            let notes = (event.notes ?? "").lowercased()
            let combined = "\(title) \(notes) \(event.calendar.title.lowercased())"
            guard let type = matchTreatmentType(in: combined) else { return nil }
            return BeautyTreatment(
                type: type,
                date: event.startDate,
                time: f.string(from: event.startDate),
                notes: event.notes ?? "",
                repeatFrequency: .none,
                calendarEventID: event.eventIdentifier
            )
        }
    }

    private func matchTreatmentType(in text: String) -> TreatmentType? {
        let map: [(String, TreatmentType)] = [
            ("nail", .nails), ("mani", .nails), ("pedi", .nails),
            ("lash", .lashes),
            ("shav", .shaving),
            ("facial", .facial), ("skin", .facial),
            ("hair", .hair), ("salon", .hair), ("color", .hair), ("cut", .hair),
            ("brow", .brows),
            ("massage", .massage), ("spa", .massage),
            ("wax", .waxing)
        ]
        for (needle, type) in map where text.contains(needle) {
            return type
        }
        // Generic beauty hints → other
        if text.contains("beauty") || text.contains("appointment") {
            return .other
        }
        return nil
    }
}
