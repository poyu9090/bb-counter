import SwiftUI
import UIKit

/// 儀表板分頁：狀態 → 籌碼變化 → 升盲倒數，一頁到底。
/// 它只負責組卡片與處理跨卡片的副作用（Live Activity 同步、計時器開關、升盲回饋）。
struct DashboardView: View {
    let chips: Int
    @Binding var smallBlind: Int
    @Binding var bigBlind: Int
    @ObservedObject var blindSession: BlindTimerSession
    @Binding var timerEnabled: Bool
    @Binding var timerDurationSec: Int
    let summary: SessionSummary
    let onEditChips: () -> Void
    let onApplyChipChange: (Int) -> Void
    let onEditBlinds: () -> Void
    let onOpenHistory: () -> Void

    @State private var showTimerSheet: Bool = false
    @State private var showAllInDevelopmentAlert: Bool = false
    @State private var hasTrackedAllInPromptImpression: Bool = false
    @State private var liveActivityStatusKey: String?

    private var bbCount: Double {
        guard bigBlind > 0 else { return 0 }
        return Double(chips) / Double(bigBlind)
    }

    private var shouldShowAllInRangePrompt: Bool {
        bbCount > 0 && bbCount < 15
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                StackStatusCard(
                    chips: chips,
                    smallBlind: smallBlind,
                    bigBlind: bigBlind,
                    onEditChips: onEditChips,
                    onEditBlinds: onEditBlinds
                )

                ChipChangeCard(
                    summary: summary,
                    onApplyChipChange: onApplyChipChange,
                    onEditChips: onEditChips,
                    onOpenHistory: onOpenHistory
                )

                if shouldShowAllInRangePrompt {
                    allInRangePrompt
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
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .blindTimerLiveActivityStatusChanged)) { notification in
            liveActivityStatusKey = notification.object as? String
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
        .alert("all_in_range.development_title", isPresented: $showAllInDevelopmentAlert) {
            Button("action.confirm", role: .cancel) {}
        } message: {
            Text("all_in_range.development_message")
        }
    }

    private var allInRangePrompt: some View {
        Button {
            AppAnalytics.trackAllInRangeTap(bbCount: bbCount, chips: chips, bigBlind: bigBlind)
            showAllInDevelopmentAlert = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.healthOrange)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Theme.healthOrange.opacity(0.14)))

                VStack(alignment: .leading, spacing: 3) {
                    Text("all_in_range.title")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.primaryText)
                    Text("all_in_range.subtitle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.healthOrange.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("allInRange.prompt")
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.healthYellow.opacity(0.12))
        )
    }

    private func handleTimerEnabledChange(_ enabled: Bool) {
        if enabled {
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
            smallBlind: smallBlind > 0 ? smallBlind : bigBlind / 2,
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

/// Live Activity 的同步觸發點很多，集中在一個 modifier 裡免得散落在畫面各處。
/// 實際要不要推送由 `BlindTimerLiveActivityController` 判斷（同樣內容不重複推）。
private struct DashboardLiveActivitySync: ViewModifier {
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
            smallBlind: smallBlind > 0 ? smallBlind : bigBlind / 2,
            bigBlind: bigBlind,
            blindSession: blindSession,
            timerEnabled: timerEnabled
        )
    }
}
