//
//  ContentView.swift
//  BB counter
//
//  Created by user on 2026/1/18.
//

import SwiftUI

struct ContentView: View {
    enum Step: Equatable {
        case chips
        case blinds
        case result
    }

    @Environment(\.scenePhase) private var scenePhase
    
    @State private var step: Step = .chips
    @State private var isEditingChipsFromResult: Bool = false
    @State private var isEditingBlindsFromResult: Bool = false
    /// 從結果頁去編輯再返回時，不要套用「初次進入結果頁」的計時器預設（關閉計時、重設剩餘時間）
    @State private var skipApplyFreshTimerDefaultsOnNextResult: Bool = false
    
    @StateObject private var blindTimerSession = BlindTimerSession()
    @AppStorage("timerEnabled") private var timerEnabled: Bool = false
    @AppStorage("timerDurationSec") private var timerDurationSec: Int = 1500
    @AppStorage("timerRemainingSec") private var timerRemainingStored: Int = 1500
    @AppStorage("timerIsPaused") private var timerIsPausedStored: Bool = false
    @AppStorage("timerCountdownEndEpoch") private var timerCountdownEndEpochStored: Double = 0
    @AppStorage("timerSelectedNextIndex") private var timerSelectedNextIndexStored: Int = 0
    @AppStorage("timerQueuedIndices") private var timerQueuedIndicesStored: String = ""
    @AppStorage("timerActiveCustomProgression") private var timerActiveCustomProgressionStored: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Persisted values
    @AppStorage("chips") private var chipsStored: Int = 0
    @AppStorage("smallBlind") private var smallBlindStored: Int = 0
    @AppStorage("bigBlind") private var bigBlindStored: Int = 0
    @AppStorage("chipChangeRecords") private var chipChangeRecordsStored: String = "[]"
    
