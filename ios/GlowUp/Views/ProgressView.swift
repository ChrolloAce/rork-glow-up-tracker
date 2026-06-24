import SwiftUI

struct GlowProgressView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var showCamera: Bool = false
    @State private var showGallery: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                insightsStatGrid
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                if challenge?.usesPhotos ?? true {
                    progressPhotosCard
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }

                VStack(spacing: 16) {
                    challengeMetricsCard
                    primaryTrendCard
                    weeklySummaryCard
                    streakHallCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .fullScreenCover(isPresented: $showCamera) {
            CameraProxyView { image in
                viewModel.addProgressPhoto(image)
            }
        }
        .sheet(isPresented: $showGallery) {
            ProgressGalleryView(viewModel: viewModel)
        }
    }

    private var challenge: Challenge? { viewModel.selectedChallenge }
    private var habits: [DailyHabit] { viewModel.activeHabits }

    private var insightsStatGrid: some View {
        // Four essential summary cards only.
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            InsightStatCell(label: "Days Complete", value: "\(viewModel.completedDayNumbers.count)", isHighlighted: true)
            InsightStatCell(label: "Day Streak", value: "\(viewModel.currentStreak)", isHighlighted: false, valueColor: Theme.pink)
            InsightStatCell(label: "Completion", value: "\(Int(viewModel.dailyCompletionFraction * 100))%", isHighlighted: false, valueColor: Theme.sageGreen)
            if challenge?.usesGlowScore ?? false {
                InsightStatCell(label: "Glow Score", value: "\(viewModel.glowScore)%", isHighlighted: false, valueColor: Theme.lavender)
            } else {
                InsightStatCell(label: "Photos", value: "\(viewModel.progressPhotos.count)", isHighlighted: false, valueColor: Theme.waterBlue)
            }
        }
    }

    /// Soft pastel palette used to add color variety across metric rows.
    private let metricPalette: [Color] = [
        Theme.pink, Theme.waterBlue, Theme.sageGreen, Theme.lavender, Theme.warmGold, Theme.pinkDeep
    ]

    // MARK: - Prioritized challenge metrics

    private var challengeMetricsCard: some View {
        let metrics = challenge?.trackedMetrics ?? []
        return VStack(alignment: .leading, spacing: 14) {
            Text("What This Challenge Tracks")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(Array(metrics.enumerated()), id: \.element) { index, metric in
                let pct = viewModel.metricProgress(metric)
                let color = metricPalette[index % metricPalette.count]
                HStack(spacing: 12) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(metric)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 122, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Theme.progressTrack).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: geo.size.width * pct, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 38, alignment: .trailing)
                }
                .frame(height: 20)
            }
        }
        .padding(18)
        .glassCard()
    }

    // MARK: - Primary trend (Glow Score for Glow Up, else Daily Completion)

    private var primaryTrendCard: some View {
        let isGlow = challenge?.usesGlowScore ?? true
        let title = isGlow ? "Glow Score" : "Daily Completion"
        let data = isGlow ? viewModel.glowScoreTrend : viewModel.activeHabits.isEmpty ? [] : completionTrend
        let value = isGlow ? "\(viewModel.glowScore)" : "\(Int(viewModel.dailyCompletionFraction * 100))%"
        return VStack(spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.pink)
            }
            GlowTrendLine(data: data.isEmpty ? [0, 0] : data, color: Theme.pink)
                .frame(height: 120)
        }
        .padding(18)
        .glassCard()
    }

    private var completionTrend: [Double] {
        let seed = viewModel.currentDay
        var series: [Double] = (0..<6).map { 55 + Double((seed + $0 * 11) % 35) }
        series.append(viewModel.dailyCompletionFraction * 100)
        return series
    }



    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Summary")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(habits) { habit in
                let completion = viewModel.weeklyCompletion(for: habit)
                let pct = Double(completion) / 7.0

                HStack(spacing: 12) {
                    Text(habit.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 110, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.progressTrack)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(habit.themeColor)
                                .frame(width: geo.size.width * pct, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(completion)/7")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, alignment: .trailing)
                }
                .frame(height: 20)
            }
        }
        .padding(18)
        .glassCard()
    }

    private var progressPhotosCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Progress Photos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                if !viewModel.progressPhotos.isEmpty {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add Photo")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.pink)
                }
            }

            if viewModel.progressPhotos.isEmpty {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 12) {
                        ForEach(0..<2, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                .foregroundStyle(Theme.pink.opacity(0.35))
                                .frame(height: 80)
                                .overlay {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Theme.pink.opacity(0.35))
                                }
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .buttonStyle(.plain)

                Text("Tap to add your first photo")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.progressPhotos) { photo in
                            Button {
                                showGallery = true
                            } label: {
                                ProgressPhotoThumb(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            showCamera = true
                        } label: {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                .foregroundStyle(Theme.pink.opacity(0.45))
                                .frame(width: 90, height: 110)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(Theme.pink)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    showGallery = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .semibold))
                        Text("View Timeline")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("\(viewModel.progressPhotos.count) photos")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .foregroundStyle(Theme.pink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Theme.pink.opacity(0.08), in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .glassCard()
    }

    private var streakHallCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(habits) { habit in
                HStack(spacing: 12) {
                    Image(systemName: habit.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(habit.themeColor)
                        .frame(width: 24)
                    Text(habit.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("🔥 \(viewModel.streak(for: habit)) days")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.pink)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .glassCard()
    }
}

struct ProgressPhotoThumb: View {
    let photo: ProgressPhoto

    var body: some View {
        Color(.secondarySystemBackground)
            .frame(width: 90, height: 110)
            .overlay {
                if let uiImage = UIImage(contentsOfFile: photo.url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(.rect(cornerRadius: 12))
            .overlay(alignment: .bottomLeading) {
                Text(photo.date, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.4), in: .capsule)
                    .padding(6)
            }
    }
}

struct InsightStatCell: View {
    let label: String
    let value: String
    let isHighlighted: Bool
    var valueColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isHighlighted ? Color.white.opacity(0.9) : Theme.textSecondary)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(isHighlighted ? .white : (valueColor ?? Theme.textPrimary))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .insightGlass(isHighlighted: isHighlighted)
    }
}

extension View {
    @ViewBuilder
    func insightGlass(isHighlighted: Bool) -> some View {
        if isHighlighted {
            self
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Theme.pinkDeep, Theme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: Theme.pink.opacity(0.25), radius: 12, x: 0, y: 6)
        } else {
            self.glassCard(radius: 16)
        }
    }
}

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.softPink)
        .clipShape(.rect(cornerRadius: 10))
    }
}

struct GlowTrendLine: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let minVal = (data.min() ?? 0) - 5
            let maxVal = (data.max() ?? 100) + 5
            let range = maxVal - minVal
            let stepX = geo.size.width / CGFloat(max(data.count - 1, 1))

            ZStack {
                Path { path in
                    for (i, val) in data.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - (val - minVal) / range)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                Path { path in
                    for (i, val) in data.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - (val - minVal) / range)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.12), color.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                if let last = data.last {
                    let x = CGFloat(data.count - 1) * stepX
                    let y = geo.size.height * (1 - (last - minVal) / range)
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}
