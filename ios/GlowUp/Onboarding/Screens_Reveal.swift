import SwiftUI
import Combine
import CoreMotion

// MARK: - Device motion (parallax tilt)

@MainActor
final class MotionManager: ObservableObject {
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let d = data else { return }
            // smooth a little so the card glides
            self?.roll  += (d.attitude.roll  - (self?.roll  ?? 0)) * 0.15
            self?.pitch += (d.attitude.pitch - (self?.pitch ?? 0)) * 0.15
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}

// MARK: - Typewriter intro → Day 1 grid card (tilts with the phone)

struct DayGridReveal: View {
    @EnvironmentObject var vm: OnboardingVM
    @StateObject private var motion = MotionManager()

    @State private var typed = ""
    @State private var caret = true
    @State private var showCard = false
    @State private var showButton = false

    private let fullText = "Your space is ready."
    private var days: Int { max(7, vm.lengthDays) }

    var body: some View {
        ZStack {
            AppColor.cream.ignoresSafeArea()
            VStack(spacing: 34) {
                // typewriter line
                (Text(typed) + Text(caret && !showButton ? "|" : " "))
                    .font(.serif(28, .bold))
                    .foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 30)

                if showCard {
                    DayGridCard(days: days)
                        .rotation3DEffect(.degrees(motion.roll * 9),  axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                        .rotation3DEffect(.degrees(-motion.pitch * 7), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                        .offset(x: CGFloat(motion.roll * 8), y: CGFloat(motion.pitch * 6))
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                if showButton {
                    PrimaryButton(title: "Let's go") { vm.next() }
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }
            }
        }
        .onAppear { motion.start(); runSequence() }
        .onDisappear { motion.stop() }
    }

    private func runSequence() {
        let chars = Array(fullText)
        for i in chars.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(i)) {
                typed = String(chars.prefix(i + 1))
            }
        }
        // blink the caret
        withAnimation(.easeInOut(duration: 0.5).repeatForever()) { caret.toggle() }

        let typingDone = 0.05 * Double(chars.count) + 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + typingDone) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) { showCard = true }
            Haptics.success()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + typingDone + 0.9) {
            withAnimation(.easeOut(duration: 0.4)) { showButton = true }
        }
    }
}

struct DayGridCard: View {
    var days: Int
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 10)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day 1").font(.serif(30, .bold)).foregroundStyle(AppColor.ink)
                    Text("\(days) day challenge")
                        .font(.sans(12)).foregroundStyle(AppColor.inkSoft)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 20)).foregroundStyle(AppColor.ink)
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<days, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(i == 0 ? AppColor.ink : AppColor.line)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if i == 0 {
                                Text("1").font(.sans(9, .bold)).foregroundStyle(.white)
                            }
                        }
                }
            }
        }
        .padding(22)
        .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
        // soft top-edge gloss to sell the "physical card" feel
        .overlay(alignment: .top) {
            Ellipse().fill(.white.opacity(0.35))
                .frame(height: 60).blur(radius: 22)
                .padding(.horizontal, 24).offset(y: -10)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 26, y: 16)
        .padding(.horizontal, 28)
    }
}
