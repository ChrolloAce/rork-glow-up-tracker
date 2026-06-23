import SwiftUI
import Combine

// MARK: - Models

struct OnbChallenge: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var joined: Int
    var seed: Int
    var tasks: [String]
}

let sampleChallenges: [OnbChallenge] = [
    OnbChallenge(name: "Her 75 OnbChallenge", joined: 17484, seed: 0, tasks: [
        "Eat clean (no junk food and no alcohol)",
        "Drink ONLY water 💧",
        "Walk 10,000 steps a day",
        "One 45-minute workout per day 💪",
        "Read any book (10 pages) or listen to a podcast (5+ min) 🎧"]),
    OnbChallenge(name: "75 Day Hard", joined: 8747, seed: 2, tasks: [
        "Two 45-minute workouts", "Follow a strict diet", "No alcohol or cheat meals",
        "Drink 1 gallon of water", "Read 10 pages"]),
    OnbChallenge(name: "75 Medium", joined: 7506, seed: 4, tasks: [
        "One 45-minute workout", "Follow a diet", "Drink ONLY water", "Read 10 pages"]),
    OnbChallenge(name: "75 Soft", joined: 7500, seed: 6, tasks: [
        "Move your body daily", "Eat well, no restriction", "1.5L water", "Read 10 pages"]),
    OnbChallenge(name: "Better Me", joined: 1838, seed: 1, tasks: [
        "Morning routine", "Workout", "Journal", "No doomscrolling"]),
    OnbChallenge(name: "Glow Up", joined: 1259, seed: 3, tasks: [
        "Skincare AM & PM", "Workout", "Drink water", "8h sleep"]),
    OnbChallenge(name: "Sugar Free", joined: 592, seed: 5, tasks: [
        "No added sugar", "Whole foods", "Water only", "Walk daily"]),
    OnbChallenge(name: "Mental Wellness", joined: 537, seed: 7, tasks: [
        "Meditate 10 min", "Journal", "No social media before noon", "Gratitude list"]),
    OnbChallenge(name: "75 Hotter", joined: 601, seed: 8, tasks: [
        "Two workouts", "Strict diet", "Gallon of water", "Skincare", "Read 10 pages"]),
    OnbChallenge(name: "30 Squat OnbChallenge", joined: 412, seed: 9, tasks: [
        "Daily squat ladder", "Protein goal", "Water", "Stretch"]),
]

// MARK: - Steps

enum Step: Int, CaseIterable {
    case welcome1, globe, welcome2, welcome3, welcome4
    case name, hearAbout, why, idealDay, biggestChallenge, findingChallenge
    case selectChallenge, challengeDetail
    case startDate, length, saveProgress, rating
    case partnerStat, matching, partnerMatch, inviteFriends, sticker
    case personalizing, congrats, paywall

    /// Progress only shown during the "work" portion of the flow.
    var progress: Double? {
        switch self {
        case .welcome1, .globe, .welcome2, .welcome3, .welcome4: return nil
        case .congrats, .paywall: return nil
        default:
            let working = Step.allCases.filter { $0.rawValue >= Step.name.rawValue && $0.rawValue <= Step.sticker.rawValue }
            guard let idx = working.firstIndex(of: self) else { return nil }
            return Double(idx + 1) / Double(working.count)
        }
    }
}

// MARK: - View model

@MainActor
final class OnboardingVM: ObservableObject {
    @Published var step: Step = .welcome1
    @Published var direction: Edge = .trailing

    // Selections
    @Published var name: String = ""
    @Published var hearAbout: String?
    @Published var why: Set<String> = []
    @Published var idealDay: String?
    @Published var biggest: Set<String> = []
    @Published var selectedChallenge: OnbChallenge = sampleChallenges[0]
    @Published var startToday: Bool = true
    @Published var lengthDays: Int = 75
    @Published var plan: String = "Yearly"

    /// Called when the user finishes onboarding (after the paywall step).
    var onComplete: (() -> Void)?

    func finish() { onComplete?() }

    func next() {
        guard let i = Step.allCases.firstIndex(of: step), i + 1 < Step.allCases.count else { return }
        direction = .trailing
        withAnimation(.spring(response: 0.55, dampingFraction: 0.92)) {
            step = Step.allCases[i + 1]
        }
    }

    func back() {
        guard let i = Step.allCases.firstIndex(of: step), i > 0 else { return }
        direction = .leading
        withAnimation(.spring(response: 0.55, dampingFraction: 0.92)) {
            step = Step.allCases[i - 1]
        }
    }
}

// MARK: - Flow container

struct OnboardingFlow: View {
    @StateObject private var vm = OnboardingVM()

    /// Invoked once the user completes onboarding (paywall finished / dismissed).
    var onComplete: () -> Void = {}

    var body: some View {
        ZStack {
            AppColor.cream.ignoresSafeArea()
            screen
                .id(vm.step)
                .transition(.push(from: vm.direction == .trailing ? .trailing : .leading)
                    .combined(with: .opacity))
        }
        .environmentObject(vm)
        .onAppear { vm.onComplete = onComplete }
    }

    @ViewBuilder private var screen: some View {
        switch vm.step {
        case .welcome1:         Welcome1()
        case .globe:            GlobeScreen()
        case .welcome2:         Welcome2()
        case .welcome3:         Welcome3()
        case .welcome4:         Welcome4()
        case .name:             NameScreen()
        case .hearAbout:        HearAboutScreen()
        case .why:              WhyScreen()
        case .idealDay:         IdealDayScreen()
        case .biggestChallenge: BiggestChallengeScreen()
        case .findingChallenge: LoaderScreen(lead: "Finding your\n", emph: "perfect", tail: " challenge")
        case .selectChallenge:  SelectChallengeScreen()
        case .challengeDetail:  ChallengeDetailScreen()
        case .startDate:        StartDateScreen()
        case .length:           LengthScreen()
        case .saveProgress:     SaveProgressScreen()
        case .rating:           RatingScreen()
        case .partnerStat:      PartnerStatScreen()
        case .matching:         LoaderScreen(lead: "Matching ", emph: "your", tail: " energy", subtitle: "Among 24,000+ women")
        case .partnerMatch:     PartnerMatchScreen()
        case .inviteFriends:    InviteFriendsScreen()
        case .sticker:          StickerScreen()
        case .personalizing:    LoaderScreen(lead: "Personalizing ", emph: "your", tail: " space")
        case .congrats:         CongratsScreen()
        case .paywall:          PaywallScreen()
        }
    }
}
