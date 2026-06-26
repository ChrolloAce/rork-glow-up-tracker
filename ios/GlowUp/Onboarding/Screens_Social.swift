import SwiftUI

// 25 — Make it official (sticker)
struct StickerScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.sticker.progress, onBack: vm.back) {
            VStack(spacing: 22) {
                PhoneMock {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 40)).foregroundStyle(Color(hex: "E8643C"))
                        Text("day one").font(.serif(20))
                        Text("It's official 🎉").font(.sans(13)).foregroundStyle(AppColor.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                }
                Display(lead: "Make ", emph: "it", tail: " official", size: 30)
            }
        } footer: {
            PrimaryButton(title: "Get my sticker", systemImage: "square.and.arrow.up") { vm.next() }
            Button("Skip") { vm.next() }.font(.sans(13)).foregroundStyle(AppColor.inkSoft)
        }
    }
}
