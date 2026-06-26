import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

/// Central authentication for the app: anonymous session by default (so the
/// community is always readable/writable), upgraded in place to Apple or Google.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var user: User?
    @Published var displayName: String = ""
    @Published var errorMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    var uid: String? { user?.uid }
    /// True only once the user has linked a real provider (not anonymous).
    var isSignedIn: Bool { (user != nil) && !(user?.isAnonymous ?? true) }

    private init() {}

    /// Call once Firebase is configured (from the root view's `.task`).
    func bootstrap() {
        if handle == nil {
            handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor in
                    self?.user = user
                    if let name = user?.displayName, !name.isEmpty { self?.displayName = name }
                }
            }
        }
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { _, error in
                if let error { print("Anonymous sign-in failed:", error.localizedDescription) }
            }
        }
    }

    // MARK: - Google

    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google sign-in isn't configured yet. Enable Google in Firebase Auth and re-download GoogleService-Info.plist."
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        guard let root = Self.rootViewController() else { return }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            guard let idToken = result.user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await linkOrSignIn(with: credential)
            if let name = result.user.profile?.name, displayName.isEmpty { try? await updateName(name) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let authorization):
            guard
                let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleCredential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else { return }
            let credential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )
            do {
                try await linkOrSignIn(with: credential)
                if let given = appleCredential.fullName?.givenName, displayName.isEmpty {
                    try? await updateName(given)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Shared

    /// Upgrade the anonymous account in place when possible, else sign in normally.
    private func linkOrSignIn(with credential: AuthCredential) async throws {
        if let current = Auth.auth().currentUser, current.isAnonymous {
            do {
                let result = try await current.link(with: credential)
                user = result.user
                return
            } catch {
                // The credential already maps to a real account — sign into it.
            }
        }
        let result = try await Auth.auth().signIn(with: credential)
        user = result.user
    }

    func updateName(_ name: String) async throws {
        let change = Auth.auth().currentUser?.createProfileChangeRequest()
        change?.displayName = name
        try await change?.commitChanges()
        displayName = name
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    /// Permanently delete the user's account and their profile document.
    /// Returns true on success; sets `errorMessage` (e.g. requires recent login) otherwise.
    @discardableResult
    func deleteAccount() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        let uid = user.uid
        // best-effort cleanup of the leaderboard profile doc
        try? await Firestore.firestore().collection("users").document(uid).delete()
        do {
            try await user.delete()
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
            return true
        } catch {
            errorMessage = (error as NSError).code == AuthErrorCode.requiresRecentLogin.rawValue
                ? "For your security, please sign in again before deleting your account."
                : error.localizedDescription
            return false
        }
    }

    // MARK: - Helpers

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            _ = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
