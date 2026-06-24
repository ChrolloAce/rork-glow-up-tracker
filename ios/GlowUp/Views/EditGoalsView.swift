import SwiftUI

/// Lets the user adjust their habit goals (water, steps, protein, sleep, weight, workout).
struct EditGoalsView: View {
    @Bindable var viewModel: GlowViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    goalStepper(icon: "drop.fill", color: Theme.waterBlue, label: "Daily Water", unit: "oz",
                                value: $viewModel.waterGoal, step: 8, range: 32...200)
                    goalStepper(icon: "figure.walk", color: Theme.pink, label: "Step Goal", unit: "steps",
                                value: $viewModel.stepGoal, step: 500, range: 2000...30000)
                    goalStepper(icon: "flame.fill", color: Theme.sageGreen, label: "Protein Goal", unit: "g",
                                value: $viewModel.proteinGoal, step: 5, range: 40...250)
                    goalStepper(icon: "bed.double.fill", color: Theme.lavender, label: "Sleep Goal", unit: "hrs",
                                value: $viewModel.sleepGoal, step: 1, range: 4...12)
                    goalStepper(icon: "scalemass.fill", color: Theme.lavender, label: "Weight Goal", unit: "lbs",
                                value: $viewModel.goalWeight, step: 1, range: 80...300)
                    goalStepper(icon: "dumbbell.fill", color: Theme.pinkDeep, label: "Workout Duration", unit: "min",
                                value: $viewModel.workoutMinutes, step: 5, range: 10...120)
                    goalStepper(icon: "book.fill", color: Theme.pink, label: "Reading", unit: "pages",
                                value: $viewModel.readingPages, step: 5, range: 5...100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Theme.screenGradient.ignoresSafeArea())
            .scrollIndicators(.hidden)
            .navigationTitle("Edit Habit Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.pinkDeep)
                }
            }
        }
    }

    private func goalStepper(icon: String, color: Color, label: String, unit: String,
                             value: Binding<Double>, step: Double, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(Int(value.wrappedValue).formatted()) \(unit)")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            HStack(spacing: 10) {
                stepButton("minus") {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                }
                stepButton("plus") {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                }
            }
        }
        .padding(16)
        .glassCard(radius: 18)
    }

    private func stepButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.pinkDeep)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.softPink))
                .overlay(Circle().stroke(Theme.pink.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
