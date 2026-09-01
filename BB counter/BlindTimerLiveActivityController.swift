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
    private static var lastPushedState: BlindTimerAttributes.ContentState?

    /// 倒數中時 Widget 用 `Text(end, style: .timer)` 自己走秒，所以每秒變動的
    /// `timeRemainingText` 不必推送——ActivityKit 的更新次數有預算，推太密會被系統節流。
    private static func shouldPush(_ state: BlindTimerAttributes.ContentState) -> Bool {
        guard let last = lastPushedState else { return true }
        guard state.countdownPeriodEnd != nil else {
            return state != last
        }
        var normalized = state
        normalized.timeRemainingText = last.timeRemainingText
        return normalized != last
    }

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

        guard shouldPush(state) else { return }

        Task {
            await startOrUpdate(using: state)
        }
    }

    @available(iOS 16.2, *)
    private static func startOrUpdate(using state: BlindTimerAttributes.ContentState) async {
        if let existing = activity {
            await existing.update(.init(state: state, staleDate: nil))
            lastPushedState = state
            postStatus(nil)
            return
        }
        do {
            activity = try Activity.request(
                attributes: BlindTimerAttributes(),
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            lastPushedState = state
            postStatus(nil)
        } catch {
            activity = nil
            lastPushedState = nil
            postStatus("live.status.failed")
        }
    }

    @available(iOS 16.2, *)
    private static func endSyncAsync() async {
        guard let existing = activity else { return }
        await existing.end(nil, dismissalPolicy: .immediate)
        activity = nil
        lastPushedState = nil
        postStatus(nil)
    }

    private static func postStatus(_ key: String?) {
        NotificationCenter.default.post(
            name: .blindTimerLiveActivityStatusChanged,
            object: key
        )
    }
}
