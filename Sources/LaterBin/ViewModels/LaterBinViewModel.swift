import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class LaterBinViewModel: ObservableObject {
    @Published var items: [LaterBinItem] = []
    @Published var isHovering = false
    @Published var isEdgeTargeted = false
    
    private let saveURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("LaterBin")
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        saveURL = appDirectory.appendingPathComponent("items.json")
    }
    
    func setup() {
        loadItems()
        removeExpiredItems()
    }
    
    private func loadItems() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        if let decoded = try? JSONDecoder().decode([LaterBinItem].self, from: data) {
            self.items = decoded.sorted(by: { $0.createdAt > $1.createdAt })
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            try? encoded.write(to: saveURL)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("ItemsChanged"), object: nil)
        }
    }
    
    func removeExpiredItems() {
        let now = Date()
        let originalCount = items.count
        items.removeAll { item in
            if let expiresAt = item.expiresAt {
                return expiresAt < now
            }
            return false
        }
        if items.count < originalCount {
            saveItems()
        }
    }
    
    func addFile(url: URL, retention: RetentionPeriod) {
        if items.contains(where: { $0.lastKnownURL?.path == url.path }) {
            print("Item already in LaterBin")
            return
        }
        
        do {
            let bookmark = try FileReferenceService.shared.createBookmark(for: url)
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let item = LaterBinItem(
                displayName: url.lastPathComponent,
                bookmarkData: bookmark,
                lastKnownURL: url,
                createdAt: Date(),
                expiresAt: retention.expirationDate(),
                isFolder: isDir
            )
            items.insert(item, at: 0)
            saveItems()
        } catch {
            print("Failed to add file: \(error)")
        }
    }
    
    func remove(item: LaterBinItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func handleDrop(providers: [NSItemProvider], retention: RetentionPeriod) -> Bool {
        // Bulletproof Native macOS Approach:
        // Read directly from the drag pasteboard synchronously.
        // This avoids SwiftUI NSItemProvider async cancellation bugs and @Sendable warnings entirely.
        let pasteboard = NSPasteboard(name: .drag)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            for url in urls {
                // adding is synchronous and safe
                self.addFile(url: url, retention: retention)
            }
            return true
        }
        
        // Fallback to basic string parsing from pasteboard if NSURL class loading fails
        if let items = pasteboard.pasteboardItems {
            var handled = false
            for item in items {
                if let stringData = item.string(forType: .fileURL), let url = URL(string: stringData) {
                    self.addFile(url: url, retention: retention)
                    handled = true
                }
            }
            return handled
        }
        
        return false
    }
}
