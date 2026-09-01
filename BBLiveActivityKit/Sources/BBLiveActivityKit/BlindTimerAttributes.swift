import ActivityKit
import Foundation

/// 盲注計時器即時動態（Live Activity）共用屬性
public struct BlindTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var chips: Int
        /// 目前盲注等級，例如「100/200」（小盲／大盲）
        public var currentBlindsText: String
        /// 依目前大盲換算的籌碼深度，僅數字（例如「15.2」），不含單位
        public var stackBBNumericText: String
        /// 與主 App 相同的 BB 深度分級：0 危險…3 健康，供 Widget 上色
        public var stackBBHealthTier: Int
        public var timeRemainingText: String
        /// 下一盲注等級顯示文字，例如「100/200」
        public var nextBlindText: String
        /// 本級盲注倒數結束的絕對時間；有值時 Widget 可用系統計時樣式在背景持續顯示倒數。
        public var countdownPeriodEnd: Date?
        /// 靈動島用：已本地化的「籌碼＋bb」整行（由主 App 組字）
        public var islandChipsSummaryLine: String
        /// 靈動島用：已本地化的「升盲時間」整行（由主 App 依 countdownPeriodEnd 組字）
        public var islandBlindUpgradeTimeLine: String
        /// 靈動島緊湊模式：升盲的牆上時鐘 `HH:mm`，暫停或無倒數時為空字串
        public var islandUpgradeAtClock: String

        public init(
            chips: Int,
            currentBlindsText: String,
            stackBBNumericText: String,
            stackBBHealthTier: Int = 3,
            timeRemainingText: String,
            nextBlindText: String = "",
            countdownPeriodEnd: Date? = nil,
            islandChipsSummaryLine: String = "",
            islandBlindUpgradeTimeLine: String = "",
            islandUpgradeAtClock: String = ""
        ) {
            self.chips = chips
            self.currentBlindsText = currentBlindsText
            self.stackBBNumericText = stackBBNumericText
            self.stackBBHealthTier = stackBBHealthTier
            self.timeRemainingText = timeRemainingText
            self.nextBlindText = nextBlindText
            self.countdownPeriodEnd = countdownPeriodEnd
            self.islandChipsSummaryLine = islandChipsSummaryLine
            self.islandBlindUpgradeTimeLine = islandBlindUpgradeTimeLine
            self.islandUpgradeAtClock = islandUpgradeAtClock
        }
    }
    
    public init() {}
}
