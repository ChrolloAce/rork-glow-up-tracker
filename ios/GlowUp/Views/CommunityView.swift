import SwiftUI

struct LeaderboardUser: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let score: Int
    let avatar: String
    let trend: Trend
    let level: Int
    let streak: Int

    enum Trend: Hashable {
        case up, down, same
    }
}


struct CommunityView: View {
    @Bindable var viewModel: GlowViewModel
    @StateObject private var community = CommunityService.shared
    @State private var filter: CommunityFilter = .sameChallenge
    @State private var showLeaderboard: Bool = false
    @State private var showNotes: Bool = false
    @State private var showComposer: Bool = false
    @State private var actionPost: FeedPost?
    @State private var showReportDialog: Bool = false
    @State private var showBlockConfirm: Bool = false
    @State private var detailPost: FeedPost?
    @State private var toast: String?

    static let reportReasons = ["Spam", "Harassment or bullying",
                                "Inappropriate content", "Something else"]

    enum CommunityFilter: String, CaseIterable, Identifiable {
        case sameChallenge = "Same Challenge"
        case everyone = "Everyone"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                challengeFilter
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                communityFeed
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button {
                showComposer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                    Text("Post Win")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 54)
                .background(
                    Capsule().fill(
                        LinearGradient(colors: [Theme.pink, Theme.pinkDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )
                .shadow(color: Theme.pink.opacity(0.45), radius: 14, x: 0, y: 8)
            }
            .padding(.trailing, 22)
            .padding(.bottom, 110)
            .sensoryFeedback(.impact(weight: .medium), trigger: showComposer)
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .onAppear {
            community.start()
            community.syncProfile(
                name: viewModel.userName.isEmpty ? "You" : viewModel.userName,
                avatar: viewModel.avatarURL,
                score: max(viewModel.currentDay * 120, 100),
                level: 7,
                streak: viewModel.currentDay
            )
        }
        .fullScreenCover(isPresented: $showLeaderboard) {
            CommunityLeaderboardView(viewModel: viewModel)
        }
        .sheet(isPresented: $showComposer) {
            ComposerSheet { title, body in
                community.createPost(
                    username: viewModel.userName.isEmpty ? "You" : viewModel.userName,
                    avatar: viewModel.avatarURL,
                    title: title,
                    body: body,
                    streak: viewModel.currentDay,
                    level: 7
                ) { error in
                    flashToast(error == nil ? "Posted to the community 🎉"
                                            : "Couldn't post: \(error!.localizedDescription)")
                }
            }
            .presentationDetents([.medium, .large])
            .adaptivePresentationBackground()
        }
        .sheet(isPresented: $showNotes) {
            NotesSheet()
                .presentationDetents([.medium, .large])
                .adaptivePresentationBackground()
        }
        .sheet(item: $detailPost) { post in
            PostDetailSheet(post: post, community: community)
        }
        .confirmationDialog("Report this post", isPresented: $showReportDialog, titleVisibility: .visible, presenting: actionPost) { post in
            ForEach(Self.reportReasons, id: \.self) { reason in
                Button(reason, role: .destructive) {
                    community.report(post, reason: reason)
                    flashToast("Thanks — our team will review this.")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Why are you reporting this? We review reports within 24 hours.")
        }
        .confirmationDialog("Block \(actionPost?.username ?? "this user")?", isPresented: $showBlockConfirm, titleVisibility: .visible, presenting: actionPost) { post in
            Button("Block", role: .destructive) {
                community.block(post)
                flashToast("Blocked. You won't see their posts.")
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("You won't see posts from this person anymore.")
        }
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Theme.textPrimary))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func flashToast(_ message: String) {
        withAnimation(.spring) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut) { toast = nil }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                showLeaderboard = true
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.glowBlue)
                    .frame(width: 38, height: 38)
                    .adaptiveGlass(in: Circle())
            }
            .sensoryFeedback(.impact(weight: .light), trigger: showLeaderboard)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Community")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text("Glow together with your sisters")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var challengeGroupBanner: some View {
        let name = viewModel.selectedChallenge?.name ?? "Glow"
        return Button { showLeaderboard = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.white.opacity(0.25)).frame(width: 38, height: 38)
                    Image(systemName: "person.3.fill").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(name) Group")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Day \(viewModel.currentDay) · glowing together")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill").font(.system(size: 11))
                    Text("Leaderboard").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.22)))
            }
            .padding(14)
            .background(
                LinearGradient(colors: [Theme.pink, Theme.pinkDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: 20)
            )
            .shadow(color: Theme.pink.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var challengeFilter: some View {
        HStack(spacing: 6) {
            ForEach(CommunityFilter.allCases) { option in
                Button {
                    withAnimation(.snappy(duration: 0.3)) { filter = option }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(filter == option ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if filter == option { Capsule().fill(Theme.pink) }
                            else { Capsule().fill(Color.clear) }
                        }
                }
            }
        }
        .padding(4)
        .background(Theme.softPink)
        .clipShape(Capsule())
        .sensoryFeedback(.selection, trigger: filter)
    }

    // MARK: - Community Feed

    private var communityFeed: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if community.posts.isEmpty {
                    emptyFeed
                } else {
                    ForEach(community.posts) { post in
                        PostCard(
                            post: post,
                            onLike: { community.toggleLike(post) },
                            onOpen: { detailPost = post },
                            onReport: { actionPost = post; showReportDialog = true },
                            onBlock: { actionPost = post; showBlockConfirm = true }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 180)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyFeed: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 30))
                .foregroundStyle(Theme.pink)
            Text("Be the first to post a win")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Share a milestone and inspire the community.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

}

// MARK: - Post Card

struct PostCard: View {
    let post: FeedPost
    var onLike: () -> Void
    var onOpen: () -> Void = {}
    var onReport: () -> Void = {}
    var onBlock: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarView(url: post.avatar, size: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.glowBlue)
                        Text("\(post.streak) day streak")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer()

                Menu {
                    Button("Save", systemImage: "bookmark") {}
                    Button("Share", systemImage: "square.and.arrow.up") {}
                    Divider()
                    Button("Report", systemImage: "flag", role: .destructive) { onReport() }
                    Button("Block \(post.username)", systemImage: "hand.raised", role: .destructive) { onBlock() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 32, height: 32)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)

                if !post.body.isEmpty {
                    Text(post.body)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onOpen() }

            HStack(spacing: 20) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { onLike() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(post.isLikedByMe ? Theme.pink : Theme.textTertiary)
                        Text("\(post.likeCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: post.isLikedByMe)

                HStack(spacing: 5) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(post.commentCount)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Text(post.relativeTime)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(16)
        .glassCard(radius: 22)
    }
}

// MARK: - Post detail (opening someone's post) with report / block

struct PostDetailSheet: View {
    let post: FeedPost
    @ObservedObject var community: CommunityService
    @Environment(\.dismiss) private var dismiss
    @State private var showReport = false
    @State private var showBlock = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        AvatarView(url: post.avatar, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.username)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(post.streak) day streak · \(post.relativeTime)")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                    }

                    Text(post.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    if !post.body.isEmpty {
                        Text(post.body)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLikedByMe ? Theme.pink : Theme.textTertiary)
                        Text("\(post.likeCount) likes")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .background(Theme.screenGradient.ignoresSafeArea())
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Report", systemImage: "flag", role: .destructive) { showReport = true }
                        Button("Block \(post.username)", systemImage: "hand.raised", role: .destructive) { showBlock = true }
                    } label: {
                        Image(systemName: "ellipsis.circle").foregroundStyle(Theme.pink)
                    }
                }
            }
            .confirmationDialog("Report this post", isPresented: $showReport, titleVisibility: .visible) {
                ForEach(CommunityView.reportReasons, id: \.self) { reason in
                    Button(reason, role: .destructive) {
                        community.report(post, reason: reason)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("We review reports within 24 hours.")
            }
            .confirmationDialog("Block \(post.username)?", isPresented: $showBlock, titleVisibility: .visible) {
                Button("Block", role: .destructive) {
                    community.block(post)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You won't see posts from this person anymore.")
            }
        }
    }
}

struct LevelBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.system(size: 8, weight: .bold))
            Text("Lv \(level)")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(
                LinearGradient(
                    colors: [Theme.pink, Theme.pinkDeep],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        )
    }
}

