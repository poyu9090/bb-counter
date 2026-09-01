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
/// 再轉發給 TelemetryDeck。DEBUG 建置送出的訊號會自動標成測試模式，
/// 不會混進正式數據裡。
///
/// 送出的內容只有事件名與分桶後的參數（`10k-50k`、`40-100bb`），
/// 沒有原始金額、沒有帳號、沒有 IDFA。對應的隱私宣告是
/// 「使用資料 → 產品互動」，未連結身分、不用於追蹤——
/// `PrivacyInfo.xcprivacy` 已經寫進去，ASC 的 App 隱私權要在 1.5 送審前一起更新。
enum AppAnalytics {
    /// 填入後才會真的往外送。空字串 = 只記在本機。
    static let telemetryDeckAppID = "0E05125A-5D2B-4F57-A659-45284859D72E"

    private static let store = AnalyticsStore()

    /// TelemetryDeck 在還沒 `initialize` 就呼叫 `signal` 會直接 assert 掛掉，
    /// 所以後台沒起來之前只寫本機，不往外送。
    private static var isBackendRunning = false

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
    ///
    /// 一定要在**畫面出現之前**呼叫（`BB_counterApp.init()`）。放在 `.onAppear`
    /// 會晚於第一次 layout，而冷啟動還原進度那條路徑在 layout 當下就會送事件。
    static func start() {
        #if canImport(TelemetryDeck)
        if !telemetryDeckAppID.isEmpty, !isBackendRunning {
            TelemetryDeck.initialize(config: .init(appID: telemetryDeckAppID))
            isBackendRunning = true
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
        if isBackendRunning {
            TelemetryDeck.signal(event, parameters: parameters)
        }
        #endif

        #if DEBUG
        print("[Analytics] \(event)", parameters)
        #endif
    }
}
