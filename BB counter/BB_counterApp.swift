//
//  BB_counterApp.swift
//  BB counter
//
//  Created by user on 2026/1/18.
//

import SwiftUI

@main
struct BB_counterApp: App {
    init() {
        if CommandLine.arguments.contains("-uiTestingResetDefaults") {
            [
                "chips",
                "bigBlind",
                "timerEnabled",
                "timerDurationSec",
                "hasCompletedOnboarding",
                "chipBreakdown",
                "customBlindStructure",
                "customBlindCurrentIndex",
                "dontShowResetConfirmation"
            ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
