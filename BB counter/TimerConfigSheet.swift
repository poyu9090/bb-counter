import SwiftUI

// MARK: - Timer Config Sheet
struct TimerConfigSheet: View {
	@Binding var isPresented: Bool
	@Binding var timerEnabled: Bool
	@Binding var timerDurationSec: Int
	let progression: [(sb: Int, bb: Int)]
	let currentIndex: Int?
	@Binding var selectedIndicesSet: Set<Int>
	let onStart: ([Int], [(sb: Int, bb: Int)]?, Int?) -> Void  // indices, customProgression, customCurrentIndex
	
	@State private var customMinutesText: String = ""
	@State private var selectedScheme: Int = 0
	@State private var showBlindStructureDetail: Bool = false
	@State private var showCustomEditSheet: Bool = false
	@AppStorage("customBlindStructure") private var customBlindStructureStored: String = ""
	@AppStorage("customBlindCurrentIndex") private var customBlindCurrentIndexStored: Int = 0
	@State private var customLevels: [(sb: Int, bb: Int)] = []
	
	private func loadCustomLevels() {
		let parts = customBlindStructureStored.split(separator: ",").compactMap { Int($0) }
		var levels: [(sb: Int, bb: Int)] = []
		var i = 0
		while i + 1 < parts.count {
			levels.append((sb: parts[i], bb: parts[i + 1]))
			i += 2
		}
		customLevels = levels
	}
	
	private func saveCustomLevels(_ levels: [(sb: Int, bb: Int)]) {
		customBlindStructureStored = levels.flatMap { ["\($0.sb)", "\($0.bb)"] }.joined(separator: ",")
		customLevels = levels
	}
	
