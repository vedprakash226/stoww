import SwiftUI
import AppKit

@main
struct StowApp: App {
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
    var viewModel = StowViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel.setup()
        
        let contentView = StowView()
            .environmentObject(settings)
            .environmentObject(viewModel)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 450)
        popover.behavior = .applicationDefined // This prevents it from closing when clicking Finder
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray", accessibilityDescription: "Stow")
            button.action = #selector(togglePopover)
        }
        
        // Observe item count
        NotificationCenter.default.addObserver(self, selector: #selector(updateBadge), name: NSNotification.Name("ItemsChanged"), object: nil)
        updateBadge()
        
        viewModel.validateLicenseSilently(settings: settings)
        
        setupNotchWindow()
    }
    
    var notchWindow: NSWindow?
    var leftEdgeWindow: NSWindow?
    var rightEdgeWindow: NSWindow?
    var dragMonitorTimer: Timer?
    var lastDragChangeCount: Int = 0
    
    func setupNotchWindow() {
        let notchView = NotchDropView()
            .environmentObject(settings)
            .environmentObject(viewModel)
            
        let hostingController = NSHostingController(rootView: notchView)
        hostingController.view.backgroundFilters = []
        
        notchWindow = createDropWindow(content: hostingController, rect: NSRect(x: 0, y: 0, width: 260, height: 240))
        
        let leftView = SideDropView(isLeft: true)
            .environmentObject(settings)
            .environmentObject(viewModel)
        leftEdgeWindow = createDropWindow(content: NSHostingController(rootView: leftView), rect: NSRect(x: 0, y: 0, width: 220, height: 200))
        
        let rightView = SideDropView(isLeft: false)
            .environmentObject(settings)
            .environmentObject(viewModel)
        rightEdgeWindow = createDropWindow(content: NSHostingController(rootView: rightView), rect: NSRect(x: 0, y: 0, width: 220, height: 200))
        
        positionDropWindows()
        
        lastDragChangeCount = NSPasteboard(name: .drag).changeCount
        dragMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkDragState()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideDropWindows), name: NSNotification.Name("HideNotchWindow"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideDropWindows), name: NSNotification.Name("HideEdgeWindows"), object: nil)
    }
    
    func createDropWindow<T: NSViewController>(content: T, rect: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.level = .popUpMenu
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentViewController = content
        return window
    }
    
    func positionDropWindows() {
        let mouseLoc = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main
        guard let validScreen = screen else { return }
        
        let screenRect = validScreen.frame
        
        if let notch = notchWindow {
            let x = screenRect.minX + (screenRect.width - notch.frame.width) / 2
            let y = screenRect.maxY - notch.frame.height
            notch.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        if let left = leftEdgeWindow {
            let y = screenRect.minY + (screenRect.height - left.frame.height) / 2
            left.setFrameOrigin(NSPoint(x: screenRect.minX, y: y))
        }
        
        if let right = rightEdgeWindow {
            let y = screenRect.minY + (screenRect.height - right.frame.height) / 2
            right.setFrameOrigin(NSPoint(x: screenRect.maxX - right.frame.width, y: y))
        }
    }
    
    @objc func hideDropWindows() {
        notchWindow?.orderOut(nil)
        leftEdgeWindow?.orderOut(nil)
        rightEdgeWindow?.orderOut(nil)
    }
    
    @objc func checkDragState() {
        let currentCount = NSPasteboard(name: .drag).changeCount
        let mouseButtons = NSEvent.pressedMouseButtons
        
        if mouseButtons == 0 {
            if notchWindow?.isVisible == true || leftEdgeWindow?.isVisible == true {
                hideDropWindows()
                lastDragChangeCount = currentCount
            }
            return
        }
        
        if currentCount != lastDragChangeCount {
            lastDragChangeCount = currentCount
            
            if notchWindow?.isVisible == false {
                positionDropWindows()
                notchWindow?.makeKeyAndOrderFront(nil)
                leftEdgeWindow?.makeKeyAndOrderFront(nil)
                rightEdgeWindow?.makeKeyAndOrderFront(nil)
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
                viewModel.validateLicenseSilently(settings: settings)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
