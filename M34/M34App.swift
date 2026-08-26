//
//  M34App.swift
//  M34
//
//  Created by Brad Kilshaw on 2026-08-26.
//

import SwiftUI

@main
struct M34App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The app lives in the menu bar; its window is managed by AppDelegate.
        // An empty Settings scene satisfies the App protocol without showing UI.
        Settings {
            EmptyView()
        }
    }
}
