import ActivityKit
import BBLiveActivityKit
import SwiftUI
import WidgetKit

// MARK: - Visual tokens（與主 App Theme 對齊的深色牌桌風格）

private enum LivePalette {
    static let bgTop = Color(red: 0.08, green: 0.13, blue: 0.12)
    static let bgBottom = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let cardFill = Color.white.opacity(0.075)
    static let cardStroke = Color.white.opacity(0.13)
    static let accent = Color(red: 0.50, green: 0.70, blue: 1.00)
    static let accentMuted = Color(red: 0.50, green: 0.70, blue: 1.00).opacity(0.35)
    static let felt = Color(red: 0.09, green: 0.30, blue: 0.24)
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
                    expandedStackBlock(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedBlindBlock(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomRow(state: context.state)
                }
            } compactLeading: {
                compactIslandStackRow(state: context.state)
            } compactTrailing: {
                compactIslandTimerColumn(state: context.state)
            } minimal: {
                ZStack {
                    Circle()
                        .fill(LivePalette.stackBBColor(tier: context.state.stackBBHealthTier).opacity(0.2))
                    Image(systemName: "timer")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(LivePalette.stackBBColor(tier: context.state.stackBBHealthTier))
                }
            }
            .keylineTint(LivePalette.stackBBColor(tier: context.state.stackBBHealthTier))
        }
    }

    // MARK: Lock Screen

    @ViewBuilder
    private func lockScreenView(_ state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Label {
                    Text("BB Counter")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(LivePalette.primary)
                } icon: {
                    Image(systemName: "suit.club.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LivePalette.accent)
                }
                .labelStyle(.titleAndIcon)

                Spacer(minLength: 8)

                blindPill(state.currentBlindsText, icon: "rectangle.split.2x1.fill")
            }

            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "live.stack"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(LivePalette.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(state.stackBBNumericText)
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundStyle(LivePalette.stackBBColor(tier: state.stackBBHealthTier))
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                        Text(String(localized: "live.bb_unit"))
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(LivePalette.secondary)
                    }
                    Text(formattedChips(state.chips))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LivePalette.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                countdownCapsule(state: state)
            }

            bottomInfoStrip(state: state)
        }
        .padding(16)
        .background(
            ZStack {
                LinearGradient(
                    colors: [LivePalette.bgTop, LivePalette.bgBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [LivePalette.felt.opacity(0.45), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .activityBackgroundTint(Color.black.opacity(0.25))
        .activitySystemActionForegroundColor(LivePalette.accent)
    }

    // MARK: Pieces

    private func blindPill(_ text: String, icon: String) -> some View {
        Label {
            Text(text)
                .font(.caption.weight(.heavy))
                .foregroundStyle(LivePalette.primary)
                .monospacedDigit()
                .lineLimit(1)
        } icon: {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(LivePalette.accent)
        }
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(LivePalette.cardFill)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(LivePalette.cardStroke, lineWidth: 1)
                )
        )
    }

    private func expandedStackBlock(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(localized: "live.stack"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(state.stackBBNumericText)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LivePalette.stackBBColor(tier: state.stackBBHealthTier))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(String(localized: "live.bb_unit"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.secondary)
            }
            Text(formattedChips(state.chips))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func expandedBlindBlock(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(String(localized: "live.current_short"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(state.currentBlindsText)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            if !state.nextBlindText.isEmpty {
                Text("\(String(localized: "live.next_short")) \(state.nextBlindText)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func expandedBottomRow(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LivePalette.accent)
                Text(String(localized: "live.countdown"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                liveCountdownText(state)
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(LivePalette.accent)
            }

            HStack(spacing: 10) {
                if !state.islandUpgradeAtClock.isEmpty {
                    Label {
                        Text(state.islandUpgradeAtClock)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "arrow.up.forward.circle.fill")
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
                if !state.nextBlindText.isEmpty {
                    Label {
                        Text(state.nextBlindText)
                            .monospacedDigit()
                    } icon: {
                        Text(String(localized: "live.next_short"))
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bottomInfoStrip(state: BlindTimerAttributes.ContentState) -> some View {
        HStack(spacing: 8) {
            if !state.nextBlindText.isEmpty {
                Label {
                    Text(state.nextBlindText)
                        .monospacedDigit()
                } icon: {
                    Text(String(localized: "live.next_short"))
                }
            }
            Spacer(minLength: 4)
            if !state.islandUpgradeAtClock.isEmpty {
                Label {
                    Text(state.islandUpgradeAtClock)
                        .monospacedDigit()
                } icon: {
                    Text(String(localized: "live.up_at"))
                }
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(LivePalette.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LivePalette.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LivePalette.cardStroke, lineWidth: 1)
                )
        )
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

    private func compactIslandStackRow(state: BlindTimerAttributes.ContentState) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(state.stackBBNumericText)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(LivePalette.stackBBColor(tier: state.stackBBHealthTier))
            Text("BB")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    private func compactIslandTimerColumn(state: BlindTimerAttributes.ContentState) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            liveCountdownText(state)
                .font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(LivePalette.accent)
            if !state.islandUpgradeAtClock.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(localized: "live.up_at"))
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
