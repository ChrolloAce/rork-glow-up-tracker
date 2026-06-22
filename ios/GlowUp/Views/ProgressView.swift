import SwiftUI

struct GlowProgressView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var selectedPeriod: Int = 0
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

                progressPhotosCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                LiquidSegmented(selected: $selectedPeriod, options: ["Weekly", "Monthly"], tint: Theme.pink)
                    .padding(.horizontal, 60)
                    .padding(.top, 20)

                VStack(spacing: 16) {
                    glowScoreTrendCard
                    habitCompletionRingsCard
                    weeklySummaryCard
                    skinMetricsChartCard
                    bodyStatsCard
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

    private var insightsStatGrid: some View {
        let startDateStr: String = {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy"
            return f.string(from: viewModel.startDate)
        }()

        let endDate = Calendar.current.date(byAdding: .day, value: 74, to: viewModel.startDate) ?? viewModel.startDate
        let endDateStr: String = {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy"
            return f.string(from: endDate)
        }()

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            InsightStatCell(label: "First Day", value: startDateStr, isHighlighted: false)
            InsightStatCell(label: "Last Day", value: endDateStr, isHighlighted: true)
            InsightStatCell(label: "Days Done", value: "\(viewModel.currentDay)", isHighlighted: false)
            InsightStatCell(label: "Days Left", value: "\(viewModel.totalDays - viewModel.currentDay)", isHighlighted: false)
            InsightStatCell(label: "Glow Score", value: "\(viewModel.glowScore)%", isHighlighted: false, valueColor: Theme.pink)
            InsightStatCell(label: "Water Drank", value: "101.5 oz", isHighlighted: false)
        }
    }


    private var glowScoreTrendCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Glow Score")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(viewModel.glowScore)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.pink)
            }

            GlowTrendLine(data: viewModel.glowScoreTrend, color: Theme.pink)
                .frame(height: 120)
        }
        .padding(18)
        .glassCard()
    }

    private var habitCompletionRingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week's Habits")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                ForEach(HabitCategory.allCases) { category in
                    let completion = viewModel.habitCompletionForWeek(category)
                    let pct = Double(completion) / 7.0

                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(Theme.progressTrack, lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: pct)
                                .stroke(category.slabColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(pct * 100))%")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)

                            if pct >= 1.0 {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "sparkle")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Theme.pink)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(width: 60, height: 60)

                        Text(category.rawValue.split(separator: " ").first.map(String.init) ?? category.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Summary")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(HabitCategory.allCases) { category in
                let completion = viewModel.habitCompletionForWeek(category)
                let pct = Double(completion) / 7.0

                HStack(spacing: 12) {
                    Text(category.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 100, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.progressTrack)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(category.slabColor)
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

    private var skinMetricsChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Habit Trends")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            MultiLineChart(metrics: viewModel.habitMetrics)
                .frame(height: 120)

            HStack(spacing: 10) {
                ForEach(HabitCategory.allCases) { category in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(category.slabColor)
                            .frame(width: 6, height: 6)
                        Text(category.shortName)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var bodyStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Body Progress")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            MiniLineChart(data: viewModel.weightHistory, color: Theme.lavender, goalValue: viewModel.goalWeight)
                .frame(height: 80)

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("Start")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(Int(viewModel.startWeight)) lbs")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("Current")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(Int(viewModel.currentWeight)) lbs")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("Lost")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(Int(viewModel.startWeight - viewModel.currentWeight)) lbs")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.sageGreen)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("Goal")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(Int(viewModel.goalWeight)) lbs")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.pink)
                }
                .frame(maxWidth: .infinity)
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

            ForEach(HabitCategory.allCases) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(category.slabColor)
                        .frame(width: 24)
                    Text(category.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("🔥 \(viewModel.habitStreaks[category] ?? 0) days")
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

struct MultiLineChart: View {
    let metrics: [HabitMetricData]

    var body: some View {
        GeometryReader { geo in
            ForEach(metrics) { metric in
                let data = metric.trend
                let minVal = 0.0
                let maxVal = 100.0
                let range = maxVal - minVal
                let stepX = geo.size.width / CGFloat(max(data.count - 1, 1))

                Path { path in
                    for (i, val) in data.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - (val - minVal) / range)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(metric.color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
