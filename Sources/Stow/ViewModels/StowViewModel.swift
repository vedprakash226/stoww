import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class StowViewModel: ObservableObject {
    @Published var items: [StowItem] = []
    @Published var isHovering = false
    @Published var isNotchTargeted = false
    @Published var isLeftTargeted = false
    @Published var isRightTargeted = false
    @Published var showUpgradeModal = false
    
    private let saveURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("Stow")
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        saveURL = appDirectory.appendingPathComponent("items.json")
    }
    
    func setup() {
        loadItems()
        removeExpiredItems()
    }
    
    private func loadItems() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        if let decoded = try? JSONDecoder().decode([StowItem].self, from: data) {
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
    
    func addFile(url: URL, retention: RetentionPeriod, isPro: Bool) {
        if !isPro && items.count >= 3 {
            showUpgradeModal = true
            return
        }
        
        if items.contains(where: { $0.lastKnownURL?.path == url.path }) {
            print("Item already in Stow")
            return
        }
        
        do {
            let bookmark = try FileReferenceService.shared.createBookmark(for: url)
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let item = StowItem(
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
    
    func remove(item: StowItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func handleDrop(providers: [NSItemProvider], retention: RetentionPeriod, isPro: Bool) -> Bool {
        // Bulletproof Native macOS Approach:
        // Read directly from the drag pasteboard synchronously.
        // This avoids SwiftUI NSItemProvider async cancellation bugs and @Sendable warnings entirely.
        let pasteboard = NSPasteboard(name: .drag)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            for url in urls {
                // adding is synchronous and safe
                self.addFile(url: url, retention: retention, isPro: isPro)
            }
            return true
        }
        
        // Fallback to basic string parsing from pasteboard if NSURL class loading fails
        if let items = pasteboard.pasteboardItems {
            var handled = false
            for item in items {
                if let stringData = item.string(forType: .fileURL), let url = URL(string: stringData) {
                    self.addFile(url: url, retention: retention, isPro: isPro)
                    handled = true
                }
            }
            return handled
        }
        
        return false
    }
    
    func deactivateLicense(settings: AppSettings) {
        guard !settings.licenseKey.isEmpty, !settings.instanceID.isEmpty else {
            // Wipe local state if missing data
            settings.isPro = false
            settings.licenseKey = ""
            settings.instanceID = ""
            return
        }
        
        guard let url = URL(string: "https://api.lemonsqueezy.com/v1/licenses/deactivate") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let payload: [String: Any] = [
            "license_key": settings.licenseKey,
            "instance_id": settings.instanceID
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                settings.isPro = false
                settings.licenseKey = ""
                settings.instanceID = ""
                print("License successfully deactivated.")
            }
        }.resume()
    }
    
    func validateLicenseSilently(settings: AppSettings) {
        guard settings.isPro, !settings.licenseKey.isEmpty, !settings.instanceID.isEmpty else { return }
        
        guard let url = URL(string: "https://api.lemonsqueezy.com/v1/licenses/validate") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let payload: [String: Any] = [
            "license_key": settings.licenseKey,
            "instance_id": settings.instanceID
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            let valid = json["valid"] as? Bool ?? false
            
            DispatchQueue.main.async {
                // If the license or this specific instance is no longer valid
                if !valid {
                    settings.isPro = false
                    settings.instanceID = ""
                    print("License invalidated remotely.")
                }
            }
        }.resume()
    }
}
