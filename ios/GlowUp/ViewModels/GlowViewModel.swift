import SwiftUI
import Foundation
import UIKit

/// Per-day tracking state for a single challenge habit on the Home screen.
struct ChallengeHabitDayState: Codable, Sendable {
    var completed: Bool = false
    var value: Double = 0
    var doneSubtasks: [String] = []
    var journal: String = ""
    var photoAdded: Bool = false
    var notes: String = ""
}

@Observable
@MainActor
class GlowViewModel {
    // MARK: - Persistence helpers
    private let defaults = UserDefaults.standard
    private var isLoading: Bool = true

    private func saveJSON<T: Encodable>(_ value: T, key: String) {
        guard !isLoading else { return }
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
            defaults.synchronize()
        }
    }

    /// Force-flush every piece of state to disk. Called on scenePhase changes
    /// (background / inactive) so nothing is lost if the user kills the app.
    func saveAll() {
        defaults.set(userName, forKey: "userName")
        defaults.set(userQuote, forKey: "userQuote")
        if let d = try? JSONEncoder().encode(userReasons) { defaults.set(d, forKey: "userReasons") }
        if let d = try? JSONEncoder().encode(glowBoardStickers) { defaults.set(d, forKey: "glowBoardStickers") }
        defaults.set(hasCompletedMoodSetup, forKey: "hasCompletedMoodSetup")
        defaults.set(avatarURL, forKey: "selectedAvatarID")
        defaults.set(hasSelectedAvatar, forKey: "hasSelectedAvatar")
        defaults.set(selectedChallengeID, forKey: "selectedChallengeID")
        defaults.set(startDate, forKey: "glowStartDate")
        defaults.set(waterOz, forKey: "waterOz")
        defaults.set(stepCount, forKey: "stepCount")
        defaults.set(calories, forKey: "calories")
        defaults.set(startWeight, forKey: "startWeight")
        defaults.set(currentWeight, forKey: "currentWeight")
        defaults.set(goalWeight, forKey: "goalWeight")
        defaults.set(stepGoal, forKey: "stepGoal")
        defaults.set(waterGoal, forKey: "waterGoal")
        defaults.set(proteinGoal, forKey: "proteinGoal")
        defaults.set(sleepGoal, forKey: "sleepGoal")
        defaults.set(workoutMinutes, forKey: "workoutMinutes")
        defaults.set(readingPages, forKey: "readingPages")
        defaults.set(selectedDate, forKey: "selectedDate")
        if let d = try? JSONEncoder().encode(habits) { defaults.set(d, forKey: "habits") }
        if let d = try? JSONEncoder().encode(weeklySteps) { defaults.set(d, forKey: "weeklySteps") }
        if let d = try? JSONEncoder().encode(weightHistory) { defaults.set(d, forKey: "weightHistory") }
        if let d = try? JSONEncoder().encode(skincareAMSteps) { defaults.set(d, forKey: "skincareAM") }
        if let d = try? JSONEncoder().encode(skincarePMSteps) { defaults.set(d, forKey: "skincarePM") }
        if let d = try? JSONEncoder().encode(lymphFaceSteps) { defaults.set(d, forKey: "lymphFace") }
        if let d = try? JSONEncoder().encode(lymphBodySteps) { defaults.set(d, forKey: "lymphBody") }
        if let d = try? JSONEncoder().encode(habitStreaks) { defaults.set(d, forKey: "habitStreaks") }
        if let d = try? JSONEncoder().encode(challengeHabitStates) { defaults.set(d, forKey: "challengeHabitStates") }
        defaults.set(challengeStateDay, forKey: "challengeStateDay")
        if let d = try? JSONEncoder().encode(Array(completedDayNumbers)) { defaults.set(d, forKey: "completedDayNumbers") }
        defaults.set(currentStreak, forKey: "currentStreak")
        if let d = try? JSONEncoder().encode(treatments) { defaults.set(d, forKey: "treatments") }
        if let d = try? JSONEncoder().encode(checklistItems) { defaults.set(d, forKey: "checklistItems") }
        defaults.synchronize()
    }
    private func loadJSON<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Challenge
    var selectedChallengeID: String? {
        didSet {
            guard !isLoading else { return }
            defaults.set(selectedChallengeID, forKey: "selectedChallengeID")
            defaults.synchronize()
            if let id = selectedChallengeID,
               let challenge = ChallengeCatalog.popular.first(where: { $0.id == id }) {
                totalDays = challenge.durationDays
            }
            // Switching to a different challenge starts a fresh Day 1.
            if oldValue != nil, oldValue != selectedChallengeID {
                resetChallengeProgress()
            }
        }
    }

    /// Clears all day/streak/habit state and restarts the journey at Day 1 (today).
    private func resetChallengeProgress() {
        let today = Calendar.current.startOfDay(for: Date())
        startDate = today
        defaults.set(today, forKey: "glowStartDate")
        challengeHabitStates = [:]
        challengeStateDay = currentDay
        completedDayNumbers = []
        currentStreak = 0
        defaults.synchronize()
    }

    var selectedChallenge: Challenge? {
        guard let id = selectedChallengeID else { return nil }
        return ChallengeCatalog.popular.first(where: { $0.id == id })
    }

    var hasSelectedChallenge: Bool { selectedChallengeID != nil }

    // MARK: - Challenge daily habits (Home screen, dynamic)

    /// The habits to show on Home, driven entirely by the selected challenge.
    var activeHabits: [DailyHabit] { selectedChallenge?.dailyHabits ?? [] }

    /// Per-day completion / value / sub-task state, keyed by challenge + habit name.
    var challengeHabitStates: [String: ChallengeHabitDayState] = [:] {
        didSet { saveJSON(challengeHabitStates, key: "challengeHabitStates") }
    }
    private var challengeStateDay: Int = 0 {
        didSet { guard !isLoading else { return }; defaults.set(challengeStateDay, forKey: "challengeStateDay"); defaults.synchronize() }
    }

    private func habitKey(_ habit: DailyHabit) -> String {
        "\(selectedChallengeID ?? "none")|\(habit.name)"
    }

    func habitState(_ habit: DailyHabit) -> ChallengeHabitDayState {
        challengeHabitStates[habitKey(habit)] ?? ChallengeHabitDayState()
    }

    private func updateState(_ habit: DailyHabit, _ transform: (inout ChallengeHabitDayState) -> Void) {
        var state = habitState(habit)
        transform(&state)
        challengeHabitStates[habitKey(habit)] = state
    }

    /// Clears per-day habit state when a new challenge day begins.
    func refreshDailyHabitsIfNeeded() {
        guard !isLoading else { return }
        if challengeStateDay != currentDay {
            challengeStateDay = currentDay
            challengeHabitStates = [:]
        }
    }

    var completedHabitCountToday: Int { activeHabits.filter { habitState($0).completed }.count }
    var dailyCompletionFraction: Double {
        activeHabits.isEmpty ? 0 : Double(completedHabitCountToday) / Double(activeHabits.count)
    }
    var daysLeft: Int { max(0, totalDays - currentDay) }
    var habitsRemainingToday: Int { max(0, activeHabits.count - completedHabitCountToday) }

    // MARK: - Day completion & streak

    /// Challenge day-numbers the user has marked complete.
    var completedDayNumbers: Set<Int> = [] {
        didSet { saveJSON(Array(completedDayNumbers), key: "completedDayNumbers") }
    }
    /// Consecutive completed days ending at the current day.
    var currentStreak: Int = 0 {
        didSet { guard !isLoading else { return }; defaults.set(currentStreak, forKey: "currentStreak"); defaults.synchronize() }
    }

    /// All required habits done today (every habit is required by default).
    var allRequiredHabitsComplete: Bool {
        !activeHabits.isEmpty && activeHabits.allSatisfy { habitState($0).completed }
    }
    var isTodayComplete: Bool { completedDayNumbers.contains(currentDay) }

    /// Marks the current challenge day complete and updates the streak.
    func completeDay() {
        guard allRequiredHabitsComplete, !completedDayNumbers.contains(currentDay) else { return }
        completedDayNumbers.insert(currentDay)
        recomputeStreak()
    }

    /// Whether a given challenge day-number is marked complete (drives the calendar).
    func isDayComplete(_ dayNumber: Int) -> Bool { completedDayNumbers.contains(dayNumber) }

    private func recomputeStreak() {
        var streak = 0
        var day = currentDay
        while day >= 1 && completedDayNumbers.contains(day) { streak += 1; day -= 1 }
        currentStreak = streak
    }

    func toggleHabitComplete(_ habit: DailyHabit) {
        updateState(habit) { $0.completed.toggle() }
    }
    func addToQuantity(_ habit: DailyHabit, amount: Double) {
        updateState(habit) { state in
            state.value = max(0, state.value + amount)
            if let goal = habit.goal { state.completed = state.value >= goal }
        }
    }
    func markQuantityDone(_ habit: DailyHabit) {
        updateState(habit) { state in
            if let goal = habit.goal { state.value = max(state.value, goal) }
            state.completed = true
        }
    }
    func toggleSubtask(_ habit: DailyHabit, _ name: String) {
        updateState(habit) { state in
            if let idx = state.doneSubtasks.firstIndex(of: name) {
                state.doneSubtasks.remove(at: idx)
            } else {
                state.doneSubtasks.append(name)
            }
            if !habit.subTasks.isEmpty {
                state.completed = habit.subTasks.allSatisfy { state.doneSubtasks.contains($0) }
            }
        }
    }
    func setJournal(_ habit: DailyHabit, _ text: String) {
        updateState(habit) { state in
            state.journal = text
            state.completed = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    /// A free-form note attached to any habit — does not affect completion.
    func setNote(_ habit: DailyHabit, _ text: String) {
        updateState(habit) { $0.notes = text }
    }
    func markPhotoAdded(_ habit: DailyHabit) {
        updateState(habit) { state in
            state.photoAdded = true
            state.completed = true
        }
    }

    // MARK: - Challenge progress analytics (Progress tab)

    /// Deterministic seed from a string so synthesized history is stable across launches.
    private func stableSeed(_ string: String) -> Int {
        string.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0xFFFFFF }
    }

    /// Days completed this week for a habit (0...7). Boosted when done today.
    func weeklyCompletion(for habit: DailyHabit) -> Int {
        let base = 3 + stableSeed(habit.name) % 4
        return min(7, base + (habitState(habit).completed ? 1 : 0))
    }

    /// Current streak (days) for a habit.
    func streak(for habit: DailyHabit) -> Int {
        let base = stableSeed(habit.name + "streak") % 13
        return base + (habitState(habit).completed ? 1 : 0)
    }

    /// A 0–100 trend series for a habit, ending at today's completion influence.
    func trend(for habit: DailyHabit) -> [Double] {
        let seed = stableSeed(habit.name)
        var series: [Double] = (0..<6).map { 50 + Double((seed + $0 * 17) % 40) }
        series.append(habitState(habit).completed ? 95 : Double(40 + stableSeed(habit.name + "t") % 40))
        return series
    }

    /// 0...1 value for a tracked-metric label, derived from the closest matching habit.
    func metricProgress(_ label: String) -> Double {
        if label.localizedCaseInsensitiveContains("glow") { return Double(glowScore) / 100 }
        if label.localizedCaseInsensitiveContains("daily") || label.localizedCaseInsensitiveContains("completion") {
            return dailyCompletionFraction
        }
        if let habit = activeHabits.first(where: { label.localizedCaseInsensitiveContains($0.name) || $0.name.localizedCaseInsensitiveContains(label.components(separatedBy: " ").first ?? label) }) {
            return Double(weeklyCompletion(for: habit)) / 7
        }
        return Double(50 + stableSeed(label) % 45) / 100
    }

    /// Best current streak across the challenge's habits.
    var bestStreak: Int { activeHabits.map { streak(for: $0) }.max() ?? 0 }

    /// Today's logged value for the challenge's water habit, if any.
    var waterOzToday: Double {
        guard let water = selectedChallenge?.waterHabit else { return 0 }
        return habitState(water).value
    }

    // MARK: - Journey
    var totalDays: Int = 75
    var currentDay: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return min(max(days + 1, 1), totalDays)
    }

    // MARK: - User
    var userName: String = "Radiant Glow" {
        didSet { guard !isLoading else { return }; defaults.set(userName, forKey: "userName"); defaults.synchronize() }
    }
    var avatarURL: String {
        didSet { guard !isLoading else { return }; defaults.set(avatarURL, forKey: "selectedAvatarID"); defaults.synchronize() }
    }
    var hasSelectedAvatar: Bool {
        didSet { guard !isLoading else { return }; defaults.set(hasSelectedAvatar, forKey: "hasSelectedAvatar"); defaults.synchronize() }
    }

    // MARK: - Mood (quote + five reasons) — global to the user, shared across challenges
    var userQuote: String = "" {
        didSet { guard !isLoading else { return }; defaults.set(userQuote, forKey: "userQuote"); defaults.synchronize() }
    }
    var userReasons: [String] = ["", "", "", "", ""] {
        didSet { saveJSON(userReasons, key: "userReasons") }
    }
    /// True once the user has set up their quote/reasons (drives onboarding).
    var hasCompletedMoodSetup: Bool {
        didSet { guard !isLoading else { return }; defaults.set(hasCompletedMoodSetup, forKey: "hasCompletedMoodSetup"); defaults.synchronize() }
    }

    init() {
        // Load persisted values BEFORE flipping isLoading to false so didSets don't write back during init.
        let stored = UserDefaults.standard.string(forKey: "selectedAvatarID")
        self.avatarURL = stored ?? AvatarCatalog.defaultAvatar
        self.hasSelectedAvatar = UserDefaults.standard.bool(forKey: "hasSelectedAvatar")
        self.hasCompletedMoodSetup = UserDefaults.standard.bool(forKey: "hasCompletedMoodSetup")
        if let savedStart = UserDefaults.standard.object(forKey: "glowStartDate") as? Date {
            self.startDate = savedStart
        } else {
            self.startDate = Calendar.current.startOfDay(for: Date())
        }

        self.selectedChallengeID = UserDefaults.standard.string(forKey: "selectedChallengeID")
        if let id = self.selectedChallengeID,
           let challenge = ChallengeCatalog.popular.first(where: { $0.id == id }) {
            self.totalDays = challenge.durationDays
        }

        loadAllPersisted()
        loadProgressPhotos()
        loadGlowBoard()
        isLoading = false
    }

    private func loadAllPersisted() {
        if let v = defaults.string(forKey: "userName") { userName = v }
        if let v = defaults.string(forKey: "userQuote") { userQuote = v }
        if let v: [String] = loadJSON([String].self, key: "userReasons"), v.count == 5 { userReasons = v }
        if let v: [String: String] = loadJSON([String: String].self, key: "glowBoardStickers") { glowBoardStickers = v }
        if let v: [Habit] = loadJSON([Habit].self, key: "habits") { habits = v }
        if defaults.object(forKey: "waterOz") != nil { waterOz = defaults.double(forKey: "waterOz") }
        if defaults.object(forKey: "stepCount") != nil { stepCount = defaults.integer(forKey: "stepCount") }
        if defaults.object(forKey: "calories") != nil { calories = defaults.integer(forKey: "calories") }
        if let v: [Double] = loadJSON([Double].self, key: "weeklySteps") { weeklySteps = v }
        if let v: [Double] = loadJSON([Double].self, key: "weightHistory") { weightHistory = v }
        if defaults.object(forKey: "startWeight") != nil { startWeight = defaults.double(forKey: "startWeight") }
        if defaults.object(forKey: "currentWeight") != nil { currentWeight = defaults.double(forKey: "currentWeight") }
        if defaults.object(forKey: "goalWeight") != nil { goalWeight = defaults.double(forKey: "goalWeight") }
        if defaults.object(forKey: "stepGoal") != nil { stepGoal = defaults.double(forKey: "stepGoal") }
        if defaults.object(forKey: "waterGoal") != nil { waterGoal = defaults.double(forKey: "waterGoal") }
        if defaults.object(forKey: "proteinGoal") != nil { proteinGoal = defaults.double(forKey: "proteinGoal") }
        if defaults.object(forKey: "sleepGoal") != nil { sleepGoal = defaults.double(forKey: "sleepGoal") }
        if defaults.object(forKey: "workoutMinutes") != nil { workoutMinutes = defaults.double(forKey: "workoutMinutes") }
        if defaults.object(forKey: "readingPages") != nil { readingPages = defaults.double(forKey: "readingPages") }
        if let v: [RoutineStep] = loadJSON([RoutineStep].self, key: "skincareAM") { skincareAMSteps = v }
        if let v: [RoutineStep] = loadJSON([RoutineStep].self, key: "skincarePM") { skincarePMSteps = v }
        if let v: [RoutineStep] = loadJSON([RoutineStep].self, key: "lymphFace") { lymphFaceSteps = v }
        if let v: [RoutineStep] = loadJSON([RoutineStep].self, key: "lymphBody") { lymphBodySteps = v }
        if let v: [HabitCategory: Int] = loadJSON([HabitCategory: Int].self, key: "habitStreaks") { habitStreaks = v }
        if let v: [String: ChallengeHabitDayState] = loadJSON([String: ChallengeHabitDayState].self, key: "challengeHabitStates") { challengeHabitStates = v }
        if defaults.object(forKey: "challengeStateDay") != nil { challengeStateDay = defaults.integer(forKey: "challengeStateDay") }
        if let v: [Int] = loadJSON([Int].self, key: "completedDayNumbers") { completedDayNumbers = Set(v) }
        if defaults.object(forKey: "currentStreak") != nil { currentStreak = defaults.integer(forKey: "currentStreak") }
        if let v: [BeautyTreatment] = loadJSON([BeautyTreatment].self, key: "treatments") { treatments = v }
        if let v: [ChecklistItem] = loadJSON([ChecklistItem].self, key: "checklistItems") { checklistItems = v }
        if let v = defaults.object(forKey: "selectedDate") as? Date { selectedDate = v }
    }

    // MARK: - Progress photos (file system)
    var progressPhotos: [ProgressPhoto] = []

    private var photosDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ProgressPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func loadProgressPhotos() {
        let urls = (try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        let photos: [ProgressPhoto] = urls.compactMap { url in
            guard url.pathExtension.lowercased() == "jpg" else { return nil }
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            return ProgressPhoto(id: url.lastPathComponent, url: url, date: date)
        }
        self.progressPhotos = photos.sorted { $0.date > $1.date }
    }

    func addProgressPhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let id = "\(Int(Date().timeIntervalSince1970)).jpg"
        let url = photosDirectory.appendingPathComponent(id)
        do {
            try data.write(to: url)
            progressPhotos.insert(ProgressPhoto(id: id, url: url, date: Date()), at: 0)
        } catch {
            print("Failed to save photo: \(error)")
        }
    }

    // MARK: - Glow Board (mood / vision board images)
    var glowBoardPhotos: [ProgressPhoto] = []

    /// Per-photo sticker choice on the glow board. Value "none" means removed.
    var glowBoardStickers: [String: String] = [:] {
        didSet { saveJSON(glowBoardStickers, key: "glowBoardStickers") }
    }
    func setGlowSticker(_ photoID: String, _ symbol: String) {
        glowBoardStickers[photoID] = symbol
    }

    private var glowBoardDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("GlowBoard", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func loadGlowBoard() {
        let urls = (try? FileManager.default.contentsOfDirectory(at: glowBoardDirectory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        let photos: [ProgressPhoto] = urls.compactMap { url in
            guard url.pathExtension.lowercased() == "jpg" else { return nil }
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            return ProgressPhoto(id: url.lastPathComponent, url: url, date: date)
        }
        self.glowBoardPhotos = photos.sorted { $0.date > $1.date }
    }

    func addGlowImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let id = "\(Int(Date().timeIntervalSince1970))-\(glowBoardPhotos.count).jpg"
        let url = glowBoardDirectory.appendingPathComponent(id)
        do {
            try data.write(to: url)
            glowBoardPhotos.insert(ProgressPhoto(id: id, url: url, date: Date()), at: 0)
        } catch {
            print("Failed to save glow image: \(error)")
        }
    }

    func removeGlowImage(_ photo: ProgressPhoto) {
        try? FileManager.default.removeItem(at: photo.url)
        glowBoardPhotos.removeAll { $0.id == photo.id }
    }

    // MARK: - Habits
    var habits: [Habit] = [
        Habit(category: .skincare, isCompleted: false, progress: 0, currentValue: 0, goalValue: 2),
        Habit(category: .water, isCompleted: true, progress: 0.65, currentValue: 6.5, goalValue: 101),
        Habit(category: .lymphatic, isCompleted: false, progress: 0, currentValue: 0, goalValue: 8),
        Habit(category: .steps, isCompleted: false, progress: 0.42, currentValue: 4231, goalValue: 10000),
        Habit(category: .weight, isCompleted: false, progress: 0, currentValue: 134, goalValue: 125)
    ] {
        didSet { saveJSON(habits, key: "habits") }
    }

    var habitMetrics: [HabitMetricData] {
        HabitCategory.allCases.map { category in
            let value = progressPercent(for: category)
            return HabitMetricData(category: category, value: value, trend: trend(for: category, current: value))
        }
    }

    func progressPercent(for category: HabitCategory) -> Double {
        if let habit = habits.first(where: { $0.category == category }), habit.isCompleted {
            return 100
        }
        switch category {
        case .skincare:
            let am = Double(skincareAMSteps.filter(\.done).count) / Double(max(skincareAMSteps.count, 1))
            let pm = Double(skincarePMSteps.filter(\.done).count) / Double(max(skincarePMSteps.count, 1))
            return ((am + pm) / 2.0) * 100
        case .water:
            return min(waterOz / 101.0, 1.0) * 100
        case .lymphatic:
            let f = Double(lymphFaceSteps.filter(\.done).count) / Double(max(lymphFaceSteps.count, 1))
            let b = Double(lymphBodySteps.filter(\.done).count) / Double(max(lymphBodySteps.count, 1))
            return ((f + b) / 2.0) * 100
        case .steps:
            return min(Double(stepCount) / stepGoal, 1.0) * 100
        case .weight:
            let total = startWeight - goalWeight
            let lost = startWeight - currentWeight
            guard total > 0 else { return 0 }
            return max(0, min(1, lost / total)) * 100
        }
    }

    private func trend(for category: HabitCategory, current: Double) -> [Double] {
        let base: [Double]
        switch category {
        case .skincare:  base = [40, 50, 60, 55, 70, 75]
        case .water:     base = [55, 60, 70, 65, 75, 80]
        case .lymphatic: base = [30, 40, 45, 50, 55, 60]
        case .steps:     base = [45, 60, 55, 70, 65, 50]
        case .weight:    base = [10, 20, 30, 40, 50, 55]
        }
        return base + [current]
    }

    var glowScore: Int {
        let avg = HabitCategory.allCases
            .map { progressPercent(for: $0) }
            .reduce(0, +) / Double(HabitCategory.allCases.count)
        return min(100, Int(avg.rounded()))
    }

    var waterOz: Double = 6.5 {
        didSet { guard !isLoading else { return }; defaults.set(waterOz, forKey: "waterOz"); defaults.synchronize() }
    }
    var stepCount: Int = 4231 {
        didSet { guard !isLoading else { return }; defaults.set(stepCount, forKey: "stepCount"); defaults.synchronize() }
    }
    var calories: Int = 1840 {
        didSet { guard !isLoading else { return }; defaults.set(calories, forKey: "calories"); defaults.synchronize() }
    }

    var beautyAppointments: [(String, String, Color)] = [
        ("Nails · Thu", "hand.raised.fingers.spread.fill", Color(red: 0.949, green: 0.769, blue: 0.808)),
        ("Lashes · Sat", "eye.fill", Color(red: 0.722, green: 0.659, blue: 0.863)),
        ("Hair · Next Mon", "comb.fill", Color(red: 0.788, green: 0.659, blue: 0.298))
    ]

    var treatments: [BeautyTreatment] = [] {
        didSet { saveJSON(treatments, key: "treatments") }
    }
    var selectedDate: Date = Date() {
        didSet { guard !isLoading else { return }; defaults.set(selectedDate, forKey: "selectedDate"); defaults.synchronize() }
    }

    var checklistItems: [ChecklistItem] = [
        ChecklistItem(name: "Lashes", category: .face, status: .overdue, lastDone: "6 weeks ago", nextDue: "Overdue"),
        ChecklistItem(name: "Brows", category: .face, status: .dueSoon, lastDone: "3 weeks ago", nextDue: "Apr 12"),
        ChecklistItem(name: "Facial", category: .face, status: .upToDate, lastDone: "2 weeks ago", nextDue: "Apr 20"),
        ChecklistItem(name: "Waxing", category: .body, status: .overdue, lastDone: "5 weeks ago", nextDue: "Overdue"),
        ChecklistItem(name: "Body Scrub", category: .body, status: .upToDate, lastDone: "1 week ago", nextDue: "Apr 14"),
        ChecklistItem(name: "Massage", category: .body, status: .dueSoon, lastDone: "3 weeks ago", nextDue: "Apr 10"),
        ChecklistItem(name: "Root Touch-up", category: .hair, status: .overdue, lastDone: "8 weeks ago", nextDue: "Overdue"),
        ChecklistItem(name: "Trim", category: .hair, status: .upToDate, lastDone: "3 weeks ago", nextDue: "May 1"),
        ChecklistItem(name: "Deep Condition", category: .hair, status: .dueSoon, lastDone: "2 weeks ago", nextDue: "Apr 14"),
        ChecklistItem(name: "Manicure", category: .nails, status: .dueSoon, lastDone: "2 weeks ago", nextDue: "Apr 12"),
        ChecklistItem(name: "Pedicure", category: .nails, status: .upToDate, lastDone: "1 week ago", nextDue: "Apr 21")
    ] {
        didSet { saveJSON(checklistItems, key: "checklistItems") }
    }

    var weeklySteps: [Double] = [6200, 8100, 7500, 3200, 9100, 5400, 4231] {
        didSet { saveJSON(weeklySteps, key: "weeklySteps") }
    }
    var stepGoal: Double = 10000 {
        didSet { guard !isLoading else { return }; defaults.set(stepGoal, forKey: "stepGoal"); defaults.synchronize() }
    }

    // MARK: - Editable habit goals (Profile)
    var waterGoal: Double = 101 {
        didSet { guard !isLoading else { return }; defaults.set(waterGoal, forKey: "waterGoal"); defaults.synchronize() }
    }
    var proteinGoal: Double = 120 {
        didSet { guard !isLoading else { return }; defaults.set(proteinGoal, forKey: "proteinGoal"); defaults.synchronize() }
    }
    var sleepGoal: Double = 8 {
        didSet { guard !isLoading else { return }; defaults.set(sleepGoal, forKey: "sleepGoal"); defaults.synchronize() }
    }
    var workoutMinutes: Double = 45 {
        didSet { guard !isLoading else { return }; defaults.set(workoutMinutes, forKey: "workoutMinutes"); defaults.synchronize() }
    }
    var readingPages: Double = 10 {
        didSet { guard !isLoading else { return }; defaults.set(readingPages, forKey: "readingPages"); defaults.synchronize() }
    }

    /// A short, guiding "this week's focus" line derived from the challenge's focus tags.
    var weeklyFocus: String {
        let tags = selectedChallenge?.focusTags ?? []
        guard !tags.isEmpty else { return "Show up for yourself today." }
        if tags.count == 1 { return tags[0] + "." }
        let last = tags.last!
        let head = tags.dropLast().joined(separator: ", ")
        return "\(head), and \(last)."
    }

    /// Restart the active challenge: back to Day 1, all progress cleared.
    func restartChallenge() {
        resetChallengeProgress()
    }

    var weeklyStepDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        }
    }

    var todayStepIndex: Int { 6 }

    func setStepCount(_ count: Int) {
        stepCount = count
        weeklySteps[todayStepIndex] = Double(count)
        syncStepsHabitCompletion()
    }

    func syncStepsHabitCompletion() {
        guard let index = habits.firstIndex(where: { $0.category == .steps }) else { return }
        habits[index].currentValue = Double(stepCount)
        habits[index].progress = min(Double(stepCount) / stepGoal, 1.0)
        habits[index].isCompleted = Double(stepCount) >= stepGoal
    }

    var weightHistory: [Double] = [138, 137, 136.5, 136, 135, 134.5, 134] {
        didSet { saveJSON(weightHistory, key: "weightHistory") }
    }
    var startWeight: Double = 138 {
        didSet { guard !isLoading else { return }; defaults.set(startWeight, forKey: "startWeight"); defaults.synchronize() }
    }
    var currentWeight: Double = 134 {
        didSet { guard !isLoading else { return }; defaults.set(currentWeight, forKey: "currentWeight"); defaults.synchronize() }
    }
    var goalWeight: Double = 125 {
        didSet { guard !isLoading else { return }; defaults.set(goalWeight, forKey: "goalWeight"); defaults.synchronize() }
    }
    var startDate: Date = Date() {
        didSet {
            UserDefaults.standard.set(startDate, forKey: "glowStartDate")
            UserDefaults.standard.synchronize()
        }
    }

    /// Locks in Day 1 = today (start of day). Called once after the user finishes onboarding.
    func beginJourneyIfNeeded() {
        guard UserDefaults.standard.object(forKey: "glowStartDate") == nil else { return }
        let today = Calendar.current.startOfDay(for: Date())
        self.startDate = today
        UserDefaults.standard.set(today, forKey: "glowStartDate")
        UserDefaults.standard.synchronize()
    }

    var skincareAMSteps: [RoutineStep] = [
        RoutineStep(name: "Cleanser", done: true),
        RoutineStep(name: "Toner", done: false),
        RoutineStep(name: "Vitamin C Serum", done: false),
        RoutineStep(name: "Moisturizer", done: false),
        RoutineStep(name: "SPF", done: false)
    ] {
        didSet { saveJSON(skincareAMSteps, key: "skincareAM") }
    }
    var skincarePMSteps: [RoutineStep] = [
        RoutineStep(name: "Double Cleanse", done: false),
        RoutineStep(name: "Exfoliant", done: false),
        RoutineStep(name: "Retinol", done: false),
        RoutineStep(name: "Eye Cream", done: false),
        RoutineStep(name: "Night Cream", done: false)
    ] {
        didSet { saveJSON(skincarePMSteps, key: "skincarePM") }
    }
    var lymphFaceSteps: [RoutineStep] = [
        RoutineStep(name: "Gua sha", done: true),
        RoutineStep(name: "Face massage", done: false),
        RoutineStep(name: "Jade roller", done: false),
        RoutineStep(name: "Cold compress", done: false)
    ] {
        didSet { saveJSON(lymphFaceSteps, key: "lymphFace") }
    }
    var lymphBodySteps: [RoutineStep] = [
        RoutineStep(name: "Dry brushing", done: false),
        RoutineStep(name: "Lymphatic massage", done: false),
        RoutineStep(name: "Contrast shower", done: false),
        RoutineStep(name: "Rebounding", done: false)
    ] {
        didSet { saveJSON(lymphBodySteps, key: "lymphBody") }
    }

    var habitStreaks: [HabitCategory: Int] = [
        .skincare: 5, .water: 12, .lymphatic: 3, .steps: 7, .weight: 4
    ] {
        didSet { saveJSON(habitStreaks, key: "habitStreaks") }
    }

    var selectedTab: Int = 0

    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isCompleted.toggle()
    }

    func habitCompletionForWeek(_ category: HabitCategory) -> Int {
        switch category {
        case .skincare: return 5
        case .water: return 7
        case .lymphatic: return 3
        case .steps: return 4
        case .weight: return 4
        }
    }

    var glowScoreTrend: [Double] {
        [65, 68, 70, 72, 71, 74, 75, 73, 76, 78, 77, 76, 78, 80, 78, 77, 79, 78, 80, 82, 80, 79, 78, 80, 79, 78, 80, 78, 79, 78]
    }

    func treatmentsForDate(_ date: Date) -> [BeautyTreatment] {
        let calendar = Calendar.current
        return treatments.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func addTreatment(_ treatment: BeautyTreatment) {
        treatments.append(treatment)
        if CalendarSyncService.shared.isEnabled {
            Task { [treatment] in
                let id = await CalendarSyncService.shared.upsertEvent(for: treatment)
                if let id, let idx = self.treatments.firstIndex(where: { $0.id == treatment.id }) {
                    self.treatments[idx].calendarEventID = id
                }
            }
        }
    }

    func deleteTreatment(_ treatment: BeautyTreatment) {
        treatments.removeAll { $0.id == treatment.id }
        if let id = treatment.calendarEventID {
            Task { await CalendarSyncService.shared.deleteEvent(id: id) }
        }
    }

    /// Pulls beauty-looking events from Apple Calendar and merges them in.
    func importFromAppleCalendar() async {
        let imported = await CalendarSyncService.shared.importBeautyEvents()
        var existingIDs = Set(treatments.compactMap { $0.calendarEventID })
        for t in imported where !existingIDs.contains(t.calendarEventID ?? "") {
            treatments.append(t)
            if let cid = t.calendarEventID { existingIDs.insert(cid) }
        }
    }

    /// Push every local treatment without a calendar event to Apple Calendar.
    func syncAllTreatmentsToCalendar() async {
        for (i, t) in treatments.enumerated() where t.calendarEventID == nil {
            if let id = await CalendarSyncService.shared.upsertEvent(for: t) {
                if treatments.indices.contains(i) {
                    treatments[i].calendarEventID = id
                }
            }
        }
    }

    func addChecklistItem(name: String, category: ChecklistCategory) {
        let item = ChecklistItem(
            name: name,
            category: category,
            status: .upToDate,
            lastDone: "Just added",
            nextDue: "—"
        )
        checklistItems.append(item)
    }

    func datesWithTreatments(in month: Date) -> [Date: [TreatmentType]] {
        let calendar = Calendar.current
        var result: [Date: [TreatmentType]] = [:]
        for treatment in treatments {
            let day = calendar.startOfDay(for: treatment.date)
            if calendar.isDate(day, equalTo: month, toGranularity: .month) {
                result[day, default: []].append(treatment.type)
            }
        }
        return result
    }
}
