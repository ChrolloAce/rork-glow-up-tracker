import SwiftUI

/// Full-screen Terms of Service + Privacy Policy gate. Blocks the entire app
/// (community, profile, everything) until the user accepts.
struct TermsGateView: View {
    var onAccept: () -> Void
    @State private var agreed = false

    private let termsURL = URL(string: "https://75glowapp.vercel.app/terms.html")!
    private let privacyURL = URL(string: "https://75glowapp.vercel.app/privacy.html")!

    var body: some View {
        ZStack {
            Theme.screenGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Theme.pink)
                            Text("Before you glow")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Please review and accept our terms to continue.")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.top, 20)

                        point("Be kind", "This is a supportive community. Harassment, hate, and spam aren't allowed.")
                        point("Your content", "You're responsible for what you post. Don't share anything you don't have the right to.")
                        point("Your data", "We store your profile and progress to power the app. You can delete your account anytime in Profile.")
                        point("Not medical advice", "Glow Up is for motivation and habit-building, not medical or nutritional advice.")

                        HStack(spacing: 14) {
                            Link("Terms of Service", destination: termsURL)
                            Text("·").foregroundStyle(Theme.textTertiary)
                            Link("Privacy Policy", destination: privacyURL)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .tint(Theme.pinkDeep)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                VStack(spacing: 14) {
                    Button {
                        withAnimation(.snappy) { agreed.toggle() }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(agreed ? Theme.pink : Theme.subtleBorder, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if agreed {
                                    RoundedRectangle(cornerRadius: 7).fill(Theme.pink).frame(width: 24, height: 24)
                                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                            Text("I agree to the Terms of Service and Privacy Policy")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        onAccept()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Capsule().fill(agreed
                                    ? LinearGradient(colors: [Theme.pink, Theme.pinkDeep], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Theme.textTertiary, Theme.textTertiary], startPoint: .leading, endPoint: .trailing))
                            )
                    }
                    .disabled(!agreed)
                    .sensoryFeedback(.success, trigger: agreed)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(.ultraThinMaterial)
            }
        }
        .preferredColorScheme(.light)
        .interactiveDismissDisabled()
    }

    private func point(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.pink)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text(body).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
