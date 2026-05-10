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
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
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

struct ChipAdjustControl: View {
    let label: String
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
                    Image(systemName: "minus")
                        .font(.headline.weight(.bold))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.healthRed)
                .background(Circle().fill(Theme.healthRed.opacity(0.16)))
                .accessibilityLabel(Text("-\(label)"))
                .accessibilityIdentifier("chip.minus.\(label)")

                Button(action: addAction) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
                .background(Circle().fill(Theme.accent.opacity(0.16)))
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
