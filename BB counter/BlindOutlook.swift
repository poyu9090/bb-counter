import Foundation

/// 下一級盲注，以及升盲之後籌碼還剩幾個 BB。
/// 已經打到級距表最後一級時 `nextLevel` 為 nil——那時候談「升盲後」沒有意義。
struct BlindOutlook: Equatable {
    let nextLevel: BlindLevel?
    let stackAfterNextLevel: Double?

    var hasNextLevel: Bool {
        nextLevel != nil
    }

    /// 升盲後深度的健康分級，與 BB 深度共用同一套（0 危險…3 健康）。
    var healthTier: Int? {
        stackAfterNextLevel.map { liveActivityStackBBHealthTier(bbCount: $0) }
    }

    /// - Parameters:
    ///   - progression: 目前生效的級距表；自訂盲注結構啟用時要傳自訂的那份
    ///   - queuedIndices: 計時器排定的升盲佇列，最前面那筆就是下一級
    ///   - selectedNextIndex: 佇列跑完後預設指向的級距
    static func make(
        chips: Int,
        currentBigBlind: Int,
        progression: [BlindLevel],
        queuedIndices: [Int],
        selectedNextIndex: Int
    ) -> BlindOutlook {
        let next = resolvedNextLevel(
            currentBigBlind: currentBigBlind,
            progression: progression,
            queuedIndices: queuedIndices,
            selectedNextIndex: selectedNextIndex
        )

        guard let next, next.bb > 0, chips > 0 else {
            return BlindOutlook(nextLevel: next, stackAfterNextLevel: nil)
        }
        return BlindOutlook(nextLevel: next, stackAfterNextLevel: Double(chips) / Double(next.bb))
    }

    private static func resolvedNextLevel(
        currentBigBlind: Int,
        progression: [BlindLevel],
        queuedIndices: [Int],
        selectedNextIndex: Int
    ) -> BlindLevel? {
        if let queued = queuedIndices.first, progression.indices.contains(queued) {
            return progression[queued]
        }
        guard progression.indices.contains(selectedNextIndex) else {
            return nil
        }
        // 打到最後一級時 selectedNextIndex 會停在自己身上，這時沒有下一級可言。
        let candidate = progression[selectedNextIndex]
        return candidate.bb > currentBigBlind ? candidate : nil
    }
}
