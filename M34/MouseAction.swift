//
//  MouseAction.swift
//  M34
//
//  Created by Brad Kilshaw on 2026-08-26.
//

import CoreGraphics

/// An action that can be bound to a remappable mouse button.
///
/// Each action (other than `.none`) maps to a keyboard shortcut that is
/// synthesized and posted to the frontmost application when the button fires.
enum MouseAction: String, CaseIterable, Identifiable, Codable {
    case none
    case browserBack
    case browserForward
    case copy
    case paste
    case cut
    case closeTab
    case newTab
    case reopenClosedTab
    case refresh

    var id: String { rawValue }

    /// Human-readable name shown in the configuration UI.
    var title: String {
        switch self {
        case .none: return "Do Nothing"
        case .browserBack: return "Browser Back"
        case .browserForward: return "Browser Forward"
        case .copy: return "Copy"
        case .paste: return "Paste"
        case .cut: return "Cut"
        case .closeTab: return "Close Tab / Window"
        case .newTab: return "New Tab"
        case .reopenClosedTab: return "Reopen Closed Tab"
        case .refresh: return "Refresh"
        }
    }

    /// The keystroke synthesized for this action, or `nil` for `.none`.
    private var keystroke: (keyCode: CGKeyCode, flags: CGEventFlags)? {
        switch self {
        case .none: return nil
        // Cmd+[ and Cmd+] are the back/forward shortcuts in Safari, Chrome,
        // Firefox and Edge on macOS.
        case .browserBack: return (0x21, .maskCommand)          // [
        case .browserForward: return (0x1E, .maskCommand)       // ]
        case .copy: return (0x08, .maskCommand)                 // C
        case .paste: return (0x09, .maskCommand)                // V
        case .cut: return (0x07, .maskCommand)                  // X
        case .closeTab: return (0x0D, .maskCommand)             // W
        case .newTab: return (0x11, .maskCommand)               // T
        case .reopenClosedTab: return (0x11, [.maskCommand, .maskShift]) // Shift+Cmd+T
        case .refresh: return (0x0F, .maskCommand)              // R
        }
    }

    /// Synthesizes and posts the keystroke for this action to the system.
    func perform() {
        guard let keystroke else { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keystroke.keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keystroke.keyCode, keyDown: false)
        else { return }

        keyDown.flags = keystroke.flags
        keyUp.flags = keystroke.flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
