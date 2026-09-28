import Foundation

struct StowItem: Identifiable, Codable {
    var id: UUID
    var displayName: String
    var bookmarkData: Data
    var lastKnownURL: URL?
    var createdAt: Date
    var expiresAt: Date?
    var isFolder: Bool
    
    init(id: UUID = UUID(), displayName: String, bookmarkData: Data, lastKnownURL: URL? = nil, createdAt: Date = Date(), expiresAt: Date? = nil, isFolder: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.bookmarkData = bookmarkData
        self.lastKnownURL = lastKnownURL
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isFolder = isFolder
    }
}
