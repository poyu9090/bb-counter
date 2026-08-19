import SwiftUI

struct ChipsInputView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var chipsText: String
    let onNext: () -> Void
    let onBack: (() -> Void)?
    let onAppear: () -> Void
    let buttonLabelKey: String
    /// 只用來換算深度預覽；為 0 時不顯示。
    let bigBlind: Int
    
    /// 各面额枚数 [5万, 1万, 5千, 1千, 500, 100]，不自动换算（5 个 1 千不合并成 1 个 5 千）
    @State private var breakdown: [Int] = [0, 0, 0, 0, 0, 0]
    /// 由按钮更新 chipsText 时设为 true，避免 onChange 里用贪心覆盖 breakdown
    @State private var skipSyncFromText: Bool = false
    @FocusState private var focusedInput: ChipsFocusedInput?
    @AppStorage("chipBreakdown") private var chipBreakdownStored: String = "0,0,0,0,0,0"
    
    private static let denomValues: [Int] = [50000, 10000, 5000, 1000, 500, 100]
    private static let maxChipValue: Int = 999_999_999
    
    init(
        chipsText: Binding<String>,
        onNext: @escaping () -> Void,
        onBack: (() -> Void)? = nil,
        onAppear: @escaping () -> Void,
        buttonLabelKey: String = "action.next",
        bigBlind: Int = 0
    ) {
        self._chipsText = chipsText
        self.onNext = onNext
        self.onBack = onBack
        self.onAppear = onAppear
        self.buttonLabelKey = buttonLabelKey
        self.bigBlind = bigBlind
    }
    
    private func total(from b: [Int]) -> Int {
        zip(Self.denomValues, b).reduce(0) { $0 + $1.0 * $1.1 }
    }

    private var parsedChips: Int? {
        Int(chipsText)
    }

    private var inputErrorKey: String? {
        guard !chipsText.isEmpty else { return nil }
        guard let value = parsedChips else { return "input.error_too_large" }
        if value < 0 { return "input.error_required" }
        if value == 0, onBack == nil { return "input.error_required" }
        if value > Self.maxChipValue { return "input.error_too_large" }
        return nil
    }

    private var canProceed: Bool {
        guard let value = parsedChips else { return false }
        if onBack != nil {
            return value >= 0 && value <= Self.maxChipValue
        }
        return value > 0 && value <= Self.maxChipValue
    }

    private var titleKey: LocalizedStringKey {
        onBack == nil ? "chips.title" : "chips.current_title"
    }

    private var adjustmentPreviewValue: Int {
        Int(chipsText) ?? 0
    }

    /// 改總額時最想確認的其實是「這樣是幾個 BB」，直接寫在數字底下省得回去看。
    private var depthPreview: String? {
        guard bigBlind > 0, let chips = parsedChips, chips > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: Double(chips) / Double(bigBlind))) ?? "0"
        return String(format: NSLocalizedString("chips.depth_preview", comment: ""), value, "\(bigBlind)")
    }

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var contentMaxWidth: CGFloat {
        isWideLayout ? 640 : .infinity
    }

    private var chipGridColumns: [GridItem] {
        if isWideLayout {
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        }
        return [GridItem(.adaptive(minimum: 96), spacing: 10)]
    }

    private func formattedChips(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
    
    /// 仅当用户手动输入数字时，用贪心分解同步 breakdown（例如输入 1 万 → 1 枚 1 万）
    private func syncBreakdownFromText() {
        let totalVal = Int(chipsText) ?? 0
        applyGreedyBreakdown(to: totalVal)
        saveBreakdown()
    }
    
    /// 按总面额贪心分解并更新 breakdown（扣除时允许自动换算展示）
    private func applyGreedyBreakdown(to totalVal: Int) {
        var rem = totalVal
        var newBreakdown: [Int] = []
        for v in Self.denomValues {
            let n = rem / v
            newBreakdown.append(n)
            rem = rem % v
        }
        breakdown = newBreakdown
    }
    
    /// 持久化 breakdown，从结果页进入编辑筹码时可恢复原本展示
    private func saveBreakdown() {
        chipBreakdownStored = breakdown.map(String.init).joined(separator: ",")
    }
    
    /// 从存储解析 breakdown，若总面额与当前 chipsText 一致则恢复，否则用贪心
    private func restoreOrSyncBreakdown() {
        let currentTotal = Int(chipsText) ?? 0
        let parsed = chipBreakdownStored.split(separator: ",").compactMap { Int($0) }
        if parsed.count == Self.denomValues.count, total(from: parsed) == currentTotal {
            breakdown = parsed
        } else {
            syncBreakdownFromText()
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack(spacing: 12) {
                        if let onBack {
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
                            .accessibilityIdentifier("chips.back")
                        } else {
                            Color.clear
                                .frame(width: 44, height: 44)
                        }

                        Text(titleKey)
                            .font(.largeTitle).bold()
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)

                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 40)

                    TextField(LocalizedStringKey("chips.placeholder"), text: $chipsText)
                        .keyboardType(.numberPad)
                        .focused($focusedInput, equals: .chips)
                        .textFieldStyle(.plain)
                        .accessibilityIdentifier("chips.input")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.surfaceStroke, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .id(ChipsFocusedInput.chips)
                        .onChange(of: chipsText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                chipsText = filtered
                            } else if !skipSyncFromText {
                                syncBreakdownFromText()
                            } else {
                                skipSyncFromText = false
                            }
                        }
                        .onAppear {
                            onAppear()
                            restoreOrSyncBreakdown()
                        }
                    if let depthPreview {
                        Text(depthPreview)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }

                    if let inputErrorKey {
                        Text(LocalizedStringKey(inputErrorKey))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.healthRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }

                    ChipStackView(breakdown: breakdown)
                        .frame(height: 120)
                        .padding(.horizontal)

                    LazyVGrid(columns: chipGridColumns, spacing: isWideLayout ? 12 : 10) {
                        ForEach(Self.denomValues, id: \.self) { value in
                            ChipAdjustControl(
                                label: denominationLabel(value),
                                isSubtractDisabled: total(from: breakdown) == 0,
                                addAction: { addByDenomination(value) },
                                subtractAction: { subtractByDenomination(value) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focusedInput) { _, input in
                guard let input else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(input, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 32)
        .keyboardAwareBottomBar {
            VStack(spacing: 12) {
                Button(action: onNext) {
                    Text(LocalizedStringKey(buttonLabelKey))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.headline)
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("chips.next")
                .padding(.horizontal)
                .disabled(!canProceed)
            }
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Theme.background.opacity(0.9))
        }
    }
    
    /// 增加：按面额逐一增加，不自动换算。
    private func addByDenomination(_ amount: Int) {
        guard amount > 0, let idx = Self.denomValues.firstIndex(of: amount) else { return }
        guard total(from: breakdown) + amount <= Self.maxChipValue else { return }
        breakdown[idx] += 1
        updateTextFromBreakdown()
    }

    /// 扣除：按总额扣减并用贪心重排展示；扣超过目前总额时归零。
    private func subtractByDenomination(_ amount: Int) {
        guard amount > 0, Self.denomValues.contains(amount) else { return }
        let newTotal = max(0, total(from: breakdown) - amount)
        applyGreedyBreakdown(to: newTotal)
        updateTextFromBreakdown()
    }

    private func updateTextFromBreakdown() {
        skipSyncFromText = true
        chipsText = String(total(from: breakdown))
        saveBreakdown()
    }

	private func denominationLabel(_ value: Int) -> String {
		value >= 1000 ? "\(value / 1000)k" : "\(value)"
	}
}

private enum ChipsFocusedInput: Hashable {
    case chips
}

// MARK: - Chip Stack (堆叠筹码，按实际操作面额显示，不自动换算)
private struct ChipDenomination: Identifiable {
    let id: Int
    let value: Int
    let edgeColor: Color
    let innerColor: Color
    
    /// 面额顺序：5万、1万、5千、1千、500、100（点 +1万 显示 1 枚 1 万，不合并为 2×5千）
    static let all: [ChipDenomination] = [
        ChipDenomination(id: 50000, value: 50000, edgeColor: Color(red: 0.35, green: 0.78, blue: 0.9), innerColor: Color(red: 0.1, green: 0.46, blue: 0.72)),
        ChipDenomination(id: 10000, value: 10000, edgeColor: Color(red: 0.95, green: 0.45, blue: 0.65), innerColor: Color(red: 0.9, green: 0.25, blue: 0.55)),
        ChipDenomination(id: 5000, value: 5000, edgeColor: Color(red: 0.6, green: 0.35, blue: 0.5), innerColor: Color(red: 0.75, green: 0.5, blue: 0.65)),
        ChipDenomination(id: 1000, value: 1000, edgeColor: Color(red: 0.95, green: 0.82, blue: 0.25), innerColor: Color(red: 0.95, green: 0.55, blue: 0.2)),
        ChipDenomination(id: 500, value: 500, edgeColor: Color(red: 0.45, green: 0.22, blue: 0.52), innerColor: Color(red: 0.62, green: 0.52, blue: 0.62)),
        ChipDenomination(id: 100, value: 100, edgeColor: Color(red: 0.18, green: 0.18, blue: 0.18), innerColor: Color(red: 0.72, green: 0.48, blue: 0.28))
    ]
}

private struct ChipStackView: View {
    /// 各面额枚数 [n10000, n5000, n1000, n500, n100]，与 ChipDenomination.all 顺序一致
    let breakdown: [Int]
    
    private static let maxChipsPerStack: Int = 15
    
    private func count(for denomination: ChipDenomination) -> Int {
        guard let idx = ChipDenomination.all.firstIndex(where: { $0.id == denomination.id }) else { return 0 }
        return min(Self.maxChipsPerStack, breakdown.indices.contains(idx) ? breakdown[idx] : 0)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(ChipDenomination.all) { denom in
                let n = count(for: denom)
                if n > 0 {
                    ZStack(alignment: .bottom) {
                        ForEach(0..<n, id: \.self) { index in
                            SingleChipView(denomination: denom.value, edgeColor: denom.edgeColor, innerColor: denom.innerColor)
                                .offset(y: CGFloat(index) * -5)
                                .zIndex(Double(index))
                        }
                    }
                    .frame(width: 38, height: 70)
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: n)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: breakdown)
    }
}

private struct SingleChipView: View {
    let denomination: Int
    let edgeColor: Color
    let innerColor: Color
    
    private var faceLabel: String {
        if denomination >= 1000 {
            return "\(denomination / 1000)k"
        }
        return "\(denomination)"
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(innerColor)
                .frame(width: 34, height: 34)
            Circle()
                .strokeBorder(edgeColor, lineWidth: 4)
                .frame(width: 34, height: 34)
            Circle()
                .strokeBorder(edgeColor.opacity(0.4), lineWidth: 1)
                .frame(width: 26, height: 26)
            Text(faceLabel)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
        }
        .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
    }
}
