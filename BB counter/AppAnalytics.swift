import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(TelemetryDeck)
import TelemetryDeck
#endif

/// 埋點的單一入口。
///
/// 事件一律先寫進本機的 `AnalyticsStore`（不需要網路、不需要帳號），
/// 再轉發給有接上的後台。目前後台是選用編譯：
///
/// 1. Xcode → File → Add Package Dependencies → `https://github.com/TelemetryDeck/SwiftSDK`
/// 2. 把 TelemetryDeck 後台給的 App ID 填進 `telemetryDeckAppID`
/// 3. 送審前記得同步更新 `PrivacyInfo.xcprivacy` 與 App 隱私標籤：
///    會多一項「使用資料 → 產品互動」，未連結身分、不追蹤
///
/// 在 ID 還是空字串以前，所有資料都留在裝置上，隱私標籤維持「不收集資料」。
enum AppAnalytics {
    /// 填入後才會真的往外送。空字串 = 只記在本機。
    static let telemetryDeckAppID = ""

    private static let store = AnalyticsStore()

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

    static var snapshot: AnalyticsStore.Snapshot { store.snapshot }

    // MARK: - 主要入口

    static func track(_ event: AnalyticsEvent) {
        store.record(event.name)
        forward(event.name, parameters: event.parameters)
    }

    /// App 啟動時呼叫一次：初始化後台並記下今天有使用。
    static func start() {
        #if canImport(TelemetryDeck)
        if !telemetryDeckAppID.isEmpty {
            TelemetryDeck.initialize(config: .init(appID: telemetryDeckAppID))
        }
        #endif
        track(.appOpened)
    }

    // MARK: - All-in 假門（保留既有計數，供 CTR 判讀）

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
        track(.allInPromptShown)
    }

    static func trackAllInRangeTap(bbCount: Double, chips: Int, bigBlind: Int) {
        increment(Key.allInRangeTaps)
        UserDefaults.standard.set(true, forKey: Key.allInRangeUniqueTap)
        track(.allInPromptTapped)
    }

    // MARK: - 測試用

    static func resetForUITesting() {
        [
            Key.installID,
            Key.allInRangeImpressions,
            Key.allInRangeTaps,
            Key.allInRangeUniqueImpression,
            Key.allInRangeUniqueTap
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        store.reset()
    }

    private static func increment(_ key: String) {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    private static func forward(_ event: String, parameters: [String: String]) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(event, parameters: parameters)
        #endif

        #if canImport(TelemetryDeck)
        if !telemetryDeckAppID.isEmpty {
            TelemetryDeck.signal(event, parameters: parameters)
        }
        #endif

        #if DEBUG
        print("[Analytics] \(event)", parameters)
        #endif
    }
}
