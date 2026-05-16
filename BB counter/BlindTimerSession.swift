import Combine
import Foundation

/// 盲注倒數狀態掛在 App 層，離開結果頁編輯籌碼／盲注時倒數仍持續。
/// 使用 `countdownPeriodEnd` 與系統時間對齊，回到桌面或前景時倒數仍正確。
final class BlindTimerSession: ObservableObject {
    @Published var remainingSeconds: Int = 1500
    @Published var isPaused: Bool = false
    @Published private(set) var countdownPeriodEnd: Date?
    @Published var selectedNextIndex: Int = 0
    @Published var selectedIndicesSet: Set<Int> = []
    @Published var queuedIndices: [Int] = []
    @Published var activeCustomProgression: [(sb: Int, bb: Int)]? = nil

    static let progression: [(sb: Int, bb: Int)] = [
        (100, 100), (100, 200), (200, 300), (200, 400), (300, 500), (300, 600),
        (400, 800), (500, 1000), (600, 1200), (800, 1600), (1000, 2000),
        (1200, 2400), (1500, 3000), (2000, 4000), (2500, 5000), (3000, 6000),
        (4000, 8000), (5000, 10000), (6000, 12000), (8000, 16000), (10000, 20000),
        (12000, 24000), (15000, 30000), (20000, 40000), (25000, 50000), (30000, 60000),
        (40000, 80000), (50000, 100000)
    ]

    func effectiveProgression() -> [(sb: Int, bb: Int)] {
        activeCustomProgression ?? Self.progression
    }

    func restorePersistedState(
        remainingSeconds: Int,
        isPaused: Bool,
        countdownEndEpoch: Double,
        selectedNextIndex: Int,
        queuedIndices: [Int],
        activeCustomProgression: [(sb: Int, bb: Int)]?
    ) {
        self.remainingSeconds = max(0, remainingSeconds)
        self.isPaused = isPaused
        self.countdownPeriodEnd = countdownEndEpoch > 0 ? Date(timeIntervalSince1970: countdownEndEpoch) : nil
        self.selectedNextIndex = max(0, selectedNextIndex)
        self.queuedIndices = queuedIndices
        self.selectedIndicesSet = Set(queuedIndices)
        self.activeCustomProgression = activeCustomProgression
    }

    func setupNextLevel(bigBlind: Int) {
        let progression = Self.progression
        if let idx = progression.firstIndex(where: { $0.bb == bigBlind }), idx + 1 < progression.count {
            selectedNextIndex = idx + 1
        } else if let firstHigher = progression.firstIndex(where: { $0.bb > bigBlind }) {
            selectedNextIndex = firstHigher
        } else {
            selectedNextIndex = min(progression.count - 1, max(0, progression.count - 1))
        }
    }

    func prepareTimerSheetDefaults(bigBlind: Int) {
        if selectedIndicesSet.isEmpty {
            let progression = Self.progression
            if let start = progression.firstIndex(where: { $0.bb == bigBlind }) {
                let startIdx = min(start + 1, progression.count - 1)
                let endIdx = min(startIdx + 2, progression.count - 1)
                selectedIndicesSet = Set(startIdx...endIdx)
            }
        }
    }

    func currentIndex(for bigBlind: Int) -> Int? {
        Self.progression.firstIndex(where: { $0.bb == bigBlind })
    }

    func nextDisplayLevelText(for bigBlind: Int) -> String {
        let prog = effectiveProgression()
        if let first = queuedIndices.first, first < prog.count {
            let level = prog[first]
            return "\(level.sb)/\(level.bb)"
        }
        let idx = min(max(0, selectedNextIndex), max(0, prog.count - 1))
        guard idx >= 0, idx < prog.count else { return "" }
        let level = prog[idx]
        return "\(level.sb)/\(level.bb)"
    }

    func invalidateCountdownAnchor() {
        countdownPeriodEnd = nil
    }

    func setCountdownEnd(_ date: Date?) {
        countdownPeriodEnd = date
    }

