import Combine
import SwiftUI
import UIKit

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

final class KeyboardVisibilityObserver: ObservableObject {
    @Published var isVisible = false

    private var cancellables: Set<AnyCancellable> = []

    init(notificationCenter: NotificationCenter = .default) {
        notificationCenter.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
            .merge(with: notificationCenter.publisher(for: UIResponder.keyboardWillHideNotification).map { _ in false })
            .receive(on: RunLoop.main)
            .assign(to: &$isVisible)
    }
}

private struct KeyboardAwareBottomBar<Bar: View>: ViewModifier {
    @StateObject private var keyboard = KeyboardVisibilityObserver()
    let bar: () -> Bar

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            if !keyboard.isVisible {
                bar()
            }
        }
    }
}

private struct KeyboardConfirmationToolbar: ViewModifier {
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("action.confirm") {
                    onConfirm()
                    UIApplication.shared.dismissKeyboard()
                }
            }
        }
    }
}

extension View {
    func keyboardAwareBottomBar<Bar: View>(@ViewBuilder _ bar: @escaping () -> Bar) -> some View {
        modifier(KeyboardAwareBottomBar(bar: bar))
    }

    func keyboardConfirmationToolbar(onConfirm: @escaping () -> Void = {}) -> some View {
        modifier(KeyboardConfirmationToolbar(onConfirm: onConfirm))
    }
}
