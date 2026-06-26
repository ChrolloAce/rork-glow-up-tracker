import SwiftUI
import CoreText
import SuperwallKit
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct GlowUpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var auth = AuthService.shared

    init() {
        FontLoader.registerAll()
        Superwall.configure(apiKey: "pk_g0izh0xV3YAoFlTRZCs90")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .task { auth.bootstrap() }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

/// Registers the bundled Playfair Display fonts at runtime (no Info.plist needed).
enum FontLoader {
    static func registerAll() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

/// Shows the onboarding flow on first launch, then the main app.
struct RootView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false

    var body: some View {
        if didCompleteOnboarding {
            ContentView()
        } else {
            OnboardingFlow {
                withAnimation(.easeInOut(duration: 0.4)) {
                    didCompleteOnboarding = true
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
