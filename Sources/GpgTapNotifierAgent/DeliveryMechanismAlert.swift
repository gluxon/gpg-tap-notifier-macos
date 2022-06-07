// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import AppKit
import Foundation

class DeliveryMechanismAlert {
    private lazy var alertWindow: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)

        panel.center()
        panel.isFloatingPanel = true

        return panel
    }()

    private var currentAlert: NSAlert?
}

extension DeliveryMechanismAlert: DeliveryMechanism {
    func present(title: String, body: String) {
        guard self.currentAlert == nil else {
            return
        }

        let alert = NSAlert()

        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational

        // NOTE: According to AppKit docs, the order buttons are added affect
        // what code they're assigned in the modalResponse.
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Open Configuration")

        self.currentAlert = alert

        alert.beginSheetModal(for: alertWindow) { modalResponse in
            self.currentAlert = nil

            // Corresponds with the "Open Configuration" button since it was
            // added second. What a strange API.
            if modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn {
                openConfigurationApp()
            }
        }
    }

    func dismiss() {
        guard let alert = currentAlert else {
            return
        }
        self.currentAlert = nil
        alertWindow.endSheet(alert.window)
    }
}

func openConfigurationApp() {
    guard let configurationAppUrl = guessConfigurationAppUrl() else {
        return
    }
    NSWorkspace.shared.open(configurationAppUrl)
}

func guessConfigurationAppUrl() -> URL? {
    let agentBundleUrl = Bundle.main.bundleURL

    // The agent bundle lives within "Contents/Library/GPG Tap Notifier Agent.app". Trim these paths.
    let mainAppUrl = agentBundleUrl.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    if mainAppUrl.path.hasSuffix(".app") {
        return mainAppUrl
    }

    // The Agent app may not be inside the normal GUI app's Contents/Library dir during development.
    // Guessing from the GUI app's bundle identifier as the next
    return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.palantir.gpg-tap-notifier")
}
