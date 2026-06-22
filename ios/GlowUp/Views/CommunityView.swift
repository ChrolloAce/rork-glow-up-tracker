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

struct CommunityPost: Identifiable, Hashable {
    let id = UUID()
    let username: String
    let avatar: String
    let age: Int
    let level: Int
    let title: String
    let body: String
    let likes: Int
    let comments: Int
    let timestamp: String
    var isLiked: Bool = false
}

struct ChatMessage: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let username: String
    let avatar: String
    let age: Int
    let message: String
    let timestamp: String
    let isCurrentUser: Bool

    static func formatTimestamp(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: iso)
            ?? ISO8601DateFormatter().date(from: iso)
            ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

let glowAvatars: [String] = [
    "character_2", "character_5", "character_9", "character_14", "character_22"
]

struct CommunityView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var selectedTab: CommunityTab = .community
    @State private var showLeaderboard: Bool = false
    @State private var showNotes: Bool = false
    @State private var showComposer: Bool = false
    @State private var chatInput: String = ""
    @State private var posts: [CommunityPost] = CommunityPost.samples
    @State private var messages: [ChatMessage] = []
    @State private var chatLoading: Bool = false
    @State private var chatError: String? = nil
    @State private var pollTask: Task<Void, Never>? = nil
    @FocusState private var chatFocused: Bool

    enum CommunityTab: String, CaseIterable, Identifiable {
        case community = "Community"
        case liveChat = "Live Chat"
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

                tabSwitcher
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                Group {
                    switch selectedTab {
                    case .community:
                        communityFeed
                    case .liveChat:
                        liveChat
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if selectedTab == .community {
                Button {
                    showComposer = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.pink, Theme.pinkDeep],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Theme.pink.opacity(0.45), radius: 14, x: 0, y: 8)
                }
                .padding(.trailing, 22)
                .padding(.bottom, 110)
                .sensoryFeedback(.impact(weight: .medium), trigger: showComposer)
            }
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: selectedTab)
        .fullScreenCover(isPresented: $showLeaderboard) {
            CommunityLeaderboardView(viewModel: viewModel)
        }
        .sheet(isPresented: $showComposer) {
            ComposerSheet { title, body in
                let new = CommunityPost(
                    username: "You",
                    avatar: viewModel.avatarURL,
                    age: 24,
                    level: 7,
                    title: title,
                    body: body,
                    likes: 0,
                    comments: 0,
                    timestamp: "now"
                )
                posts.insert(new, at: 0)
            }
            .presentationDetents([.medium, .large])
            .adaptivePresentationBackground()
        }
        .sheet(isPresented: $showNotes) {
            NotesSheet()
                .presentationDetents([.medium, .large])
                .adaptivePresentationBackground()
        }
        .task {
            await loadMessages()
            startPolling()
        }
        .onDisappear {
            pollTask?.cancel()
            pollTask = nil
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.selectedTab = 0
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.pink)
                    .frame(width: 38, height: 38)
                    .adaptiveGlass(in: Circle())
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    showLeaderboard = true
                } label: {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.warmGold)
                        .frame(width: 38, height: 38)
                        .adaptiveGlass(in: Circle())
                }
                .sensoryFeedback(.impact(weight: .light), trigger: showLeaderboard)

                Button {
                    showNotes = true
                } label: {
                    Image(systemName: "note.text")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.pink)
                        .frame(width: 38, height: 38)
                        .adaptiveGlass(in: Circle())
                }
            }
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

    private var tabSwitcher: some View {
        HStack(spacing: 6) {
            ForEach(CommunityTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTab == tab {
                                Capsule().fill(Theme.pink)
                            } else {
                                Capsule().fill(Color.clear)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(Theme.softPink)
        .clipShape(Capsule())
    }

    // MARK: - Community Feed

    private var communityFeed: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach($posts) { $post in
                    PostCard(post: $post)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 180)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Live Chat

    private var liveChat: some View {
        VStack(spacing: 0) {
            if !SupabaseService.shared.isConfigured {
                chatConfigBanner
            } else if let chatError {
                chatErrorBanner(chatError)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if messages.isEmpty && chatLoading {
                            HStack { Spacer(); ProgressView().tint(Theme.pink); Spacer() }
                                .padding(.top, 60)
                        } else if messages.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Theme.pink.opacity(0.6))
                                Text("Be the first to say hi")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            chatInputBar
        }
    }

    private var chatConfigBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.warmOrange)
            Text("Live chat needs Supabase configured")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.softPink)
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func chatErrorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.warmOrange)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
            Spacer()
            Button {
                Task { await loadMessages() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.pink)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.softPink)
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textTertiary)

                TextField("Message the community…", text: $chatInput)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .focused($chatFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.softPink)
            .clipShape(Capsule())

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [Theme.pink, Theme.pinkDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(color: Theme.pink.opacity(0.35), radius: 8, y: 4)
            }
            .disabled(chatInput.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(chatInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 100)
        .background(
            Rectangle()
                .fill(.white.opacity(0.95))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func sendMessage() {
        let trimmed = chatInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        chatInput = ""

        let optimistic = ChatMessage(
            username: "You",
            avatar: viewModel.avatarURL,
            age: 24,
            message: trimmed,
            timestamp: "now",
            isCurrentUser: true
        )
        messages.append(optimistic)

        guard SupabaseService.shared.isConfigured else { return }

        Task {
            do {
                _ = try await SupabaseService.shared.sendMessage(
                    username: "You",
                    avatar: viewModel.avatarURL,
                    age: 24,
                    message: trimmed
                )
                await loadMessages()
            } catch {
                chatError = "Couldn't send. Tap retry."
            }
        }
    }

    private func loadMessages() async {
        guard SupabaseService.shared.isConfigured else { return }
        if messages.isEmpty { chatLoading = true }
        do {
            let rows = try await SupabaseService.shared.fetchMessages(limit: 200)
            let mapped: [ChatMessage] = rows.map { row in
                ChatMessage(
                    username: row.username,
                    avatar: row.avatar,
                    age: row.age,
                    message: row.message,
                    timestamp: ChatMessage.formatTimestamp(row.created_at),
                    isCurrentUser: row.username == "You"
                )
            }
            messages = mapped
            chatError = nil
        } catch SupabaseError.missingConfig {
            chatError = nil
        } catch {
            chatError = "Couldn't load chat."
        }
        chatLoading = false
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak viewModel] in
            _ = viewModel
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                if Task.isCancelled { break }
                await loadMessages()
            }
        }
    }
}

