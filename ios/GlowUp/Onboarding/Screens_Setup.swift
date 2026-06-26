import SwiftUI
import AuthenticationServices

// 16 — When do you start?
struct StartDateScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.startDate.progress, onBack: vm.back) {
            VStack(spacing: 26) {
                Display(lead: "When\ndo ", emph: "you", tail: " start?", size: 32)
                Picker("", selection: $vm.startToday) {
                    Text("Today").tag(true)
                    Text("Pick a date").tag(false)
                }
                .pickerStyle(.segmented)
                Ruler()
                Text(vm.startToday ? "Sat, Jun 20" : "Mon, Jun 22")
                    .font(.serif(20)).foregroundStyle(AppColor.ink)
                CollageGrid(count: 3, seed: 3).frame(height: 120).clipped()
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

// 17 — Set challenge length
struct LengthScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var endDate: String {
        switch vm.lengthDays {
        case ..<40: return "Sun, Aug 3"
        case 40..<70: return "Tue, Aug 26"
        default: return "Wed, Sep 2"
        }
    }
    var body: some View {
        Scaffold(progress: Step.length.progress, onBack: vm.back) {
            VStack(spacing: 24) {
                Display(lead: "Set challenge\n", emph: "length?", size: 32)
                Text("\(vm.lengthDays) days").font(.serif(40)).foregroundStyle(AppColor.ink)
                Slider(value: Binding(
                    get: { Double(vm.lengthDays) },
                    set: { vm.lengthDays = Int($0) }), in: 7...90, step: 1)
                    .tint(AppColor.ink)
                Text("Fri, Jun 19  →  \(endDate)")
                    .font(.sans(14)).foregroundStyle(AppColor.inkSoft)
                CollageGrid(count: 3, seed: 6).frame(height: 120).clipped()
            }
        } footer: {
            PrimaryButton(title: "Continue") { vm.next() }
        }
    }
}

struct Ruler: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<30, id: \.self) { i in
                Rectangle().fill(i == 15 ? AppColor.ink : AppColor.line)
                    .frame(width: i == 15 ? 2 : 1, height: i % 5 == 0 ? 22 : 14)
            }
        }
        .frame(height: 26)
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
                CollageGrid(count: 3, seed: 2).frame(height: 110).clipped()
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
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            PrimaryButton(title: "Continue with Google", filled: false) {
                Task {
                    await auth.signInWithGoogle()
                    if !auth.displayName.isEmpty { vm.name = auth.displayName }
                    vm.next()
                }
            }

            Button("Maybe later") { vm.next() }
                .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
        }
    }
}

