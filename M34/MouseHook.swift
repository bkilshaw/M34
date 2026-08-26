//
//  MouseHook.swift
//  M34
//
//  Created by Brad Kilshaw on 2026-08-26.
//

import CoreGraphics
import ApplicationServices

/// Installs a global event tap that intercepts the "back" (button 4) and
/// "forward" (button 5) mouse buttons and remaps them to configurable actions.
///
/// The tap is created on, and its callback runs on, the main run loop. The
/// current bindings are plain stored properties updated from the main actor,
/// so all access happens on a single thread.
nonisolated final class MouseHook: @unchecked Sendable {
    static let shared = MouseHook()

    /// Action bound to mouse button 4 (the "back" button, reported as 3).
    var button4Action: MouseAction = .browserBack
    /// Action bound to mouse button 5 (the "forward" button, reported as 4).
    var button5Action: MouseAction = .browserForward

    private var eventTap: CFMachPort?

    private init() {}

    /// Whether the event tap is currently installed and running.
    var isRunning: Bool { eventTap != nil }

    /// Attempts to install the event tap. Idempotent, and a no-op when the tap
    /// is already running or when Accessibility permission has not been granted
    /// (in which case `CGEvent.tapCreate` returns `nil`).
    func start() {
        guard eventTap == nil else { return }

        let mask = (1 << CGEventType.otherMouseDown.rawValue)
            | (1 << CGEventType.otherMouseUp.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let hook = Unmanaged<MouseHook>.fromOpaque(refcon).takeUnretainedValue()
            return hook.handle(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }

        // The run loop retains the source, which in turn keeps the tap alive.
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
    }

    /// Handles a tapped mouse event. Returns `nil` to swallow the event or the
    /// original event to let it pass through untouched.
    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable the tap if the system disabled it (e.g. we were too slow).
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        let button = event.getIntegerValueField(.mouseEventButtonNumber)
        let action: MouseAction
        switch button {
        case 3: action = button4Action
        case 4: action = button5Action
        default: return Unmanaged.passUnretained(event)
        }

        // Leave the button untouched when it is unbound so its native behavior
        // (if any) is preserved.
        guard action != .none else { return Unmanaged.passUnretained(event) }

        // Fire on the down event only, then swallow both down and up so the
        // remapped button never triggers its default behavior as well.
        if type == .otherMouseDown {
            action.perform()
        }
        return nil
    }
}
