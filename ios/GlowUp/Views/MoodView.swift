import SwiftUI
import PhotosUI

/// Tab 2 — "Mood". A daily quote, an aesthetic glow board, and the user's five reasons why.
/// All of this is global to the user, so it's the same across every challenge.
struct MoodView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var showEditQuote = false
    @State private var showEditReasons = false
    @State private var pickerItems: [PhotosPickerItem] = []

    private let ink = Theme.ink
    private let pink = Theme.glowBlue

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                quoteCard
                glowBoard
                reasonsCard
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.white.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showEditQuote) {
            MoodEditSheet(viewModel: viewModel, mode: .quote) { showEditQuote = false }
        }
        .sheet(isPresented: $showEditReasons) {
            MoodEditSheet(viewModel: viewModel, mode: .reasons) { showEditReasons = false }
        }
        .onChange(of: pickerItems) { _, items in loadImages(items) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Mood").font(.system(size: 34, weight: .heavy)).foregroundStyle(ink)
            Text("Your reminder, your vision, your why.")
                .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    /// Small pink "Edit" chip used in the corner of the quote and reasons sections.
    private func editChip(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "pencil").font(.system(size: 10, weight: .bold))
                Text("Edit").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(pink)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(pink.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily quote

    private var quoteCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24))
                .foregroundStyle(pink.opacity(0.55))
            if viewModel.userQuote.isEmpty {
                Text("Add a quote that means everything to you.")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                Button { showEditQuote = true } label: {
                    Text("Add your quote")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).frame(height: 40)
                        .background(Capsule().fill(ink))
                }
                .buttonStyle(.plain)
            } else {
                Text(viewModel.userQuote)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 26).fill(pink.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26).stroke(pink.opacity(0.18), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if !viewModel.userQuote.isEmpty {
                editChip { showEditQuote = true }.padding(12)
            }
        }
    }

    // MARK: - Glow board

    private var glowBoard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Glow Board").font(.system(size: 17, weight: .bold)).foregroundStyle(ink)
                Spacer()
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 12, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                        Text("Add").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(pink)
                }
            }

            if viewModel.glowBoardPhotos.isEmpty {
                boardEmptyState
            } else {
                boardGrid
            }
        }
    }

    /// Cute, generic stickers (no false claims about content).
    private let stickerSet = ["sparkles", "heart.fill", "leaf.fill", "star.fill", "sun.max.fill", "moon.stars.fill"]

    private var boardGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(viewModel.glowBoardPhotos.enumerated()), id: \.element.id) { index, photo in
                boardTile(photo, index: index)
            }
        }
    }

    private func boardTile(_ photo: ProgressPhoto, index: Int) -> some View {
        let tall = index % 3 == 0
        return ZStack(alignment: .topTrailing) {
            Color(.secondarySystemBackground)
                .frame(height: tall ? 200 : 150)
                .frame(maxWidth: .infinity)
                .overlay {
                    if let img = UIImage(contentsOfFile: photo.url.path) {
                        Image(uiImage: img).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                    }
                }
                .clipShape(.rect(cornerRadius: 18))

            Button { viewModel.removeGlowImage(photo) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(.black.opacity(0.4)))
            }
            .padding(6)
        }
        .overlay(alignment: .bottomLeading) {
            sticker(stickerSet[index % stickerSet.count], rotation: index % 2 == 0 ? -12 : 10)
                .offset(x: -8, y: 8)
        }
        .overlay(alignment: .bottomTrailing) {
            // a second, smaller accent sticker on some tiles for a fuller collage feel
            if index % 2 == 1 {
                sticker(stickerSet[(index + 3) % stickerSet.count], rotation: index % 3 == 0 ? 14 : -8)
                    .scaleEffect(0.78)
                    .offset(x: 8, y: 8)
            }
        }
    }

    private var boardEmptyState: some View {
        PhotosPicker(selection: $pickerItems, maxSelectionCount: 12, matching: .images) {
            VStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 34, weight: .light)).foregroundStyle(pink.opacity(0.6))
                Text("Build your glow board")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(ink)
                Text("Add at least 6 images that remind you who you're becoming.")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [7, 6]))
                    .foregroundStyle(pink.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }

    private func sticker(_ symbol: String, rotation: Double) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 20))
            .foregroundStyle(pink)
            .padding(8)
            .background(Circle().fill(.white))
            .shadow(color: pink.opacity(0.3), radius: 5, y: 2)
            .rotationEffect(.degrees(rotation))
    }

    // MARK: - Five reasons

    private var reasonsCard: some View {
        let reasons = viewModel.userReasons.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Five Reasons Why").font(.system(size: 17, weight: .bold)).foregroundStyle(ink)
                Spacer()
                if !reasons.isEmpty { editChip { showEditReasons = true } }
            }

            if reasons.isEmpty {
                VStack(spacing: 10) {
                    Text("Why are you really doing this? Write down your five.")
                        .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button { showEditReasons = true } label: {
                        Text("Add your reasons")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 18).frame(height: 40)
                            .background(Capsule().fill(ink))
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(pink.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(pink.opacity(0.18), lineWidth: 1))
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(reasons.enumerated()), id: \.offset) { index, reason in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(pink.opacity(0.18)).frame(width: 28, height: 28)
                                Text("\(index + 1)").font(.system(size: 13, weight: .bold)).foregroundStyle(pink)
                            }
                            Text(reason)
                                .font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 22).fill(pink.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(pink.opacity(0.18), lineWidth: 1))
            }
        }
    }

    // MARK: - Helpers

    private func loadImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    viewModel.addGlowImage(img)
                }
            }
            pickerItems = []
        }
    }
}

