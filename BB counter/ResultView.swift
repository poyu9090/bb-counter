import SwiftUI

struct ResultView: View {
	let chips: Int
	@Binding var bigBlind: Int
	@ObservedObject var blindSession: BlindTimerSession
	@Binding var timerEnabled: Bool
	@Binding var timerDurationSec: Int
    let onEditChips: () -> Void
    let onEditBlinds: () -> Void
    let onReset: () -> Void
	
	// Explicit initializer to avoid private memberwise init exposure issues
	init(
		chips: Int,
		bigBlind: Binding<Int>,
		blindSession: BlindTimerSession,
		timerEnabled: Binding<Bool>,
		timerDurationSec: Binding<Int>,
		onEditChips: @escaping () -> Void,
		onEditBlinds: @escaping () -> Void,
		onReset: @escaping () -> Void
	) {
		self.chips = chips
		self._bigBlind = bigBlind
		self.blindSession = blindSession
		self._timerEnabled = timerEnabled
		self._timerDurationSec = timerDurationSec
		self.onEditChips = onEditChips
		self.onEditBlinds = onEditBlinds
		self.onReset = onReset
	}
    
    private var bbCount: Double {
        guard bigBlind > 0 else { return 0 }
        return Double(chips) / Double(bigBlind)
    }
	
	private var bbColor: Color {
		switch bbCount {
		case ..<10:
			return Theme.healthRed
		case 10..<20:
			return Theme.healthOrange
		case 20..<30:
			return Theme.healthYellow
		default:
			return Theme.healthGreen
		}
	}
	
	private var nextLevelBBCount: Double {
		let prog = blindSession.effectiveProgression()
		let nextBB: Int
		if let first = blindSession.queuedIndices.first, first < prog.count {
			nextBB = prog[first].bb
		} else {
			let idx = min(max(0, blindSession.selectedNextIndex), max(0, prog.count - 1))
			guard idx >= 0, idx < prog.count else { return 0 }
			nextBB = prog[idx].bb
		}
		guard nextBB > 0 else { return 0 }
		return Double(chips) / Double(nextBB)
	}
	
	private var nextLevelBBColor: Color {
		switch nextLevelBBCount {
		case ..<10:
			return Theme.healthRed
		case 10..<20:
			return Theme.healthOrange
		case 20..<30:
			return Theme.healthYellow
		default:
			return Theme.healthGreen
		}
	}
	
	@State private var showTimerSheet: Bool = false
	@State private var showResetConfirmation: Bool = false
	@State private var dontShowResetConfirmation: Bool = false
	@State private var liveActivityStatusKey: String?
	@AppStorage("dontShowResetConfirmation") private var dontShowResetConfirmationStored: Bool = false

	private var stackStatusKey: String {
		switch bbCount {
		case ..<10:
			return "result.status.danger"
		case 10..<20:
			return "result.status.short"
		case 20..<30:
			return "result.status.playable"
		default:
			return "result.status.healthy"
		}
	}

	private var blindText: String {
		"\(bigBlind / 2)/\(bigBlind)"
	}
    
