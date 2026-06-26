import SwiftUI
import UIKit

/// A single Home-screen habit card, driven by the selected challenge's habit.
/// Every habit expands into a clean dropdown: a short description + one focused
/// feature (stepper, sub-tasks, photo, reflection, or a note).
struct ChallengeHabitCard: View {
    let habit: DailyHabit
    @Bindable var viewModel: GlowViewModel
    let accent: Color
    let isExpanded: Bool
    let onExpand: () -> Void

    @State private var checkTrigger: Int = 0
    @State private var showCamera: Bool = false
    @State private var journalDraft: String = ""

    private let blue = Theme.glowBlue

    private var state: ChallengeHabitDayState { viewModel.habitState(habit) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: onExpand) {
                    HStack(spacing: 0) {
                        leftSlab
                        centerContent
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                rightSection
            }
            .frame(minHeight: 84)

            if isExpanded {
                Rectangle().fill(Theme.subtleBorder).frame(height: 1)
                    .padding(.horizontal, 16)
                expandedContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .padding(.top, 16)
                    .transition(.opacity)
            }
        }
        .flatCard()
        .onAppear {
            journalDraft = state.journal
        }
        .sheet(isPresented: $showCamera) {
            CameraProxyView { image in
                viewModel.addProgressPhoto(image)
                viewModel.markPhotoAdded(habit)
            }
        }
    }

    // MARK: - Left slab

    private var leftSlab: some View {
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22)
                .fill(accent.opacity(0.9))
            Image(systemName: habit.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: 72)
    }

    // MARK: - Center

    private var centerContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(habit.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            subtitleText
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 84)
    }

    @ViewBuilder
    private var subtitleText: some View {
        switch habit.type {
        case .quantity:
            HStack(spacing: 0) {
                Text(formatted(state.value)).foregroundStyle(blue)
                Text(" / \(formatted(habit.goal ?? 0)) \(habit.unit ?? "")").foregroundStyle(Theme.textSecondary)
            }
            .font(.system(size: 13, weight: .medium))
        case .routine:
            Text("\(doneSubtaskCount) of \(habit.subTasks.count) steps")
                .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
        case .photo:
            Text(state.photoAdded ? "Photo added today" : "Add today's photo")
                .font(.system(size: 13)).foregroundStyle(state.photoAdded ? accent : Theme.textSecondary)
        case .journal:
            Text(state.journal.isEmpty ? "Tap to reflect" : state.journal)
                .font(.system(size: 13)).foregroundStyle(state.journal.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                .lineLimit(1)
        case .checkmark:
            Text(state.completed ? "Completed" : "Tap to open")
                .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Right (check button only)

    private var rightSection: some View {
        checkButton
            .padding(.trailing, 16)
    }

    private var checkButton: some View {
        Button(action: rightButtonAction) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(state.completed ? accent : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(state.completed ? Color.clear : accent.opacity(0.4), lineWidth: 1.2)
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: rightButtonIcon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(state.completed ? .white : accent)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: checkTrigger)
    }

    private var rightButtonIcon: String {
        if state.completed { return "checkmark" }
        switch habit.type {
        case .quantity: return "plus"
        case .photo: return "camera.fill"
        case .journal: return "pencil"
        default: return "checkmark"
        }
    }

    private func rightButtonAction() {
        checkTrigger += 1
        switch habit.type {
        case .checkmark:
            viewModel.toggleHabitComplete(habit)
        case .quantity:
            if state.completed { viewModel.toggleHabitComplete(habit) } else { viewModel.addToQuantity(habit, amount: quantityStep) }
        case .routine:
            viewModel.toggleHabitComplete(habit)
        case .photo:
            if state.completed { viewModel.toggleHabitComplete(habit) } else { showCamera = true }
        case .journal:
            if state.completed { viewModel.toggleHabitComplete(habit) } else { onExpand() }
        }
    }

    // MARK: - Expanded dropdown (instruction + tip + optional control)

    private var hasFeature: Bool { habit.type != .checkmark }
    private var isWater: Bool { habit.type == .quantity && habit.unit == "oz" }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !isWater { adviceCard }      // water shows just the bottles + label
            if hasFeature { featureBody }
        }
    }

    /// A clean, breathable advice box with real coaching for this habit.
    private var adviceCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(blue)
                .padding(.top, 1)
            Text(habit.tip.isEmpty ? habit.explanation : habit.tip)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(blue.opacity(0.07)))
    }

    @ViewBuilder
    private var featureBody: some View {
        switch habit.type {
        case .quantity: quantityFeature
        case .routine: routineFeature
        case .photo: photoFeature
        case .journal: journalFeature
        case .checkmark: EmptyView()
        }
    }

    @ViewBuilder
    private var quantityFeature: some View {
        if habit.unit == "oz" {
            waterFeature
        } else {
            standardQuantity
        }
    }

    private var standardQuantity: some View {
        let goal = habit.goal ?? 0
        return VStack(spacing: 16) {
            HStack {
                stepButton("minus") { viewModel.addToQuantity(habit, amount: -quantityStep) }
                Spacer()
                VStack(spacing: 2) {
                    Text(formatted(state.value)).font(.system(size: 32, weight: .bold)).foregroundStyle(Theme.textPrimary)
                    Text("of \(formatted(goal)) \(habit.unit ?? "")").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                stepButton("plus") { viewModel.addToQuantity(habit, amount: quantityStep) }
            }
            pillButton(state.completed ? "Completed ✓" : "Mark as done") { viewModel.markQuantityDone(habit) }
        }
    }

    /// Cute water tracker — a row of little bottles (1 ≈ 8 oz) you tap to fill.
    private var waterFeature: some View {
        let goal = habit.goal ?? 0
        let cupOz = 8.0
        let totalCups = max(1, Int((goal / cupOz).rounded(.up)))
        let filledCups = min(totalCups, Int(state.value / cupOz))
        let cupsLeft = max(0, totalCups - filledCups)
        let columns = [GridItem(.adaptive(minimum: 34), spacing: 6)]
        return VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<totalCups, id: \.self) { i in
                    Button {
                        let target = Double(i + 1) * cupOz
                        checkTrigger += 1
                        viewModel.addToQuantity(habit, amount: target - state.value)
                    } label: {
                        Image(systemName: i < filledCups ? "waterbottle.fill" : "waterbottle")
                            .font(.system(size: 22))
                            .foregroundStyle(i < filledCups ? blue : Theme.textTertiary.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: checkTrigger)

            VStack(spacing: 3) {
                Text(cupsLeft == 0 ? "All bottles done 🎉" : "\(cupsLeft) bottle\(cupsLeft == 1 ? "" : "s") to go")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(Int(state.value)) of \(Int(goal)) oz · 1 bottle ≈ 8 oz")
                    .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 12) {
                stepButton("minus") { viewModel.addToQuantity(habit, amount: -cupOz) }
                pillButton("Mark as done") { viewModel.markQuantityDone(habit) }
                stepButton("plus") { viewModel.addToQuantity(habit, amount: cupOz) }
            }
        }
    }

    private func stepButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 46, height: 46)
                .background(Circle().fill(blue.opacity(0.13)))
        }
        .buttonStyle(.plain)
    }

    private var routineFeature: some View {
        VStack(spacing: 4) {
            ForEach(habit.subTasks, id: \.self) { step in
                let done = state.doneSubtasks.contains(step)
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light); gen.impactOccurred()
                    viewModel.toggleSubtask(habit, step)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(done ? Color.clear : accent.opacity(0.45), lineWidth: 2)
                                .background(Circle().fill(done ? accent : Color.clear))
                                .frame(width: 26, height: 26)
                            if done {
                                Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        Text(step)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(done ? Theme.textTertiary : Theme.textPrimary)
                            .strikethrough(done, color: Theme.textTertiary)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var photoFeature: some View {
        VStack(spacing: 12) {
            if state.photoAdded, let image = latestPhoto {
                Image(uiImage: image)
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(height: 150).frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 14))
            }
            pillButton(state.photoAdded ? "Retake photo" : "Add / Upload Photo", icon: "camera.fill") { showCamera = true }
            Text("Saved to your Progress timeline.")
                .font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
        }
    }

    private var journalFeature: some View {
        VStack(alignment: .leading, spacing: 10) {
            textArea(placeholder: "Write a short reflection…", text: $journalDraft)
            pillButton("Save entry") { viewModel.setJournal(habit, journalDraft) }
        }
    }

    // MARK: - Reusable bits

    private func textArea(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .font(.system(size: 14))
            .lineLimit(2...4)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.softPink))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.subtleBorder, lineWidth: 1))
    }

    private func pillButton(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().fill(blue.opacity(0.13)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var doneSubtaskCount: Int { habit.subTasks.filter { state.doneSubtasks.contains($0) }.count }

    private var quantityStep: Double {
        switch habit.unit {
        case "oz": return 8
        case "steps": return 1000
        case "g": return 10
        default: return 1
        }
    }

    private var latestPhoto: UIImage? {
        guard let url = viewModel.progressPhotos.first?.url else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
