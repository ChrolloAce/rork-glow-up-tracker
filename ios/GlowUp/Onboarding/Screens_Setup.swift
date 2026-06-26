import SwiftUI
import AuthenticationServices

// 17 — Set challenge length
struct LengthScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.length.progress, onBack: vm.back) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                Display(lead: "Set challenge\n", emph: "length?", size: 32)
                Text("\(vm.lengthDays) days").font(.serif(48, .bold)).foregroundStyle(AppColor.ink)
                    .contentTransition(.numericText())
                TickSlider(value: Binding(
                    get: { Double(vm.lengthDays) },
                    set: { vm.lengthDays = Int($0) }), range: 7...90)
                    .padding(.horizontal, 8)
                Text("Slide to set how many days")
                    .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

// 18/19 — Save your progress (auth)
struct SaveProgressScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    @EnvironmentObject var auth: AuthService

    var body: some View {
        Scaffold(progress: Step.saveProgress.progress, onBack: vm.back) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                Display(lead: "Save your\n", emph: "progress", size: 32)
                Text("Create an account so your streak is never lost.")
                    .font(.sans(14)).foregroundStyle(AppColor.inkSoft).multilineTextAlignment(.center)
                ProgressMarquee().padding(.top, 6)
            }
        } footer: {
            SignInWithAppleButton(.continue) { request in
                auth.prepareAppleRequest(request)
            } onCompletion: { result in
                Task {
                    await auth.handleAppleCompletion(result)
                    if !auth.displayName.isEmpty { vm.name = auth.displayName }
                    vm.next()
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            Button {
                Task {
                    await auth.signInWithGoogle()
                    if !auth.displayName.isEmpty { vm.name = auth.displayName }
                    vm.next()
                }
            } label: {
                HStack(spacing: 10) {
                    GoogleGLogo().frame(width: 19, height: 19)
                    Text("Continue with Google")
                        .font(.sans(16, .semibold)).foregroundStyle(AppColor.ink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(AppColor.line, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button("Maybe later") { vm.next() }
                .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
        }
    }
}

// MARK: - Day 1 → Day 75 sliding image marquee

struct ProgressMarquee: View {
    private let images = Collage.glow + Collage.fit
    private let itemW: CGFloat = 84
    private let spacing: CGFloat = 10
    @State private var shift: CGFloat = 0

    var body: some View {
        let loopWidth = CGFloat(images.count) * (itemW + spacing)
        VStack(spacing: 10) {
            // Fixed-width container; the wide moving strip lives in an overlay so it
            // can't expand the layout (which was pushing the footer buttons out of bounds).
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 104)
                .overlay(alignment: .leading) {
                    HStack(spacing: spacing) {
                        ForEach(Array((images + images).enumerated()), id: \.offset) { _, name in
                            Image(name).resizable().scaledToFill()
                                .frame(width: itemW, height: 104)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white, lineWidth: 2))
                        }
                    }
                    .offset(x: shift)
                    .fixedSize()
                }
            .clipped()
            .mask(
                LinearGradient(colors: [.clear, .black, .black, .black, .clear],
                               startPoint: .leading, endPoint: .trailing)
            )
            .overlay(alignment: .leading) { dayTag("Day 1") }
            .overlay(alignment: .trailing) { dayTag("Day 75") }

            HStack(spacing: 6) {
                Text("Day 1").font(.sans(11, .semibold)).foregroundStyle(AppColor.inkSoft)
                Rectangle().fill(AppColor.line).frame(height: 1)
                Text("Day 75").font(.sans(11, .semibold)).foregroundStyle(AppColor.inkSoft)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
                shift = -loopWidth
            }
        }
    }

    private func dayTag(_ t: String) -> some View {
        Text(t)
            .font(.sans(10, .bold)).foregroundStyle(AppColor.ink)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            .padding(8)
    }
}

/// Google's multi-color "G" mark for the sign-in button.
struct GoogleGLogo: View {
    var body: some View {
        Text("G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "4285F4"), Color(hex: "34A853"),
                        Color(hex: "FBBC05"), Color(hex: "EA4335"),
                        Color(hex: "4285F4")]),
                    center: .center, angle: .degrees(-90))
            )
    }
}

