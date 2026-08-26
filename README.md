# M34

A tiny macOS menu-bar app that remaps your mouse's back and forward buttons (buttons 4 & 5) to configurable actions.

Many mice have side buttons that macOS ignores outside of a few apps. M34 intercepts them system-wide and turns them into keyboard shortcuts — by default Browser Back (⌘[) and Browser Forward (⌘]), which work in Safari, Chrome, Firefox, Edge, Finder, and most other apps.

## Features

- Remap mouse buttons 4 and 5 independently
- Built-in actions: Browser Back / Forward, Copy, Paste, Cut, Close Tab, New Tab, Reopen Closed Tab, Refresh, or Do Nothing
- Lives in the menu bar — no Dock icon
- Optional launch at login
- No network access, no telemetry, no dependencies — a few hundred lines of Swift

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16 or later to build

## Building

1. Clone the repo and open `M34.xcodeproj` in Xcode.
2. In the target's **Signing & Capabilities** tab, select your own development team (a free Personal Team works).
3. Build and run (⌘R).

## Accessibility permission

M34 uses a CoreGraphics event tap to see mouse button presses, which requires **Accessibility** access. On first launch, macOS will prompt you; grant it under **System Settings → Privacy & Security → Accessibility**. The app starts working immediately once granted — no restart needed.

This permission is per-machine and per-build-signature, so you'll be re-prompted if you rebuild with a different signing identity.

## How it works

- A `CGEvent` tap listens for `otherMouseDown`/`otherMouseUp` events only — it never observes keyboard input.
- When a bound button is pressed, the corresponding keyboard shortcut is synthesized and posted to the frontmost app, and the original mouse event is swallowed.
- Bindings are stored in `UserDefaults`; launch at login uses `SMAppService`.

## License

[MIT](LICENSE)
