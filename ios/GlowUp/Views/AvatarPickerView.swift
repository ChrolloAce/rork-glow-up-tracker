import SwiftUI

struct AvatarPickerView: View {
    @Binding var selected: String
    let isFirstLaunch: Bool
    var onConfirm: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var localSelection: String = AvatarCatalog.defaultAvatar

    private let columns = [
        GridItem(.adaptive(minimum: 90), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AvatarCatalog.all, id: \.self) { name in
                            AvatarTile(
                                name: name,
                                isSelected: localSelection == name
                            ) {
                                localSelection = name
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .background(Theme.screenGradient.ignoresSafeArea())
            .navigationTitle(isFirstLaunch ? "Pick Your Avatar" : "Change Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isFirstLaunch {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                confirmButton
            }
            .onAppear {
                localSelection = selected
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.pink.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)

                Circle()
                    .fill(Theme.softPink)
                    .frame(width: 130, height: 130)
                    .overlay {
                        Image(localSelection)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .shadow(color: Theme.pink.opacity(0.3), radius: 16, y: 8)
                    .id(localSelection)
                    .transition(.scale.combined(with: .opacity))
            }
            .frame(height: 180)

            Text(isFirstLaunch ? "Choose your glow avatar" : "Tap any avatar to switch")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: localSelection)
    }

    private var confirmButton: some View {
        Button {
            selected = localSelection
            UserDefaults.standard.set(localSelection, forKey: "selectedAvatarID")
            UserDefaults.standard.set(true, forKey: "hasSelectedAvatar")
            UserDefaults.standard.synchronize()
            onConfirm?()
            dismiss()
        } label: {
            Text(isFirstLaunch ? "Start Glowing" : "Save")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Theme.pink, Theme.pinkDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(.rect(cornerRadius: 18))
                .shadow(color: Theme.pink.opacity(0.45), radius: 14, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .background(.ultraThinMaterial)
        .sensoryFeedback(.success, trigger: false)
    }
}

private struct AvatarTile: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Theme.softPink)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Theme.pink : Color.white.opacity(0.6), lineWidth: isSelected ? 3 : 1.5)
                    )
                    .shadow(color: isSelected ? Theme.pink.opacity(0.4) : .black.opacity(0.05), radius: isSelected ? 10 : 4, y: 3)
                    .scaleEffect(isSelected ? 1.05 : 1)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, Theme.pink)
                        .offset(x: 4, y: -4)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
