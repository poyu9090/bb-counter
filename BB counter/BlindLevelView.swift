import SwiftUI

struct BlindLevelView: View {
    @Binding var smallBlindText: String
    @Binding var bigBlindText: String
    let selectPreset: (Int, Int) -> Void
    let onShowResult: () -> Void
    let onBack: () -> Void
    let onAppear: () -> Void
    let isEditingFromResult: Bool
    
    init(
        smallBlindText: Binding<String>,
        bigBlindText: Binding<String>,
        selectPreset: @escaping (Int, Int) -> Void,
        onShowResult: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onAppear: @escaping () -> Void,
        isEditingFromResult: Bool = false
    ) {
        self._smallBlindText = smallBlindText
        self._bigBlindText = bigBlindText
        self.selectPreset = selectPreset
        self.onShowResult = onShowResult
        self.onBack = onBack
        self.onAppear = onAppear
        self.isEditingFromResult = isEditingFromResult
    }
    
    private let presets: [(sb: Int, bb: Int)] = [
        (100, 200), (200, 400), (300, 600), (500, 1000), (1000, 2000),
        (1500, 3000), (2000, 4000), (3000, 6000), (5000, 10000)
    ]
    private let maxBlindValue: Int = 99_999_999
    @State private var selectedPresetBB: Int = 200
    @FocusState private var focusedInput: BlindFocusedInput?

    private var parsedBigBlind: Int? {
        Int(bigBlindText)
    }

    private var parsedSmallBlind: Int? {
        Int(smallBlindText)
    }

    private var inputErrorKey: String? {
        guard !smallBlindText.isEmpty || !bigBlindText.isEmpty else { return nil }
        guard let sb = parsedSmallBlind, let bb = parsedBigBlind else { return "input.error_too_large" }
        if sb <= 0 || bb <= 0 { return "input.error_required" }
        if sb > maxBlindValue || bb > maxBlindValue { return "input.error_too_large" }
        if bb < sb { return "timer.validation_bb_lt_sb_plain" }
        return nil
    }

    private var canProceed: Bool {
        guard let sb = parsedSmallBlind, let bb = parsedBigBlind else { return false }
        return sb > 0 && bb > 0 && sb <= maxBlindValue && bb <= maxBlindValue && bb >= sb
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
                            ForEach(presets, id: \.bb) { level in
                                Button {
                                    applyPreset(level)
                                } label: {
                                    currentBlindSelection(level)
                                        .frame(maxWidth: .infinity, minHeight: 128)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .tag(level.bb)
                                .accessibilityIdentifier("blind.preset.\(level.bb)")
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 168)
                        .onChange(of: selectedPresetBB) { _, newValue in
                            if let level = presets.first(where: { $0.bb == newValue }) {
                                applyPreset(level)
                            }
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("blinds.enter")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                        HStack(spacing: 10) {
                            blindInputField(
                                titleKey: "blinds.small_blind",
                                placeholderKey: "blinds.small_placeholder",
                                text: $smallBlindText,
                                identifier: "blind.small.input",
                                focus: .smallBlind
                            )
                            blindInputField(
                                titleKey: "blinds.big_blind",
                                placeholderKey: "blinds.big_placeholder",
                                text: $bigBlindText,
                                identifier: "blind.input",
                                focus: .bigBlind
                            )
                        }
                        .onAppear {
                            onAppear()
                            if smallBlindText.isEmpty, bigBlindText.isEmpty, let first = presets.first {
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
                .accessibilityIdentifier(isEditingFromResult ? "blind.done" : "blind.next")
                .padding(.horizontal)
                .disabled(!canProceed)
            }
            .padding(.vertical, 8)
            .background(Theme.background.opacity(0.9))
        }
    }
    
    @ViewBuilder
    private func currentBlindSelection(_ level: (sb: Int, bb: Int)) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                blindValueColumn(title: "SB", value: level.sb)
                Rectangle()
                    .fill(Theme.surfaceStroke)
                    .frame(width: 1, height: 44)
                blindValueColumn(title: "BB", value: level.bb)
            }
        }
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

    private func applyPreset(_ level: (sb: Int, bb: Int)) {
        if smallBlindText != String(level.sb) || bigBlindText != String(level.bb) {
            selectPreset(level.sb, level.bb)
        }
    }

    private func syncPresetSelectionFromText() {
        guard let value = Int(bigBlindText),
              presets.contains(where: { $0.bb == value }),
              selectedPresetBB != value
        else { return }
        selectedPresetBB = value
    }

    private func currentPresetPosition() -> Int {
        guard let index = presets.firstIndex(where: { $0.bb == selectedPresetBB }) else { return 1 }
        return index + 1
    }

    private func movePreset(delta: Int) {
        guard let currentIndex = presets.firstIndex(where: { $0.bb == selectedPresetBB }) else { return }
        let nextIndex = currentIndex + delta
        guard presets.indices.contains(nextIndex) else { return }
        selectedPresetBB = presets[nextIndex].bb
    }

    private func previousPreset(before bb: Int) -> (sb: Int, bb: Int)? {
        guard let index = presets.firstIndex(where: { $0.bb == bb }), index > 0 else { return nil }
        return presets[index - 1]
    }

    private func nextPreset(after bb: Int) -> (sb: Int, bb: Int)? {
        guard let index = presets.firstIndex(where: { $0.bb == bb }), index + 1 < presets.count else { return nil }
        return presets[index + 1]
    }
}

private enum BlindFocusedInput: Hashable {
    case smallBlind
    case bigBlind
    case inputGroup
}
