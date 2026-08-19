import SwiftUI

/// 升盲倒數卡。錦標賽真正要判斷的是「時間換算成深度」，所以下一級盲注旁邊
/// 直接寫出升盲後還剩幾個 BB，而不是只報一個下一級的數字。
struct BlindTimerCard: View {
    @ObservedObject var blindSession: BlindTimerSession
    @Binding var timerEnabled: Bool
    let timerDurationSec: Int
    let chips: Int
    let bigBlind: Int
    let onConfigure: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var clockFontSize: CGFloat = 46

    private var outlook: BlindOutlook {
        BlindOutlook.make(
            chips: chips,
            currentBigBlind: bigBlind,
            progression: blindSession.effectiveProgression().map { BlindLevel(sb: $0.sb, bb: $0.bb) },
            queuedIndices: blindSession.queuedIndices,
            selectedNextIndex: blindSession.selectedNextIndex
        )
    }

    private var progress: Double {
        guard timerDurationSec > 0 else { return 0 }
        return min(1, max(0, Double(blindSession.remainingSeconds) / Double(timerDurationSec)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if bigBlind <= 0 {
                missingBlindsBody
            } else if timerEnabled {
                runningBody
            } else {
                idleBody
            }
        }
        .padding(16)
        .background(Theme.surfaceElevated, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.surfaceStroke, lineWidth: 1)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Label("timer.title", systemImage: "timer")
                .font(.headline)
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Button(action: onConfigure) {
                Label("timer.configure", systemImage: "slider.horizontal.3")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(Text("timer.configure"))
            .accessibilityIdentifier("timer.configure")

            Toggle(isOn: $timerEnabled) {
                Text("timer.title")
            }
            .labelsHidden()
            .toggleStyle(.switch)
            // 沒有盲注就沒有級距可升，開了也只會空轉。
            .disabled(bigBlind <= 0)
            .accessibilityIdentifier("timer.toggle")
        }
    }

    private var runningBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formattedTime(blindSession.remainingSeconds))
                        .font(.system(size: min(clockFontSize, 64), weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.primaryText)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    nextLevelLine
                }

                Spacer(minLength: 8)

                Button {
                    if blindSession.isPaused {
                        blindSession.isPaused = false
                    } else {
                        blindSession.snapRemainingAtPause()
                        blindSession.isPaused = true
                    }
                } label: {
                    Image(systemName: blindSession.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 62, height: 62)
                        .background(
                            Circle()
                                .fill(Theme.accent)
                                .shadow(color: Theme.accent.opacity(0.35), radius: 18, x: 0, y: 10)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(blindSession.isPaused ? "timer.resume" : "timer.pause"))
                .accessibilityIdentifier("timer.playPause")
            }

            ProgressView(value: progress)
                .tint(Theme.healthOrange)
                .accessibilityLabel(Text("timer.title"))
                .accessibilityValue(Text(formattedTime(blindSession.remainingSeconds)))
        }
    }

    @ViewBuilder
    private var nextLevelLine: some View {
        if let next = outlook.nextLevel {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(NSLocalizedString("timer.next", comment: "")): \(next.sb)/\(next.bb)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let stack = outlook.stackAfterNextLevel {
                    Text(String(format: NSLocalizedString("dashboard.after_level_up", comment: ""), formattedBB(stack)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color(for: outlook.healthTier))
                        .accessibilityIdentifier("dashboard.afterLevelUp")
                }
            }
        } else {
            Text("dashboard.last_level")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var missingBlindsBody: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.title)
                .foregroundStyle(Theme.healthYellow)
                .frame(width: 44, height: 44)
            Text("dashboard.set_blinds_first")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var idleBody: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer.circle")
                .font(.title)
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("timer.off_title")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                Text("timer.off_body")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func color(for tier: Int?) -> Color {
        switch tier {
        case 0: return Theme.healthRed
        case 1: return Theme.healthOrange
        case 2: return Theme.healthYellow
        case 3: return Theme.healthGreen
        default: return Theme.secondaryText
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func formattedBB(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }
}
