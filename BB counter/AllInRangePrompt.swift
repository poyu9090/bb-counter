import SwiftUI

/// 短碼時出現的 all-in 範圍入口。功能還沒做，先量使用者有多想要。
struct AllInRangePrompt: View {
    let bbCount: Double
    let chips: Int
    let bigBlind: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.healthOrange)
                    .frame(width: 34, height: 34)
                    .background(Theme.healthOrange.opacity(0.14), in: .circle)

                VStack(alignment: .leading, spacing: 3) {
                    Text("all_in_range.title")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.primaryText)
                    Text("all_in_range.subtitle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceElevated, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.healthOrange.opacity(0.28), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("allInRange.prompt")
    }

    private func handleTap() {
        AppAnalytics.trackAllInRangeTap(bbCount: bbCount, chips: chips, bigBlind: bigBlind)
        onTap()
    }
}