	var body: some View {
		ZStack {
			Theme.background.ignoresSafeArea()
			ScrollView(.vertical, showsIndicators: false) {
				VStack(spacing: 18) {
					HStack {
						VStack(alignment: .leading, spacing: 4) {
							Text("timer.title")
								.font(.title2.bold())
								.foregroundStyle(Theme.primaryText)
							Text(labelForDuration(timerDurationSec))
								.font(.subheadline.weight(.semibold))
								.foregroundStyle(Theme.accent)
						}
						Spacer()
						Button {
							isPresented = false
						} label: {
							Image(systemName: "xmark.circle.fill")
								.font(.title2)
								.foregroundStyle(Theme.secondaryText)
								.frame(width: 44, height: 44)
						}
						.buttonStyle(.plain)
						.accessibilityLabel(Text("action.back"))
					}
					.padding(.horizontal)
					.padding(.top, 8)
					
					TimerConfigSection(titleKey: "timer.duration", iconName: "clock") {
						LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
							ForEach([600, 900, 1200, 1500, 1800, 3600], id: \.self) { sec in
								TimerDurationOption(
									title: labelForDuration(sec),
									isSelected: timerDurationSec == sec,
									action: {
										timerDurationSec = sec
										customMinutesText = ""
									}
								)
							}
						}

						VStack(alignment: .leading, spacing: 8) {
							Text("timer.custom")
								.font(.subheadline.bold())
								.foregroundStyle(Theme.primaryText)
							HStack(spacing: 12) {
								TextField("", text: Binding(
									get: { customMinutesText },
									set: { newValue in
										let filtered = newValue.filter { $0.isNumber }
										customMinutesText = filtered
										if let mins = Int(filtered), mins > 0 {
											timerDurationSec = mins * 60
										}
									})
								)
								.keyboardType(.numberPad)
								.textFieldStyle(.plain)
								.font(.title3)
								.multilineTextAlignment(.center)
								.frame(width: 96)
								.padding(.vertical, 12)
								.padding(.horizontal, 16)
								.background(
									RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
								)
								.overlay(
									RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.surfaceStroke, lineWidth: 1)
								)
								.foregroundStyle(Theme.primaryText)
								.accessibilityIdentifier("timer.customMinutes")
								
								Text(LocalizedStringKey("timer.min_unit"))
									.font(.body)
									.foregroundStyle(Theme.secondaryText)
								
								Spacer()
							}
						}

						HStack {
							Text(LocalizedStringKey("timer.current"))
								.font(.subheadline)
								.foregroundStyle(Theme.secondaryText)
							Text(labelForDuration(timerDurationSec))
								.font(.subheadline.bold())
								.foregroundStyle(Theme.accent)
						}
					}
					.padding(.horizontal)
					
					TimerConfigSection(titleKey: "timer.blind_structure", iconName: "list.bullet.rectangle") {
						VStack(spacing: 12) {
							ForEach(Array(availableSchemes().enumerated()), id: \.offset) { (idx, scheme) in
								VStack(alignment: .leading, spacing: 12) {
									Button {
										selectedScheme = idx
									} label: {
										VStack(alignment: .leading, spacing: 10) {
											HStack(spacing: 8) {
												Text(LocalizedStringKey(scheme.titleKey))
													.font(.body.bold())
													.foregroundStyle(Theme.primaryText)
												Spacer()
												Text(selectedCountString(scheme.indices.count))
													.font(.caption.weight(.semibold))
													.foregroundStyle(Theme.secondaryText)
												Image(systemName: selectedScheme == idx ? "checkmark.circle.fill" : "circle")
													.font(.title3)
													.foregroundStyle(selectedScheme == idx ? Theme.accent : Theme.surfaceStroke)
											}
											VStack(alignment: .leading, spacing: 5) {
												ForEach(nextThreeLevelsArray(for: scheme), id: \.self) { levelText in
													Text(levelText)
														.font(.subheadline)
														.foregroundStyle(Theme.secondaryText)
												}
											}
										}
										.frame(maxWidth: .infinity, alignment: .leading)
										.padding(16)
										.background(
											RoundedRectangle(cornerRadius: 16, style: .continuous)
												.fill(selectedScheme == idx ? Theme.accent.opacity(0.16) : Theme.surface)
										)
										.overlay(
											RoundedRectangle(cornerRadius: 16, style: .continuous)
												.stroke(selectedScheme == idx ? Theme.accent : Theme.surfaceStroke, lineWidth: selectedScheme == idx ? 2 : 1)
										)
									}
									.buttonStyle(.plain)
									.accessibilityIdentifier("timer.scheme.\(idx)")

									HStack {
										if idx == 0 {
											Button {
												showBlindStructureDetail = true
											} label: {
												Label("timer.blind_structure_detail", systemImage: "info.circle")
											}
											.buttonStyle(.bordered)
										} else if idx == 1 {
												Button {
													showCustomEditSheet = true
												} label: {
													Label("timer.custom_edit_levels", systemImage: "pencil")
												}
												.buttonStyle(.bordered)
										}
										Spacer(minLength: 0)
									}
									.padding(.horizontal, 2)
								}
							}
						}
					}
					.padding(.horizontal)
					
					Spacer(minLength: 20)
				}
				.padding(.bottom, 8)
			}
		}
		.onAppear {
			loadCustomLevels()
			let schemes = availableSchemes()
			if selectedScheme >= schemes.count {
				selectedScheme = 0
			}
		}
		.sheet(isPresented: $showBlindStructureDetail) {
			BlindStructureDetailView(
				progression: progression,
				currentIndex: currentIndex
			)
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
			.tint(Theme.accent)
			.preferredColorScheme(.dark)
			.background(Theme.background)
		}
		.sheet(isPresented: $showCustomEditSheet) {
			CustomBlindEditSheet(
				isPresented: $showCustomEditSheet,
				initialLevels: customLevels,
				initialCurrentIndex: customBlindCurrentIndexStored >= 0 && customBlindCurrentIndexStored < customLevels.count ? customBlindCurrentIndexStored : nil,
				onSave: { levels, currentIndex in
					saveCustomLevels(levels)
					if let idx = currentIndex {
						customBlindCurrentIndexStored = idx
					} else {
						customBlindCurrentIndexStored = 0
					}
				}
			)
		}
		.safeAreaInset(edge: .bottom) {
			VStack(spacing: 8) {
				HStack(spacing: 12) {
					Button(role: .cancel) {
						isPresented = false
					} label: {
						Text("action.back")
							.frame(maxWidth: .infinity)
							.padding()
					}
					.buttonStyle(.bordered)
					
					Button {
						let schemes = availableSchemes()
						guard !schemes.isEmpty else {
							isPresented = false
							return
						}
						let safeIndex = min(selectedScheme, schemes.count - 1)
						let scheme = schemes[safeIndex]
						let indices = scheme.indices
						selectedIndicesSet = Set(indices)
						let customProg = scheme.customLevels
						if let custom = customProg, !custom.isEmpty {
							onStart(indices, custom, customBlindCurrentIndexStored >= 0 && customBlindCurrentIndexStored < custom.count ? customBlindCurrentIndexStored : 0)
						} else {
							onStart(indices, nil, nil)
						}
						isPresented = false
					} label: {
						Text("timer.start")
							.frame(maxWidth: .infinity)
							.padding()
							.font(.headline)
							.foregroundStyle(Color.white)
					}
					.buttonStyle(.borderedProminent)
					.accessibilityIdentifier("timer.start")
				}
				.padding(.horizontal)
				.padding(.bottom, 4)
			}
			.padding(.vertical, 8)
			.background(Theme.background.opacity(0.95))
		}
	}
	
	private func upcomingLevels() -> [(sb: Int, bb: Int)] {
		let start = (currentIndex ?? -1) + 1
		guard start >= 0 else { return progression }
		return Array(progression.suffix(from: start))
	}
	
	// MARK: - Helpers
	private func labelForDuration(_ seconds: Int) -> String {
		switch seconds {
		case 600: return NSLocalizedString("timer.10m", comment: "")
		case 900: return NSLocalizedString("timer.15m", comment: "")
		case 1200: return NSLocalizedString("timer.20m", comment: "")
		case 1500: return NSLocalizedString("timer.25m", comment: "")
		case 1800: return NSLocalizedString("timer.30m", comment: "")
		case 3600: return NSLocalizedString("timer.60m", comment: "")
		default: return "\(seconds / 60)m"
		}
	}
	
	private func selectedCountString(_ count: Int) -> String {
		String(format: NSLocalizedString("timer.selected_count", comment: ""), count)
	}
	
	private func availableSchemes() -> [(titleKey: String, indices: [Int], displayText: String, customLevels: [(sb: Int, bb: Int)]?)] {
		let startIdx = (currentIndex ?? -1)
		let base = max(0, startIdx)
		let total = progression.count
		
		func textFor(_ indices: [Int], prog: [(sb: Int, bb: Int)]) -> String {
			let pairs = indices.compactMap { i -> String? in
				guard i >= 0 && i < prog.count else { return nil }
				let l = prog[i]
				return "\(l.sb)/\(l.bb)"
			}
			return pairs.isEmpty ? NSLocalizedString("timer.no_levels", comment: "No levels") : pairs.joined(separator: "  ·  ")
		}
		
		var schemes: [(titleKey: String, indices: [Int], displayText: String, customLevels: [(sb: Int, bb: Int)]?)] = []
		if total > 0 {
			let start = base + 1
			let end = total - 1
			let allUpcoming: [Int] = start <= end && start < total ? Array(start...end) : []
			schemes.append(("timer.scheme_one", allUpcoming, textFor(allUpcoming, prog: progression), nil))
		}
		let customIndices = Array(0..<customLevels.count)
		schemes.append(("timer.scheme_custom", customIndices, textFor(customIndices, prog: customLevels), customLevels))
		return schemes
	}
	
	private func nextThreeLevelsArray(for scheme: (titleKey: String, indices: [Int], displayText: String, customLevels: [(sb: Int, bb: Int)]?)) -> [String] {
		let prog = scheme.customLevels ?? progression
		let nextThree = Array(scheme.indices.prefix(3))
		guard !nextThree.isEmpty else {
			return [NSLocalizedString("timer.no_more_levels", comment: "")]
		}
		return nextThree.compactMap { i -> String? in
			guard i >= 0 && i < prog.count else { return nil }
			let l = prog[i]
			return "\(l.sb) / \(l.bb)"
		}
	}
}