    // Working text states for inputs
    @State private var chipsText: String = ""
    @State private var smallBlindText: String = ""
    @State private var bigBlindText: String = ""
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            currentStepView
            if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .keyboardConfirmationToolbar()
        .animation(.default, value: step)
        .modifier(contentLifecycleModifier)
        .onAppear {
            restoreTimerStateIfNeeded()
            // Keep onboarding for truly new users only.
            if !hasCompletedOnboarding, (chipsStored > 0 || bigBlindStored > 0) {
                hasCompletedOnboarding = true
            }
            // Initialize visible texts from stored if available
            if chipsStored > 0 && chipsText.isEmpty {
                chipsText = String(chipsStored)
            }
            if smallBlindStored == 0, bigBlindStored > 0 {
                smallBlindStored = bigBlindStored / 2
            }
            if smallBlindStored > 0 && smallBlindText.isEmpty {
                smallBlindText = String(smallBlindStored)
            }
            if bigBlindStored > 0 && bigBlindText.isEmpty {
                bigBlindText = String(bigBlindStored)
            }
        }
    }

    private var contentLifecycleModifier: ContentLifecycleModifier {
        ContentLifecycleModifier(
            scenePhase: scenePhase,
            step: step,
            timerEnabled: timerEnabled,
            timerDurationSec: timerDurationSec,
            timerRemainingSeconds: blindTimerSession.remainingSeconds,
            timerIsPaused: blindTimerSession.isPaused,
            timerSelectedNextIndex: blindTimerSession.selectedNextIndex,
            timerQueuedIndices: blindTimerSession.queuedIndices,
            timerCountdownPeriodEnd: blindTimerSession.countdownPeriodEnd,
            chips: chipsStored,
            smallBlind: smallBlindStored,
            bigBlind: bigBlindStored,
            onTick: handleTimerTick,
            onSceneActive: handleSceneActive,
            onTimerDurationChanged: handleTimerDurationChanged,
            onStepChanged: handleStepChanged,
            onStoredValueChanged: syncLiveActivityFromContent,
            onTimerEnabledChanged: handleTimerEnabledChanged,
            onTimerProgressChanged: handleTimerProgressChanged,
            onTimerPauseChanged: handleTimerPauseChanged,
            onTimerQueueChanged: handleTimerQueueChanged,
            onTimerCountdownEndChanged: handleTimerCountdownEndChanged
        )
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case .chips:
            chipsStepView
        case .blinds:
            blindsStepView
        case .result:
            resultStepView
        }
    }

    private var chipsStepView: some View {
        ChipsInputView(
            chipsText: $chipsText,
            onNext: commitChipsStep,
            onBack: isEditingChipsFromResult ? leaveChipsStep : nil,
            onAppear: restoreChipsText,
            buttonLabelKey: isEditingChipsFromResult ? "action.done" : "action.next"
        )
    }

    private var blindsStepView: some View {
        BlindLevelView(
            smallBlindText: $smallBlindText,
            bigBlindText: $bigBlindText,
            selectPreset: applyBlindPreset,
            onShowResult: commitBlindsStep,
            onBack: leaveBlindsStep,
            onAppear: restoreBlindTexts,
            isEditingFromResult: isEditingBlindsFromResult
        )
    }

    private var resultStepView: some View {
        ResultView(
            chips: chipsStored,
            smallBlind: $smallBlindStored,
            bigBlind: $bigBlindStored,
            blindSession: blindTimerSession,
            timerEnabled: $timerEnabled,
            timerDurationSec: $timerDurationSec,
            chipChangeRecords: chipChangeRecords,
            onClearChipHistory: clearChipChangeRecords,
            onEditChips: startEditingChips,
            onEditBlinds: startEditingBlinds,
            onReset: resetAll
        )
    }

    private func commitChipsStep() {
        let chips = numericValue(from: chipsText)
        guard isEditingChipsFromResult ? chips >= 0 : chips > 0 else { return }
        let previousChips = chipsStored
        chipsStored = chips
        if isEditingChipsFromResult, previousChips > 0, previousChips != chips {
            appendChipChangeRecord(previousChips: previousChips, newChips: chips)
        }
        if isEditingChipsFromResult {
            isEditingChipsFromResult = false
            step = .result
        } else {
            step = .blinds
        }
    }

    private func leaveChipsStep() {
        isEditingChipsFromResult = false
        restoreChipsTextFromStored()
        step = .result
    }

    private func restoreChipsText() {
        if chipsStored > 0 && chipsText.isEmpty {
            chipsText = String(chipsStored)
        }
    }

    private func restoreChipsTextFromStored() {
        chipsText = chipsStored > 0 ? String(chipsStored) : ""
    }

    private func applyBlindPreset(_ smallBlind: Int, _ bigBlind: Int) {
        smallBlindStored = smallBlind
        bigBlindStored = bigBlind
        smallBlindText = String(smallBlind)
        bigBlindText = String(bigBlind)
    }

    private func commitBlindsStep() {
        let sb = numericValue(from: smallBlindText)
        let bb = numericValue(from: bigBlindText)
        guard sb > 0, bb > 0, bb >= sb else { return }
        smallBlindStored = sb
        bigBlindStored = bb
        if isEditingBlindsFromResult {
            isEditingBlindsFromResult = false
        }
        step = .result
    }

    private func leaveBlindsStep() {
        if isEditingBlindsFromResult {
            isEditingBlindsFromResult = false
            step = .result
        } else {
            step = .chips
        }
    }

    private func restoreBlindTexts() {
        if smallBlindStored == 0, bigBlindStored > 0 {
            smallBlindStored = bigBlindStored / 2
        }
        if smallBlindStored > 0 && smallBlindText.isEmpty {
            smallBlindText = String(smallBlindStored)
        }
        if bigBlindStored > 0 && bigBlindText.isEmpty {
            bigBlindText = String(bigBlindStored)
        }
    }

    private func startEditingChips() {
        skipApplyFreshTimerDefaultsOnNextResult = true
        isEditingChipsFromResult = true
        step = .chips
    }

    private func startEditingBlinds() {
        skipApplyFreshTimerDefaultsOnNextResult = true
        isEditingBlindsFromResult = true
        step = .blinds
    }

    private func resetAll() {
        chipsStored = 0
        smallBlindStored = 0
        bigBlindStored = 0
        chipsText = ""
        smallBlindText = ""
        bigBlindText = ""
        clearChipChangeRecords()
        isEditingChipsFromResult = false
        isEditingBlindsFromResult = false
        timerEnabled = false
        clearPersistedTimerState()
        blindTimerSession.resetAfterGlobalReset(timerDurationSec: timerDurationSec)
        step = .chips
    }

    private func handleTimerTick() {
        runBlindTimerWallClockSync()
        if timerEnabled {
            syncLiveActivityFromContent()
        }
    }

    private func handleSceneActive() {
        runBlindTimerWallClockSync()
        if timerEnabled {
            syncLiveActivityFromContent()
        }
    }

    private func handleTimerDurationChanged() {
        if timerEnabled, !blindTimerSession.isPaused {
            blindTimerSession.invalidateCountdownAnchor()
        }
    }

    private func handleStepChanged(old: Step, new: Step) {
        guard new == .result else { return }
        if skipApplyFreshTimerDefaultsOnNextResult {
            skipApplyFreshTimerDefaultsOnNextResult = false
            return
        }
        if old == .blinds {
            timerEnabled = false
            blindTimerSession.applyFreshResultDefaults(timerDurationSec: timerDurationSec, bigBlind: bigBlindStored)
        }
    }

    private func handleTimerEnabledChanged() {
        persistTimerState()
        updateBlindTimerNotification()
        syncLiveActivityFromContent()
    }

    private func handleTimerProgressChanged() {
        persistTimerState()
        syncLiveActivityFromContent()
    }

    private func handleTimerPauseChanged() {
        persistTimerState()
        updateBlindTimerNotification()
        syncLiveActivityFromContent()
    }

    private func handleTimerQueueChanged() {
        persistTimerState()
        syncLiveActivityFromContent()
    }

    private func handleTimerCountdownEndChanged() {
        persistTimerState()
        updateBlindTimerNotification()
        if timerEnabled {
            syncLiveActivityFromContent()
        }
    }

    private func runBlindTimerWallClockSync() {
        var sb = smallBlindStored
        var bb = bigBlindStored
        blindTimerSession.syncFromWallClock(timerEnabled: timerEnabled, timerDurationSec: timerDurationSec, smallBlind: &sb, bigBlind: &bb)
        if sb != smallBlindStored {
            smallBlindStored = sb
            if step == .blinds {
                smallBlindText = String(sb)
            }
        }
        if bb != bigBlindStored {
            bigBlindStored = bb
            if step == .blinds {
                bigBlindText = String(bb)
            }
        }
    }
    
    private func syncLiveActivityFromContent() {
        syncLiveActivityPayload(
            chips: chipsStored,
            smallBlind: smallBlindStored,
            bigBlind: bigBlindStored,
            blindSession: blindTimerSession,
            timerEnabled: timerEnabled
        )
    }

    private func restoreTimerStateIfNeeded() {
        guard timerEnabled else { return }
        blindTimerSession.restorePersistedState(
            remainingSeconds: timerRemainingStored,
            isPaused: timerIsPausedStored,
            countdownEndEpoch: timerCountdownEndEpochStored,
            selectedNextIndex: timerSelectedNextIndexStored,
            queuedIndices: BlindTimerSession.decodeQueuedIndices(timerQueuedIndicesStored),
            activeCustomProgression: BlindTimerSession.decodeProgression(timerActiveCustomProgressionStored)
        )
        runBlindTimerWallClockSync()
        updateBlindTimerNotification()
    }

    private func persistTimerState() {
        timerRemainingStored = blindTimerSession.remainingSeconds
        timerIsPausedStored = blindTimerSession.isPaused
        timerCountdownEndEpochStored = blindTimerSession.countdownPeriodEnd?.timeIntervalSince1970 ?? 0
        timerSelectedNextIndexStored = blindTimerSession.selectedNextIndex
        timerQueuedIndicesStored = BlindTimerSession.encodeQueuedIndices(blindTimerSession.queuedIndices)
        timerActiveCustomProgressionStored = BlindTimerSession.encodeProgression(blindTimerSession.activeCustomProgression)
    }

    private func clearPersistedTimerState() {
        timerRemainingStored = timerDurationSec
        timerIsPausedStored = false
        timerCountdownEndEpochStored = 0
        timerSelectedNextIndexStored = 0
        timerQueuedIndicesStored = ""
        timerActiveCustomProgressionStored = ""
        BlindTimerNotificationScheduler.cancel()
    }

    private func updateBlindTimerNotification() {
        guard timerEnabled, !blindTimerSession.isPaused else {
            BlindTimerNotificationScheduler.cancel()
            return
        }
        BlindTimerNotificationScheduler.schedule(
            endDate: blindTimerSession.countdownPeriodEnd,
            nextBlindText: blindTimerSession.nextDisplayLevelText(for: bigBlindStored)
        )
    }
    
    private func numericValue(from text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
    }

    private var chipChangeRecords: [ChipChangeRecord] {
        guard let data = chipChangeRecordsStored.data(using: .utf8),
              let records = try? JSONDecoder().decode([ChipChangeRecord].self, from: data) else {
            return []
        }
        return records
    }

    private func appendChipChangeRecord(previousChips: Int, newChips: Int) {
        var records = chipChangeRecords
        records.insert(
            ChipChangeRecord(
                id: UUID(),
                previousChips: previousChips,
                newChips: newChips,
                changedAt: Date()
            ),
            at: 0
        )
        persistChipChangeRecords(Array(records.prefix(50)))
    }

    private func clearChipChangeRecords() {
        persistChipChangeRecords([])
    }

    private func persistChipChangeRecords(_ records: [ChipChangeRecord]) {
        guard let data = try? JSONEncoder().encode(records),
              let payload = String(data: data, encoding: .utf8) else {
            return
        }
        chipChangeRecordsStored = payload
    }

}

