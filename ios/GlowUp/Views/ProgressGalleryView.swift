import SwiftUI

struct ProgressGalleryView: View {
    @Bindable var viewModel: GlowViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCamera: Bool = false
    @State private var selectedPhoto: ProgressPhoto? = nil

    private var groupedPhotos: [(key: String, photos: [ProgressPhoto])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: viewModel.progressPhotos) { photo -> Date in
            let comps = calendar.dateComponents([.year, .month], from: photo.date)
            return calendar.date(from: comps) ?? photo.date
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (formatter.string(from: $0.key), $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.progressPhotos.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    LazyVStack(alignment: .leading, spacing: 28, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedPhotos, id: \.key) { group in
                            Section {
                                timelineRows(for: group.photos)
                            } header: {
                                sectionHeader(group.key, count: group.photos.count)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.screenGradient.ignoresSafeArea())
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.pink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(Theme.pink)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraProxyView { image in
                    viewModel.addProgressPhoto(image)
                }
            }
            .fullScreenCover(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.pink)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.pink.opacity(0.12), in: .capsule)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Theme.screenGradient)
    }

    private func timelineRows(for photos: [ProgressPhoto]) -> some View {
        VStack(spacing: 16) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                TimelineRow(
                    photo: photo,
                    isFirst: index == 0,
                    isLast: index == photos.count - 1
                ) {
                    selectedPhoto = photo
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.pink.opacity(0.12))
                    .frame(width: 84, height: 84)
                Image(systemName: "photo.stack")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.pink)
            }
            Text("No Progress Photos Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Capture your transformation. Add your first photo to start your timeline.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showCamera = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Add First Photo")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Theme.pinkDeep, Theme.pink], startPoint: .leading, endPoint: .trailing),
                    in: .capsule
                )
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TimelineRow: View {
    let photo: ProgressPhoto
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : Theme.pink.opacity(0.25))
                    .frame(width: 2, height: 14)

                ZStack {
                    Circle()
                        .fill(Theme.pink.opacity(0.18))
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Theme.pink)
                        .frame(width: 8, height: 8)
                }

                Rectangle()
                    .fill(isLast ? Color.clear : Theme.pink.opacity(0.25))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 18)

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(photo.date, format: .dateTime.weekday(.wide).month().day())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(photo.date, format: .dateTime.hour().minute())
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Color(.secondarySystemBackground)
                        .frame(height: 220)
                        .overlay {
                            if let uiImage = UIImage(contentsOfFile: photo.url.path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .allowsHitTesting(false)
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .clipShape(.rect(cornerRadius: 16))
                }
                .padding(12)
                .glassCard(radius: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }
}

private struct PhotoDetailView: View {
    let photo: ProgressPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let uiImage = UIImage(contentsOfFile: photo.url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                }
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(photo.date, format: .dateTime.weekday(.wide).month().day().year())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(photo.date, format: .dateTime.hour().minute())
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(16)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
            }
            .padding(20)
        }
    }
}