private struct TimerConfigSection<Content: View>: View {
	let titleKey: String
	let iconName: String
	@ViewBuilder let content: Content

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			Label(titleKey, systemImage: iconName)
				.font(.headline)
				.foregroundStyle(Theme.primaryText)

			content
		}
		.padding(16)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(Theme.surfaceElevated)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(Theme.surfaceStroke, lineWidth: 1)
		)
	}
}

private struct TimerDurationOption: View {
	let title: String
	let isSelected: Bool
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Text(title)
				.font(.subheadline.bold())
				.foregroundStyle(isSelected ? Color.white : Theme.primaryText)
				.frame(maxWidth: .infinity, minHeight: 48)
				.background(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(isSelected ? Theme.accent : Theme.surface)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.stroke(isSelected ? Theme.accent : Theme.surfaceStroke, lineWidth: 1)
				)
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Custom Blind Edit Sheet
private struct CustomBlindEditSheet: View {
	@Binding var isPresented: Bool
	let initialLevels: [(sb: Int, bb: Int)]
	let initialCurrentIndex: Int?
	let onSave: ([(sb: Int, bb: Int)], Int?) -> Void
	
	private struct LevelRow: Identifiable {
		let id = UUID()
		var sb: String
		var bb: String
	}
	
	@State private var rows: [LevelRow] = []
	@State private var selectedCurrentIndex: Int? = nil
	
