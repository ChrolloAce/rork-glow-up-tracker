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
    @State private var noteDraft: String = ""

    private var state: ChallengeHabitDayState { viewModel.habitState(habit) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                leftSlab
                centerContent
                rightSection
            }
            .frame(minHeight: 84)

            if isExpanded {
                expandedContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard(accent: accent)
        .onAppear {
            journalDraft = state.journal
            noteDraft = state.notes
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
        Button(action: onExpand) {
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22)
                    .fill(accent.opacity(0.9))
                Image(systemName: habit.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Center

    private var centerContent: some View {
        Button(action: onExpand) {
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
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var subtitleText: some View {
        switch habit.type {
        case .quantity:
            HStack(spacing: 0) {
                Text(formatted(state.value)).foregroundStyle(accent)
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

    // MARK: - Right (status + check, plus a chevron for symmetry)

    private var rightSection: some View {
        HStack(spacing: 10) {
            checkButton
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
        }
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

    // MARK: - Expanded dropdown (description + one focused feature)

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            descriptionRow
            Rectangle().fill(Theme.subtleBorder).frame(height: 1)
            featureBody
        }
    }

    private var descriptionRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(accent.opacity(0.8))
            Text(habit.explanation)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var featureBody: some View {
        switch habit.type {
        case .quantity: quantityFeature
        case .routine: routineFeature
        case .photo: photoFeature
        case .journal: journalFeature
        case .checkmark: noteFeature
        }
    }

    private var quantityFeature: some View {
        let goal = habit.goal ?? 0
        return VStack(spacing: 14) {
            HStack {
                stepButton("minus") { viewModel.addToQuantity(habit, amount: -quantityStep) }
                Spacer()
                VStack(spacing: 2) {
                    Text(formatted(state.value)).font(.system(size: 30, weight: .bold)).foregroundStyle(Theme.textPrimary)
                    Text("of \(formatted(goal)) \(habit.unit ?? "")").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                stepButton("plus") { viewModel.addToQuantity(habit, amount: quantityStep) }
            }
            pillButton(state.completed ? "Completed ✓" : "Mark as done") { viewModel.markQuantityDone(habit) }
        }
    }

    private func stepButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 46, height: 46)
                .background(Circle().fill(accent.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }

    private var routineFeature: some View {
        VStack(spacing: 8) {
            ForEach(habit.subTasks, id: \.self) { step in
                let done = state.doneSubtasks.contains(step)
                Button { viewModel.toggleSubtask(habit, step) } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(done ? Color.clear : accent.opacity(0.4), lineWidth: 1.5)
                                .background(Circle().fill(done ? accent : Color.clear))
                                .frame(width: 24, height: 24)
                            if done {
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        Text(step)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(done ? Theme.textTertiary : Theme.textPrimary)
                            .strikethrough(done, color: Theme.textTertiary)
                        Spacer()
                    }
                    .padding(.vertical, 3)
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

    private var noteFeature: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: state.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16)).foregroundStyle(state.completed ? accent : Theme.textTertiary)
                Text(state.completed ? "Done for today" : "Tap the check to complete")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            textArea(placeholder: "Add a note (optional)…", text: $noteDraft)
            pillButton("Save note") { viewModel.setNote(habit, noteDraft) }
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
            .foregroundStyle(Theme.pinkDeep)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().fill(accent.opacity(0.14)))
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