// MARK: - Avatar

struct AvatarView: View {
    let url: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Theme.softPink)
            .frame(width: size, height: size)
            .overlay {
                Group {
                    if AvatarCatalog.isLocal(url) {
                        Image(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        AsyncImage(url: URL(string: url)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(Theme.softPink)
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.pink.opacity(0.35), lineWidth: 1.5))
    }
}

// MARK: - Composer Sheet

struct ComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var bodyText: String = ""
    let onPost: (String, String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Divider()

                TextField("Share your glow story…", text: $bodyText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(8...20)

                Spacer()
            }
            .padding(20)
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
                        let trimmedBody = bodyText.trimmingCharacters(in: .whitespaces)
                        guard !trimmedTitle.isEmpty else { return }
                        onPost(trimmedTitle, trimmedBody)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.pink)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Notes Sheet

struct NotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your private glow journal — only you can see this.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)

                TextField("Write your thoughts…", text: $notes, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(10...30)
                    .padding(14)
                    .background(Theme.softPink)
                    .clipShape(.rect(cornerRadius: 16))

                Spacer()
            }
            .padding(20)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.pink)
                }
            }
        }
    }
}

// MARK: - Sample Data

// MARK: - Leaderboard Screen

struct CommunityLeaderboardView: View {
    @Bindable var viewModel: GlowViewModel
    @StateObject private var community = CommunityService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var podiumAppeared: Bool = false
    @State private var listAppeared: Bool = false

