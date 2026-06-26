import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var selectedSkinType: String = "Combination"
    @State private var showAvatarPicker: Bool = false
    @State private var showChallengePicker: Bool = false
    @State private var showChallengeDetail: Bool = false
    @State private var showEditGoals: Bool = false
    @State private var showCustomBuilder: Bool = false
    @State private var confirmSwitch: Bool = false
    @State private var confirmRestart: Bool = false
    @State private var calendarSync = CalendarSyncService.shared
    @State private var isImporting: Bool = false
    @State private var importToast: String? = nil
    @State private var showLogoutConfirm: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var isDeleting: Bool = false
    @EnvironmentObject private var auth: AuthService
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = true
    @State private var remindMorning: Bool = true
    @State private var remindEvening: Bool = true
    @State private var remindUnfinished: Bool = true
    @State private var remindStreak: Bool = false

    private let skinTypes = ["Dry", "Oily", "Combination", "Sensitive", "Normal"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                    .padding(.top, 16)

                VStack(spacing: 12) {
                    currentChallengeCard
                    challengeManagementCard
                    journeyCard
                    notificationsCard
                    connectionsCard
                    aboutCard
                    logoutButton
                    deleteAccountButton
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
        .fullScreenCover(isPresented: $showChallengeDetail) {
            if let challenge = viewModel.selectedChallenge {
                NavigationStack {
                    ChallengeDetailView(challenge: challenge) { showChallengeDetail = false }
                }
            }
        }
        .sheet(isPresented: $showEditGoals) {
            EditGoalsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showCustomBuilder) {
            CustomChallengeBuilderView(viewModel: viewModel)
        }
        .alert("Switch Challenge?", isPresented: $confirmSwitch) {
            Button("Switch", role: .destructive) { showChallengePicker = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Switching may reset your current challenge progress unless it's saved. You'll pick a new challenge and start fresh.")
        }
        .alert("Restart Challenge?", isPresented: $confirmRestart) {
            Button("Restart", role: .destructive) { viewModel.restartChallenge() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This sets your challenge back to Day 1 and clears today's progress. Your photos are kept.")
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
        .confirmationDialog("Delete account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete My Account", role: .destructive) {
                Task {
                    isDeleting = true
                    let ok = await auth.deleteAccount()
                    isDeleting = false
                    if ok {
                        auth.bootstrap()                 // fresh anonymous session
                        withAnimation { didCompleteOnboarding = false }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account, profile, and posts. This can't be undone.")
        }
    }

    private var deleteAccountButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 8) {
                if isDeleting {
                    ProgressView().controlSize(.small).tint(Theme.textTertiary)
                } else {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(isDeleting ? "Deleting…" : "Delete Account")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
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

    // MARK: - Current Challenge

    @ViewBuilder
    private var currentChallengeCard: some View {
        if let challenge = viewModel.selectedChallenge {
            let pct = viewModel.dailyCompletionFraction
            VStack(alignment: .leading, spacing: 16) {
                Text("CURRENT CHALLENGE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textTertiary)

                HStack(spacing: 16) {
                    ZStack {
                        Circle().stroke(Theme.progressTrack, lineWidth: 7)
                        Circle()
                            .trim(from: 0, to: pct)
                            .stroke(
                                LinearGradient(colors: [Theme.pink, Theme.pinkDeep], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 7, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(Int(pct * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("today")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("Day \(viewModel.currentDay) of \(viewModel.totalDays)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(viewModel.daysLeft) days left")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    Button { showChallengeDetail = true } label: {
                        Text("View Challenge")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(LinearGradient(colors: [Theme.pink, Theme.pinkDeep], startPoint: .leading, endPoint: .trailing), in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button { confirmSwitch = true } label: {
                        Text("Switch Challenge")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.pinkDeep)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.softPink, in: .rect(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.pink.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .glassCard()
        } else {
            Button { showChallengePicker = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(Theme.pink)
                    Text("Choose your challenge")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
                }
                .padding(18)
            }
            .buttonStyle(.plain)
            .glassCard()
        }
    }

    // MARK: - Challenge management

    private var challengeManagementCard: some View {
        VStack(spacing: 0) {
            challengeRow(icon: "doc.text.magnifyingglass", label: "View Challenge Details") { showChallengeDetail = true }
            Divider().opacity(0.4).padding(.leading, 52)
            challengeRow(icon: "arrow.left.arrow.right", label: "Switch Challenge") { confirmSwitch = true }
            Divider().opacity(0.4).padding(.leading, 52)
            challengeRow(icon: "arrow.counterclockwise", label: "Restart Challenge") { confirmRestart = true }
        }
        .glassCard()
    }

    private func challengeRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.glowBlue)
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
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
        }
        .padding(18)
        .glassCard()
    }

    private var goalsCard: some View {
        Button { showEditGoals = true } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Habit Goals")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Edit")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.pinkDeep)
                }

                GoalRow(icon: "drop.fill", color: Theme.waterBlue, label: "Daily Water", value: "\(Int(viewModel.waterGoal)) oz")
                GoalRow(icon: "figure.walk", color: Theme.pink, label: "Step Goal", value: "\(Int(viewModel.stepGoal).formatted())")
                GoalRow(icon: "flame.fill", color: Theme.sageGreen, label: "Protein Goal", value: "\(Int(viewModel.proteinGoal)) g")
                GoalRow(icon: "bed.double.fill", color: Theme.lavender, label: "Sleep Goal", value: "\(Int(viewModel.sleepGoal)) hrs")
            }
            .padding(18)
        }
        .buttonStyle(.plain)
        .glassCard()
    }

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reminders")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            reminderRow(icon: "sunrise.fill", color: Theme.glowBlue, label: "Morning reminder", isOn: $remindMorning)
            Divider().opacity(0.4)
            reminderRow(icon: "moon.stars.fill", color: Theme.glowBlue, label: "Evening reminder", isOn: $remindEvening)
            Divider().opacity(0.4)
            reminderRow(icon: "checklist", color: Theme.glowBlue, label: "Unfinished habits", isOn: $remindUnfinished)
            Divider().opacity(0.4)
            reminderRow(icon: "flame.fill", color: Theme.glowBlue, label: "Streak reminder", isOn: $remindStreak)
        }
        .padding(18)
        .glassCard()
    }

    private func reminderRow(icon: String, color: Color, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color).frame(width: 24)
            Text(label).font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).tint(Theme.glowBlue).labelsHidden()
        }
    }

    private var connectionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connections")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.glowBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Calendar")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textPrimary)
                    Text(calendarSync.isEnabled ? "Calendar connected" : "Sync to your calendar")
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
                .tint(Theme.glowBlue)
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
                        .foregroundStyle(Theme.glowBlue)
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
                    .foregroundStyle(Theme.glowBlue)
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
