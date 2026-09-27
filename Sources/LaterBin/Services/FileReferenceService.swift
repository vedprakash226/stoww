import Foundation
import AppKit

enum FileReferenceError: Error {
    case bookmarkCreationError
    case resolutionFailed
}

final class FileReferenceService {
    static let shared = FileReferenceService()
    
    private init() {}
    
    func createBookmark(for url: URL) throws -> Data {
        // First try to create a security-scoped bookmark.
        // If the app is not sandboxed, this might throw or silently fallback depending on macOS.
        // We will try withSecurityScope, if it fails, try without.
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            return bookmark
        } catch {
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            return bookmark
        }
    }
    
    func resolveBookmark(data: Data) throws -> URL {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                // If stale, the caller might want to update the bookmark, but for MVP we just return it.
                // In a real app we'd update the bookmark data.
            }
            return url
        } catch {
            let url = try URL(resolvingBookmarkData: data, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
            return url
        }
    }
    
    func openFile(at data: Data) {
        do {
            let url = try resolveBookmark(data: data)
            let _ = url.startAccessingSecurityScopedResource()
            NSWorkspace.shared.open(url)
            // Note: technically we should stopAccessingSecurityScopedResource() at some point,
            // but for simple `open` NSWorkspace handles launching the appropriate app.
        } catch {
            print("Failed to open file: \(error)")
        }
    }
    
    func revealInFinder(data: Data) {
        do {
            let url = try resolveBookmark(data: data)
            let _ = url.startAccessingSecurityScopedResource()
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            print("Failed to reveal file: \(error)")
        }
    }
}
