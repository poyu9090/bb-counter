import SwiftUI

/// iPad（regular 寬度）上把表單夾在一欄裡置中，不然輸入框會被拉成整片 13 吋寬。
/// iPhone 是 compact 寬度，維持原本的滿版。
private struct ReadableColumn: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private static let maxWidth: CGFloat = 640

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: horizontalSizeClass == .regular ? Self.maxWidth : .infinity)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func readableColumn() -> some View {
        modifier(ReadableColumn())
    }
}