// MARK: - Post Card

struct PostCard: View {
    @Binding var post: CommunityPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarView(url: post.avatar, size: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(post.username)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)

                        Text("\(post.age)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.pinkDeep)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Theme.softPink)
                            .clipShape(Capsule())

                        LevelBadge(level: post.level)
                    }
                    Text("Contributor")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                Menu {
                    Button("Save", systemImage: "bookmark") {}
                    Button("Share", systemImage: "square.and.arrow.up") {}
                    Button("Report", systemImage: "exclamationmark.triangle", role: .destructive) {}
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

                Text(post.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: 20) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        post.isLiked.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(post.isLiked ? Theme.pink : Theme.textTertiary)
                        Text("\(post.likes + (post.isLiked ? 1 : 0))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: post.isLiked)

                HStack(spacing: 5) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(post.comments)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Text(post.timestamp)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(16)
        .glassCard(radius: 22)
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

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.isCurrentUser {
                Spacer(minLength: 40)
                bubbleColumn(alignment: .trailing)
                AvatarView(url: message.avatar, size: 36)
            } else {
                AvatarView(url: message.avatar, size: 36)
                bubbleColumn(alignment: .leading)
                Spacer(minLength: 40)
            }
        }
    }

    private func bubbleColumn(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(message.username)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            Text(message.message)
                .font(.system(size: 14))
                .foregroundStyle(message.isCurrentUser ? .white : Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if message.isCurrentUser {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.pink, Theme.pinkDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.softPink)
                    }
                }

