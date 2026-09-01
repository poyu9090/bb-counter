import SwiftUI

/// Live Activity 的同步觸發點很多，集中在一個 modifier 裡免得散落在畫面各處。
/// 它自己觀察 session，所以外層畫面不必為了推送而每秒重繪；
/// 實際要不要送出由 `BlindTimerLiveActivityController` 判斷（同樣內容不重複推）。
struct DashboardLiveActivitySync: ViewModifier {
    let chips: Int
    let smallBlind: Int
    let bigBlind: Int
    @ObservedObject var blindSession: BlindTimerSession
    let timerEnabled: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: chips) { _, _ in sync() }
            .onChange(of: smallBlind) { _, _ in sync() }
            .onChange(of: bigBlind) { _, _ in sync() }
            .onChange(of: blindSession.remainingSeconds) { _, _ in sync() }
            .onChange(of: blindSession.isPaused) { _, _ in sync() }
            .onChange(of: blindSession.selectedNextIndex) { _, _ in sync() }
            .onChange(of: blindSession.queuedIndices) { _, _ in sync() }
    }

    private func sync() {
        syncLiveActivityPayload(
            chips: chips,
            bigBlind: bigBlind,
            blindSession: blindSession,
            timerEnabled: timerEnabled
        )
    }
}