    private var users: [LeaderboardUser] {
        community.leaders.map {
            LeaderboardUser(name: $0.name, score: $0.score, avatar: $0.avatar,
                            trend: .same, level: $0.level, streak: $0.streak)
        }
    }

    private var podium: [LeaderboardUser] { Array(users.prefix(3)) }
    private var rest: [LeaderboardUser] { Array(users.dropFirst(3)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                podiumSection
                    .padding(.top, 36)
                    .padding(.bottom, 8)

                listHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 10)

                listSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
            }
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .onAppear {
            community.start()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                podiumAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                listAppeared = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.glowBlue)
                    .frame(width: 38, height: 38)
                    .adaptiveGlass(in: Circle())
            }
            Spacer()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Leaderboard")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text("This week's top glowers")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var podiumSection: some View {
        HStack(alignment: .top, spacing: 14) {
            podiumColumn(user: podium.indices.contains(1) ? podium[1] : nil, rank: 2, color: Theme.lavender, size: 78)
                .opacity(podiumAppeared ? 1 : 0)
                .offset(y: podiumAppeared ? 0 : 30)

            podiumColumn(user: podium.first, rank: 1, color: Theme.pink, size: 104, isWinner: true)
                .opacity(podiumAppeared ? 1 : 0)
                .offset(y: podiumAppeared ? 0 : 40)

            podiumColumn(user: podium.indices.contains(2) ? podium[2] : nil, rank: 3, color: Theme.roseGold, size: 78)
                .opacity(podiumAppeared ? 1 : 0)
                .offset(y: podiumAppeared ? 0 : 30)
        }
        .padding(.horizontal, 20)
    }

    private func podiumColumn(user: LeaderboardUser?, rank: Int, color: Color, size: CGFloat, isWinner: Bool = false) -> some View {
        VStack(spacing: 8) {
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.warmGold)
                    .shadow(color: Theme.warmGold.opacity(0.45), radius: 8, y: 2)
            } else {
                Color.clear.frame(height: 22)
            }

            ZStack {
                Circle()
                    .fill(color.opacity(0.22))
                    .frame(width: size + 16, height: size + 16)
                    .blur(radius: 16)

                Circle()
                    .fill(Theme.softPink)
                    .frame(width: size, height: size)
                    .overlay {
                        Group {
                            let avatar = user?.avatar ?? ""
                            if AvatarCatalog.isLocal(avatar) {
                                Image(avatar)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                AsyncImage(url: URL(string: avatar)) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle().fill(Theme.softPink)
                                    }
                                }
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
                    .overlay(Circle().stroke(color, lineWidth: 3))

                Text("\(rank)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(color))
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: size / 2 - 6, y: size / 2 - 6)
            }
            .frame(width: size + 12, height: size + 12)

            VStack(spacing: 4) {
                Text(user?.name ?? "—")
                    .font(.system(size: isWinner ? 15 : 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(user?.streak ?? 0) days")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var listHeader: some View {
        HStack {
            Text("Rank")
                .frame(width: 38, alignment: .leading)
            Text("User")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Streak")
                .frame(width: 70, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(Theme.textTertiary)
        .textCase(.uppercase)
    }

    private var listSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(rest.enumerated()), id: \.element.id) { index, user in
                LeaderboardRankRow(rank: index + 4, user: user, isCurrentUser: user.name == "You")
                    .opacity(listAppeared ? 1 : 0)
                    .offset(y: listAppeared ? 0 : 14)
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.04), value: listAppeared)
            }
        }
    }
}

struct LeaderboardRankRow: View {
    let rank: Int
    let user: LeaderboardUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isCurrentUser ? Theme.pink : Theme.textTertiary)
                .frame(width: 38, alignment: .leading)

            HStack(spacing: 10) {
                AvatarView(url: user.avatar, size: 38)

                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Theme.pink)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.glowBlue)
                Text("\(user.streak)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .glassCard(radius: 18, tinted: isCurrentUser, accent: isCurrentUser ? Theme.pink : Theme.pinkLight)
    }
}

// MARK: - Currency Pill

struct CurrencyPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .adaptiveGlass(in: Capsule())
    }
}
