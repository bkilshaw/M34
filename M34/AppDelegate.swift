//
//  AppDelegate.swift
//  M34
//
//  Created by Brad Kilshaw on 2026-08-26.
//

import AppKit
import SwiftUI
import ApplicationServices

/// Owns the menu-bar status item, the configuration window, and the lifecycle
/// of the global mouse hook.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var configWindow: NSWindow?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()

        AppSettings.shared.syncToHook()
        requestAccessibilityIfNeeded()
        startHookWhenPermitted()
    }

    // MARK: - Status item

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "computermouse.fill",
            accessibilityDescription: "M34"
        )

        // A permanently attached menu means any click on the icon shows the
        // Open / Quit menu; the window only ever opens from the Open item.
        let menu = NSMenu()
        let open = NSMenuItem(title: "Open", action: #selector(openConfigWindow), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu

        statusItem = item
    }

    // MARK: - Configuration window

    @objc private func openConfigWindow() {
        // Defer to the next run-loop tick so that, when invoked from the
        // right-click menu, the menu's modal tracking loop has fully finished.
        // Presenting a window from inside that loop otherwise gets swallowed.
        Task { @MainActor in
            self.presentConfigWindow()
        }
    }

    private func presentConfigWindow() {
        if configWindow == nil {
            // Let the SwiftUI content drive the window size.
            let hosting = NSHostingController(rootView: ConfigView())
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.title = "M34"
            window.isReleasedWhenClosed = false
            window.setContentSize(hosting.view.fittingSize)
            window.center()
            configWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        configWindow?.makeKeyAndOrderFront(nil)
        configWindow?.orderFrontRegardless()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Accessibility permission

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Starts the hook now if permitted, otherwise polls until permission is
    /// granted (the tap can only be created once the app is trusted).
    private func startHookWhenPermitted() {
        MouseHook.shared.start()
        guard !MouseHook.shared.isRunning else { return }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                MouseHook.shared.start()
                if MouseHook.shared.isRunning {
                    timer.invalidate()
                    self?.permissionTimer = nil
                }
            }
        }
    }
}
