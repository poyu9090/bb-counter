import ActivityKit
import BBLiveActivityKit
import SwiftUI
import WidgetKit

// MARK: - Visual tokens（與主 App Theme 對齊的深色牌桌風格）

private enum LivePalette {
    static let bgTop = Color(red: 0.10, green: 0.11, blue: 0.16)
    static let bgBottom = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let cardFill = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.14)
    static let accent = Color(red: 0.50, green: 0.70, blue: 1.00)
    static let accentMuted = Color(red: 0.50, green: 0.70, blue: 1.00).opacity(0.35)
    static let primary = Color.white.opacity(0.92)
    static let secondary = Color.white.opacity(0.58)

    static func stackBBColor(tier: Int) -> Color {
        switch tier {
        case 0: return Color(red: 1.00, green: 0.40, blue: 0.40)
        case 1: return Color(red: 1.00, green: 0.75, blue: 0.30)
        case 2: return Color(red: 0.95, green: 0.88, blue: 0.38)
        default: return Color(red: 0.45, green: 0.85, blue: 0.55)
        }
    }
}

private func formattedChips(_ value: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.groupingSeparator = ","
    return f.string(from: NSNumber(value: value)) ?? "\(value)"
}

struct BlindTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BlindTimerAttributes.self) { context in
            lockScreenView(context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedMetricBlock(
                        icon: "square.stack.3d.up.fill",
                        titleKey: "live.chips",
                        value: formattedChips(context.state.chips),
                        valueFont: .title2
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedMetricBlock(
                        icon: "rectangle.split.2x1.fill",
                        titleKey: "live.level",
                        value: context.state.currentBlindsText,
                        valueFont: .title3
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomRow(state: context.state)
                }
            } compactLeading: {
                compactIslandChipsRow(state: context.state)
            } compactTrailing: {
                compactIslandTimerColumn(state: context.state)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(LivePalette.accent)
            }
        }
    }

    // MARK: Lock Screen

    @ViewBuilder
    private func lockScreenView(_ state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                metricTile(
                    icon: "square.stack.3d.up.fill",
                    titleKey: "live.chips",
                    primary: formattedChips(state.chips)
                )
                metricTile(
                    icon: "rectangle.split.2x1.fill",
                    titleKey: "live.level",
                    primary: state.currentBlindsText
                )
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(state.stackBBNumericText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(LivePalette.stackBBColor(tier: state.stackBBHealthTier))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(String(localized: "live.bb_unit"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(LivePalette.secondary)
                Spacer(minLength: 8)
                countdownCapsule(state: state)
            }

            if !state.nextBlindText.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(LivePalette.accent)
                    Text(String(localized: "live.next_level"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LivePalette.secondary)
                    Text(state.nextBlindText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LivePalette.primary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(LivePalette.accentMuted.opacity(0.45))
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [LivePalette.bgTop, LivePalette.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .activityBackgroundTint(Color.black.opacity(0.25))
    }

    // MARK: Pieces

    private func metricTile(icon: String, titleKey: LocalizedStringKey, primary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(titleKey)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(LivePalette.secondary)
            } icon: {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(LivePalette.accent)
            }
            .labelStyle(.titleAndIcon)
            Text(primary)
                .font(.headline.weight(.bold))
                .foregroundStyle(LivePalette.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LivePalette.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(LivePalette.cardStroke, lineWidth: 1)
                )
        )
    }

    private func expandedMetricBlock(icon: String, titleKey: LocalizedStringKey, value: String, valueFont: Font) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(titleKey)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(LivePalette.accent)
            }
            .labelStyle(.titleAndIcon)
            Text(value)
                .font(valueFont.bold())
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func expandedBottomRow(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !state.islandChipsSummaryLine.isEmpty {
                Text(state.islandChipsSummaryLine)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            if !state.islandBlindUpgradeTimeLine.isEmpty {
                Text(state.islandBlindUpgradeTimeLine)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(state.stackBBNumericText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(LivePalette.stackBBColor(tier: state.stackBBHealthTier))
                Text(String(localized: "live.bb_unit"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                liveCountdownText(state)
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(LivePalette.accent)
            }
            if !state.nextBlindText.isEmpty {
                HStack(spacing: 6) {
                    Text(String(localized: "live.next_short"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(state.nextBlindText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func countdownCapsule(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(String(localized: "live.countdown"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LivePalette.secondary)
            liveCountdownText(state)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(LivePalette.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LivePalette.cardFill)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [LivePalette.accent.opacity(0.9), LivePalette.accent.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
    }

    /// 緊湊靈動島左側：籌碼標題 + 數量與 (xxbb)（長按展開可看完整兩行說明）
    private func compactIslandChipsRow(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(localized: "live.compact.chips_caption"))
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedChips(state.chips))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LivePalette.primary)
                Text("(\(state.stackBBNumericText)bb)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LivePalette.stackBBColor(tier: state.stackBBHealthTier))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.55)
        }
    }

    /// 緊湊靈動島右側：倒數 + 升盲牆上時鐘
    private func compactIslandTimerColumn(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            liveCountdownText(state)
                .font(.caption2.monospacedDigit().bold())
                .foregroundStyle(LivePalette.accent)
            if !state.islandUpgradeAtClock.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(localized: "live.compact.blinds_caption"))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(state.islandUpgradeAtClock)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(LivePalette.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            } else {
                Text(String(localized: "live.compact.blinds_paused"))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func liveCountdownText(_ state: BlindTimerAttributes.ContentState) -> some View {
        if let end = state.countdownPeriodEnd {
            Text(end, style: .timer)
        } else {
            Text(state.timeRemainingText)
        }
    }
}
