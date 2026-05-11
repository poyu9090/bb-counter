import ActivityKit
import BBLiveActivityKit
import Foundation

extension Notification.Name {
    static let blindTimerLiveActivityStatusChanged = Notification.Name("blindTimerLiveActivityStatusChanged")
}

/// 盲注倒數計時開啟時，同步「即時動態」顯示籌碼、BB 與倒數。
@MainActor
enum BlindTimerLiveActivityController {
    private static var activity: Activity<BlindTimerAttributes>?

    static func sync(
        timerEnabled: Bool,
        chips: Int,
        currentBlindsText: String,
        stackBBNumericText: String,
        stackBBHealthTier: Int,
        timeRemainingText: String,
        nextBlindText: String,
        countdownPeriodEnd: Date?,
        islandChipsSummaryLine: String,
        islandBlindUpgradeTimeLine: String,
        islandUpgradeAtClock: String
    ) {
        guard #available(iOS 16.2, *) else {
            postStatus("live.status.unsupported")
            return
        }

        if !timerEnabled {
            Task { await endSyncAsync() }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            postStatus("live.status.disabled")
            return
        }

        let state = BlindTimerAttributes.ContentState(
            chips: chips,
            currentBlindsText: currentBlindsText,
            stackBBNumericText: stackBBNumericText,
            stackBBHealthTier: stackBBHealthTier,
            timeRemainingText: timeRemainingText,
            nextBlindText: nextBlindText,
            countdownPeriodEnd: countdownPeriodEnd,
            islandChipsSummaryLine: islandChipsSummaryLine,
            islandBlindUpgradeTimeLine: islandBlindUpgradeTimeLine,
            islandUpgradeAtClock: islandUpgradeAtClock
        )

        Task {
            await startOrUpdate(using: state)
        }
    }

    @available(iOS 16.2, *)
    private static func startOrUpdate(using state: BlindTimerAttributes.ContentState) async {
        if let existing = activity {
            await existing.update(.init(state: state, staleDate: nil))
            postStatus(nil)
            return
        }
        do {
            activity = try Activity.request(
                attributes: BlindTimerAttributes(),
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            postStatus(nil)
        } catch {
            activity = nil
            postStatus("live.status.failed")
        }
    }

    @available(iOS 16.2, *)
    private static func endSyncAsync() async {
        guard let existing = activity else { return }
        await existing.end(nil, dismissalPolicy: .immediate)
        activity = nil
        postStatus(nil)
    }

    private static func postStatus(_ key: String?) {
        NotificationCenter.default.post(
            name: .blindTimerLiveActivityStatusChanged,
            object: key
        )
    }
}