    func snapRemainingAtPause() {
        guard let end = countdownPeriodEnd else { return }
        let now = Date()
        remainingSeconds = max(0, Int(ceil(end.timeIntervalSince(now))))
        countdownPeriodEnd = nil
    }

    func syncFromWallClock(timerEnabled: Bool, timerDurationSec: Int, smallBlind: inout Int, bigBlind: inout Int) {
        guard timerEnabled else {
            countdownPeriodEnd = nil
            return
        }
        guard !isPaused else { return }

        let now = Date()
        if countdownPeriodEnd == nil {
            countdownPeriodEnd = now.addingTimeInterval(TimeInterval(remainingSeconds))
        }
        guard var end = countdownPeriodEnd else { return }

        while end <= now {
            advanceBlindLevelUsingQueue(smallBlind: &smallBlind, bigBlind: &bigBlind)
            end = end.addingTimeInterval(TimeInterval(timerDurationSec))
        }
        countdownPeriodEnd = end
        remainingSeconds = max(0, Int(ceil(end.timeIntervalSince(now))))
    }

    func syncFromWallClock(timerEnabled: Bool, timerDurationSec: Int, bigBlind: inout Int) {
        var smallBlind = 0
        syncFromWallClock(timerEnabled: timerEnabled, timerDurationSec: timerDurationSec, smallBlind: &smallBlind, bigBlind: &bigBlind)
    }

    func applyFreshResultDefaults(timerDurationSec: Int, bigBlind: Int) {
        invalidateCountdownAnchor()
        isPaused = false
        setupNextLevel(bigBlind: bigBlind)
        remainingSeconds = timerDurationSec
    }

    func resetAfterGlobalReset(timerDurationSec: Int) {
        invalidateCountdownAnchor()
        isPaused = false
        selectedNextIndex = 0
        selectedIndicesSet = []
        queuedIndices = []
        activeCustomProgression = nil
        remainingSeconds = timerDurationSec
        setupNextLevel(bigBlind: 0)
    }

    private func advanceBlindLevel(smallBlind: inout Int, bigBlind: inout Int) {
        let progression = Self.progression
        guard selectedNextIndex < progression.count else { return }
        let next = progression[selectedNextIndex]
        smallBlind = next.sb
        bigBlind = next.bb
        if selectedNextIndex + 1 < progression.count {
            selectedNextIndex += 1
        }
    }

    private func advanceBlindLevel(bigBlind: inout Int) {
        var smallBlind = 0
        advanceBlindLevel(smallBlind: &smallBlind, bigBlind: &bigBlind)
    }

    func advanceBlindLevelUsingQueue(smallBlind: inout Int, bigBlind: inout Int) {
        let prog = effectiveProgression()
        if !queuedIndices.isEmpty {
            var q = queuedIndices
            let nextIdx = q.removeFirst()
            queuedIndices = q
            if nextIdx < prog.count {
                let next = prog[nextIdx]
                smallBlind = next.sb
                bigBlind = next.bb
                selectedNextIndex = min(nextIdx + 1, max(0, prog.count - 1))
            }
        } else {
            advanceBlindLevel(smallBlind: &smallBlind, bigBlind: &bigBlind)
        }
    }

    func advanceBlindLevelUsingQueue(bigBlind: inout Int) {
        var smallBlind = 0
        advanceBlindLevelUsingQueue(smallBlind: &smallBlind, bigBlind: &bigBlind)
    }

    static func encodeQueuedIndices(_ indices: [Int]) -> String {
        indices.map(String.init).joined(separator: ",")
    }

    static func decodeQueuedIndices(_ string: String) -> [Int] {
        string.split(separator: ",").compactMap { Int($0) }
    }

    static func encodeProgression(_ progression: [(sb: Int, bb: Int)]?) -> String {
        guard let progression else { return "" }
        return BlindStructureCodec.encodeLevels(progression.map { BlindLevel(sb: $0.sb, bb: $0.bb) })
    }

    static func decodeProgression(_ string: String) -> [(sb: Int, bb: Int)]? {
        let levels = BlindStructureCodec.decodeLevels(from: string)
        guard !levels.isEmpty else { return nil }
        return levels.map { ($0.sb, $0.bb) }
    }
}
