import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var selectedSkinType: String = "Combination"
    @State private var connectHealth: Bool = false
    @State private var showAvatarPicker: Bool = false
    @State private var showChallengePicker: Bool = false
    @State private var calendarSync = CalendarSyncService.shared
    @State private var isImporting: Bool = false
    @State private var importToast: String? = nil
    @State private var showLogoutConfirm: Bool = false
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = true

    private let skinTypes = ["Dry", "Oily", "Combination", "Sensitive", "Normal"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                    .padding(.top, 16)

                VStack(spacing: 12) {
                    skinTypeCard
                    journeyCard
                    goalsCard
                    notificationsCard
                    connectionsCard
                    aboutCard
                    logoutButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 100)
            }
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView(selected: $viewModel.avatarURL, isFirstLaunch: false)
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
        .fullScreenCover(isPresented: $showChallengePicker) {
            NavigationStack {
                SelectChallengeView(
                    viewModel: viewModel,
                    isOnboarding: false,
                    onContinue: {}
                )
            }
        }
        .confirmationDialog("Log out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out & Restart Onboarding", role: .destructive) {
                viewModel.saveAll()
                withAnimation { didCompleteOnboarding = false }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll go back to the beginning of onboarding. Your data is kept.")
        }
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            showLogoutConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Log Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Theme.pinkDeep)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Theme.pinkDeep.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Button {
                showAvatarPicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Theme.glassBackground)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Group {
                                if AvatarCatalog.isLocal(viewModel.avatarURL) {
                                    Image(viewModel.avatarURL)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    AsyncImage(url: URL(string: viewModel.avatarURL)) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Circle().fill(Theme.glassBackground)
                                        }
                                    }
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.pink.opacity(0.4), lineWidth: 2))

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white, Theme.pink)
                        .background(Circle().fill(.white).frame(width: 24, height: 24))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: showAvatarPicker)

            Text(viewModel.userName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            Text("Day \(viewModel.currentDay) · \(viewModel.selectedChallenge?.name ?? "Glow Challenge")")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var skinTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skin Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(skinTypes, id: \.self) { type in
                        Button {
                            selectedSkinType = type
                        } label: {
                            Text(type)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedSkinType == type ? .white : Theme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedSkinType == type ? Theme.pink : Theme.softPink)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(18)
        .glassCard()
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Glow Journey")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.pink)
                    .frame(width: 24)
                Text("Day 1 Start Date")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.startDate },
                        set: { newValue in
                            viewModel.startDate = Calendar.current.startOfDay(for: newValue)
                        }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(Theme.pink)
            }

            Text("You're currently on Day \(viewModel.currentDay) of \(viewModel.totalDays).")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)

            Divider().opacity(0.4)

            Button {
                showChallengePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.pink)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Challenge")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textPrimary)
                        Text(viewModel.selectedChallenge?.name ?? "Not selected")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Text("Switch")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.pinkDeep)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .glassCard()
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Goals")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            GoalRow(icon: "scalemass.fill", color: Theme.lavender, label: "Weight Goal", value: "\(Int(viewModel.goalWeight)) lbs")
            GoalRow(icon: "drop.fill", color: Theme.waterBlue, label: "Daily Water", value: "101 oz")
            GoalRow(icon: "figure.walk", color: Theme.pink, label: "Step Goal", value: "10,000")
        }
        .padding(18)
        .glassCard()
    }

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notifications")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(HabitCategory.allCases) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(category.slabColor)
                        .frame(width: 24)
                    Text(category.rawValue)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Toggle("", isOn: .constant(category.hasReminder))
                        .tint(Theme.pink)
                        .labelsHidden()
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var connectionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connections")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.pink)
                Text("Apple Health")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Toggle("", isOn: $connectHealth)
                    .tint(Theme.pink)
                    .labelsHidden()
            }

            Divider().opacity(0.4)

            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.pink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Calendar")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textPrimary)
                    Text(calendarSync.isEnabled ? "Beauty appointments syncing" : "Sync beauty appointments")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { calendarSync.isEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                let granted = await calendarSync.requestAccess()
                                calendarSync.isEnabled = granted
                                if granted {
                                    await viewModel.syncAllTreatmentsToCalendar()
                                }
                            }
                        } else {
                            calendarSync.isEnabled = false
                        }
                    }
                ))
                .tint(Theme.pink)
                .labelsHidden()
            }

            if calendarSync.isEnabled {
                Button {
                    Task {
                        isImporting = true
                        let before = viewModel.treatments.count
                        await viewModel.importFromAppleCalendar()
                        let added = viewModel.treatments.count - before
                        importToast = added > 0 ? "Imported \(added) appointment\(added == 1 ? "" : "s")" : "No new appointments found"
                        isImporting = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isImporting {
                            ProgressView().controlSize(.small).tint(Theme.pink)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text(isImporting ? "Importing…" : "Import from Calendar")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Theme.pink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .overlay(Capsule().stroke(Theme.pink.opacity(0.4), lineWidth: 1))
                }
                .disabled(isImporting)
                .sensoryFeedback(.impact(weight: .light), trigger: isImporting)

                if let toast = importToast {
                    Text(toast)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var aboutCard: some View {
        VStack(spacing: 0) {
            Button {
                showAvatarPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.pink)
                    Text("Change Avatar")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(18)
            }
            .sensoryFeedback(.selection, trigger: showAvatarPicker)

            SettingsRow(icon: "lock.shield.fill", label: "Privacy")
            SettingsRow(icon: "questionmark.circle.fill", label: "Help")
            SettingsRow(icon: "info.circle.fill", label: "About")
        }
        .glassCard()
    }
}

struct GoalRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let label: String

    var body: some View {
        Button { } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.pink)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(18)
        }
    }
}
