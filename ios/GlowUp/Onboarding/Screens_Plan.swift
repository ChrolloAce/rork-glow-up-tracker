import SwiftUI

// MARK: - Weight (slider)

struct WeightScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.weight.progress, onBack: vm.back) {
            VStack(spacing: 26) {
                Spacer(minLength: 10)
                Display(lead: "I weigh\n", emph: "this much", size: 32)
                Text("\(Int(vm.weightLbs)) lb")
                    .font(.serif(56, .bold)).foregroundStyle(AppColor.ink)
                    .contentTransition(.numericText())
                TickSlider(value: $vm.weightLbs, range: 80...350)
                    .padding(.horizontal, 8)
                Text("Slide to set your current weight")
                    .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
                CollageGrid(count: 3, seed: 7).frame(height: 100).clipped()
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

// MARK: - Goal

struct GoalScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.goal.progress, onBack: vm.back) {
            VStack(spacing: 22) {
                Display(lead: "What's your\n", emph: "main goal?", size: 30)
                VStack(spacing: 12) {
                    ForEach(Goal.allCases) { g in
                        IconOption(symbol: g.icon, label: g.rawValue, selected: vm.goal == g) {
                            vm.goal = g
                        }
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "Continue", enabled: vm.goal != nil) { vm.next() }
        }
    }
}

// MARK: - How much to lose (only when goal is "lose weight")

struct WeightLossScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.weightLoss.progress, onBack: vm.back) {
            VStack(spacing: 26) {
                Spacer(minLength: 10)
                Display(lead: "How much do you\nwant to ", emph: "lose?", size: 30)
                Text("\(Int(vm.targetLossLbs)) lb")
                    .font(.serif(56, .bold)).foregroundStyle(AppColor.ink)
                    .contentTransition(.numericText())
                TickSlider(value: $vm.targetLossLbs, range: 3...80)
                    .padding(.horizontal, 8)
                Text("A healthy, realistic goal works best 💛")
                    .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

// MARK: - Height (slider)

struct HeightScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    private var heightLabel: String {
        let total = Int(vm.heightInches)
        return "\(total / 12)'\(total % 12)\""
    }
    var body: some View {
        Scaffold(progress: Step.height.progress, onBack: vm.back) {
            VStack(spacing: 26) {
                Spacer(minLength: 10)
                Display(lead: "How ", emph: "tall", tail: " are you?", size: 32)
                Text(heightLabel)
                    .font(.serif(56, .bold)).foregroundStyle(AppColor.ink)
                TickSlider(value: $vm.heightInches, range: 48...84)
                    .padding(.horizontal, 8)
                Text("Slide to set your height")
                    .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
                CollageGrid(count: 3, seed: 5).frame(height: 100).clipped()
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

// MARK: - Diet

struct DietScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    private let diets = ["No restrictions", "Vegetarian", "Vegan", "Pescatarian",
                         "Keto / Low-carb", "Mediterranean", "Gluten-free", "Other"]
    var body: some View {
        Scaffold(progress: Step.diet.progress, onBack: vm.back) {
            VStack(spacing: 18) {
                Display(lead: "What's your\n", emph: "diet", tail: " like?", size: 30)
                VStack(spacing: 8) {
                    ForEach(diets, id: \.self) { d in
                        RadioRow(label: d, selected: vm.diet == d) { vm.diet = d }
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "Continue", enabled: vm.diet != nil) { vm.next() }
        }
    }
}

// MARK: - Building your plan (circular loader + stepping checklist)

struct BuildingPlanScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    @State private var pct: Int = 0
    @State private var doneCount: Int = 0

    private let tasks = ["Analyzing your goals",
                         "Calculating your targets",
                         "Matching your diet",
                         "Personalizing your plan"]

    var body: some View {
        ZStack {
            AppColor.cream.ignoresSafeArea()
            VStack(spacing: 34) {
                Display(lead: "Finding your\n", emph: "perfect", tail: " plan", size: 30)

                ZStack {
                    Circle().stroke(AppColor.line, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: Double(pct) / 100)
                        .stroke(AppColor.ink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.04), value: pct)
                    Text("\(pct)%")
                        .font(.serif(30, .bold)).foregroundStyle(AppColor.ink)
                        .contentTransition(.numericText())
                }
                .frame(width: 158, height: 158)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(tasks.enumerated()), id: \.offset) { i, t in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(i < doneCount ? AppColor.ink : AppColor.line, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if i < doneCount {
                                    Circle().fill(AppColor.ink).frame(width: 24, height: 24)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                            Text(t)
                                .font(.sans(15, i < doneCount ? .semibold : .regular))
                                .foregroundStyle(i < doneCount ? AppColor.ink : AppColor.inkSoft)
                            Spacer()
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: doneCount)
                    }
                }
                .padding(.horizontal, 50)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { run() }
    }

    private func run() {
        let totalDuration = 3.6
        for p in 0...100 {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration * Double(p) / 100) {
                pct = p
                let newDone = (p * tasks.count) / 100
                if newDone > doneCount {
                    doneCount = newDone
                    Haptics.select()
                    if newDone == tasks.count { Haptics.success() }
                }
            }
        }
        // plan is built — continue automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.6) {
            vm.next()
        }
    }
}

// MARK: - Tick slider (ruler-style, haptic per tick, easy drag)

struct TickSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1
    private let tickCount = 41
    @State private var lastStep: Double = .nan

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let span = max(range.upperBound - range.lowerBound, 0.0001)
            let frac = min(max((value - range.lowerBound) / span, 0), 1)
            ZStack(alignment: .leading) {
                // ruler ticks
                HStack(spacing: 0) {
                    ForEach(0..<tickCount, id: \.self) { i in
                        Rectangle()
                            .fill(AppColor.line)
                            .frame(width: 1.5, height: i % 5 == 0 ? 22 : 12)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 24)
                // current position indicator
                Capsule()
                    .fill(AppColor.ink)
                    .frame(width: 4, height: 34)
                    .offset(x: CGFloat(frac) * w - 2)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let x = min(max(0, g.location.x), w)
                        let raw = range.lowerBound + Double(x / w) * span
                        let snapped = (raw / step).rounded() * step
                        let clamped = min(max(range.lowerBound, snapped), range.upperBound)
                        if clamped != lastStep {
                            lastStep = clamped
                            Haptics.select()
                        }
                        value = clamped
                    }
            )
        }
        .frame(height: 44)
    }
}
