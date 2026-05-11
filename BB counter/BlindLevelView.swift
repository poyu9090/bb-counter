import SwiftUI

struct BlindLevelView: View {
    @Binding var bigBlindText: String
    let selectPreset: (Int) -> Void
    let onShowResult: () -> Void
    let onBack: () -> Void
    let onAppear: () -> Void
    let isEditingFromResult: Bool
    
    init(
        bigBlindText: Binding<String>,
        selectPreset: @escaping (Int) -> Void,
        onShowResult: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onAppear: @escaping () -> Void,
        isEditingFromResult: Bool = false
    ) {
        self._bigBlindText = bigBlindText
        self.selectPreset = selectPreset
        self.onShowResult = onShowResult
        self.onBack = onBack
        self.onAppear = onAppear
        self.isEditingFromResult = isEditingFromResult
    }
    
    private let presets: [(sb: Int, bb: Int)] = [
        (100, 200), (200, 400), (300, 600), (500, 1000), (1000, 2000),
        (1500, 3000), (2000, 4000), (3000, 6000), (5000, 10000)
    ]
    private let maxBlindValue: Int = 99_999_999

    private var parsedBigBlind: Int? {
        Int(bigBlindText)
    }

    private var inputErrorKey: String? {
        guard !bigBlindText.isEmpty else { return nil }
        guard let value = parsedBigBlind else { return "input.error_too_large" }
        if value <= 0 { return "input.error_required" }
        if value > maxBlindValue { return "input.error_too_large" }
        return nil
    }

    private var canProceed: Bool {
        guard let value = parsedBigBlind else { return false }
        return value > 0 && value <= maxBlindValue
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            
            VStack(spacing: 8) {
                Text("blinds.title")
					.font(.largeTitle).bold()
                    .foregroundStyle(Theme.primaryText)
            }
            .multilineTextAlignment(.center)
            
			LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
				ForEach(presets, id: \.bb) { level in
					Button {
						selectPreset(level.bb)
					} label: {
						VStack(alignment: .leading, spacing: 7) {
							Text("\(level.sb)")
								.font(.caption.weight(.semibold))
								.foregroundStyle(Theme.secondaryText)
							Text("\(level.bb)")
								.font(.title3.weight(.bold))
								.foregroundStyle(Theme.primaryText)
								.monospacedDigit()
							Text("SB / BB")
								.font(.caption2.weight(.semibold))
								.foregroundStyle(isSelected(level) ? Theme.accent : Theme.secondaryText)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(12)
						.background(
							RoundedRectangle(cornerRadius: 18, style: .continuous)
								.fill(isSelected(level) ? Theme.accent.opacity(0.18) : Theme.surfaceElevated)
						)
						.overlay(
							RoundedRectangle(cornerRadius: 18, style: .continuous)
								.stroke(isSelected(level) ? Theme.accent : Theme.surfaceStroke, lineWidth: isSelected(level) ? 2 : 1)
						)
					}
					.buttonStyle(.plain)
					.accessibilityIdentifier("blind.preset.\(level.bb)")
				}
			}
			.padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("blinds.enter")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                TextField(LocalizedStringKey("blinds.placeholder"), text: $bigBlindText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("blind.input")
                    .font(.title2)
                    .foregroundStyle(Theme.primaryText)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.surfaceStroke, lineWidth: 1)
                    )
                    .onChange(of: bigBlindText) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            bigBlindText = filtered
                        }
                    }
                    .onAppear {
                        onAppear()
                    }
                if let inputErrorKey {
                    Text(LocalizedStringKey(inputErrorKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.healthRed)
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
        }
        .padding(.top, 32)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if isEditingFromResult {
                    // 编辑模式：只显示一个"完成"按钮
                    Button(action: onShowResult) {
                        Text("action.done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("blind.done")
                    .padding(.horizontal)
                    .disabled(!canProceed)
                } else {
                    // 正常流程：显示"显示结果"和"返回"按钮
                    Button(action: onShowResult) {
                        Text("action.show_result")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("blind.showResult")
                    .padding(.horizontal)
                    .disabled(!canProceed)
                    
                    Button(role: .cancel, action: onBack) {
                        Text("action.back")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Theme.primaryText)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("blind.back")
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
            }
            .padding(.vertical, 8)
            .background(Theme.background.opacity(0.9))
        }
    }
    
    private func isSelected(_ level: (sb: Int, bb: Int)) -> Bool {
        (Int(bigBlindText) ?? 0) == level.bb
    }
}