// MARK: - Mood setup / editor (used in onboarding and from the Mood tab)

struct MoodSetupView: View {
    @Bindable var viewModel: GlowViewModel
    var isOnboarding: Bool = true
    var onDone: () -> Void

    @State private var quote: String = ""
    @State private var reasons: [String] = ["", "", "", "", ""]

    private let ink = Theme.ink
    private let pink = Theme.glowBlue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isOnboarding ? "One last thing" : "Edit your mood")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(ink)
                        Text("Set the reminder and the reasons that keep you going.")
                            .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    section("A quote that means everything to you") {
                        TextField("e.g. Discipline is choosing what you want most over what you want now.", text: $quote, axis: .vertical)
                            .font(.system(size: 15))
                            .lineLimit(2...4)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.softPink))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.subtleBorder, lineWidth: 1))
                    }

                    section("Your 5 reasons why") {
                        VStack(spacing: 10) {
                            ForEach(0..<5, id: \.self) { i in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(pink.opacity(0.14)).frame(width: 28, height: 28)
                                        Text("\(i + 1)").font(.system(size: 13, weight: .bold)).foregroundStyle(pink)
                                    }
                                    TextField("Reason \(i + 1)", text: $reasons[i])
                                        .font(.system(size: 15))
                                        .padding(.vertical, 11).padding(.horizontal, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.softPink))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.subtleBorder, lineWidth: 1))
                                }
                            }
                        }
                    }

                    Button { save() } label: {
                        Text(isOnboarding ? "Continue" : "Save")
                            .font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(Capsule().fill(ink))
                    }
                    .buttonStyle(.plain)

                    if isOnboarding {
                        Button { skip() } label: {
                            Text("Skip for now")
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textTertiary)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color.white.ignoresSafeArea())
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { onDone() }.foregroundStyle(ink)
                    }
                }
            }
        }
        .onAppear {
            quote = viewModel.userQuote
            reasons = viewModel.userReasons.count == 5 ? viewModel.userReasons : ["", "", "", "", ""]
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            content()
        }
    }

    private func save() {
        viewModel.userQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.userReasons = reasons
        viewModel.hasCompletedMoodSetup = true
        onDone()
    }

    private func skip() {
        viewModel.hasCompletedMoodSetup = true
        onDone()
    }
}

// MARK: - Single-field editor (quote OR reasons) used from the Mood tab

enum MoodEditMode { case quote, reasons }

struct MoodEditSheet: View {
    @Bindable var viewModel: GlowViewModel
    let mode: MoodEditMode
    var onDone: () -> Void

    @State private var quote: String = ""
    @State private var reasons: [String] = ["", "", "", "", ""]

    private let ink = Theme.ink
    private let pink = Theme.glowBlue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if mode == .quote {
                        Text("A quote that means everything to you")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                        TextField("e.g. Discipline is choosing what you want most over what you want now.", text: $quote, axis: .vertical)
                            .font(.system(size: 16))
                            .lineLimit(2...6)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.softPink))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.subtleBorder, lineWidth: 1))
                    } else {
                        Text("Your 5 reasons why")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                        VStack(spacing: 10) {
                            ForEach(0..<5, id: \.self) { i in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(pink.opacity(0.14)).frame(width: 28, height: 28)
                                        Text("\(i + 1)").font(.system(size: 13, weight: .bold)).foregroundStyle(pink)
                                    }
                                    TextField("Reason \(i + 1)", text: $reasons[i])
                                        .font(.system(size: 15))
                                        .padding(.vertical, 11).padding(.horizontal, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.softPink))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.subtleBorder, lineWidth: 1))
                                }
                            }
                        }
                    }

                    Button { save() } label: {
                        Text("Save")
                            .font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Capsule().fill(ink))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Color.white.ignoresSafeArea())
            .scrollIndicators(.hidden)
            .navigationTitle(mode == .quote ? "Edit your quote" : "Edit your reasons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDone() }.foregroundStyle(ink)
                }
            }
        }
        .onAppear {
            quote = viewModel.userQuote
            reasons = viewModel.userReasons.count == 5 ? viewModel.userReasons : ["", "", "", "", ""]
        }
    }

    private func save() {
        if mode == .quote {
            viewModel.userQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            viewModel.userReasons = reasons
        }
        onDone()
    }
}