	private func loadRowsIfNeeded() {
		if rows.isEmpty {
			if initialLevels.isEmpty {
				rows = [LevelRow(sb: "", bb: "")]
			} else {
				rows = initialLevels.map { LevelRow(sb: "\($0.sb)", bb: "\($0.bb)") }
			}
			selectedCurrentIndex = initialCurrentIndex
		}
	}
	
	private func addRow() {
		rows.append(LevelRow(sb: "", bb: ""))
	}
	
	private func removeRow(at index: Int) {
		guard rows.indices.contains(index) else { return }
		rows.remove(at: index)
		if selectedCurrentIndex == index {
			selectedCurrentIndex = nil
		} else if let s = selectedCurrentIndex, s > index {
			selectedCurrentIndex = s - 1
		}
		if rows.isEmpty {
			rows.append(LevelRow(sb: "", bb: ""))
		}
	}
	
	private func commitAndClose() {
		let cleaned: [(sb: Int, bb: Int)] = rows.compactMap { row in
			let sb = Int(row.sb.filter { $0.isNumber }) ?? 0
			let bb = Int(row.bb.filter { $0.isNumber }) ?? 0
			guard sb > 0, bb > 0 else { return nil }
			return (sb: sb, bb: bb)
		}
		let validIndex = selectedCurrentIndex.flatMap { idx in
			(idx >= 0 && idx < cleaned.count) ? idx : nil
		}
		onSave(cleaned, validIndex)
		isPresented = false
	}
	
