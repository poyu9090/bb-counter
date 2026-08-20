import SwiftUI

/// 籌碼變化卡：這一頁的主角。輸入、結果、歷史收在同一張卡裡閉環。
/// 快捷金額是「填進輸入框、可累加」，按下記錄才寫入——誤觸不會直接改到籌碼。
struct ChipChangeCard: View {
    let summary: SessionSummary
    let onApplyChipChange: (Int) -> Void
    let onEditChips: () -> Void
    let onOpenHistory: () -> Void

    @State private var isWinning: Bool = true
    @State private var amountText: String = ""
    @State private var recordedTrigger: Int = 0
    @FocusState private var isAmountFocused: Bool

    private static let quickAmounts = [1_000, 5_000, 10_000]

    private var amount: Int {
        Int(amountText) ?? 0
    }

    private var canRecord: Bool {
        amount > 0
    }

    private var deltaColor: Color {
        if summary.delta == 0 { return Theme.secondaryText }
        return summary.delta > 0 ? Theme.healthGreen : Theme.healthRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            inputRow
            quickRow
            footer
        }
        .padding(16)
        .background(Theme.surfaceElevated, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        }
        .sensoryFeedback(.success, trigger: recordedTrigger)
    }

    /// 卡片本身就是輸入區，不需要再標一次「籌碼變化」；標題列讓給本場輸贏。
    private var header: some View {
        HStack {
            Text(String(format: NSLocalizedString("dashboard.session", comment: ""), signedChips(summary.delta)))
                .font(.headline.weight(.bold))
                .foregroundStyle(deltaColor)
                .accessibilityIdentifier("dashboard.sessionDelta")
            Spacer(minLength: 0)
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                directionButton(isWin: true, titleKey: "dashboard.win", tint: Theme.healthGreen)
                directionButton(isWin: false, titleKey: "dashboard.lose", tint: Theme.healthRed)
            }
            .padding(3)
            .background(Theme.background.opacity(0.6), in: .rect(cornerRadius: 12))
            .accessibilityIdentifier("dashboard.direction")

            TextField(LocalizedStringKey("chips.custom_amount_placeholder"), text: $amountText)
            .keyboardType(.numberPad)
            .onChange(of: amountText) { _, newValue in
                let digits = String(newValue.filter(\.isNumber).prefix(9))
                if digits != newValue {
                    amountText = digits
                }
            }
            .focused($isAmountFocused)
            .font(.title3.weight(.bold).monospacedDigit())
            .foregroundStyle(Theme.primaryText)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Theme.background.opacity(0.6), in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isAmountFocused ? Theme.accent.opacity(0.7) : Theme.surfaceStroke, lineWidth: 1)
            }
            .accessibilityIdentifier("dashboard.amount")

            Button(action: record) {
                Text("dashboard.record")
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(canRecord ? Color.white : Theme.secondaryText)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(canRecord ? Theme.accent : Color.clear, in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(canRecord ? Color.clear : Theme.surfaceStroke, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!canRecord)
            .accessibilityIdentifier("dashboard.record")
        }
    }

    private func directionButton(isWin: Bool, titleKey: String, tint: Color) -> some View {
        Button {
            isWinning = isWin
        } label: {
            Text(LocalizedStringKey(titleKey))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isWinning == isWin ? Color.white : Theme.secondaryText)
                .frame(width: 46, height: 38)
                .background(isWinning == isWin ? tint : Color.clear, in: .rect(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isWinning == isWin ? .isSelected : [])
    }

    private var quickRow: some View {
        HStack(spacing: 6) {
            ForEach(Self.quickAmounts, id: \.self) { value in
                Button {
                    amountText = String(min(SessionSummary.maxChipValue, amount + value))
                } label: {
                    Text("+\(shortAmount(value))")
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(
                    Text(String(format: NSLocalizedString("dashboard.quick_add_a11y", comment: ""), formattedChips(value)))
                )
                .accessibilityIdentifier("dashboard.quick.\(value)")
            }

            Button(action: onEditChips) {
                Label("dashboard.change_total", systemImage: "square.stack.3d.up")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, 10)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dashboard.changeTotal")
        }
    }

    private var footer: some View {
        Button(action: onOpenHistory) {
            HStack(spacing: 10) {
                SessionSparkline(points: summary.sparkline, height: 22, isPositive: summary.delta >= 0)
                    .frame(width: 68)
                Spacer(minLength: 0)
                Text(
                    String(
                        format: NSLocalizedString("dashboard.session_footer", comment: ""),
                        summary.recordCount,
                        formattedChips(summary.startChips)
                    )
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.top, 10)
            .frame(minHeight: 44)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.surfaceStroke).frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("dashboard.openHistory")
    }

    private func record() {
        guard canRecord else { return }
        let next = SessionSummary.chips(after: amount, isWinning: isWinning, from: summary.currentChips)
        onApplyChipChange(next)
        amountText = ""
        isAmountFocused = false
        recordedTrigger += 1
    }

    private func shortAmount(_ value: Int) -> String {
        value >= 1_000 ? "\(value / 1_000)k" : "\(value)"
    }

    private func formattedChips(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func signedChips(_ value: Int) -> String {
        let formatted = formattedChips(abs(value))
        return value >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
}