    var body: some View {
		ScrollView(.vertical, showsIndicators: false) {
			VStack(spacing: 16) {
				stackHero
				LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
					DashboardMetricButton(
						titleKey: "result.chips",
						valueText: formattedChips(chips),
						iconName: "square.stack.3d.up.fill",
						accent: Theme.chipGold,
						action: onEditChips
					)
					DashboardMetricButton(
						titleKey: "result.blinds",
						valueText: blindText,
						iconName: "rectangle.split.2x1.fill",
						accent: Theme.accent,
						action: onEditBlinds
					)
				}
				timerDashboard
				if let liveActivityStatusKey {
					HStack(spacing: 10) {
						Image(systemName: "exclamationmark.triangle.fill")
							.foregroundStyle(Theme.healthYellow)
						Text(LocalizedStringKey(liveActivityStatusKey))
							.font(.caption.weight(.semibold))
							.foregroundStyle(Theme.secondaryText)
							.fixedSize(horizontal: false, vertical: true)
						Spacer(minLength: 0)
					}
					.padding(12)
					.background(
						RoundedRectangle(cornerRadius: 14, style: .continuous)
							.fill(Theme.healthYellow.opacity(0.12))
					)
				}
			}
			.padding(.horizontal, 16)
			.padding(.top, 18)
			.padding(.bottom, 120)
		}
		.accessibilityIdentifier("result.screen")
		.background(
			RadialGradient(
				colors: [Theme.tableFelt.opacity(0.8), Theme.background],
				center: .top,
				startRadius: 30,
				endRadius: 520
			)
			.ignoresSafeArea()
		)
		.onChange(of: chips) { _, _ in
			syncLiveActivityFromCurrentState()
		}
		.onChange(of: bigBlind) { _, _ in
			syncLiveActivityFromCurrentState()
		}
		.onChange(of: blindSession.remainingSeconds) { _, _ in
			syncLiveActivityFromCurrentState()
		}
		.onChange(of: blindSession.isPaused) { _, _ in
			syncLiveActivityFromCurrentState()
		}
		.onChange(of: blindSession.selectedNextIndex) { _, _ in
			syncLiveActivityFromCurrentState()
		}
		.onChange(of: blindSession.queuedIndices) { _, _ in
			syncLiveActivityFromCurrentState()
		}
		.onReceive(NotificationCenter.default.publisher(for: .blindTimerLiveActivityStatusChanged)) { notification in
			liveActivityStatusKey = notification.object as? String
		}
		.safeAreaInset(edge: .bottom) {
			VStack(spacing: 10) {
				HStack(spacing: 12) {
					Button(action: onEditChips) {
						Label("action.edit_chips", systemImage: "square.stack.3d.up.fill")
							.frame(maxWidth: .infinity)
							.padding(.vertical, 13)
					}
					.buttonStyle(.bordered)
					
					Button(action: onEditBlinds) {
						Label("action.edit_blinds", systemImage: "rectangle.split.2x1.fill")
							.frame(maxWidth: .infinity)
							.padding(.vertical, 13)
					}
					.buttonStyle(.bordered)
				}
				.padding(.horizontal)
				
				Button(role: .destructive, action: {
					if dontShowResetConfirmationStored {
						onReset()
					} else {
						showResetConfirmation = true
					}
				}) {
					Label("action.reset", systemImage: "arrow.counterclockwise")
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.font(.headline)
						.foregroundStyle(Color.white)
				}
				.buttonStyle(.borderedProminent)
				.padding(.horizontal)
			}
			.padding(.vertical, 10)
			.background(.ultraThinMaterial)
			.background(Theme.background.opacity(0.76))
		}
		.sheet(isPresented: $showTimerSheet) {
			TimerConfigSheet(
				isPresented: $showTimerSheet,
				timerEnabled: $timerEnabled,
				timerDurationSec: $timerDurationSec,
				progression: BlindTimerSession.progression,
					currentIndex: blindSession.currentIndex(for: bigBlind),
					selectedIndicesSet: $blindSession.selectedIndicesSet,
					onStart: { orderedIndices, customProgression, customCurrentIndex in
						blindSession.activeCustomProgression = customProgression
						if let custom = customProgression, let cur = customCurrentIndex, cur >= 0, cur < custom.count {
							bigBlind = custom[cur].bb
						blindSession.queuedIndices = Array((cur + 1)..<custom.count)
					} else {
						blindSession.queuedIndices = orderedIndices
					}
					timerEnabled = true
					blindSession.invalidateCountdownAnchor()
					blindSession.isPaused = false
					blindSession.remainingSeconds = timerDurationSec
					if let first = blindSession.queuedIndices.first {
						blindSession.selectedNextIndex = first
					} else {
						blindSession.setupNextLevel(bigBlind: bigBlind)
					}
					syncLiveActivityFromCurrentState()
				}
			)
			.presentationDetents([.large])
			.presentationDragIndicator(.visible)
			.tint(Theme.accent)
			.preferredColorScheme(.dark)
			.background(Theme.background)
		}
		.sheet(isPresented: $showResetConfirmation) {
			ResetConfirmationSheet(
				isPresented: $showResetConfirmation,
				dontShowAgain: $dontShowResetConfirmation,
				onConfirm: {
					if dontShowResetConfirmation {
						dontShowResetConfirmationStored = true
					}
					onReset()
				}
			)
			.presentationDetents([.medium])
			.presentationDragIndicator(.visible)
		}
		.onChange(of: showResetConfirmation) { _, isPresented in
			if isPresented {
				dontShowResetConfirmation = false
			}
		}
    }

	private var stackHero: some View {
		VStack(alignment: .leading, spacing: 18) {
			HStack(alignment: .top) {
				VStack(alignment: .leading, spacing: 6) {
					Text("result.stack_depth")
						.font(.subheadline.weight(.semibold))
						.foregroundStyle(Theme.secondaryText)
					Text(LocalizedStringKey(stackStatusKey))
						.font(.headline.weight(.semibold))
						.foregroundStyle(bbColor)
				}
				Spacer()
				HealthBadge(titleKey: stackStatusKey, color: bbColor)
			}

			HStack(alignment: .lastTextBaseline, spacing: 8) {
				Text(formattedBB(bbCount))
					.font(.system(size: 86, weight: .black, design: .rounded))
					.foregroundStyle(bbColor)
					.minimumScaleFactor(0.45)
					.lineLimit(1)
				Text("BB")
					.font(.system(size: 26, weight: .bold, design: .rounded))
					.foregroundStyle(Theme.primaryText.opacity(0.72))
			}
			.accessibilityElement(children: .combine)

			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Text("result.stack_pressure")
						.font(.caption.weight(.semibold))
						.foregroundStyle(Theme.secondaryText)
					Spacer()
					Text(formattedBB(nextLevelBBCount) + " BB")
						.font(.caption.weight(.semibold))
						.foregroundStyle(nextLevelBBColor)
				}
				GeometryReader { proxy in
					ZStack(alignment: .leading) {
						Capsule()
							.fill(Color.white.opacity(0.08))
						Capsule()
							.fill(
								LinearGradient(
									colors: [bbColor.opacity(0.65), bbColor],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
							.frame(width: proxy.size.width * min(max(bbCount / 40, 0.08), 1))
					}
				}
				.frame(height: 8)
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
		.shadow(color: bbColor.opacity(0.18), radius: 30, x: 0, y: 18)
	}

	private var timerDashboard: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack(spacing: 12) {
				Label("timer.title", systemImage: "timer")
					.font(.headline)
					.foregroundStyle(Theme.primaryText)
				Spacer()
				Button {
					blindSession.prepareTimerSheetDefaults(bigBlind: bigBlind)
					showTimerSheet = true
				} label: {
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
				.accessibilityIdentifier("timer.toggle")
				.onChange(of: timerEnabled) { _, enabled in
					if enabled {
						if blindSession.queuedIndices.isEmpty {
							blindSession.prepareTimerSheetDefaults(bigBlind: bigBlind)
							blindSession.queuedIndices = blindSession.selectedIndicesSet.sorted()
						}
						if blindSession.queuedIndices.isEmpty {
							blindSession.setupNextLevel(bigBlind: bigBlind)
						}
						blindSession.invalidateCountdownAnchor()
						blindSession.remainingSeconds = timerDurationSec
						blindSession.isPaused = true
					} else {
						blindSession.isPaused = false
						blindSession.invalidateCountdownAnchor()
					}
					syncLiveActivityFromCurrentState()
				}
			}

			if timerEnabled {
				HStack(alignment: .center, spacing: 16) {
					VStack(alignment: .leading, spacing: 6) {
						Text(formattedTime(blindSession.remainingSeconds))
							.font(.system(size: 48, weight: .black, design: .rounded))
							.monospacedDigit()
							.foregroundStyle(Theme.primaryText)
							.minimumScaleFactor(0.65)
							.lineLimit(1)
						Text("\(NSLocalizedString("timer.next", comment: "")): \(blindSession.nextDisplayLevelText(for: bigBlind))")
							.font(.subheadline.weight(.medium))
							.foregroundStyle(Theme.secondaryText)
							.lineLimit(1)
							.minimumScaleFactor(0.75)
						Text(String(format: NSLocalizedString("timer.next_stack", comment: ""), formattedBB(nextLevelBBCount)))
							.font(.caption.weight(.semibold))
							.foregroundStyle(nextLevelBBColor)
					}
					Spacer(minLength: 8)
					Button(action: {
						if blindSession.isPaused {
							blindSession.isPaused = false
						} else {
							blindSession.snapRemainingAtPause()
							blindSession.isPaused = true
						}
					}) {
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
			} else {
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
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(Theme.surfaceElevated)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(Theme.surfaceStroke, lineWidth: 1)
		)
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
	
	private func formattedTime(_ seconds: Int) -> String {
		let m = seconds / 60
		let s = seconds % 60
		return String(format: "%02d:%02d", m, s)
	}

	private func syncLiveActivityFromCurrentState() {
		syncLiveActivityPayload(
			chips: chips,
			bigBlind: bigBlind,
			blindSession: blindSession,
			timerEnabled: timerEnabled
		)
	}
}
