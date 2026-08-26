//
//  ContentView.swift
//  M34
//
//  Created by Brad Kilshaw on 2026-08-26.
//

import SwiftUI
import ApplicationServices

/// Configuration UI shown when the user opens the app from the menu bar.
struct ConfigView: View {
    @Bindable private var settings = AppSettings.shared
    @State private var isTrusted = AXIsProcessTrusted()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if !isTrusted {
                permissionBanner
            }

            GroupBox("Button Bindings") {
                VStack(alignment: .leading, spacing: 12) {
                    actionPicker("Mouse Button 4", selection: $settings.button4Action)
                    Divider()
                    actionPicker("Mouse Button 5", selection: $settings.button5Action)
                }
                .padding(6)
            }

            Toggle("Launch at login", isOn: $settings.launchAtLogin)
        }
        .padding(20)
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
        .task {
            // Re-check the Accessibility permission so the banner clears itself
            // once the user grants access in System Settings.
            while !Task.isCancelled {
                isTrusted = AXIsProcessTrusted()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "computermouse.fill")
                .font(.title)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("M34")
                    .font(.headline)
                Text("Remap your mouse's back & forward buttons.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var permissionBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 6) {
                Text("Accessibility permission required")
                    .font(.subheadline.weight(.semibold))
                Text("M34 needs Accessibility access to read your mouse buttons.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open System Settings") {
                    openAccessibilitySettings()
                }
                .controlSize(.small)
            }
            Spacer()
        }
        .padding(10)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private func actionPicker(_ label: String, selection: Binding<MouseAction>) -> some View {
        Picker(label, selection: selection) {
            ForEach(MouseAction.allCases) { action in
                Text(action.title).tag(action)
            }
        }
        .pickerStyle(.menu)
    }

    private func openAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    ConfigView()
}