            HStack(spacing: 6) {
                Text("\(message.age)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.pinkDeep)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Theme.softPink)
                    .clipShape(Capsule())
                Text(message.timestamp)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
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

extension CommunityPost {
    static let samples: [CommunityPost] = [
        .init(
            username: "Aurora",
            avatar: glowAvatars[1],
            age: 26,
            level: 12,
            title: "My 6-month skincare glow up ✨",
            body: "Started with double cleansing every night and a simple vitamin C + SPF combo in the morning. The trick was sticking with it — patience really is the most underrated ingredient.",
            likes: 248,
            comments: 42,
            timestamp: "2h"
        ),
        .init(
            username: "Mira",
            avatar: glowAvatars[3],
            age: 23,
            level: 8,
            title: "Best drugstore retinol for sensitive skin?",
            body: "Looking for recs that won't wreck my barrier. Currently using a basic moisturizer and SPF only — ready to level up but nervous to start.",
            likes: 86,
            comments: 31,
            timestamp: "4h"
        ),
        .init(
            username: "Sienna",
            avatar: glowAvatars[2],
            age: 29,
            level: 15,
            title: "Hydration changed everything",
            body: "Tracking water for 30 days through this app and my skin has never looked better. Genuinely glowing without trying. Who else is on the water streak?",
            likes: 174,
            comments: 28,
            timestamp: "8h"
        ),
        .init(
            username: "Camille",
            avatar: glowAvatars[0],
            age: 25,
            level: 6,
            title: "Sunday self-care ritual 🌸",
            body: "Long bath, clay mask, lo-fi playlist, and journaling. The most underrated part of glow culture is actually slowing down to enjoy it.",
            likes: 312,
            comments: 54,
            timestamp: "1d"
        ),
        .init(
            username: "Naomi",
            avatar: glowAvatars[4],
            age: 31,
            level: 18,
            title: "Lasered my pigmentation — here's what I learned",
            body: "Three sessions in and I have honest thoughts. SPF before and after is non-negotiable. Ask me anything in the comments.",
            likes: 421,
            comments: 87,
            timestamp: "1d"
        )
    ]
}

extension ChatMessage {
    static let samples: [ChatMessage] = [
        .init(username: "Aurora", avatar: glowAvatars[1], age: 26, message: "Morning girlies ☀️ what's everyone using for SPF today?", timestamp: "9:14 AM", isCurrentUser: false),
        .init(username: "Mira", avatar: glowAvatars[3], age: 23, message: "Beauty of Joseon, never miss a day", timestamp: "9:16 AM", isCurrentUser: false),
        .init(username: "You", avatar: AvatarCatalog.defaultAvatar, age: 24, message: "Same!! That one is unreal under makeup", timestamp: "9:18 AM", isCurrentUser: true),
        .init(username: "Sienna", avatar: glowAvatars[2], age: 29, message: "Anyone tried the new Glossier serum?", timestamp: "9:22 AM", isCurrentUser: false),
        .init(username: "Camille", avatar: glowAvatars[0], age: 25, message: "It's actually cute, makes my skin look soft 🌸", timestamp: "9:24 AM", isCurrentUser: false),
        .init(username: "Naomi", avatar: glowAvatars[4], age: 31, message: "Adding to my list ✨", timestamp: "9:26 AM", isCurrentUser: false)
    ]
}

// MARK: - Leaderboard Screen

struct CommunityLeaderboardView: View {
    @Bindable var viewModel: GlowViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var podiumAppeared: Bool = false
    @State private var listAppeared: Bool = false

    private var users: [LeaderboardUser] {
        [
            .init(name: "Aurora", score: 9_840, avatar: glowAvatars[1], trend: .same, level: 18, streak: 42),
            .init(name: "Mira", score: 9_410, avatar: glowAvatars[3], trend: .up, level: 16, streak: 38),
            .init(name: "Sienna", score: 9_120, avatar: glowAvatars[2], trend: .down, level: 15, streak: 30),
            .init(name: "Camille", score: 7_980, avatar: glowAvatars[0], trend: .up, level: 12, streak: 24),
            .init(name: "Naomi", score: 7_640, avatar: glowAvatars[4], trend: .down, level: 11, streak: 22),
            .init(name: "Lila", score: 7_120, avatar: glowAvatars[1], trend: .up, level: 10, streak: 19),
            .init(name: "Chiara", score: 6_870, avatar: glowAvatars[2], trend: .same, level: 9, streak: 17),
            .init(name: "Esme", score: 6_440, avatar: glowAvatars[0], trend: .down, level: 9, streak: 14),
            .init(name: "Zara", score: 6_180, avatar: glowAvatars[4], trend: .up, level: 8, streak: 12),
            .init(name: "Petra", score: 5_990, avatar: glowAvatars[3], trend: .down, level: 8, streak: 10),
            .init(name: "You", score: 5_720, avatar: viewModel.avatarURL, trend: .up, level: 7, streak: 8)
        ]
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
                    .foregroundStyle(Theme.pink)
                    .frame(width: 38, height: 38)
                    .adaptiveGlass(in: Circle())
            }
            Spacer()
            HStack(spacing: 8) {
                CurrencyPill(icon: "sparkles", value: "\(viewModel.glowScore * 28)", color: Theme.pink)
                CurrencyPill(icon: "flame.fill", value: "\(viewModel.habitStreaks[.skincare] ?? 0)", color: Theme.warmOrange)
            }
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
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                    Text((user?.score ?? 0).formatted(.number))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(color)

                LevelBadge(level: user?.level ?? 0)
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
            Text("Level")
                .frame(width: 60, alignment: .center)
            Text("Points")
                .frame(width: 64, alignment: .trailing)
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

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
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
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.warmOrange)
                        Text("\(user.streak) days")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Lv \(user.level)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.pinkDeep)
                .frame(width: 60, alignment: .center)

            HStack(spacing: 3) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.pink)
                Text(user.score.formatted(.number))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 64, alignment: .trailing)
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
