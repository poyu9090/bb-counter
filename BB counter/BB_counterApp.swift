//
//  BB_counterApp.swift
//  BB counter
//
//  Created by user on 2026/1/18.
//

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct BB_counterApp: App {
    init() {
        #if canImport(FirebaseCore)
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        #endif

        if CommandLine.arguments.contains("-uiTestingResetDefaults") {
            [
                "chips",
                "smallBlind",
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
                "allInRangePromptImpressions",
                "allInRangePromptTaps"
            ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
            AppAnalytics.resetForUITesting()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
