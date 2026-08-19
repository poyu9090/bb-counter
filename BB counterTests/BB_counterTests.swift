//
//  BB_counterTests.swift
//  BB counterTests
//
//  Created by user on 2026/1/18.
//

import Foundation
import Testing
@testable import BB_counter

struct BB_counterTests {

    @Test func setupNextLevelChoosesNextKnownBlind() async throws {
        let session = BlindTimerSession()

        session.setupNextLevel(bigBlind: 200)

        #expect(session.selectedNextIndex == 2)
        #expect(session.nextDisplayLevelText(for: 200) == "200/300")
    }

    @Test func queuedBlindLevelsAdvanceBeforeDefaultProgression() async throws {
        let session = BlindTimerSession()
        session.queuedIndices = [3, 4]
        var bigBlind = 200

        session.advanceBlindLevelUsingQueue(bigBlind: &bigBlind)

        #expect(bigBlind == 400)
        #expect(session.queuedIndices == [4])
        #expect(session.selectedNextIndex == 4)
    }

    @Test func customStructureStaysOnCustomLevelsAfterQueueDrains() async throws {
        let session = BlindTimerSession()
        session.activeCustomProgression = [(sb: 25, bb: 50), (sb: 50, bb: 100), (sb: 75, bb: 150)]
        session.queuedIndices = []
        session.selectedNextIndex = 1
        var smallBlind = 25
        var bigBlind = 50

        session.advanceBlindLevelUsingQueue(smallBlind: &smallBlind, bigBlind: &bigBlind)

        #expect(smallBlind == 50)
        #expect(bigBlind == 100)
        #expect(session.selectedNextIndex == 2)
    }

    @Test func wallClockSyncAdvancesExpiredTimer() async throws {
        let session = BlindTimerSession()
        session.queuedIndices = [1]
        session.remainingSeconds = 0
        var bigBlind = 100

        session.syncFromWallClock(timerEnabled: true, timerDurationSec: 1500, bigBlind: &bigBlind)

        #expect(bigBlind == 200)
        #expect(session.remainingSeconds > 0)
    }

    // MARK: - Session summary

    private func chipRecords(_ pairs: [(previous: Int, new: Int)]) -> [ChipChangeRecord] {
        // 實際儲存是最新的排最前面，所以這裡把時間序反過來。
        pairs.reversed().enumerated().map { offset, pair in
            ChipChangeRecord(
                id: UUID(),
                previousChips: pair.previous,
                newChips: pair.new,
                changedAt: Date(timeIntervalSince1970: 1_700_000_000 - Double(offset * 60))
            )
        }
    }

    @Test func sessionDeltaComparesCurrentAgainstStart() async throws {
        let records = chipRecords([(30_000, 32_000), (32_000, 34_000)])

        let summary = SessionSummary.make(currentChips: 34_000, storedStartChips: 30_000, records: records)

        #expect(summary.startChips == 30_000)
        #expect(summary.delta == 4_000)
        #expect(summary.recordCount == 2)
        #expect(summary.sparkline == [30_000, 32_000, 34_000])
    }

    @Test func sessionDeltaSurvivesATotalRewrite() async throws {
        // 改總額不是增減，所以只有「目前 − 起始」算得對。
        let records = chipRecords([(30_000, 32_000), (32_000, 12_000)])

        let summary = SessionSummary.make(currentChips: 12_000, storedStartChips: 30_000, records: records)

        #expect(summary.delta == -18_000)
    }

    @Test func sessionStartFallsBackToOldestRecord() async throws {
        let records = chipRecords([(30_000, 32_000), (32_000, 34_000)])

        let summary = SessionSummary.make(currentChips: 34_000, storedStartChips: 0, records: records)

        #expect(summary.startChips == 30_000)
        #expect(summary.delta == 4_000)
    }

    @Test func sessionStartsFlatWithoutAnyHistory() async throws {
        let summary = SessionSummary.make(currentChips: 34_000, storedStartChips: 0, records: [])

        #expect(summary.startChips == 34_000)
        #expect(summary.delta == 0)
        #expect(summary.sparkline == [34_000])
    }

    @Test func sparklineCapsPointsAndEndsAtCurrentChips() async throws {
        let pairs = (0..<12).map { (previous: 30_000 + $0 * 1_000, new: 31_000 + $0 * 1_000) }
        let records = chipRecords(pairs)

        let summary = SessionSummary.make(currentChips: 42_000, storedStartChips: 30_000, records: records)

        #expect(summary.sparkline.count == SessionSummary.sparklinePointLimit)
        #expect(summary.sparkline.last == 42_000)
    }

    // MARK: - Blind outlook

    private let sampleProgression = [
        BlindLevel(sb: 100, bb: 200),
        BlindLevel(sb: 200, bb: 400),
        BlindLevel(sb: 300, bb: 600)
    ]

    @Test func blindOutlookPrefersTheQueuedLevel() async throws {
        let outlook = BlindOutlook.make(
            chips: 34_000,
            currentBigBlind: 200,
            progression: sampleProgression,
            queuedIndices: [2],
            selectedNextIndex: 1
        )

        #expect(outlook.nextLevel == BlindLevel(sb: 300, bb: 600))
        #expect(outlook.stackAfterNextLevel == 34_000.0 / 600.0)
    }