private struct ContentLifecycleModifier: ViewModifier {
    let scenePhase: ScenePhase
    let step: ContentView.Step
    let timerEnabled: Bool
    let timerDurationSec: Int
    let timerRemainingSeconds: Int
    let timerIsPaused: Bool
    let timerSelectedNextIndex: Int
    let timerQueuedIndices: [Int]
    let timerCountdownPeriodEnd: Date?
    let chips: Int
    let smallBlind: Int
    let bigBlind: Int
    let onTick: () -> Void
    let onSceneActive: () -> Void
    let onTimerDurationChanged: () -> Void
    let onStepChanged: (_ old: ContentView.Step, _ new: ContentView.Step) -> Void
    let onStoredValueChanged: () -> Void
    let onTimerEnabledChanged: () -> Void
    let onTimerProgressChanged: () -> Void
    let onTimerPauseChanged: () -> Void
    let onTimerQueueChanged: () -> Void
    let onTimerCountdownEndChanged: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                onTick()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    onSceneActive()
                }
            }
            .onChange(of: timerDurationSec) { _, _ in
                onTimerDurationChanged()
            }
            .onChange(of: step) { old, new in
                onStepChanged(old, new)
            }
            .onChange(of: chips) { _, _ in
                onStoredValueChanged()
            }
            .onChange(of: smallBlind) { _, _ in
                onStoredValueChanged()
            }
            .onChange(of: bigBlind) { _, _ in
                onStoredValueChanged()
            }
            .onChange(of: timerEnabled) { _, _ in
                onTimerEnabledChanged()
            }
            .onChange(of: timerRemainingSeconds) { _, _ in
                onTimerProgressChanged()
            }
            .onChange(of: timerIsPaused) { _, _ in
                onTimerPauseChanged()
            }
            .onChange(of: timerSelectedNextIndex) { _, _ in
                onTimerQueueChanged()
            }
            .onChange(of: timerQueuedIndices) { _, _ in
                onTimerQueueChanged()
            }
            .onChange(of: timerCountdownPeriodEnd) { _, _ in
                onTimerCountdownEndChanged()
            }
    }
}

private struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Text("onboarding.title")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.primaryText)
                Text("onboarding.subtitle")
                    .font(.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                OnboardingStepCard(
                    titleKey: "onboarding.step1.title",
                    descriptionKey: "onboarding.step1.description",
                    iconName: "checklist"
                )
                OnboardingStepCard(
                    titleKey: "onboarding.step2.title",
                    descriptionKey: "onboarding.step2.description",
                    iconName: "slider.horizontal.3"
                )
                OnboardingStepCard(
                    titleKey: "onboarding.step3.title",
                    descriptionKey: "onboarding.step3.description",
                    iconName: "timer"
                )
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .padding(.top, 32)
        .background(Theme.background.ignoresSafeArea())
        .keyboardAwareBottomBar {
            Button(action: onContinue) {
                Text("onboarding.continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .font(.headline)
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("onboarding.continue")
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Theme.background.opacity(0.95))
        }
    }
}

private struct OnboardingStepCard: View {
    let titleKey: String
    let descriptionKey: String
    let iconName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(titleKey))
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                Text(LocalizedStringKey(descriptionKey))
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.surfaceStroke, lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
