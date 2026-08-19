import SwiftUI

/// 計時器設定頁的共用外殼。儀表板與設定分頁都會開它，所以把接線收在同一處，
/// 避免兩邊各自維護一份「按下開始之後要做什麼」。
struct TimerConfigLauncher: View {
    @Binding var isPresented: Bool
    @ObservedObject var blindSession: BlindTimerSession
    @Binding var smallBlind: Int
    @Binding var bigBlind: Int
    @Binding var timerEnabled: Bool
    @Binding var timerDurationSec: Int
    let chips: Int

    var body: some View {
        TimerConfigSheet(
            isPresented: $isPresented,
            timerEnabled: $timerEnabled,
            timerDurationSec: $timerDurationSec,
            timerRemainingSec: $blindSession.remainingSeconds,
            progression: BlindTimerSession.progression,
            currentIndex: blindSession.currentIndex(for: bigBlind),
            selectedIndicesSet: $blindSession.selectedIndicesSet,
            onStart: { orderedIndices, customProgression, customCurrentIndex in
                var nextSmallBlind = smallBlind
                var nextBigBlind = bigBlind
                blindSession.applyConfiguration(
                    orderedIndices: orderedIndices,
                    customProgression: customProgression,
                    customCurrentIndex: customCurrentIndex,
                    timerDurationSec: timerDurationSec,
                    smallBlind: &nextSmallBlind,
                    bigBlind: &nextBigBlind
                )
                smallBlind = nextSmallBlind
                bigBlind = nextBigBlind
                timerEnabled = true
                syncLiveActivityPayload(
                    chips: chips,
                    smallBlind: nextSmallBlind > 0 ? nextSmallBlind : nextBigBlind / 2,
                    bigBlind: nextBigBlind,
                    blindSession: blindSession,
                    timerEnabled: true
                )
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .background(Theme.background)
    }
}
