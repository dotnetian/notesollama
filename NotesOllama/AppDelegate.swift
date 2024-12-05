import Foundation
import SwiftUI
import AXSwift

let PANEL_HEIGHT: CGFloat = 22
let PANEL_WIDTH: CGFloat = 46

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject, NSWindowDelegate {
    private var menuPanel: NSPanel?
    private var window: NSWindow?
    
    var authorizationCheckTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if getIsAuthorized() {
            let hideWelcomeMessage = UserDefaults.standard.bool(forKey: "hideWelcomeMessage")
            
            if !hideWelcomeMessage {
                self.showWindow(view: WelcomeView(onGotItClicked: {
                    self.hideWindow()
                }))
            }
            
            addMenuPanel()
        } else {
            let authorizeView = AuthorizeView()
            showWindow(view: authorizeView)
            
            // Set up a repeating timer to check for authorization
            authorizationCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                if self?.getIsAuthorized() ?? false {
                    self?.authorizationGranted()
                }
            }
        }
        
        if isAppAlreadyRunning() {
            showAlreadyRunningAlert()
        }
    }
    
    func getIsAuthorized() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false, ]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func authorizationGranted() {
        // Invalidate the timer
        authorizationCheckTimer?.invalidate()
        authorizationCheckTimer = nil
        
        hideWindow()

        addMenuPanel()
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showWindow(view: WelcomeView(onGotItClicked: {
                self.hideWindow()
            }))
        }
    }

    func showAlreadyRunningAlert() {
        // Show an error dialog
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = "An instance of NotesOllama is already running."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.runModal()

        // Terminate the application
        NSApplication.shared.terminate(self)
    }
    
    func addMenuPanel() {
        menuPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: PANEL_WIDTH, height: PANEL_HEIGHT),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        menuPanel?.backgroundColor = NSColor.clear
        menuPanel?.isOpaque = false
        menuPanel?.hasShadow = false
        menuPanel?.level = .floating
        menuPanel?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: MenuView(
            updatePanelPosition: self.updatePanelPosition
        ))
        menuPanel?.contentView = hostingView
    }
    
    func updatePanelPosition(position: CGPoint?) {
        if let position {
            guard let screen = NSScreen.main else { return }
            let newFrame = NSRect(x: position.x - PANEL_WIDTH - 20, y: screen.frame.height - position.y + PANEL_HEIGHT, width: PANEL_WIDTH, height: PANEL_HEIGHT)
            menuPanel?.setFrame(newFrame, display: true)
            menuPanel?.level = .floating
            menuPanel?.makeKeyAndOrderFront(nil)
        } else {
            menuPanel?.level = .normal
            menuPanel?.orderOut(nil)
        }
    }
    
    func showWindow(view: some View) {
        if let window {
            hideWindow()
        }
                
        // Create the window and set the content view
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window?.center()
        window?.contentView = NSHostingView(rootView: view)
        window?.delegate = self

        // Set the toolbar style to unified
        let toolbar = NSToolbar()
        toolbar.showsBaselineSeparator = false
        window?.toolbar = toolbar
        window?.toolbarStyle = .unifiedCompact
        
        // Keep the window at the front
        window?.level = NSWindow.Level.floating
        window?.makeKeyAndOrderFront(nil)
    }

    func hideWindow() {
        window?.level = NSWindow.Level.normal
        window?.orderOut(nil)
        window = nil
    }
    
    func windowWillClose(_ notification: Notification) {
        if !getIsAuthorized() {
            NSApplication.shared.terminate(self)
        }
    }
    
    func isAppAlreadyRunning() -> Bool {
        Application.allForBundleID(Bundle.main.bundleIdentifier ?? "").count > 1
    }
}
