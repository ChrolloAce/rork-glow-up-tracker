import SwiftUI

// 21 — 87% stat
struct PartnerStatScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.partnerStat.progress, onBack: vm.back) {
            VStack(spacing: 22) {
                Spacer(minLength: 20)
                Text("87%").font(.serif(72, .medium)).foregroundStyle(AppColor.ink)
                Display(lead: "of women who\n", emph: "finished", tail: " had someone\ndoing it ", size: 22)
                Display(emph: "with them", size: 22)
                Image(systemName: "figure.2")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(AppColor.ink)
                    .padding(.top, 8)
            }
        } footer: {
            PrimaryButton(title: "Find my partner") { vm.next() }
            Button("Continue solo") { vm.step = .inviteFriends }
                .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
        }
    }
}

// 23 — Partner match
struct PartnerMatchScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.partnerMatch.progress, onBack: vm.back) {
            VStack(spacing: 18) {
                ZStack(alignment: .bottom) {
                    Image("life3").resizable().scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 6)
                    Text("● live").font(.sans(10, .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(hex: "E8643C"), in: Capsule())
                        .offset(y: 8)
                }
                .padding(.top, 10)
                Display(emph: "Amelia", size: 30)
                Text("88% match").font(.sans(15, .semibold)).foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(AppColor.chipGreen, in: Capsule())
                VStack(spacing: 8) {
                    TagChip(text: "Build discipline", color: AppColor.chipYellow)
                    TagChip(text: "Staying consistent with workouts", color: AppColor.chipGreen)
                    TagChip(text: "Mental clarity & focus", color: AppColor.chipLavender)
                }
            }
        } footer: {
            PrimaryButton(title: "Start with Amelia") { vm.next() }
            Button {
                vm.next()
            } label: {
                (Text("Prefer solo? ") + Text("Continue without partner").underline())
                    .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
            }
        }
    }
}

// 24 — Invite friends
struct InviteFriendsScreen: View {
    @EnvironmentObject var vm: OnboardingVM
    var body: some View {
        Scaffold(progress: Step.inviteFriends.progress, onBack: vm.back) {
            VStack(spacing: 22) {
                Spacer(minLength: 10)
                Display(lead: "Start the challenge\n", emph: "with your friends?", size: 26)
                Text("+30% success with friends")
                    .font(.sans(13, .semibold)).foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(AppColor.chipGreen, in: Capsule())

                VStack(spacing: 10) {
                    Text("You're invited to join")
                        .font(.sans(13)).foregroundStyle(AppColor.inkSoft)
                    Text("\(vm.name.isEmpty ? "Manuel" : vm.name)'s challenge")
                        .font(.serif(22)).foregroundStyle(AppColor.ink)
                    Text("1257 B6D8")
                        .font(.sans(20, .bold)).kerning(2).foregroundStyle(AppColor.ink)
                    Text("Use this code to join")
                        .font(.sans(11)).foregroundStyle(AppColor.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColor.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AppColor.line, lineWidth: 1))
                .shadow(color: .black.opacity(0.04), radius: 16, y: 8)
            }
        } footer: {
            HStack(spacing: 12) {
                PrimaryButton(title: "Start solo", filled: false) { vm.next() }
                PrimaryButton(title: "Send invites", systemImage: "paperplane.fill") { vm.next() }
            }
        }
    }
}

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
