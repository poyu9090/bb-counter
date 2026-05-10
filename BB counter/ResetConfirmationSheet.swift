import SwiftUI

// MARK: - Reset Confirmation Sheet
struct ResetConfirmationSheet: View {
	@Binding var isPresented: Bool
	@Binding var dontShowAgain: Bool
	let onConfirm: () -> Void
	
	var body: some View {
		ZStack {
			Theme.background.ignoresSafeArea()
			VStack(spacing: 24) {
				// Header
				HStack {
					Text("reset.confirm_title")
						.font(.title2.bold())
						.foregroundStyle(Theme.primaryText)
					Spacer()
					Button {
						isPresented = false
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.title3)
							.foregroundStyle(Theme.secondaryText)
					}
				}
				.padding(.horizontal)
				.padding(.top, 8)
				
				// Message
				Text("reset.confirm_message")
					.font(.body)
					.foregroundStyle(Theme.primaryText)
					.multilineTextAlignment(.leading)
					.padding(.horizontal)
				
				// Don't show again option
				Button(action: {
					dontShowAgain.toggle()
				}) {
					HStack(spacing: 12) {
						Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
							.font(.title3)
							.foregroundStyle(dontShowAgain ? Theme.accent : Theme.secondaryText)
						Text("reset.dont_show_again")
							.font(.subheadline)
							.foregroundStyle(Theme.primaryText)
						Spacer()
					}
				}
				.buttonStyle(.plain)
				.padding(.horizontal)
				
				Spacer()
			}
			.padding(.top, 16)
		}
		.safeAreaInset(edge: .bottom) {
			VStack(spacing: 12) {
				Button(action: {
					onConfirm()
					isPresented = false
				}) {
					Text("action.confirm")
						.frame(maxWidth: .infinity)
						.padding()
						.font(.headline)
						.foregroundStyle(Color.white)
				}
				.buttonStyle(.borderedProminent)
				.padding(.horizontal)
				
				Button(role: .cancel, action: {
					isPresented = false
				}) {
					Text("action.cancel")
						.frame(maxWidth: .infinity)
						.padding()
						.foregroundStyle(Theme.primaryText)
				}
				.buttonStyle(.bordered)
				.padding(.horizontal)
				.padding(.bottom, 4)
			}
			.padding(.vertical, 8)
			.background(Theme.background.opacity(0.95))
		}
		.preferredColorScheme(.dark)
		.tint(Theme.accent)
	}
}
