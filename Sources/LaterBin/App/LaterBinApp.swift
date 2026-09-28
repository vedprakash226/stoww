import SwiftUI
import AppKit

@main
struct LaterBinApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // No default SwiftUI scenes; AppDelegate handles the UI
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var settings = AppSettings()
    var viewModel = LaterBinViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel.setup()
        
        let contentView = LaterBinView()
            .environmentObject(settings)
            .environmentObject(viewModel)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 450)
        popover.behavior = .applicationDefined // This prevents it from closing when clicking Finder
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray", accessibilityDescription: "LaterBin")
            button.action = #selector(togglePopover)
        }
        
        // Observe item count
        NotificationCenter.default.addObserver(self, selector: #selector(updateBadge), name: NSNotification.Name("ItemsChanged"), object: nil)
        updateBadge()
        
        setupNotchWindow()
    }
    
    var notchWindow: NSWindow?
    var dragMonitorTimer: Timer?
    var lastDragChangeCount: Int = 0
    
    func setupNotchWindow() {
        let notchView = NotchDropView()
            .environmentObject(settings)
            .environmentObject(viewModel)
            
        let hostingController = NSHostingController(rootView: notchView)
        hostingController.view.backgroundFilters = []
        
        notchWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 240),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        notchWindow?.isReleasedWhenClosed = false
        notchWindow?.isOpaque = false
        notchWindow?.backgroundColor = .clear
        notchWindow?.hasShadow = false
        notchWindow?.ignoresMouseEvents = false
        notchWindow?.level = .popUpMenu // Level 101, floats above normal windows but accepts drags
        notchWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        notchWindow?.contentViewController = hostingController
        
        positionNotchWindow()
        
        lastDragChangeCount = NSPasteboard(name: .drag).changeCount
        dragMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkDragState()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideNotchWindow), name: NSNotification.Name("HideNotchWindow"), object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowProSuccess"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.positionNotchWindow()
                self?.notchWindow?.makeKeyAndOrderFront(nil)
                
                // Wait for the transparent NSWindow to physically render on screen
                try? await Task.sleep(nanoseconds: 100_000_000)
                self?.viewModel.showProSuccess = true
                
                // Show for 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.viewModel.showProSuccess = false
                
                // Wait for SwiftUI slide-up animation to complete before destroying the window
                try? await Task.sleep(nanoseconds: 500_000_000)
                self?.hideNotchWindow()
            }
        }
    }
    
    func positionNotchWindow() {
        let mouseLoc = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main
        guard let validScreen = screen, let window = notchWindow else { return }
        
        let screenRect = validScreen.frame
        let x = screenRect.minX + (screenRect.width - window.frame.width) / 2
        let y = screenRect.maxY - window.frame.height
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    @objc func hideNotchWindow() {
        notchWindow?.orderOut(nil)
    }
    
    @objc func checkDragState() {
        let currentCount = NSPasteboard(name: .drag).changeCount
        let mouseButtons = NSEvent.pressedMouseButtons
        
        if mouseButtons == 0 {
            if notchWindow?.isVisible == true {
                hideNotchWindow()
                lastDragChangeCount = currentCount
            }
            return
        }
        
        if currentCount != lastDragChangeCount {
            lastDragChangeCount = currentCount
            
            if notchWindow?.isVisible == false {
                positionNotchWindow()
                notchWindow?.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    @objc func updateBadge() {
        if let button = statusItem.button {
            if settings.showItemCount && !viewModel.items.isEmpty {
                button.title = "\(viewModel.items.count)"
                button.imagePosition = .imageLeading
            } else {
                button.title = ""
                button.imagePosition = .imageOnly
            }
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                viewModel.removeExpiredItems()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
