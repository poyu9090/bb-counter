import SwiftUI

/// 狀態卡：BB 深度是主角，籌碼與盲注在下面一行，各自可以點進去編輯。
struct StackStatusCard: View {
    let chips: Int
    let smallBlind: Int
    let bigBlind: Int
    let onEditChips: () -> Void
    let onEditBlinds: () -> Void

    /// 固定 78pt 會完全無視動態字級；綁在 largeTitle 上讓它跟著放大，但設上限免得撐爆卡片。
    @ScaledMetric(relativeTo: .largeTitle) private var bbFontSize: CGFloat = 78

    private var bbCount: Double {
        guard bigBlind > 0 else { return 0 }
        return Double(chips) / Double(bigBlind)
    }

    private var hasBlinds: Bool {
        bigBlind > 0
    }

    private var statusKey: String {
        switch bbCount {
        case ..<10: return "result.status.danger"
        case 10..<20: return "result.status.short"
        case 20..<30: return "result.status.playable"
        default: return "result.status.healthy"
        }
    }

    private var statusColor: Color {
        switch bbCount {
        case ..<10: return Theme.healthRed
        case 10..<20: return Theme.healthOrange
        case 20..<30: return Theme.healthYellow
        default: return Theme.healthGreen
        }
    }

    private var blindText: String {
        guard hasBlinds else { return "—" }
        return "\(smallBlind > 0 ? smallBlind : bigBlind / 2)/\(bigBlind)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text("result.stack_depth")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                if hasBlinds {
                    HealthBadge(titleKey: statusKey, color: statusColor)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(hasBlinds ? formattedBB(bbCount) : "--")
                    .font(.system(size: min(bbFontSize, 104), weight: .black, design: .rounded))
                    .foregroundStyle(hasBlinds ? statusColor : Theme.secondaryText)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                Text("BB")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primaryText.opacity(0.72))
            }
            .accessibilityElement(children: .combine)

            Divider().overlay(Theme.surfaceStroke)

            HStack(spacing: 0) {
                metric(titleKey: "result.chips", value: formattedChips(chips), action: onEditChips)
                    .accessibilityIdentifier("dashboard.chips")
                Rectangle()
                    .fill(Theme.surfaceStroke)
                    .frame(width: 1, height: 34)
                metric(titleKey: "result.blinds", value: blindText, action: onEditBlinds)
                    .accessibilityIdentifier("dashboard.blinds")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.surfaceElevated, Theme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: (hasBlinds ? statusColor : .black).opacity(0.18), radius: 30, x: 0, y: 18)
    }

    private func metric(titleKey: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                    Image(systemName: "pencil")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.secondaryText)
                }
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.leading, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formattedBB(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    private func formattedChips(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