    @Test func blindOutlookFallsBackToSelectedNextIndex() async throws {
        let outlook = BlindOutlook.make(
            chips: 34_000,
            currentBigBlind: 200,
            progression: sampleProgression,
            queuedIndices: [],
            selectedNextIndex: 1
        )

        #expect(outlook.nextLevel == BlindLevel(sb: 200, bb: 400))
        #expect(outlook.stackAfterNextLevel == 85)
        #expect(outlook.healthTier == 3)
    }

    @Test func blindOutlookHasNothingAfterTheLastLevel() async throws {
        let outlook = BlindOutlook.make(
            chips: 34_000,
            currentBigBlind: 600,
            progression: sampleProgression,
            queuedIndices: [],
            selectedNextIndex: 2
        )

        #expect(outlook.hasNextLevel == false)
        #expect(outlook.stackAfterNextLevel == nil)
        #expect(outlook.healthTier == nil)
    }

    @Test func blindOutlookFollowsACustomStructure() async throws {
        let custom = [BlindLevel(sb: 25, bb: 50), BlindLevel(sb: 50, bb: 100)]

        let outlook = BlindOutlook.make(
            chips: 3_400,
            currentBigBlind: 50,
            progression: custom,
            queuedIndices: [],
            selectedNextIndex: 1
        )

        #expect(outlook.nextLevel == BlindLevel(sb: 50, bb: 100))
        #expect(outlook.stackAfterNextLevel == 34)
    }

    // MARK: - Hand pot math

    private func record(with actions: [(HandStreet, String, String, String)], stackBB: Double = 100) -> HandActionLineRecord {
        var record = HandActionLineRecord.new(smallBlind: 50, bigBlind: 100, stackBB: stackBB)
        for (street, position, action, amount) in actions {
            guard let index = record.streets.firstIndex(where: { $0.street == street }) else { continue }
            record.streets[index].actions.append(
                HandActionRecord(id: UUID(), position: position, action: action, amount: amount, note: "", createdAt: Date())
            )
        }
        return record
    }

    @Test func preflopPotCountsBlindsRaisesAndCalls() async throws {
        let hand = record(with: [
            (.preflop, "UTG", "Open", "3bb"),
            (.preflop, "BTN", "Call", "3bb"),
            (.preflop, "SB", "Fold", ""),
            (.preflop, "BB", "Call", "3bb")
        ])

        let snapshot = HandPotMath.snapshot(for: hand, through: .preflop)

        // 0.5 + 1 盲注 + UTG 3 + BTN 3 + BB 再補 2
        #expect(snapshot.potBB == 9.5)
        #expect(snapshot.currentBetBB == 3)
        #expect(snapshot.isEstimated == false)
    }

    @Test func postflopBetAddsRecordedSizeToPot() async throws {
        let hand = record(with: [
            (.preflop, "UTG", "Open", "3bb"),
            (.preflop, "BB", "Call", "3bb"),
            (.flop, "BB", "Check", ""),
            (.flop, "UTG", "Bet", "3.5bb (1/2 pot)")
        ])

        let snapshot = HandPotMath.snapshot(for: hand, through: .flop)

        // Preflop 進池 6.5bb（0.5 + 1 盲注 + UTG 3 + BB 再補 2），翻牌半池 3.5bb
        #expect(snapshot.potBB == 10)
        #expect(snapshot.currentBetBB == 3.5)
        #expect(snapshot.toCall(for: "BB") == 3.5)
    }

    @Test func allInMarksPotAsEstimated() async throws {
        let hand = record(with: [
            (.preflop, "UTG", "All-in", "")
        ], stackBB: 40)

        let snapshot = HandPotMath.snapshot(for: hand, through: .preflop)

        #expect(snapshot.isEstimated)
        #expect(snapshot.currentBetBB == 40)
        #expect(snapshot.potBB == 41.5)
    }

    @Test func amountParsingHandlesRecordedFormats() async throws {
        #expect(HandPotMath.bbValue(from: "4.5bb (1/2 pot)") == 4.5)
        #expect(HandPotMath.bbValue(from: "9bb (2x)") == 9)
        #expect(HandPotMath.bbValue(from: "1/2 pot") == nil)
        #expect(HandPotMath.potFraction(from: "2/3 pot") == 2.0 / 3)
        #expect(HandPotMath.potFraction(from: "pot") == 1)
        #expect(HandPotMath.multiplier(from: "3x") == 3)
        #expect(HandPotMath.formatted(4.75) == "5bb")
        #expect(HandPotMath.formatted(4.6) == "4.5bb")
        #expect(HandPotMath.formatted(9) == "9bb")
    }

    @Test func resetClearsCustomTimerState() async throws {
        let session = BlindTimerSession()
        session.selectedIndicesSet = [1, 2]
        session.queuedIndices = [1]
        session.activeCustomProgression = [(sb: 500, bb: 1000)]
        session.isPaused = true

        session.resetAfterGlobalReset(timerDurationSec: 900)

        #expect(session.selectedIndicesSet.isEmpty)
        #expect(session.queuedIndices.isEmpty)
        #expect(session.activeCustomProgression == nil)
        #expect(session.isPaused == false)
        #expect(session.remainingSeconds == 900)
    }

}
