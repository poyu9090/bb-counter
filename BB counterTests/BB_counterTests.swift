//
//  BB_counterTests.swift
//  BB counterTests
//
//  Created by user on 2026/1/18.
//

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

    @Test func wallClockSyncAdvancesExpiredTimer() async throws {
        let session = BlindTimerSession()
        session.queuedIndices = [1]
        session.remainingSeconds = 0
        var bigBlind = 100

        session.syncFromWallClock(timerEnabled: true, timerDurationSec: 1500, bigBlind: &bigBlind)

        #expect(bigBlind == 200)
        #expect(session.remainingSeconds > 0)
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
