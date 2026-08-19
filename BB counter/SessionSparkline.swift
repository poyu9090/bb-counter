import SwiftUI

/// 本場籌碼走勢的迷你長條圖，只表達起伏，不標數字。
/// 高度由呼叫端決定，所以不需要 GeometryReader 讀尺寸。
struct SessionSparkline: View {
    let points: [Int]
    let height: CGFloat
    let isPositive: Bool

    private var bars: [Double] {
        guard points.count > 1, let minValue = points.min(), let maxValue = points.max() else { return [] }
        let span = Double(max(1, maxValue - minValue))
        return points.map { 0.25 + 0.75 * (Double($0 - minValue) / span) }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, ratio in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill((isPositive ? Theme.healthGreen : Theme.healthRed).opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(3, height * ratio))
            }
        }
        .frame(height: height, alignment: .bottom)
        .accessibilityHidden(true)
    }
}
