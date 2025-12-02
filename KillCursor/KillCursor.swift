import Cocoa
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menu: NSMenu?
    
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
        
        let killItem = NSMenuItem(title: "Kill Cursor", action: #selector(killCursor), keyEquivalent: "k")
        killItem.target = self
        menu?.addItem(killItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
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
    
    @objc func killCursor() {
        // Find and kill all Cursor processes
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["-9", "Cursor"]
        
        let pipe = Pipe()
        task.standardError = pipe
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // Show notification if successful
            if task.terminationStatus == 0 {
                showNotification(title: "Cursor Killed", message: "All Cursor processes have been terminated.")
            } else {
                // Process not found
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                if output.contains("No matching processes") {
                    showNotification(title: "Cursor Not Found", message: "No running Cursor process found.")
                } else {
                    showNotification(title: "Error", message: "An error occurred while killing Cursor.")
                }
            }
        } catch {
            showNotification(title: "Error", message: "Error: \(error.localizedDescription)")
        }
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Kill Cursor"
        alert.informativeText = "This app was created to solve a problem: even after quitting Cursor IDE, it continues running in the background and consumes significant battery power. Kill Cursor allows you to completely terminate all Cursor processes with a single click.\n\nThis project is open source and available under the MIT License.\n\nMade by Ahmet Bugra Avcilar\n© 2025"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Visit Website")
        alert.addButton(withTitle: "OK")
        
        // Load app icon - use NSApp.applicationIconImage first to get proper styling
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
