import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ItemView: View {
    @EnvironmentObject var viewModel: StowViewModel
    let item: StowItem
    
    var body: some View {
        HStack {
            Image(nsImage: icon(for: item))
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading) {
                Text(item.displayName)
                    .font(.body)
                    .lineLimit(1)
                
                if !isAvailable(item: item) {
                    Text("Original file unavailable")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if let expiresAt = item.expiresAt {
                Text(timeRemaining(to: expiresAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                viewModel.remove(item: item)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .imageScale(.medium)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 4)
            .help("Remove from Stow")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onDrag {
            let provider = NSItemProvider()
            if let url = try? FileReferenceService.shared.resolveBookmark(data: item.bookmarkData) {
                provider.registerFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier, fileOptions: [.openInPlace], visibility: .all) { completion in
                    completion(url, true, nil)
                    // We remove it from Stow when it's dragged out successfully
                    DispatchQueue.main.async {
                        viewModel.remove(item: item)
                    }
                    return nil
                }
                // Also provide a standard URL object in case receiver prefers that
                // But wait, if we register the object directly, it might bypass our closure.
                // It's better to register data representation for fileURL as well.
                provider.registerDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier, visibility: .all) { completion in
                    completion(url.dataRepresentation, nil)
                    DispatchQueue.main.async {
                        viewModel.remove(item: item)
                    }
                    return nil
                }
            }
            return provider
        }
        .onTapGesture(count: 2) {
            FileReferenceService.shared.openFile(at: item.bookmarkData)
        }
        .contextMenu {
            Button("Open") {
                FileReferenceService.shared.openFile(at: item.bookmarkData)
            }
            Button("Reveal in Finder") {
                FileReferenceService.shared.revealInFinder(data: item.bookmarkData)
            }
            Divider()
            Button("Remove from Stow") {
                viewModel.remove(item: item)
            }
        }
    }
    
    private func icon(for item: StowItem) -> NSImage {
        guard let url = try? FileReferenceService.shared.resolveBookmark(data: item.bookmarkData) else {
            return NSWorkspace.shared.icon(for: .item)
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
    
    private func isAvailable(item: StowItem) -> Bool {
        guard let url = try? FileReferenceService.shared.resolveBookmark(data: item.bookmarkData) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func timeRemaining(to date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        if diff < 0 { return "Expired" }
        
        let days = Int(diff / 86400)
        let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "Soon"
        }
    }
}
