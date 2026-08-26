//
//  AppSettings.swift
//  M34
//
//  Created by Brad Kilshaw on 2026-08-26.
//

import Foundation
import Observation
import ServiceManagement

/// Persisted, observable configuration for the app's button bindings and
/// launch-at-login preference. Changes are written straight through to
/// `UserDefaults` and pushed to the running ``MouseHook``.
@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let button4 = "button4Action"
        static let button5 = "button5Action"
    }

    /// Action bound to mouse button 4 (defaults to Browser Back).
    var button4Action: MouseAction {
        didSet {
            defaults.set(button4Action.rawValue, forKey: Keys.button4)
            MouseHook.shared.button4Action = button4Action
        }
    }

    /// Action bound to mouse button 5 (defaults to Browser Forward).
    var button5Action: MouseAction {
        didSet {
            defaults.set(button5Action.rawValue, forKey: Keys.button5)
            MouseHook.shared.button5Action = button5Action
        }
    }

    /// Whether the app is registered to launch at login.
    var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    private let defaults = UserDefaults.standard

    private init() {
        button4Action = defaults.string(forKey: Keys.button4)
            .flatMap(MouseAction.init(rawValue:)) ?? .browserBack
        button5Action = defaults.string(forKey: Keys.button5)
            .flatMap(MouseAction.init(rawValue:)) ?? .browserForward
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Pushes the persisted bindings into the shared hook. Called once at launch
    /// (property `didSet` observers do not run during `init`).
    func syncToHook() {
        MouseHook.shared.button4Action = button4Action
        MouseHook.shared.button5Action = button5Action
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert the toggle to reflect the real state if the change failed.
            NSLog("M34: failed to update launch-at-login: \(error.localizedDescription)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
