import Foundation
import Testing
@testable import BB_counter

@Suite("埋點統計")
struct AnalyticsStoreTests {
    /// 每個測試都給一份乾淨的 UserDefaults，才不會互相污染。
    private func makeDefaults() -> UserDefaults {
        let suiteName = "analytics.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func date(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: iso)!
    }

    @Test("事件次數會累加，首末次時間分別記住")
    func countsAccumulate() {
        var current = date("2026-09-01 10:00")
        let store = AnalyticsStore(defaults: makeDefaults(), now: { current })

        store.record(AnalyticsEvent.appOpened.name)
        current = date("2026-09-01 11:30")
        store.record(AnalyticsEvent.appOpened.name)
        store.record(AnalyticsEvent.chipTotalEdited.name)

        let snapshot = store.snapshot
        #expect(snapshot.count(of: .appOpened) == 2)
        #expect(snapshot.count(of: .chipTotalEdited) == 1)
        #expect(snapshot.firstSeen[AnalyticsEvent.appOpened.name] == date("2026-09-01 10:00"))
        #expect(snapshot.lastSeen[AnalyticsEvent.appOpened.name] == date("2026-09-01 11:30"))
    }

    @Test("同一天多次使用只算一個活躍日")
    func activeDaysAreDeduplicated() {
        var current = date("2026-09-01 09:00")
        let store = AnalyticsStore(defaults: makeDefaults(), now: { current })

        store.record(AnalyticsEvent.appOpened.name)
        current = date("2026-09-01 22:00")
        store.record(AnalyticsEvent.appOpened.name)
        current = date("2026-09-03 08:00")
        store.record(AnalyticsEvent.appOpened.name)

        #expect(store.snapshot.activeDayCount == 2)
    }

    @Test("隔天回訪才算 D1")
    func nextDayReturn() {
        var current = date("2026-09-01 09:00")
        let store = AnalyticsStore(defaults: makeDefaults(), now: { current })
        store.record(AnalyticsEvent.appOpened.name)

        #expect(store.snapshot.returnedNextDay == false)

        current = date("2026-09-02 20:00")
        store.record(AnalyticsEvent.appOpened.name)
        #expect(store.snapshot.returnedNextDay)
    }

    @Test("隔了三天才回來不算 D1，但算進首週活躍")
    func laterReturnCountsForWeekOnly() {
        var current = date("2026-09-01 09:00")
        let store = AnalyticsStore(defaults: makeDefaults(), now: { current })
        store.record(AnalyticsEvent.appOpened.name)

        current = date("2026-09-04 09:00")
        store.record(AnalyticsEvent.appOpened.name)

        let snapshot = store.snapshot
        #expect(snapshot.returnedNextDay == false)
        #expect(snapshot.activeDaysInFirstWeek == 1)
        #expect(snapshot.daysSinceInstall == 3)
    }

    @Test("漏斗照順序給出五個步驟的次數")
    func funnelReportsEachStep() {
        let current = date("2026-09-01 09:00")
        let store = AnalyticsStore(defaults: makeDefaults(), now: { current })

        store.record(AnalyticsEvent.appOpened.name)
        store.record(AnalyticsEvent.chipsEntered(method: .denomination, chips: 35_000).name)
        store.record(AnalyticsEvent.blindsSet(method: .preset, bigBlind: 400).name)
        store.record(AnalyticsEvent.dashboardShown(bbDepth: 87.5).name)

        let funnel = store.snapshot.funnel
        #expect(funnel.map(\.step) == [
            "app_opened", "chips_entered", "blinds_set", "dashboard_shown", "chip_change_logged"
        ])
        #expect(funnel.map(\.count) == [1, 1, 1, 1, 0])
    }

    @Test("重設會把統計清乾淨")
    func resetClearsEverything() {
        let store = AnalyticsStore(defaults: makeDefaults(), now: { self.date("2026-09-01 09:00") })
        store.record(AnalyticsEvent.appOpened.name)
        store.reset()

        let snapshot = store.snapshot
        #expect(snapshot.counts.isEmpty)
        #expect(snapshot.installDate == nil)
        #expect(snapshot.activeDayCount == 0)
    }

    @Test("金額只會以分桶送出，不會外流原始數字")
    func parametersAreBucketed() {
        let event = AnalyticsEvent.chipsEntered(method: .keypad, chips: 35_000)
        #expect(event.parameters["chips_bucket"] == "10k-50k")
        #expect(event.parameters["method"] == "keypad")
        #expect(event.parameters.values.contains("35000") == false)

        #expect(AnalyticsEvent.dashboardShown(bbDepth: 87.5).parameters["depth_bucket"] == "40-100bb")
        #expect(AnalyticsEvent.dashboardShown(bbDepth: 8).parameters["depth_bucket"] == "<10bb")
    }
}
