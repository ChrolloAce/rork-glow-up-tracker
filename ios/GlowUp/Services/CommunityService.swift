import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// A community win/post stored in Firestore (`posts` collection).
struct FeedPost: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var username: String
    var avatar: String
    var title: String
    var body: String
    var likeCount: Int = 0
    var commentCount: Int = 0
    var likedBy: [String] = []
    var streak: Int = 0
    var level: Int = 1
    var authorID: String = ""
    @ServerTimestamp var createdAt: Timestamp?

    var isLikedByMe: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return likedBy.contains(uid)
    }

    var relativeTime: String {
        guard let date = createdAt?.dateValue() else { return "now" }
        let secs = Int(Date().timeIntervalSince(date))
        switch secs {
        case ..<60: return "now"
        case ..<3600: return "\(secs / 60)m"
        case ..<86400: return "\(secs / 3600)h"
        default: return "\(secs / 86400)d"
        }
    }
}

/// A comment on a post (`posts/{id}/comments`).
struct Comment: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var username: String
    var avatar: String
    var text: String
    var authorID: String = ""
    @ServerTimestamp var createdAt: Timestamp?

    var relativeTime: String {
        guard let date = createdAt?.dateValue() else { return "now" }
        let secs = Int(Date().timeIntervalSince(date))
        switch secs {
        case ..<60: return "now"
        case ..<3600: return "\(secs / 60)m"
        case ..<86400: return "\(secs / 3600)h"
        default: return "\(secs / 86400)d"
        }
    }
}

/// A leaderboard entry mirrored from the `users` collection.
struct LeaderRow: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var avatar: String
    var score: Int
    var level: Int
    var streak: Int
}

/// Real-time community backend: streams posts + leaderboard and writes posts/likes.
@MainActor
final class CommunityService: ObservableObject {
    static let shared = CommunityService()

    @Published private(set) var allPosts: [FeedPost] = []
    @Published var leaders: [LeaderRow] = []
    @Published private(set) var blockedIDs: Set<String> = []

    private let db = Firestore.firestore()
    private var postsListener: ListenerRegistration?
    private var leadersListener: ListenerRegistration?
    private let blockedKey = "community_blocked_ids"

    /// Posts with blocked authors filtered out.
    var posts: [FeedPost] { allPosts.filter { !blockedIDs.contains($0.authorID) } }

    private init() {
        blockedIDs = Set(UserDefaults.standard.stringArray(forKey: blockedKey) ?? [])
    }

    func start() {
        if postsListener == nil {
            postsListener = db.collection("posts")
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error { print("posts listener:", error.localizedDescription); return }
                    self?.allPosts = snapshot?.documents.compactMap { try? $0.data(as: FeedPost.self) } ?? []
                }
        }
        if leadersListener == nil {
            leadersListener = db.collection("users")
                .order(by: "score", descending: true)
                .limit(to: 50)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error { print("leaders listener:", error.localizedDescription); return }
                    self?.leaders = snapshot?.documents.compactMap { try? $0.data(as: LeaderRow.self) } ?? []
                }
        }
    }

    func createPost(username: String, avatar: String, title: String, body: String,
                    streak: Int, level: Int, completion: ((Error?) -> Void)? = nil) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let post = FeedPost(
            username: username, avatar: avatar, title: title, body: body,
            streak: streak, level: level, authorID: uid
        )
        do {
            _ = try db.collection("posts").addDocument(from: post) { error in
                if let error { print("createPost:", error.localizedDescription) }
                DispatchQueue.main.async { completion?(error) }
            }
        } catch {
            print("createPost encode:", error.localizedDescription)
            completion?(error)
        }
    }

    func toggleLike(_ post: FeedPost) {
        guard let id = post.id, let uid = Auth.auth().currentUser?.uid else { return }
        let ref = db.collection("posts").document(id)
        if post.likedBy.contains(uid) {
            ref.updateData([
                "likedBy": FieldValue.arrayRemove([uid]),
                "likeCount": FieldValue.increment(Int64(-1))
            ])
        } else {
            ref.updateData([
                "likedBy": FieldValue.arrayUnion([uid]),
                "likeCount": FieldValue.increment(Int64(1))
            ])
        }
    }

    /// Upsert the current user's leaderboard profile (`users/{uid}`).
    func syncProfile(name: String, avatar: String, score: Int, level: Int, streak: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let row = LeaderRow(name: name, avatar: avatar, score: score, level: level, streak: streak)
        do { try db.collection("users").document(uid).setData(from: row, merge: true) }
        catch { print("syncProfile:", error.localizedDescription) }
    }

    // MARK: - Comments

    /// Live-stream comments for a post; returns the listener so the caller can remove it.
    func observeComments(postID: String, onChange: @escaping ([Comment]) -> Void) -> ListenerRegistration {
        db.collection("posts").document(postID).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error { print("comments listener:", error.localizedDescription); return }
                onChange(snapshot?.documents.compactMap { try? $0.data(as: Comment.self) } ?? [])
            }
    }

    func addComment(postID: String, text: String, username: String, avatar: String,
                    completion: ((Error?) -> Void)? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { completion?(nil); return }
        let uid = Auth.auth().currentUser?.uid ?? ""
        let comment = Comment(username: username, avatar: avatar, text: trimmed, authorID: uid)
        let postRef = db.collection("posts").document(postID)
        do {
            _ = try postRef.collection("comments").addDocument(from: comment) { error in
                if error == nil {
                    postRef.updateData(["commentCount": FieldValue.increment(Int64(1))])
                }
                DispatchQueue.main.async { completion?(error) }
            }
        } catch {
            print("addComment:", error.localizedDescription)
            completion?(error)
        }
    }

    // MARK: - Moderation (report / block)

    /// Hide a user's content and remember the block locally.
    func block(_ post: FeedPost) {
        guard !post.authorID.isEmpty else { return }
        blockedIDs.insert(post.authorID)
        UserDefaults.standard.set(Array(blockedIDs), forKey: blockedKey)
    }

    func unblockAll() {
        blockedIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: blockedKey)
    }

    func isBlocked(_ post: FeedPost) -> Bool { blockedIDs.contains(post.authorID) }

    /// File a report to the `reports` collection for moderation review.
    func report(_ post: FeedPost, reason: String) {
        let reporter = Auth.auth().currentUser?.uid ?? ""
        let data: [String: Any] = [
            "postID": post.id ?? "",
            "postTitle": post.title,
            "reportedUserID": post.authorID,
            "reportedUsername": post.username,
            "reason": reason,
            "reporterID": reporter,
            "createdAt": FieldValue.serverTimestamp()
        ]
        db.collection("reports").addDocument(data: data) { error in
            if let error { print("report:", error.localizedDescription) }
        }
    }
}
