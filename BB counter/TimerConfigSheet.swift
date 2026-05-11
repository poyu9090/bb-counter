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
	@State private var editingCustomStructure: BlindStructure?
	@AppStorage("customBlindStructure") private var customBlindStructureStored: String = ""
	@AppStorage("customBlindCurrentIndex") private var customBlindCurrentIndexStored: Int = 0
	@AppStorage("customBlindStructures") private var customBlindStructuresStored: String = ""
	@AppStorage("selectedCustomBlindStructureID") private var selectedCustomBlindStructureID: String = ""
	@State private var customStructures: [BlindStructure] = []
	
	private func loadCustomStructures() {
		var decoded = BlindStructureCodec.decodeStructures(from: customBlindStructuresStored)
		if decoded.isEmpty {
			let legacy = BlindStructureCodec.decodeLegacyLevels(from: customBlindStructureStored)
			if !legacy.isEmpty {
				decoded = [BlindStructure(name: NSLocalizedString("timer.scheme_custom", comment: ""), levels: legacy)]
				customBlindStructuresStored = BlindStructureCodec.encodeStructures(decoded)
				selectedCustomBlindStructureID = decoded[0].id
			}
		}
		customStructures = decoded
		if selectedCustomBlindStructureID.isEmpty, let first = decoded.first {
			selectedCustomBlindStructureID = first.id
		}
	}
	
	private func saveCustomStructure(_ structure: BlindStructure, currentIndex: Int?) {
		if let existing = customStructures.firstIndex(where: { $0.id == structure.id }) {
			customStructures[existing] = structure
		} else {
			customStructures.append(structure)
		}
		selectedCustomBlindStructureID = structure.id
		customBlindCurrentIndexStored = currentIndex ?? 0
		customBlindStructuresStored = BlindStructureCodec.encodeStructures(customStructures)
		customBlindStructureStored = BlindStructureCodec.encodeLevels(structure.levels)
	}

	private func deleteSelectedCustomStructure() {
		guard !selectedCustomBlindStructureID.isEmpty else { return }
		customStructures.removeAll { $0.id == selectedCustomBlindStructureID }
		selectedCustomBlindStructureID = customStructures.first?.id ?? ""
		customBlindStructuresStored = BlindStructureCodec.encodeStructures(customStructures)
		customBlindStructureStored = customStructures.first.map { BlindStructureCodec.encodeLevels($0.levels) } ?? ""
		selectedScheme = selectedCustomBlindStructureID.isEmpty ? 0 : idxForCustomStructure(id: selectedCustomBlindStructureID)
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
												Text(scheme.title)
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
										} else if idx > 0 {
												if customStructures.count > 1 {
													Menu {
														ForEach(customStructures) { structure in
															Button(structure.name) {
																selectedCustomBlindStructureID = structure.id
																selectedScheme = idxForCustomStructure(id: structure.id)
															}
														}
													} label: {
														Label("timer.custom_switch_structure", systemImage: "rectangle.2.swap")
													}
													.buttonStyle(.bordered)
												}
												Button {
													editingCustomStructure = scheme.customStructure
													showCustomEditSheet = true
												} label: {
													Label("timer.custom_edit_levels", systemImage: "pencil")
												}
												.buttonStyle(.bordered)
												if scheme.customStructure != nil {
													Button(role: .destructive) {
														deleteSelectedCustomStructure()
													} label: {
														Label("action.delete", systemImage: "trash")
													}
													.buttonStyle(.bordered)
												}
										}
										Button {
											editingCustomStructure = nil
											showCustomEditSheet = true
										} label: {
											Label("timer.custom_new_structure", systemImage: "plus")
										}
										.buttonStyle(.bordered)
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
			loadCustomStructures()
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
				initialStructure: editingCustomStructure ?? selectedCustomStructure(),
				initialCurrentIndex: currentIndexForSelectedCustomStructure(),
				onSave: { structure, currentIndex in
					saveCustomStructure(structure, currentIndex: currentIndex)
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
						if customProg?.isEmpty == true {
							editingCustomStructure = scheme.customStructure
							showCustomEditSheet = true
							return
						}
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
	
	private func availableSchemes() -> [TimerBlindScheme] {
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
		
		var schemes: [TimerBlindScheme] = []
		if total > 0 {
			let start = base + 1
			let end = total - 1
			let allUpcoming: [Int] = start <= end && start < total ? Array(start...end) : []
			schemes.append(TimerBlindScheme(title: NSLocalizedString("timer.scheme_one", comment: ""), indices: allUpcoming, displayText: textFor(allUpcoming, prog: progression), customLevels: nil, customStructure: nil))
		}
		for structure in customStructures {
			let levels = structure.levels.map { ($0.sb, $0.bb) }
			let customIndices = Array(0..<levels.count)
			schemes.append(TimerBlindScheme(title: structure.name, indices: customIndices, displayText: textFor(customIndices, prog: levels), customLevels: levels, customStructure: structure))
		}
		if customStructures.isEmpty {
			schemes.append(TimerBlindScheme(title: NSLocalizedString("timer.scheme_custom", comment: ""), indices: [], displayText: NSLocalizedString("timer.no_levels", comment: ""), customLevels: [], customStructure: nil))
		}
		return schemes
	}
	
	private func nextThreeLevelsArray(for scheme: TimerBlindScheme) -> [String] {
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

	private func selectedCustomStructure() -> BlindStructure? {
		if let selected = customStructures.first(where: { $0.id == selectedCustomBlindStructureID }) {
			return selected
		}
		return customStructures.first
	}

	private func currentIndexForSelectedCustomStructure() -> Int? {
		guard let selected = selectedCustomStructure() else { return nil }
		return customBlindCurrentIndexStored >= 0 && customBlindCurrentIndexStored < selected.levels.count ? customBlindCurrentIndexStored : nil
	}

	private func idxForCustomStructure(id: String) -> Int {
		let schemes = availableSchemes()
		return schemes.firstIndex { $0.customStructure?.id == id } ?? selectedScheme
	}
}

private struct TimerBlindScheme {
	let title: String
	let indices: [Int]
	let displayText: String
	let customLevels: [(sb: Int, bb: Int)]?
	let customStructure: BlindStructure?
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
	let initialStructure: BlindStructure?
	let initialCurrentIndex: Int?
	let onSave: (BlindStructure, Int?) -> Void
	
	private struct LevelRow: Identifiable {
		let id = UUID()
		var sb: String
		var bb: String
	}
	
	@State private var rows: [LevelRow] = []
	@State private var nameText: String = ""
	@State private var selectedCurrentIndex: Int? = nil
	@State private var validationMessage: String? = nil
	
	private func loadRowsIfNeeded() {
		if rows.isEmpty {
			nameText = initialStructure?.name ?? NSLocalizedString("timer.default_custom_name", comment: "")
			let initialLevels = initialStructure?.levels ?? []
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
		let cleaned: [BlindLevel] = rows.compactMap { row in
			let sb = Int(row.sb.filter { $0.isNumber }) ?? 0
			let bb = Int(row.bb.filter { $0.isNumber }) ?? 0
			guard sb > 0, bb > 0 else { return nil }
			return BlindLevel(sb: sb, bb: bb)
		}
		if let error = BlindStructureValidation.validate(name: nameText, levels: cleaned) {
			validationMessage = error
			return
		}
		let validIndex = selectedCurrentIndex.flatMap { idx in
			(idx >= 0 && idx < cleaned.count) ? idx : nil
		}
		let structure = BlindStructure(
			id: initialStructure?.id ?? UUID().uuidString,
			name: nameText.trimmingCharacters(in: .whitespacesAndNewlines),
			levels: cleaned
		)
		onSave(structure, validIndex)
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

				VStack(alignment: .leading, spacing: 8) {
					Text("timer.structure_name")
						.font(.caption.weight(.bold))
						.foregroundStyle(Theme.secondaryText)
					TextField(LocalizedStringKey("timer.structure_name_placeholder"), text: $nameText)
						.textFieldStyle(.plain)
						.foregroundStyle(Theme.primaryText)
						.padding(.vertical, 12)
						.padding(.horizontal, 14)
						.background(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(Theme.surface)
						)
						.overlay(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.stroke(Theme.surfaceStroke, lineWidth: 1)
						)
					if let validationMessage {
						Text(validationMessage)
							.font(.caption.weight(.semibold))
							.foregroundStyle(Theme.healthRed)
							.fixedSize(horizontal: false, vertical: true)
					}
				}
				.padding(.horizontal)
				.padding(.top, 14)
				
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
