import Foundation

// MARK: - Live Activity Payload

func liveActivityStackBBHealthTier(bbCount: Double) -> Int {
	switch bbCount {
	case ..<10: return 0
	case 10..<20: return 1
	case 20..<30: return 2
	default: return 3
	}
}

@MainActor
func syncLiveActivityPayload(
	chips: Int,
	bigBlind: Int,
	blindSession: BlindTimerSession,
	timerEnabled: Bool
) {
	let bbCount: Double = {
		guard bigBlind > 0 else { return 0 }
		return Double(chips) / Double(bigBlind)
	}()
	let nf = NumberFormatter()
	nf.maximumFractionDigits = 1
	nf.minimumFractionDigits = 0
	let stackBBNumeric = nf.string(from: NSNumber(value: bbCount)) ?? String(format: "%.1f", bbCount)
	let tier = liveActivityStackBBHealthTier(bbCount: bbCount)
	let blindsText: String = {
		guard bigBlind > 0 else { return "—" }
		return "\(bigBlind)"
	}()
	let rem = blindSession.remainingSeconds
	let timeText = String(format: "%02d:%02d", rem / 60, rem % 60)
	let periodEnd: Date? = (timerEnabled && !blindSession.isPaused) ? blindSession.countdownPeriodEnd : nil

	let chipGrouping = NumberFormatter()
	chipGrouping.numberStyle = .decimal
	chipGrouping.groupingSeparator = ","
	let chipsFormatted = chipGrouping.string(from: NSNumber(value: chips)) ?? "\(chips)"
	let chipsSummaryLine = String(
		format: NSLocalizedString("live.island.chips_bb", bundle: .main, comment: ""),
		chipsFormatted,
		stackBBNumeric
	)
	let clockFormatter = DateFormatter()
	clockFormatter.locale = .current
	clockFormatter.dateFormat = "HH:mm"
	let upgradeClock: String = periodEnd.map { clockFormatter.string(from: $0) } ?? ""

	let upgradeTimeLine: String = {
		guard let end = periodEnd else {
			return NSLocalizedString("live.island.upgrade_paused", bundle: .main, comment: "")
		}
		let clock = clockFormatter.string(from: end)
		return String(
			format: NSLocalizedString("live.island.upgrade_at", bundle: .main, comment: ""),
			clock
		)
	}()

	BlindTimerLiveActivityController.sync(
		timerEnabled: timerEnabled,
		chips: chips,
		currentBlindsText: blindsText,
		stackBBNumericText: stackBBNumeric,
		stackBBHealthTier: tier,
		timeRemainingText: timeText,
		nextBlindText: blindSession.nextDisplayLevelText(for: bigBlind),
		countdownPeriodEnd: periodEnd,
		islandChipsSummaryLine: chipsSummaryLine,
		islandBlindUpgradeTimeLine: upgradeTimeLine,
		islandUpgradeAtClock: upgradeClock
	)
}
