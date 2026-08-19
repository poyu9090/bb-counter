import SwiftUI

struct BlindLevelView: View {
    @Binding var bigBlindText: String
    /// 只回報大盲；小盲一律由大盲推導，介面上不再出現。
    let selectPreset: (Int) -> Void
    let onShowResult: () -> Void
    let onBack: () -> Void
    let onAppear: () -> Void
    let isEditingFromResult: Bool
    
    init(
        bigBlindText: Binding<String>,
        selectPreset: @escaping (Int) -> Void,
        onShowResult: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onAppear: @escaping () -> Void,
        isEditingFromResult: Bool = false
    ) {
        self._bigBlindText = bigBlindText
        self.selectPreset = selectPreset
        self.onShowResult = onShowResult
        self.onBack = onBack
        self.onAppear = onAppear
        self.isEditingFromResult = isEditingFromResult
    }
    
    private let presets: [Int] = [200, 400, 600, 1000, 2000, 3000, 4000, 6000, 10000]
    private let maxBlindValue: Int = 99_999_999
    @State private var selectedPresetBB: Int = 200
    @FocusState private var focusedInput: BlindFocusedInput?

    private var parsedBigBlind: Int? {
        Int(bigBlindText)
    }

    private var inputErrorKey: String? {
        guard !bigBlindText.isEmpty else { return nil }
        guard let bb = parsedBigBlind else { return "input.error_too_large" }
        if bb <= 0 { return "input.error_required" }
        if bb > maxBlindValue { return "input.error_too_large" }
        return nil
    }

    private var canProceed: Bool {
        guard let bb = parsedBigBlind else { return false }
        return bb > 0 && bb <= maxBlindValue
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Theme.primaryText)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Theme.surfaceElevated)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Theme.surfaceStroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("action.back"))
                        .accessibilityIdentifier("blind.back")

                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        Text("blinds.title")
                            .font(.largeTitle).bold()
                            .foregroundStyle(Theme.primaryText)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 64)

                    VStack(spacing: 10) {
                        HStack {
                            presetArrowButton(
                                systemName: "chevron.left",
                                accessibilityIdentifier: "blind.previous",
                                isDisabled: previousPreset(before: selectedPresetBB) == nil
                            ) {
                                movePreset(delta: -1)
                            }
                            Spacer()
                            Text("\(currentPresetPosition()) / \(presets.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.secondaryText)
                                .monospacedDigit()
                            Spacer()
                            presetArrowButton(
                                systemName: "chevron.right",
                                accessibilityIdentifier: "blind.next",
                                isDisabled: nextPreset(after: selectedPresetBB) == nil
                            ) {
                                movePreset(delta: 1)
                            }
                        }
                        .padding(.horizontal, 8)

                        TabView(selection: $selectedPresetBB) {
                            ForEach(presets, id: \.self) { bigBlind in
                                Button {
                                    applyPreset(bigBlind)
                                } label: {
                                    currentBlindSelection(bigBlind)
                                        .frame(maxWidth: .infinity, minHeight: 128)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .tag(bigBlind)
                                .accessibilityIdentifier("blind.preset.\(bigBlind)")
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 168)
                        .onChange(of: selectedPresetBB) { _, newValue in
                            if presets.contains(newValue) {
                                applyPreset(newValue)
                            }
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("blinds.enter")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                        blindInputField(
                            titleKey: "blinds.big_blind",
                            placeholderKey: "blinds.big_placeholder",
                            text: $bigBlindText,
                            identifier: "blind.input",
                            focus: .bigBlind
                        )
                        .onAppear {
                            onAppear()
                            if bigBlindText.isEmpty, let first = presets.first {
                                applyPreset(first)
                            } else {
                                syncPresetSelectionFromText()
                            }
                        }
                        if let inputErrorKey {
                            Text(LocalizedStringKey(inputErrorKey))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.healthRed)
                        }
                    }
                    .padding(.horizontal)
                    .id(BlindFocusedInput.inputGroup)
                }
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focusedInput) { _, input in
                guard input != nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(BlindFocusedInput.inputGroup, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 32)
        .keyboardAwareBottomBar {
            VStack(spacing: 8) {
                Button(action: onShowResult) {
                    Text(LocalizedStringKey(isEditingFromResult ? "action.done" : "action.next"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.headline)
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.borderedProminent)
                // 不能叫 blind.next，會和上方輪播的「下一個預設」箭頭撞名。
                .accessibilityIdentifier(isEditingFromResult ? "blind.done" : "blind.showResult")
                .padding(.horizontal)
                .disabled(!canProceed)
            }
            .padding(.vertical, 8)
            .background(Theme.background.opacity(0.9))
        }
    }
    
    @ViewBuilder
    private func currentBlindSelection(_ bigBlind: Int) -> some View {
        blindValueColumn(title: "BB", value: bigBlind)
            .padding(.horizontal, 24)
    }

    private func blindValueColumn(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(Theme.secondaryText)
            Text("\(value)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity)
    }

    private func presetArrowButton(
        systemName: String,
        accessibilityIdentifier: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.bold))
                .foregroundStyle(isDisabled ? Theme.secondaryText.opacity(0.35) : Theme.secondaryText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func blindInputField(titleKey: String, placeholderKey: String, text: Binding<String>, identifier: String, focus: BlindFocusedInput) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            TextField(LocalizedStringKey(placeholderKey), text: text)
                .keyboardType(.numberPad)
                .focused($focusedInput, equals: focus)
                .textFieldStyle(.plain)
                .accessibilityIdentifier(identifier)
                .font(.title3)
                .foregroundStyle(Theme.primaryText)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.surfaceStroke, lineWidth: 1)
                )
                .onChange(of: text.wrappedValue) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        text.wrappedValue = filtered
                    } else {
                        syncPresetSelectionFromText()
                    }
                }
        }
    }

    private func applyPreset(_ bigBlind: Int) {
        if bigBlindText != String(bigBlind) {
            selectPreset(bigBlind)
        }
    }

    private func syncPresetSelectionFromText() {
        guard let value = Int(bigBlindText),
              presets.contains(value),
              selectedPresetBB != value
        else { return }
        selectedPresetBB = value
    }

    private func currentPresetPosition() -> Int {
        guard let index = presets.firstIndex(of: selectedPresetBB) else { return 1 }
        return index + 1
    }

    private func movePreset(delta: Int) {
        guard let currentIndex = presets.firstIndex(of: selectedPresetBB) else { return }
        let nextIndex = currentIndex + delta
        guard presets.indices.contains(nextIndex) else { return }
        selectedPresetBB = presets[nextIndex]
    }

    private func previousPreset(before bb: Int) -> Int? {
        guard let index = presets.firstIndex(of: bb), index > 0 else { return nil }
        return presets[index - 1]
    }

    private func nextPreset(after bb: Int) -> Int? {
        guard let index = presets.firstIndex(of: bb), index + 1 < presets.count else { return nil }
        return presets[index + 1]
    }
}

private enum BlindFocusedInput: Hashable {
    case bigBlind
    case inputGroup
}
