import SwiftUI

/// UI foundation for a future custom-challenge builder. Intentionally not yet
/// functional — it lays out every field the builder will eventually support.
struct CustomChallengeBuilderView: View {
    @Bindable var viewModel: GlowViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var durationDays: Double = 30
    @State private var startDate: Date = Date()
    @State private var selectedColor: Int = 0

    private let themeSwatches: [Color] = [
        Color(red: 0.96, green: 0.56, blue: 0.66), // pink
        Color(red: 0.70, green: 0.62, blue: 0.88), // lavender
        Color(red: 0.557, green: 0.769, blue: 0.627), // sage
        Color(red: 0.42, green: 0.66, blue: 0.86), // blue
        Color(red: 0.96, green: 0.62, blue: 0.38)  // warm orange
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    comingSoonBanner
                    nameSection
                    durationSection
                    habitsSection
                    goalsSection
                    themeSection
                    imageSection
                    startDateSection
                    createButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Theme.screenGradient.ignoresSafeArea())
            .scrollIndicators(.hidden)
            .navigationTitle("Custom Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.pinkDeep)
                }
            }
        }
    }

    private var comingSoonBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wand.and.stars")
                .foregroundStyle(Theme.pink)
            Text("Coming soon — design your own challenge with custom habits, goals, and theme.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.softPink, in: .rect(cornerRadius: 16))
    }

    private var nameSection: some View {
        section("Challenge Name") {
            TextField("e.g. My Glow Reset", text: $name)
                .font(.system(size: 15))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.subtleBorder, lineWidth: 1))
        }
    }

    private var durationSection: some View {
        section("Duration") {
            HStack {
                Text("\(Int(durationDays)) days")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Stepper("", value: $durationDays, in: 7...100, step: 1)
                    .labelsHidden()
                    .tint(Theme.pink)
            }
        }
    }

    private var habitsSection: some View {
        section("Habits") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pick from the habit library or add your own.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                placeholderChips(["Water", "Workout", "Skincare", "Reading", "+ Add"])
            }
        }
    }

    private var goalsSection: some View {
        section("Custom Goals") {
            Text("Set targets for each habit (water, steps, protein…).")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var themeSection: some View {
        section("Color / Theme") {
            HStack(spacing: 12) {
                ForEach(themeSwatches.indices, id: \.self) { index in
                    Circle()
                        .fill(themeSwatches[index])
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle().stroke(Theme.textPrimary.opacity(selectedColor == index ? 0.6 : 0), lineWidth: 2)
                        )
                        .onTapGesture { selectedColor = index }
                }
                Spacer()
            }
        }
    }

    private var imageSection: some View {
        section("Cover Image (optional)") {
            RoundedRectangle(cornerRadius: 14)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [7, 6]))
                .foregroundStyle(Theme.pink.opacity(0.35))
                .frame(height: 90)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.pink.opacity(0.6))
                        Text("Add an image")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
        }
    }

    private var startDateSection: some View {
        section("Start Date") {
            HStack {
                Text("Begin on")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Theme.pink)
            }
        }
    }

    private var createButton: some View {
        Button { } label: {
            Text("Create Challenge")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.progressTrack, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(true)
        .overlay(alignment: .center) {
            Text("Coming soon")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .offset(y: 20)
        }
    }

    // MARK: - Helpers

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassCard()
    }

    private func placeholderChips(_ items: [String]) -> some View {
        let columns = [GridItem(.adaptive(minimum: 80), spacing: 8, alignment: .leading)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.pinkDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(Theme.softPink))
                    .overlay(Capsule().stroke(Theme.pink.opacity(0.25), lineWidth: 1))
            }
        }
    }
}
