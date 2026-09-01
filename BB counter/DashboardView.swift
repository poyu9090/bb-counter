import SwiftUI

/// 儀表板分頁：狀態 → 籌碼變化 → 升盲倒數，一頁到底。
/// 它只負責組卡片與處理跨卡片的副作用（Live Activity 同步、計時器開關、升盲回饋）。
struct DashboardView: View {
    let chips: Int
    @Binding var smallBlind: Int
    @Binding var bigBlind: Int
    /// 刻意不用 @ObservedObject：倒數每秒都在變，整頁跟著重繪不划算。
    /// 需要觀察的是 BlindTimerCard 與 DashboardLiveActivitySync，它們各自持有觀察。
    let blindSession: BlindTimerSession
    @Binding var timerEnabled: Bool
    @Binding var timerDurationSec: Int
    let summary: SessionSummary
    let chipChangeRecords: [ChipChangeRecord]
    let onClearChipHistory: () -> Void
    let onEditChips: () -> Void
    let onApplyChipChange: (Int) -> Void
    let onEditBlinds: () -> Void

    @State private var showTimerSheet: Bool = false
    @State private var showHistorySheet: Bool = false
    @State private var showAllInDevelopmentAlert: Bool = false
    @State private var hasTrackedAllInPromptImpression: Bool = false
    @State private var liveActivityStatusKey: String?
    @State private var levelUpTrigger: Int = 0

    private var bbCount: Double {
        guard bigBlind > 0 else { return 0 }
        return Double(chips) / Double(bigBlind)
    }

    /// All-in 範圍還沒做，點下去只會跳「開發中」。審核把這種假門當成 placeholder 功能，
    /// 所以先不顯示；功能做好（或要再量一次需求）時把這裡改回 true 即可。
    private static let showsAllInRangePrompt = false

    private var shouldShowAllInRangePrompt: Bool {
        Self.showsAllInRangePrompt && bbCount > 0 && bbCount < 15
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                StackStatusCard(
                    chips: chips,
                    bigBlind: bigBlind,
                    onEditChips: onEditChips,
                    onEditBlinds: onEditBlinds
                )

                ChipChangeCard(
                    summary: summary,
                    onApplyChipChange: onApplyChipChange,
                    onEditChips: onEditChips,
                    onOpenHistory: { showHistorySheet = true }
                )

                if shouldShowAllInRangePrompt {
                    AllInRangePrompt(bbCount: bbCount, chips: chips, bigBlind: bigBlind) {
                        showAllInDevelopmentAlert = true
                    }
                }

                BlindTimerCard(
                    blindSession: blindSession,
                    timerEnabled: $timerEnabled,
                    timerDurationSec: timerDurationSec,
                    chips: chips,
                    bigBlind: bigBlind,
                    onConfigure: {
                        blindSession.prepareTimerSheetDefaults(bigBlind: bigBlind)
                        showTimerSheet = true
                    }
                )

                if let liveActivityStatusKey {
                    liveActivityWarning(key: liveActivityStatusKey)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("result.screen")
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(
            RadialGradient(
                colors: [Theme.tableFelt.opacity(0.8), Theme.background],
                center: .top,
                startRadius: 30,
                endRadius: 520
            )
            .ignoresSafeArea()
        )
        .modifier(
            DashboardLiveActivitySync(
                chips: chips,
                smallBlind: smallBlind,
                bigBlind: bigBlind,
                blindSession: blindSession,
                timerEnabled: timerEnabled
            )
        )
        .onChange(of: timerEnabled) { _, enabled in
            handleTimerEnabledChange(enabled)
        }
        .onChange(of: bigBlind) { previous, current in
            // 升盲當下震一下，讓人不用盯著畫面也知道級距換了。
            if timerEnabled, current > previous {
                levelUpTrigger += 1
                AppAnalytics.track(.blindLevelUp(bigBlind: current))
            }
        }
        .sensoryFeedback(.warning, trigger: levelUpTrigger)
        .onReceive(NotificationCenter.default.publisher(for: .blindTimerLiveActivityStatusChanged)) { notification in
            liveActivityStatusKey = notification.object as? String
            if let key = liveActivityStatusKey {
                AppAnalytics.track(.liveActivityUnavailable(reason: key))
            } else {
                AppAnalytics.track(.liveActivityStarted)
            }
        }
        .onAppear {
            trackAllInPromptImpressionIfNeeded()
        }
        .onChange(of: shouldShowAllInRangePrompt) { _, _ in
            trackAllInPromptImpressionIfNeeded()
        }
        .sheet(isPresented: $showTimerSheet) {
            TimerConfigLauncher(
                isPresented: $showTimerSheet,
                blindSession: blindSession,
                smallBlind: $smallBlind,
                bigBlind: $bigBlind,
                timerEnabled: $timerEnabled,
                timerDurationSec: $timerDurationSec,
                chips: chips
            )
        }
        .sheet(isPresented: $showHistorySheet) {
            ChipChangeHistoryView(
                records: chipChangeRecords,
                onClear: onClearChipHistory
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .tint(Theme.accent)
            .preferredColorScheme(.dark)
        }
        .alert("all_in_range.development_title", isPresented: $showAllInDevelopmentAlert) {
            Button("action.confirm", role: .cancel) {}
        } message: {
            Text("all_in_range.development_message")
        }
    }

    private func liveActivityWarning(key: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.healthYellow)
            Text(LocalizedStringKey(key))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.healthYellow.opacity(0.12), in: .rect(cornerRadius: 14))
    }

    private func handleTimerEnabledChange(_ enabled: Bool) {
        if enabled {
            AppAnalytics.track(.timerEnabled)
            if blindSession.queuedIndices.isEmpty {
                blindSession.prepareTimerSheetDefaults(bigBlind: bigBlind)
                blindSession.queuedIndices = blindSession.selectedIndicesSet.sorted()
            }
            if blindSession.queuedIndices.isEmpty {
                blindSession.setupNextLevel(bigBlind: bigBlind)
            }
            blindSession.invalidateCountdownAnchor()
            if blindSession.remainingSeconds <= 0 || blindSession.remainingSeconds > timerDurationSec {
                blindSession.remainingSeconds = timerDurationSec
            }
            blindSession.isPaused = true
        } else {
            blindSession.isPaused = false
            blindSession.invalidateCountdownAnchor()
        }
        syncLiveActivity()
    }

    private func syncLiveActivity() {
        syncLiveActivityPayload(
            chips: chips,
            bigBlind: bigBlind,
            blindSession: blindSession,
            timerEnabled: timerEnabled
        )
    }

    private func trackAllInPromptImpressionIfNeeded() {
        guard shouldShowAllInRangePrompt, !hasTrackedAllInPromptImpression else {
            if !shouldShowAllInRangePrompt {
                hasTrackedAllInPromptImpression = false
            }
            return
        }
        hasTrackedAllInPromptImpression = true
        AppAnalytics.trackAllInRangeImpression(bbCount: bbCount, chips: chips, bigBlind: bigBlind)
    }
}
