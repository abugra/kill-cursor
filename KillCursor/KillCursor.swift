import Cocoa
import AppKit
import UserNotifications
import ServiceManagement
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menu: NSMenu?
    var statusMenuItem: NSMenuItem?
    var launchAtLoginItem: NSMenuItem?
    var cursorStatusTimer: Timer?
    var isCursorRunning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Update icon based on current appearance
        updateStatusBarIcon()

        // Observe appearance changes
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusBarIcon),
            name: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )

        // Create menu
        menu = NSMenu()

        let aboutItem = NSMenuItem(title: "About Kill Cursor", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu?.addItem(aboutItem)

        menu?.addItem(NSMenuItem.separator())

        // Cursor status indicator
        statusMenuItem = NSMenuItem(title: "Cursor: Checking...", action: nil, keyEquivalent: "")
        statusMenuItem?.isEnabled = false
        menu?.addItem(statusMenuItem!)

        menu?.addItem(NSMenuItem.separator())

        let killItem = NSMenuItem(title: "Kill Cursor", action: #selector(killCursor), keyEquivalent: "k")
        killItem.target = self
        menu?.addItem(killItem)

        menu?.addItem(NSMenuItem.separator())

        // Launch at Login toggle
        launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem?.target = self
        updateLaunchAtLoginState()
        menu?.addItem(launchAtLoginItem!)

        menu?.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)

        statusItem?.menu = menu

        // Start Cursor status polling
        checkCursorStatus()
        cursorStatusTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkCursorStatus), userInfo: nil, repeats: true)

        // Register global hotkey (Cmd+Shift+K)
        registerGlobalHotkey()
    }

    // MARK: - Global Hotkey

    func registerGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd+Shift+K
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 40 { // 40 = 'k'
                self?.killCursor()
            }
        }
    }

    // MARK: - Cursor Status

    @objc func checkCursorStatus() {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-x", "Cursor"]
        task.standardOutput = Pipe()
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            let running = task.terminationStatus == 0
            DispatchQueue.main.async { [weak self] in
                self?.isCursorRunning = running
                self?.updateCursorStatusDisplay()
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isCursorRunning = false
                self?.updateCursorStatusDisplay()
            }
        }
    }

    func updateCursorStatusDisplay() {
        if isCursorRunning {
            statusMenuItem?.title = "● Cursor is running"
        } else {
            statusMenuItem?.title = "○ Cursor is not running"
        }
    }

    // MARK: - Launch at Login

    @objc func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if service.status == .enabled {
                    try service.unregister()
                } else {
                    try service.register()
                }
            } catch {
                print("Launch at Login error: \(error)")
            }
        } else {
            // For macOS 11-12, use legacy approach via user defaults flag
            let key = "LaunchAtLogin"
            let current = UserDefaults.standard.bool(forKey: key)
            UserDefaults.standard.set(!current, forKey: key)
        }
        updateLaunchAtLoginState()
    }

    func updateLaunchAtLoginState() {
        var isEnabled = false
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        }
        launchAtLoginItem?.state = isEnabled ? .on : .off
    }

    // MARK: - Status Bar Icon

    @objc func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }

        // Determine if dark mode is active
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // Load appropriate icon
        let iconName = isDarkMode ? "StatusBarIconDark" : "StatusBarIconLight"

        if let customIcon = NSImage(named: iconName) {
            customIcon.size = NSSize(width: 22, height: 22)
            button.image = customIcon
        } else if let iconPath = Bundle.main.path(forResource: iconName, ofType: "png"),
                  let customIcon = NSImage(contentsOfFile: iconPath) {
            customIcon.size = NSSize(width: 22, height: 22)
            button.image = customIcon
        } else {
            // Fallback to system symbol
            button.image = NSImage(systemSymbolName: "cursorarrow.click", accessibilityDescription: "Kill Cursor")
            button.image?.isTemplate = true
        }
    }

    // MARK: - Kill Cursor

    @objc func killCursor() {
        // Check if any Cursor process is running
        let checkTask = Process()
        checkTask.launchPath = "/usr/bin/pgrep"
        checkTask.arguments = ["-x", "Cursor"]
        checkTask.standardOutput = Pipe()
        checkTask.standardError = Pipe()

        do {
            try checkTask.run()
            checkTask.waitUntilExit()
        } catch {
            showNotification(title: "Error", message: "Failed to check Cursor status: \(error.localizedDescription)")
            return
        }

        if checkTask.terminationStatus != 0 {
            showNotification(title: "Cursor Not Running", message: "No running Cursor processes found.")
            return
        }

        // Kill all Cursor-related processes
        let processNames = ["Cursor", "Cursor Helper", "Cursor Helper (Renderer)", "Cursor Helper (GPU)", "Cursor Helper (Plugin)"]
        var killedAny = false
        var lastError: String?

        for name in processNames {
            let task = Process()
            task.launchPath = "/usr/bin/killall"
            task.arguments = ["-9", name]

            let errPipe = Pipe()
            task.standardError = errPipe
            task.standardOutput = Pipe()

            do {
                try task.run()
                task.waitUntilExit()

                if task.terminationStatus == 0 {
                    killedAny = true
                } else {
                    let data = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    if output.contains("Operation not permitted") {
                        lastError = "Permission denied. Try running the app with appropriate privileges."
                    }
                }
            } catch {
                // Silently continue for helper processes that may not exist
            }
        }

        if let error = lastError {
            showNotification(title: "Error", message: error)
        } else if killedAny {
            showNotification(title: "Cursor Killed", message: "All Cursor processes have been terminated.")
        } else {
            showNotification(title: "Error", message: "Failed to kill Cursor processes.")
        }

        // Refresh status immediately after kill
        checkCursorStatus()
    }

    // MARK: - About

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Kill Cursor"
        alert.informativeText = "This app was created to solve a problem: even after quitting Cursor IDE, it continues running in the background and consumes significant battery power. Kill Cursor allows you to completely terminate all Cursor processes with a single click.\n\nGlobal Shortcut: ⌘⇧K\n\nThis project is open source and available under the MIT License.\n\nMade by Ahmet Bugra Avcilar\n© 2025"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Visit Website")
        alert.addButton(withTitle: "OK")

        // Load app icon
        if let appIcon = NSApp.applicationIconImage {
            alert.icon = appIcon
        } else if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
                  let iconImage = NSImage(contentsOfFile: iconPath) {
            alert.icon = iconImage
        } else if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
                  let iconImage = NSImage(contentsOfFile: iconPath) {
            alert.icon = iconImage
        }

        let response = alert.runModal()

        // Handle "Visit Website" button click
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "https://ahm.et") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Notifications

    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification delivery error: \(error)")
            }
        }
    }
}

// Launch application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
