import SwiftUI

struct HealthBadge: View {
    let titleKey: String
    let color: Color

    var body: some View {
        Text(LocalizedStringKey(titleKey))
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 1)
            )
    }
}

struct DashboardMetricButton: View {
    let titleKey: String
    let valueText: String
    let iconName: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: iconName)
                        .font(.headline)
                        .foregroundStyle(accent)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(accent.opacity(0.14))
                        )
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.secondaryText)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                    Text(valueText)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 116, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 結果頁最常用的操作：贏一手、輸一手後直接改籌碼，所以放在 BB 深度下方第一排。
struct ChipQuickAdjustBar: View {
    let chipsValueText: String
    let bbValueText: String
    let onQuickAdjust: () -> Void
    let onEditChips: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEditChips) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("result.chips")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText)
                        Image(systemName: "pencil")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Text(chipsValueText)
                        .font(.title2.weight(.black))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(bbValueText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("chips.edit.open")

            Button(action: onQuickAdjust) {
                Image(systemName: "plusminus")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Theme.accent)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 14, x: 0, y: 8)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("chips.quick_adjust"))
            .accessibilityIdentifier("chips.quickAdjust.open")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.surfaceStroke, lineWidth: 1)
        )
    }
}

/// 沿用原本籌碼頁的做法：自行輸入這手要「增加」或「減少」多少籌碼，
/// 只是改成結果頁上的 sheet，不用整頁跳走。確認後才寫回並留下一筆變化紀錄。
struct ChipQuickAdjustSheet: View {
    let currentChips: Int
    let onApply: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var increaseText: String = ""
    @State private var decreaseText: String = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case increase
        case decrease
    }

    private static let maxChipValue: Int = 999_999_999

    private var increaseValue: Int {
        Int(increaseText) ?? 0
    }

    private var decreaseValue: Int {
        Int(decreaseText) ?? 0
    }

    private var draftChips: Int {
        min(Self.maxChipValue, max(0, currentChips + increaseValue - decreaseValue))
    }

    private var delta: Int {
        draftChips - currentChips
    }

    private var deltaColor: Color {
        if delta == 0 { return Theme.secondaryText }
        return delta > 0 ? Theme.healthGreen : Theme.healthRed
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    summaryCard
                    amountFields
                }
                .padding(16)
                .padding(.bottom, 90)
            }
            .background(Theme.background.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text("chips.quick_adjust"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("action.cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                focusedField = .increase
            }
            .keyboardAwareBottomBar {
                Button {
                    onApply(draftChips)
                    dismiss()
                } label: {
                    Text("action.save")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(delta == 0)
                .accessibilityIdentifier("chips.quickAdjust.save")
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .background(Theme.background.opacity(0.78))
            }
        }
        .keyboardConfirmationToolbar()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("chips.after_adjustment")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)

            Text(formattedChips(draftChips))
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 8) {
                Text(signedChips(delta))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(deltaColor)
                Text("\(formattedChips(currentChips)) →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Spacer(minLength: 0)
                Button {
                    increaseText = ""
                    decreaseText = ""
                    focusedField = .increase
                } label: {
                    Label("chips.quick_adjust_reset", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.bordered)
                .disabled(delta == 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.surfaceStroke, lineWidth: 1)
        )
    }

    private var amountFields: some View {
        VStack(spacing: 10) {
            amountField(
                titleKey: "chips.increase_amount",
                field: .increase,
                text: $increaseText,
                iconName: "plus",
                tint: Theme.healthGreen,
                accessibilityIdentifier: "chips.quickAdjust.increase"
            )
            amountField(
                titleKey: "chips.decrease_amount",
                field: .decrease,
                text: $decreaseText,
                iconName: "minus",
                tint: Theme.healthRed,
                accessibilityIdentifier: "chips.quickAdjust.decrease"
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.surfaceStroke, lineWidth: 1)
        )
    }

    private func amountField(
        titleKey: String,
        field: Field,
        text: Binding<String>,
        iconName: String,
        tint: Color,
        accessibilityIdentifier: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(Circle().fill(tint.opacity(0.16)))

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(titleKey))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)

                TextField(LocalizedStringKey("chips.custom_amount_placeholder"), text: Binding(
                    get: { text.wrappedValue },
                    set: { text.wrappedValue = $0.filter { $0.isNumber } }
                ))
                .keyboardType(.numberPad)
                .focused($focusedField, equals: field)
                .textFieldStyle(.plain)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.primaryText)
                .frame(minHeight: 30)
                .accessibilityIdentifier(accessibilityIdentifier)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.background.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(focusedField == field ? tint.opacity(0.7) : Theme.surfaceStroke, lineWidth: 1)
        )
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

struct ChipHistoryButton: View {
    let recordCount: Int
    let latestDeltaText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Theme.accent.opacity(0.14))
                        )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("chips.history.title")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                    Text(latestDeltaText)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(recordCount == 0 ? Theme.secondaryText : Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(String(format: NSLocalizedString("chips.history.count", comment: ""), recordCount))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(width: 128, alignment: .leading)
            .frame(height: 116, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("chips.history.title"))
        .accessibilityIdentifier("chips.history.open")
    }
}

struct ChipChangeHistoryView: View {
    let records: [ChipChangeRecord]
    let onClear: () -> Void
    /// 當成分頁使用時不需要「完成」。
    var showsDoneButton: Bool = true
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(records) { record in
                            ChipChangeRecordRow(record: record)
                                .listRowBackground(Theme.surfaceElevated)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.background)
                }
            }
            .navigationTitle(Text("chips.history.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if showsDoneButton {
                        Button("action.done") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !records.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel(Text("chips.history.clear"))
                    }
                }
            }
            .confirmationDialog(
                Text("chips.history.clear_title"),
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("chips.history.clear", role: .destructive) {
                    onClear()
                }
                Button("action.cancel", role: .cancel) {}
            } message: {
                Text("chips.history.clear_message")
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text("chips.history.empty_title")
                .font(.headline)
                .foregroundStyle(Theme.primaryText)
            Text("chips.history.empty_body")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

private struct ChipChangeRecordRow: View {
    let record: ChipChangeRecord

    private var isPositive: Bool {
        record.delta >= 0
    }

    private var accent: Color {
        isPositive ? Theme.healthGreen : Theme.healthRed
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                Image(systemName: isPositive ? "plus" : "minus")
                    .font(.caption.weight(.black))
                    .foregroundStyle(accent)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(signedChips(record.delta))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(accent)
                Text("\(formattedChips(record.previousChips)) → \(formattedChips(record.newChips))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 8)

            Text(formattedDate(record.changedAt))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct ChipAdjustControl: View {
    let label: String
    let isSubtractDisabled: Bool
    let addAction: () -> Void
    let subtractAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                Button(action: subtractAction) {
                    ZStack {
                        Circle()
                            .fill(isSubtractDisabled ? Theme.surfaceStroke.opacity(0.22) : Theme.healthRed.opacity(0.16))
                        Image(systemName: "minus")
                            .font(.headline.weight(.bold))
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(isSubtractDisabled ? Theme.secondaryText.opacity(0.45) : Theme.healthRed)
                .disabled(isSubtractDisabled)
                .accessibilityLabel(Text("-\(label)"))
                .accessibilityIdentifier("chip.minus.\(label)")

                Button(action: addAction) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.16))
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
                .accessibilityLabel(Text("+\(label)"))
                .accessibilityIdentifier("chip.plus.\(label)")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.surfaceStroke, lineWidth: 1)
        )
    }
}
