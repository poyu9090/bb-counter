import SwiftUI
import UIKit

/// 籌碼變化卡：這一頁的主角。輸入、結果、歷史收在同一張卡裡閉環。
/// 快捷金額是「填進輸入框、可累加」，按下記錄才寫入——誤觸不會直接改到籌碼。
struct ChipChangeCard: View {
    let summary: SessionSummary
    let onApplyChipChange: (Int) -> Void
    let onEditChips: () -> Void
    let onOpenHistory: () -> Void

    @State private var isWinning: Bool = true
    @State private var amountText: String = ""
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
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Text("chips.quick_adjust")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Text(String(format: NSLocalizedString("dashboard.session", comment: ""), signedChips(summary.delta)))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(deltaColor)
                .accessibilityIdentifier("dashboard.sessionDelta")
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            Picker("", selection: $isWinning) {
                Text("dashboard.win").tag(true)
                Text("dashboard.lose").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .accessibilityIdentifier("dashboard.direction")

            TextField(LocalizedStringKey("chips.custom_amount_placeholder"), text: Binding(
                get: { amountText },
                set: { amountText = String($0.filter(\.isNumber).prefix(9)) }
            ))
            .keyboardType(.numberPad)
            .focused($isAmountFocused)
            .font(.title3.weight(.bold).monospacedDigit())
            .foregroundStyle(Theme.primaryText)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.background.opacity(0.6)))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isAmountFocused ? Theme.accent.opacity(0.7) : Theme.surfaceStroke, lineWidth: 1)
            )
            .accessibilityIdentifier("dashboard.amount")

            Button(action: record) {
                Text("dashboard.record")
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canRecord)
            .accessibilityIdentifier("dashboard.record")
        }
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
                        .frame(height: 36)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("dashboard.quick.\(value)")
            }

            Button(action: onEditChips) {
                Text("dashboard.change_total")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("dashboard.changeTotal")
        }
    }

    private var footer: some View {
        Button(action: onOpenHistory) {
            HStack(spacing: 10) {
                SessionSparkline(points: summary.sparkline, isPositive: summary.delta >= 0)
                    .frame(width: 68, height: 22)
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
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.surfaceStroke).frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard.openHistory")
    }

    private func record() {
        guard canRecord else { return }
        let next = SessionSummary.chips(after: amount, isWinning: isWinning, from: summary.currentChips)
        onApplyChipChange(next)
        amountText = ""
        isAmountFocused = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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

/// 本場籌碼走勢的迷你長條圖，只表達起伏，不標數字。
private struct SessionSparkline: View {
    let points: [Int]
    let isPositive: Bool

    var body: some View {
        GeometryReader { proxy in
            let values = points.count > 1 ? points : []
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let span = max(1, maxValue - minValue)
            let barWidth = values.isEmpty ? 0 : max(2, (proxy.size.width - CGFloat(values.count - 1) * 3) / CGFloat(values.count))

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                    let ratio = Double(value - minValue) / Double(span)
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill((isPositive ? Theme.healthGreen : Theme.healthRed).opacity(0.55))
                        .frame(width: barWidth, height: max(3, proxy.size.height * (0.25 + 0.75 * ratio)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .accessibilityHidden(true)
    }
}
