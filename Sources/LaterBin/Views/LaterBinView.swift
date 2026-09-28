import SwiftUI
import UniformTypeIdentifiers

struct LaterBinView: View {
    @EnvironmentObject var viewModel: LaterBinViewModel
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Stow")
                    .font(.headline)
                
                if settings.isPro {
                    Text("PRO")
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Spacer()
                Button(action: { addFile() }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Add file manually")
                
                Menu {
                    if settings.isPro {
                        Text("Stow Pro Active ✦")
                            .font(.caption)
                        Divider()
                        Text("Default Retention")
                            .font(.caption)
                        
                        Picker("Retention", selection: $settings.defaultRetentionRawValue) {
                            ForEach(RetentionPeriod.allCases) { period in
                                Text(period.label).tag(period.rawValue)
                            }
                        }
                        .pickerStyle(InlinePickerStyle())
                        Divider()
                    } else {
                        Button(action: { viewModel.showUpgradeModal = true }) {
                            Text("Retention: 1 Day (Pro to unlock)")
                        }
                        Divider()
                        Button(action: { viewModel.showUpgradeModal = true }) {
                            Label("Upgrade to Stow Pro...", systemImage: "star.fill")
                        }
                        Divider()
                    }
                    
                    Toggle("Show item count in menu bar", isOn: $settings.showItemCount)
                } label: {
                    Image(systemName: "gearshape")
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .menuIndicator(.hidden)
                .frame(width: 24)
                .help("Settings")
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Quit LaterBin")
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            if viewModel.items.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        ItemView(item: item)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.remove(item: item)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            // Drop Overlay
            if viewModel.isHovering {
                VStack {
                    Image(systemName: "arrow.down.doc")
                        .font(.largeTitle)
                    Text("Drop here")
                        .font(.headline)
                    Text("I'll remember this without copying it")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
            }
        }
        .frame(width: 400, height: 450)
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isHovering) { providers in
            return viewModel.handleDrop(providers: providers, retention: settings.defaultRetention, isPro: settings.isPro)
        }
        .sheet(isPresented: $viewModel.showUpgradeModal) {
            StowProView(isPresented: $viewModel.showUpgradeModal)
                .environmentObject(settings)
        }
    }
    
    private func addFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                viewModel.addFile(url: url, retention: settings.defaultRetention, isPro: settings.isPro)
            }
        }
    }
}
