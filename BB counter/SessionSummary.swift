import Foundation

/// 本場統計：起始籌碼、本場輸贏，以及畫迷你長條圖用的籌碼序列。
///
/// 「本場」以重置為界。本場變化算的是「目前籌碼 − 起始籌碼」，而不是把每筆增減加總——
/// 因為使用者也可以直接改總額，那種變動沒有對應的增減金額。
struct SessionSummary: Equatable {
    /// 長條圖最多畫幾個點（起始值加上最近幾筆變化）。
    static let sparklinePointLimit = 9

    let startChips: Int
    let currentChips: Int
    let recordCount: Int
    let sparkline: [Int]

    var delta: Int {
        currentChips - startChips
    }

    /// - Parameters:
    ///   - storedStartChips: `sessionStartChips` 的值；0 代表還沒寫過（改版前的舊資料）
    ///   - records: 籌碼變化紀錄，最新的排在最前面
    static func make(currentChips: Int, storedStartChips: Int, records: [ChipChangeRecord]) -> SessionSummary {
        let start = resolvedStartChips(
            currentChips: currentChips,
            storedStartChips: storedStartChips,
            records: records
        )

        var series = [start] + records.reversed().map(\.newChips)
        if series.last != currentChips {
            series.append(currentChips)
        }

        return SessionSummary(
            startChips: start,
            currentChips: currentChips,
            recordCount: records.count,
            sparkline: Array(series.suffix(sparklinePointLimit))
        )
    }

    /// 舊使用者沒有起始值，用最早一筆紀錄的「變更前籌碼」回推；連紀錄都沒有就從這一刻開始算。
    static func resolvedStartChips(currentChips: Int, storedStartChips: Int, records: [ChipChangeRecord]) -> Int {
        if storedStartChips > 0 {
            return storedStartChips
        }
        if let oldest = records.last {
            return oldest.previousChips
        }
        return currentChips
    }
}