	var body: some View {
		ZStack {
			Theme.background.ignoresSafeArea()
			VStack(spacing: 0) {
				// Header
				HStack {
					Text("timer.scheme_custom")
						.font(.title2.bold())
						.foregroundStyle(Theme.primaryText)
					Spacer()
					Button {
						commitAndClose()
					} label: {
						Text("action.done")
							.font(.headline)
							.foregroundStyle(Theme.accent)
					}
				}
				.padding(.horizontal)
				.padding(.top, 8)
				
				ScrollView {
					VStack(spacing: 10) {
						ForEach(Array(rows.enumerated()), id: \.element.id) { (idx, row) in
							let isCurrent = selectedCurrentIndex == idx
							VStack(alignment: .leading, spacing: 12) {
								HStack(spacing: 10) {
									Button {
										selectedCurrentIndex = (selectedCurrentIndex == idx) ? nil : idx
									} label: {
										Label("Lv \(idx + 1)", systemImage: isCurrent ? "checkmark.circle.fill" : "circle")
											.font(.subheadline.weight(.semibold))
											.foregroundStyle(isCurrent ? Theme.accent : Theme.secondaryText)
											.frame(minHeight: 44)
									}
									.buttonStyle(.plain)
									
									if isCurrent {
										Text("timer.current_level")
											.font(.caption.weight(.semibold))
											.foregroundStyle(Theme.accent)
											.padding(.horizontal, 8)
											.padding(.vertical, 4)
											.background(Capsule().fill(Theme.accent.opacity(0.16)))
									}
									
									Spacer()
									
									Button {
										removeRow(at: idx)
									} label: {
										Image(systemName: "trash")
											.font(.subheadline.weight(.semibold))
											.foregroundStyle(Theme.secondaryText)
											.frame(width: 44, height: 44)
									}
									.buttonStyle(.plain)
								}
								
								HStack(spacing: 10) {
									CustomBlindLevelField(
										title: "SB",
										placeholder: idx == 0 ? "500" : "",
										text: Binding(
											get: { rows[idx].sb },
											set: { rows[idx].sb = $0.filter { $0.isNumber } }
										)
									)
									CustomBlindLevelField(
										title: "BB",
										placeholder: idx == 0 ? "1000" : "",
										text: Binding(
											get: { rows[idx].bb },
											set: { rows[idx].bb = $0.filter { $0.isNumber } }
										)
									)
								}
							}
							.padding(14)
							.background(
								RoundedRectangle(cornerRadius: 16, style: .continuous)
									.fill(isCurrent ? Theme.accent.opacity(0.15) : Theme.surface)
							)
							.overlay(
								RoundedRectangle(cornerRadius: 16, style: .continuous)
									.stroke(isCurrent ? Theme.accent.opacity(0.7) : Theme.surfaceStroke, lineWidth: 1)
							)
						}
					}
					.padding(.horizontal)
					.padding(.top, 14)
				}
				
				// Add row button
				Button(action: addRow) {
					Text("timer.add_level")
						.frame(maxWidth: .infinity)
						.padding()
				}
				.buttonStyle(.bordered)
				.padding(.horizontal)
				.padding(.bottom, 8)
			}
		}
		.onAppear {
			loadRowsIfNeeded()
		}
		.preferredColorScheme(.dark)
		.tint(Theme.accent)
	}
}

private struct CustomBlindLevelField: View {
	let title: String
	let placeholder: String
	@Binding var text: String

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(title)
				.font(.caption.weight(.bold))
				.foregroundStyle(Theme.secondaryText)
			TextField(placeholder, text: $text)
				.keyboardType(.numberPad)
				.textFieldStyle(.plain)
				.multilineTextAlignment(.center)
				.foregroundStyle(Theme.primaryText)
				.font(.body.weight(.semibold))
				.frame(maxWidth: .infinity, minHeight: 46)
				.background(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.fill(Theme.background.opacity(0.55))
				)
				.overlay(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.stroke(Theme.surfaceStroke, lineWidth: 1)
				)
		}
		.frame(maxWidth: .infinity)
	}
}

// MARK: - Blind Structure Detail View
private struct BlindStructureDetailView: View {
	let progression: [(sb: Int, bb: Int)]
	let currentIndex: Int?
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		ZStack {
			Theme.background.ignoresSafeArea()
			VStack(spacing: 0) {
				// Header
				HStack {
					Text("timer.blind_structure_detail")
						.font(.title2.bold())
						.foregroundStyle(Theme.primaryText)
					Spacer()
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.title3)
							.foregroundStyle(Theme.secondaryText)
					}
				}
				.padding(.horizontal)
				.padding(.top, 8)
				
				// Blind structure list
				ScrollView(.vertical, showsIndicators: true) {
					VStack(spacing: 12) {
						ForEach(Array(progression.enumerated()), id: \.offset) { (idx, level) in
							HStack {
								// Level number
								Text("\(idx + 1)")
									.font(.subheadline.bold())
									.foregroundStyle(Theme.secondaryText)
									.frame(width: 40, alignment: .leading)
								
								// Blinds
								Text("\(level.sb) / \(level.bb)")
									.font(.body)
									.foregroundStyle(Theme.primaryText)
								
								Spacer()
								
								// Current indicator
								if currentIndex == idx {
									Text("timer.current_level")
										.font(.caption)
										.foregroundStyle(Theme.accent)
										.padding(.horizontal, 8)
										.padding(.vertical, 4)
										.background(
											Capsule()
												.fill(Theme.accent.opacity(0.2))
										)
								}
							}
							.padding(.vertical, 10)
							.padding(.horizontal, 16)
							.background(
								RoundedRectangle(cornerRadius: 12, style: .continuous)
									.fill(currentIndex == idx ? Theme.accent.opacity(0.1) : Theme.surface)
							)
							.overlay(
								RoundedRectangle(cornerRadius: 12, style: .continuous)
									.stroke(currentIndex == idx ? Theme.accent : Theme.surfaceStroke, lineWidth: currentIndex == idx ? 2 : 1)
							)
						}
					}
					.padding(.horizontal)
					.padding(.vertical, 16)
				}
			}
		}
	}
}
