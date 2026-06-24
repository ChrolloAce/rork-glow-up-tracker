import SwiftUI
import UIKit

/// A single Home-screen habit card, driven by the selected challenge's habit.
/// Supports all five habit types: checkmark, quantity, routine, photo, journal.
/// Keeps the existing card style: pastel left slab, soft outline, rounded corners.
struct ChallengeHabitCard: View {
    let habit: DailyHabit
    @Bindable var viewModel: GlowViewModel
    let isExpanded: Bool
    let onExpand: () -> Void

    @State private var checkTrigger: Int = 0
    @State private var showCamera: Bool = false
    @State private var journalDraft: String = ""

    private var state: ChallengeHabitDayState { viewModel.habitState(habit) }
    private var color: Color { habit.themeColor }
    private var hasExpansion: Bool { habit.type != .checkmark }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                leftSlab
                centerContent
                rightSection
            }
            .frame(minHeight: 82)

            if isExpanded, hasExpansion {
                expandedContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard(accent: color)
        .onAppear { journalDraft = state.journal }
        .sheet(isPresented: $showCamera) {
            CameraProxyView { image in
                viewModel.addProgressPhoto(image)
                viewModel.markPhotoAdded(habit)
            }
        }
    }

    // MARK: - Left slab

    private var leftSlab: some View {
        Button(action: primaryRowAction) {
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22)
                    .fill(color.opacity(0.9))

                VStack(spacing: 4) {
                    Spacer()
                    Image(systemName: habit.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                    if hasExpansion {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, 2)
                    }
                    Spacer()
                }
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Center

    private var centerContent: some View {
        Button(action: primaryRowAction) {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                subtitleText
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 82)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var subtitleText: some View {
        switch habit.type {
        case .quantity:
            HStack(spacing: 0) {
                Text("\(formatted(state.value))")
                    .foregroundStyle(color)
                Text(" / \(formatted(habit.goal ?? 0)) \(habit.unit ?? "")")
                    .foregroundStyle(Theme.textSecondary)
            }
            .font(.system(size: 13))
        case .routine:
            Text("\(doneSubtaskCount) / \(habit.subTasks.count) steps")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        case .photo:
            Text(state.photoAdded ? "Photo added today" : "Tap to add today's photo")
                .font(.system(size: 13))
                .foregroundStyle(state.photoAdded ? color : Theme.textSecondary)
        case .journal:
            Text(state.journal.isEmpty ? "Tap to reflect" : state.journal)
                .font(.system(size: 13))
                .foregroundStyle(state.journal.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                .lineLimit(1)
        case .checkmark:
            Text(habit.explanation)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Right

    private var rightSection: some View {
        VStack(spacing: 6) {
            if !isExpanded, habit.type == .quantity, let goal = habit.goal, goal > 0 {
                Text("\(Int(min(state.value / goal, 1) * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }

            Button(action: rightButtonAction) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(state.completed ? color : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(state.completed ? Color.clear : color.opacity(0.4), lineWidth: 1.2)
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: rightButtonIcon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(state.completed ? .white : color)
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: checkTrigger)
        }
        .padding(.trailing, 14)
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

    // MARK: - Actions

    private func primaryRowAction() {
        if hasExpansion {
            onExpand()
        } else {
            checkTrigger += 1
            viewModel.toggleHabitComplete(habit)
        }
    }

    private func rightButtonAction() {
        checkTrigger += 1
        switch habit.type {
        case .checkmark:
            viewModel.toggleHabitComplete(habit)
        case .quantity:
            if state.completed {
                viewModel.toggleHabitComplete(habit)
            } else {
                viewModel.addToQuantity(habit, amount: quantityStep)
            }
        case .routine:
            viewModel.toggleHabitComplete(habit)
        case .photo:
            if state.completed { viewModel.toggleHabitComplete(habit) } else { showCamera = true }
        case .journal:
            if state.completed { viewModel.toggleHabitComplete(habit) } else { onExpand() }
        }
    }

    // MARK: - Expanded content

    @ViewBuilder
    private var expandedContent: some View {
        switch habit.type {
        case .quantity: quantityExpanded
        case .routine: routineExpanded
        case .photo: photoExpanded
        case .journal: journalExpanded
        case .checkmark: EmptyView()
        }
    }

    private var quantityExpanded: some View {
        let goal = habit.goal ?? 0
        return VStack(spacing: 14) {
            HStack {
                stepButton(system: "minus") { viewModel.addToQuantity(habit, amount: -quantityStep) }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(formatted(state.value))")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("of \(formatted(goal)) \(habit.unit ?? "")")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                stepButton(system: "plus") { viewModel.addToQuantity(habit, amount: quantityStep) }
            }

            Button { viewModel.markQuantityDone(habit) } label: {
                Text(state.completed ? "Completed ✓" : "Mark as done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(state.completed ? color : Theme.pinkDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Capsule().fill(color.opacity(0.14)))
            }
            .buttonStyle(.plain)
        }
    }

    private func stepButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(Circle().fill(color.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }

    private var routineExpanded: some View {
        VStack(spacing: 8) {
            ForEach(habit.subTasks, id: \.self) { step in
                let done = state.doneSubtasks.contains(step)
                Button { viewModel.toggleSubtask(habit, step) } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(done ? Color.clear : color.opacity(0.4), lineWidth: 1.5)
                                .background(Circle().fill(done ? color : Color.clear))
                                .frame(width: 24, height: 24)
                            if done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        Text(step)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(done ? Theme.textTertiary : Theme.textPrimary)
                            .strikethrough(done, color: Theme.textTertiary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var photoExpanded: some View {
        VStack(spacing: 12) {
            if state.photoAdded, let image = latestPhoto {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 14))
            }

            Button { showCamera = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text(state.photoAdded ? "Retake photo" : "Add / Upload Photo")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.pinkDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Capsule().fill(color.opacity(0.14)))
            }
            .buttonStyle(.plain)
        }
    }

    private var journalExpanded: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Write a short reflection…", text: $journalDraft, axis: .vertical)
                .font(.system(size: 14))
                .lineLimit(3...5)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.softPink))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.subtleBorder, lineWidth: 1))

            Button { viewModel.setJournal(habit, journalDraft) } label: {
                Text("Save entry")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.pinkDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Capsule().fill(color.opacity(0.14)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var doneSubtaskCount: Int {
        habit.subTasks.filter { state.doneSubtasks.contains($0) }.count
    }

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
        if value.rounded() == value { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}
