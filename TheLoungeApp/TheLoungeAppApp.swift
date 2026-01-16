import SwiftUI
import AppKit

@main
struct TheLoungeApp {
    static func main() {
        // Disable Liquid Glass before anything initializes
        UserDefaults.standard.set(true, forKey: "com.apple.SwiftUI.DisableSolarium")
        UserDefaults.standard.set(true, forKey: "com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CustomWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        createAndShowWindow()
        setupMenus()

        // Listen for titlebar color changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(titlebarColorDidChange),
            name: .titlebarColorChanged,
            object: nil
        )
    }

    @objc private func titlebarColorDidChange() {
        let newColor = SettingsManager.shared.getNSColor()
        window?.updateTitlebarColor(newColor)
    }

    private func setupMenus() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About The Lounge", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit The Lounge", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+")
        viewMenu.addItem(withTitle: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-")
        viewMenu.addItem(withTitle: "Actual Size", action: #selector(resetZoom), keyEquivalent: "0")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "Settings"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func zoomIn() { WebViewStore.shared.zoomIn() }
    @objc private func zoomOut() { WebViewStore.shared.zoomOut() }
    @objc private func resetZoom() { WebViewStore.shared.resetZoom() }

    private func createAndShowWindow() {
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        let titlebarColor = SettingsManager.shared.getNSColor()

        window = CustomWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.appearance = NSAppearance(named: .darkAqua)
        window?.backgroundColor = titlebarColor
        window?.isMovableByWindowBackground = true
        window?.title = "The Lounge"
        window?.contentView = hostingView
        window?.center()

        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class CustomWindow: NSWindow {
    private var currentTitlebarColor: NSColor = SettingsManager.shared.getNSColor()

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyCustomStyle()
    }

    override func becomeKey() {
        super.becomeKey()
        applyCustomStyle()
    }

    override func resignKey() {
        super.resignKey()
        applyCustomStyle()
    }

    override func becomeMain() {
        super.becomeMain()
        applyCustomStyle()
    }

    override func resignMain() {
        super.resignMain()
        applyCustomStyle()
    }

    func updateTitlebarColor(_ color: NSColor) {
        currentTitlebarColor = color
        applyCustomStyle()
    }

    private func applyCustomStyle() {
        backgroundColor = currentTitlebarColor
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // Force titlebar background color
        if let titlebarContainer = standardWindowButton(.closeButton)?.superview?.superview {
            titlebarContainer.wantsLayer = true
            titlebarContainer.layer?.backgroundColor = currentTitlebarColor.cgColor
        }
    }
}
