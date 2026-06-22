import Foundation

nonisolated enum AvatarCatalog {
    static let all: [String] = (1...50).map { "character_\($0)" }

    static func isLocal(_ identifier: String) -> Bool {
        identifier.hasPrefix("character_")
    }

    static var defaultAvatar: String { "character_1" }
}
