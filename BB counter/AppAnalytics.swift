import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum AppAnalytics {
    private enum Key {
        static let installID = "analytics.installID"
        static let allInRangeImpressions = "analytics.allInRange.impressions"
        static let allInRangeTaps = "analytics.allInRange.taps"
        static let allInRangeUniqueImpression = "analytics.allInRange.uniqueImpression"
        static let allInRangeUniqueTap = "analytics.allInRange.uniqueTap"
    }

    struct AllInRangeMetrics: Equatable {
        let installID: String
        let impressions: Int
        let taps: Int
        let hasSeenPrompt: Bool
        let hasTappedPrompt: Bool

        var clickThroughRate: Double {
            guard impressions > 0 else { return 0 }
            return Double(taps) / Double(impressions)
        }
    }

    static var installID: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: Key.installID), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        defaults.set(id, forKey: Key.installID)
        return id
    }

    static var allInRangeMetrics: AllInRangeMetrics {
        let defaults = UserDefaults.standard
        return AllInRangeMetrics(
            installID: installID,
            impressions: defaults.integer(forKey: Key.allInRangeImpressions),
            taps: defaults.integer(forKey: Key.allInRangeTaps),
            hasSeenPrompt: defaults.bool(forKey: Key.allInRangeUniqueImpression),
            hasTappedPrompt: defaults.bool(forKey: Key.allInRangeUniqueTap)
        )
    }

    static func trackAllInRangeImpression(bbCount: Double, chips: Int, bigBlind: Int) {
        increment(Key.allInRangeImpressions)
        UserDefaults.standard.set(true, forKey: Key.allInRangeUniqueImpression)
        log(
            "all_in_range_impression",
            bbCount: bbCount,
            chips: chips,
            bigBlind: bigBlind
        )
    }

    static func trackAllInRangeTap(bbCount: Double, chips: Int, bigBlind: Int) {
        increment(Key.allInRangeTaps)
        UserDefaults.standard.set(true, forKey: Key.allInRangeUniqueTap)
        log(
            "all_in_range_tap",
            bbCount: bbCount,
            chips: chips,
            bigBlind: bigBlind
        )
    }

    static func trackHandActionLineOpened() {
        log("hand_action_line_opened")
    }

    static func trackHandActionLineCreated() {
        log("hand_action_line_created")
    }

    static func trackHandActionLineActionAdded(street: String) {
        log("hand_action_line_action_added", parameters: ["street": street])
    }

    static func trackHandActionLineShared(method: String) {
        log("hand_action_line_shared", parameters: ["method": method])
    }

    static func resetForUITesting() {
        [
            Key.installID,
            Key.allInRangeImpressions,
            Key.allInRangeTaps,
            Key.allInRangeUniqueImpression,
            Key.allInRangeUniqueTap
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    private static func increment(_ key: String) {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    private static func log(_ event: String, parameters: [String: Any] = [:]) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(event, parameters: parameters)
        #endif

        #if DEBUG
        var debugParameters = parameters
        debugParameters["install_id"] = installID
        print("[Analytics] \(event)", debugParameters)
        #endif
    }

    private static func log(_ event: String, bbCount: Double, chips: Int, bigBlind: Int) {
        let roundedBB = (bbCount * 10).rounded() / 10
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(event, parameters: [
            "bb_count": roundedBB,
            "chips": chips,
            "big_blind": bigBlind
        ])
        #endif

        #if DEBUG
        print("[Analytics] \(event)", [
            "install_id": installID,
            "bb_count": roundedBB,
            "chips": chips,
            "big_blind": bigBlind
        ])
        #endif
    }
}
