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
                "timerRemainingSec",
                "timerIsPaused",
                "timerCountdownEndEpoch",
                "timerSelectedNextIndex",
                "timerQueuedIndices",
                "timerActiveCustomProgression",
                "hasCompletedOnboarding",
                "chipBreakdown",
                "customBlindStructure",
                "customBlindCurrentIndex",
                "customBlindStructures",
                "selectedCustomBlindStructureID",
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
