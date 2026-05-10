//
//  ContentView.swift
//  BB counter
//
//  Created by user on 2026/1/18.
//

import SwiftUI

struct ContentView: View {
    enum Step {
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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Persisted values
    @AppStorage("chips") private var chipsStored: Int = 0
    @AppStorage("bigBlind") private var bigBlindStored: Int = 0
    
    // Working text states for inputs
    @State private var chipsText: String = ""
    @State private var bigBlindText: String = ""
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            Group {
                switch step {
                case .chips:
                    ChipsInputView(
                        chipsText: $chipsText,
                        onNext: {
                            let chips = numericValue(from: chipsText)
                            guard chips > 0 else { return }
                            chipsStored = chips
                            if isEditingChipsFromResult {
                                isEditingChipsFromResult = false
                                step = .result
                            } else {
                                step = .blinds
                            }
                        },
                        onAppear: {
                            if chipsStored > 0 && chipsText.isEmpty {
                                chipsText = String(chipsStored)
                            }
                        },
                        buttonLabelKey: isEditingChipsFromResult ? "action.done" : "action.next"
                    )
                case .blinds:
                    BlindLevelView(
                        bigBlindText: $bigBlindText,
                        selectPreset: { bb in
                            bigBlindStored = bb
                            bigBlindText = String(bb)
                        },
                        onShowResult: {
                            let bb = numericValue(from: bigBlindText)
                            guard bb > 0 else { return }
                            bigBlindStored = bb
                            if isEditingBlindsFromResult {
                                isEditingBlindsFromResult = false
                            }
                            step = .result
                        },
                        onBack: {
                            if isEditingBlindsFromResult {
                                isEditingBlindsFromResult = false
                                step = .result
                            } else {
                                step = .chips
                            }
                        },
                        onAppear: {
                            if bigBlindStored > 0 && bigBlindText.isEmpty {
                                bigBlindText = String(bigBlindStored)
                            }
                        },
                        isEditingFromResult: isEditingBlindsFromResult
                    )
                case .result:
				ResultView(
					chips: chipsStored,
					bigBlind: $bigBlindStored,
					blindSession: blindTimerSession,
					timerEnabled: $timerEnabled,
					timerDurationSec: $timerDurationSec,
                        onEditChips: {
                            skipApplyFreshTimerDefaultsOnNextResult = true
                            isEditingChipsFromResult = true
                            step = .chips
                        },
                        onEditBlinds: {
                            skipApplyFreshTimerDefaultsOnNextResult = true
                            isEditingBlindsFromResult = true
                            step = .blinds
                        },
                        onReset: {
                            chipsStored = 0
                            bigBlindStored = 0
                            chipsText = ""
                            bigBlindText = ""
                            isEditingChipsFromResult = false
                            isEditingBlindsFromResult = false
                            timerEnabled = false
                            blindTimerSession.resetAfterGlobalReset(timerDurationSec: timerDurationSec)
                            step = .chips
                        }
                    )
                }
            }
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
        .animation(.default, value: step)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            runBlindTimerWallClockSync()
            if timerEnabled {
                syncLiveActivityFromContent()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                runBlindTimerWallClockSync()
                if timerEnabled {
                    syncLiveActivityFromContent()
                }
            }
        }
        .onChange(of: timerDurationSec) { _, _ in
            if timerEnabled, !blindTimerSession.isPaused {
                blindTimerSession.invalidateCountdownAnchor()
            }
        }
        .onChange(of: step) { old, new in
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
        .onChange(of: chipsStored) { _, _ in
            syncLiveActivityFromContent()
        }
        .onChange(of: bigBlindStored) { _, _ in
            syncLiveActivityFromContent()
        }
        .onChange(of: timerEnabled) { _, _ in
            syncLiveActivityFromContent()
        }
        .onChange(of: blindTimerSession.remainingSeconds) { _, _ in
            syncLiveActivityFromContent()
        }
        .onChange(of: blindTimerSession.isPaused) { _, _ in
            syncLiveActivityFromContent()
        }
        .onChange(of: blindTimerSession.selectedNextIndex) { _, _ in
            syncLiveActivityFromContent()
        }
        .onChange(of: blindTimerSession.queuedIndices) { _, _ in
            syncLiveActivityFromContent()
        }
        .onChange(of: blindTimerSession.countdownPeriodEnd) { _, _ in
            if timerEnabled {
                syncLiveActivityFromContent()
            }
        }
        .onAppear {
            // Keep onboarding for truly new users only.
            if !hasCompletedOnboarding, (chipsStored > 0 || bigBlindStored > 0) {
                hasCompletedOnboarding = true
            }
            // Initialize visible texts from stored if available
            if chipsStored > 0 && chipsText.isEmpty {
                chipsText = String(chipsStored)
            }
            if bigBlindStored > 0 && bigBlindText.isEmpty {
                bigBlindText = String(bigBlindStored)
            }
        }
    }

    private func runBlindTimerWallClockSync() {
        var bb = bigBlindStored
        blindTimerSession.syncFromWallClock(timerEnabled: timerEnabled, timerDurationSec: timerDurationSec, bigBlind: &bb)
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
            bigBlind: bigBlindStored,
            blindSession: blindTimerSession,
            timerEnabled: timerEnabled
        )
    }
    
    private func numericValue(from text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
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
        .safeAreaInset(edge: .bottom) {
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
