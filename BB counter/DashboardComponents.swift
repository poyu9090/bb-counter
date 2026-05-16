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

struct ChipChangeHistorySheet: View {
    let records: [ChipChangeRecord]
    let onClear: () -> Void
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
                    Button("action.done") {
                        dismiss()
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
