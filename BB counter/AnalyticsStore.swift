import Foundation

/// 本機的埋點統計：事件次數、首末次時間、活躍天數。
///
/// 後台（TelemetryDeck 之類）還沒接上以前，這層先讓數據有地方落地：
/// 自己在實機上走一輪就能看到漏斗有沒有記對，接了後台之後也還是留著——
/// 它是「這台裝置」的事實來源，不受網路或取樣影響。
struct AnalyticsStore {
    private enum Key {
        static let counts = "analytics.counts"
        static let firstSeen = "analytics.firstSeen"
        static let lastSeen = "analytics.lastSeen"
        static let installDate = "analytics.installDate"
        static let activeDays = "analytics.activeDays"
    }

    /// 活躍天數只留最近 90 天，避免 UserDefaults 無限長大。
    static let activeDayLimit = 90

    private let defaults: UserDefaults
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
    }

    // MARK: - 寫入

    func record(_ eventName: String) {
        let timestamp = now()
        markActive(at: timestamp)

        var counts = self.counts
        counts[eventName, default: 0] += 1
        defaults.set(counts, forKey: Key.counts)

        var first = timestamps(forKey: Key.firstSeen)
        if first[eventName] == nil {
            first[eventName] = timestamp.timeIntervalSince1970
            defaults.set(first, forKey: Key.firstSeen)
        }

        var last = timestamps(forKey: Key.lastSeen)
        last[eventName] = timestamp.timeIntervalSince1970
        defaults.set(last, forKey: Key.lastSeen)
    }

    /// 記下「今天有用過」。安裝日在第一次呼叫時定下來。
    func markActive(at date: Date? = nil) {
        let timestamp = date ?? now()
        if defaults.object(forKey: Key.installDate) == nil {
            defaults.set(timestamp.timeIntervalSince1970, forKey: Key.installDate)
        }

        let today = Self.dayString(from: timestamp)
        var days = defaults.stringArray(forKey: Key.activeDays) ?? []
        guard !days.contains(today) else { return }
        days.append(today)
        if days.count > Self.activeDayLimit {
            days.removeFirst(days.count - Self.activeDayLimit)
        }
        defaults.set(days, forKey: Key.activeDays)
    }

    func reset() {
        [Key.counts, Key.firstSeen, Key.lastSeen, Key.installDate, Key.activeDays]
            .forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - 讀出

    var counts: [String: Int] {
        defaults.dictionary(forKey: Key.counts) as? [String: Int] ?? [:]
    }

    func count(of event: AnalyticsEvent) -> Int {
        counts[event.name] ?? 0
    }

    var snapshot: Snapshot {
        let days = (defaults.stringArray(forKey: Key.activeDays) ?? []).sorted()
        let installDate = (defaults.object(forKey: Key.installDate) as? Double)
            .map { Date(timeIntervalSince1970: $0) }

        return Snapshot(
            installDate: installDate,
            activeDays: days,
            counts: counts,
            firstSeen: timestamps(forKey: Key.firstSeen).mapValues { Date(timeIntervalSince1970: $0) },
            lastSeen: timestamps(forKey: Key.lastSeen).mapValues { Date(timeIntervalSince1970: $0) },
            now: now()
        )
    }

    private func timestamps(forKey key: String) -> [String: Double] {
        defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
    }

    static func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Snapshot

    struct Snapshot: Equatable {
        let installDate: Date?
        let activeDays: [String]
        let counts: [String: Int]
        let firstSeen: [String: Date]
        let lastSeen: [String: Date]
        let now: Date

        var activeDayCount: Int { activeDays.count }

        var daysSinceInstall: Int {
            guard let installDate else { return 0 }
            let calendar = Calendar(identifier: .gregorian)
            let from = calendar.startOfDay(for: installDate)
            let to = calendar.startOfDay(for: now)
            return calendar.dateComponents([.day], from: from, to: to).day ?? 0
        }

        /// 安裝隔天有沒有再打開——這就是 D1 留存的個人版。
        var returnedNextDay: Bool {
            guard let day = dayString(offsetFromInstall: 1) else { return false }
            return activeDays.contains(day)
        }

        /// 安裝後第 2～7 天內活躍過幾天。比單看第 7 天那一格穩定得多。
        var activeDaysInFirstWeek: Int {
            guard installDate != nil else { return 0 }
            return (1...6).compactMap { dayString(offsetFromInstall: $0) }
                .filter { activeDays.contains($0) }
                .count
        }

        func count(of event: AnalyticsEvent) -> Int { counts[event.name] ?? 0 }
        func count(of name: String) -> Int { counts[name] ?? 0 }

        /// 主漏斗：開啟 → 輸入籌碼 → 設定盲注 → 看到儀表板 → 記一次籌碼變化
        var funnel: [(step: String, count: Int)] {
            [
                ("app_opened", count(of: .appOpened)),
                ("chips_entered", count(of: "chips_entered")),
                ("blinds_set", count(of: "blinds_set")),
                ("dashboard_shown", count(of: "dashboard_shown")),
                ("chip_change_logged", count(of: "chip_change_logged"))
            ]
        }

        private func dayString(offsetFromInstall offset: Int) -> String? {
            guard let installDate else { return nil }
            let calendar = Calendar(identifier: .gregorian)
            guard let date = calendar.date(byAdding: .day, value: offset, to: installDate) else { return nil }
            return AnalyticsStore.dayString(from: date)
        }
    }
}
