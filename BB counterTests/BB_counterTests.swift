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
