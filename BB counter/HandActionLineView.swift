import SwiftUI
import UIKit

struct HandActionLineSheet: View {
    let smallBlind: Int
    let bigBlind: Int
    let stackBB: Double

    @Environment(\.dismiss) private var dismiss
    @AppStorage("handActionLineRecords") private var recordsStored: String = "[]"
    @State private var records: [HandActionLineRecord] = []
    @State private var editingRecord: HandActionLineRecord?
    @State private var showDeleteConfirmation: Bool = false
    @State private var deletingRecord: HandActionLineRecord?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(records) { record in
                                HandActionLineCard(
                                    record: record,
                                    onEdit: { editingRecord = record },
                                    onDelete: {
                                        deletingRecord = record
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 92)
                    }
                    .background(Theme.background)
                }
            }
            .navigationTitle(Text("hand.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("action.done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createRecord()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("hand.create"))
                }
            }
            .keyboardAwareBottomBar {
                Button {
                    createRecord()
                } label: {
                    Label("hand.create", systemImage: "square.and.pencil")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .background(Theme.background.opacity(0.78))
            }
            .confirmationDialog(
                Text("hand.delete_title"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("action.delete", role: .destructive) {
                    if let deletingRecord {
                        delete(deletingRecord)
                    }
                    deletingRecord = nil
                }
                Button("action.cancel", role: .cancel) {
                    deletingRecord = nil
                }
            } message: {
                Text("hand.delete_message")
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .keyboardConfirmationToolbar()
        .onAppear {
            records = HandActionLineCodec.decode(recordsStored)
        }
        .sheet(item: $editingRecord) { record in
            HandActionLineEditor(
                record: record,
                onSave: saveRecord
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .tint(Theme.accent)
            .preferredColorScheme(.dark)
            .keyboardConfirmationToolbar()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Theme.accent)
            VStack(spacing: 6) {
                Text("hand.empty_title")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Text("hand.empty_body")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Button {
                createRecord()
            } label: {
                Label("hand.create", systemImage: "square.and.pencil")
                    .font(.headline.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    private func createRecord() {
        var record = HandActionLineRecord.new(
            smallBlind: smallBlind > 0 ? smallBlind : max(0, bigBlind / 2),
            bigBlind: bigBlind,
            stackBB: stackBB
        )
        record.title = String(format: NSLocalizedString("hand.default_title", comment: ""), records.count + 1)
        editingRecord = record
    }

    private func saveRecord(_ record: HandActionLineRecord) {
        var nextRecords = records
        if let index = nextRecords.firstIndex(where: { $0.id == record.id }) {
            nextRecords[index] = record
        } else {
            nextRecords.insert(record, at: 0)
        }
        nextRecords.sort { $0.updatedAt > $1.updatedAt }
        records = Array(nextRecords.prefix(100))
        recordsStored = HandActionLineCodec.encode(records)
    }

    private func delete(_ record: HandActionLineRecord) {
        records.removeAll { $0.id == record.id }
        recordsStored = HandActionLineCodec.encode(records)
    }
}

private struct HandActionLineCard: View {
    let record: HandActionLineRecord
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.accent.opacity(0.14)))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.displayTitle)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(1)
                        Text(summaryText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Menu {
                        ShareLink(item: record.shareText) {
                            Label("hand.share", systemImage: "square.and.arrow.up")
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label("action.delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 38, height: 38)
                    }
                    .accessibilityLabel(Text("hand.more"))
                }

                if !previewText.isEmpty {
                    Text(previewText)
                        .font(.subheadline)
                        .foregroundStyle(Theme.primaryText.opacity(0.82))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        .buttonStyle(.plain)
        .accessibilityIdentifier("hand.record.card")
    }

    private var summaryText: String {
        let blinds = record.bigBlind > 0 ? "\(record.smallBlind)/\(record.bigBlind)" : "--"
        return String(format: NSLocalizedString("hand.card_summary", comment: ""), blinds, record.actionCount)
    }

    private var previewText: String {
        record.streets
            .flatMap(\.actions)
            .prefix(3)
            .map(\.displayText)
            .joined(separator: "\n")
    }
}

private struct HandActionLineEditor: View {
    let onSave: (HandActionLineRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: HandActionLineRecord
    @State private var selectedStreet: HandStreet = .preflop
    @State private var selectedPosition: String = "UTG"
    @State private var smallBlindText: String
    @State private var bigBlindText: String
    @State private var chipsText: String
    @State private var selectedPlayerCount: Int
    @State private var selectedHeroCardSlot: Int = 0
    @State private var selectedBoardCardSlot: Int = 0
    @State private var copiedToastVisible: Bool = false

    private let ranks = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
    private let suits: [(symbol: String, name: String)] = [
        ("♣", "club"),
        ("♦", "diamond"),
        ("♥", "heart"),
        ("♠", "spade")
    ]

    init(record: HandActionLineRecord, onSave: @escaping (HandActionLineRecord) -> Void) {
        self._draft = State(initialValue: record)
        self._selectedStreet = State(initialValue: .preflop)
        self._smallBlindText = State(initialValue: record.smallBlind > 0 ? String(record.smallBlind) : "")
        self._bigBlindText = State(initialValue: record.bigBlind > 0 ? String(record.bigBlind) : "")
        self._chipsText = State(initialValue: record.chips > 0 ? String(record.chips) : "")
        self._selectedPlayerCount = State(initialValue: min(max(record.playerCount, 6), 9))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    handMetaSection
                    streetTabs
                    currentStreetSection
                    quickActionSection
                    timelineSection
                    noteSection
                }
                .padding(16)
                .padding(.bottom, 88)
            }
            .onChange(of: selectedStreet) { _, _ in
                selectedPosition = currentActionPositions.first ?? selectedPosition
                selectedBoardCardSlot = 0
            }
            .background(
                RadialGradient(
                    colors: [Theme.tableFelt.opacity(0.72), Theme.background],
                    center: .top,
                    startRadius: 40,
                    endRadius: 540
                )
                .ignoresSafeArea()
            )
            .navigationTitle(Text("hand.editor_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("action.back") {
                        saveAndDismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: currentShareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(Text("hand.share"))
                }
            }
            .keyboardAwareBottomBar {
                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = currentShareText
                        copiedToastVisible = true
                    } label: {
                        Label("hand.copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        saveAndDismiss()
                    } label: {
                        Text("action.done")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .background(Theme.background.opacity(0.78))
            }
            .overlay(alignment: .bottom) {
                if copiedToastVisible {
                    Text("hand.copied")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.surfaceElevated))
                        .overlay(Capsule().stroke(Theme.surfaceStroke, lineWidth: 1))
                        .padding(.bottom, 86)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                copiedToastVisible = false
                            }
                        }
                }
            }
        }
    }

    private var currentShareText: String {
        var record = draft
        applyEditableMeta(to: &record)
        return record.shareText
    }

    private var handMetaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(NSLocalizedString("hand.title_placeholder", comment: ""), text: $draft.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.primaryText)
                .textInputAutocapitalization(.words)

            HStack(spacing: 10) {
                HandEditableNumberField(
                    titleKey: "blinds.small_blind",
                    text: $smallBlindText,
                    iconName: "s.circle.fill"
                )
                HandEditableNumberField(
                    titleKey: "blinds.big_blind",
                    text: $bigBlindText,
                    iconName: "b.circle.fill"
                )
                HandEditableNumberField(
                    titleKey: "result.chips",
                    text: $chipsText,
                    iconName: "square.stack.3d.up.fill"
                )
            }

            heroCardPicker
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.surfaceStroke, lineWidth: 1))
    }

    private var heroCardPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("hand.hero_cards")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.primaryText)

            HStack(spacing: 10) {
                ForEach(0..<2, id: \.self) { index in
                    Button {
                        selectedHeroCardSlot = index
                    } label: {
                        Text(heroCard(at: index) ?? NSLocalizedString(index == 0 ? "hand.card_one" : "hand.card_two", comment: ""))
                            .font(.title3.weight(.black))
                            .foregroundStyle(selectedHeroCardSlot == index ? Color.white : Theme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(selectedHeroCardSlot == index ? Theme.accent : Theme.surface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(ranks, id: \.self) { rank in
                    Button {
                        selectHeroRank(rank)
                    } label: {
                        Text(rank)
                            .font(.caption.weight(.black))
                            .foregroundStyle(Theme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                ForEach(suits, id: \.symbol) { suit in
                    Button {
                        selectHeroSuit(suit.symbol)
                    } label: {
                        Text(suit.symbol)
                            .font(.title3.weight(.black))
                            .foregroundStyle(suitColor(suit.symbol))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(suit.name))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface.opacity(0.72)))
    }

    private var streetTabs: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(HandStreet.allCases) { street in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(streetStepFill(for: street))
                            .frame(width: 10, height: 10)
                        Text(street.title)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(street == selectedStreet ? Theme.primaryText : Theme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 10) {
                Button {
                    moveToPreviousStreet()
                } label: {
                    Label("hand.previous_step", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 38)
                }
                .buttonStyle(.bordered)
                .disabled(selectedStreet == .preflop)

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedStreet.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.primaryText)
                    Text("hand.step_hint")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }

                Spacer(minLength: 0)

                Button {
                    moveToNextStreet()
                } label: {
                    Label("hand.next_step", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 38)
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveToNextStreet)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.surfaceStroke, lineWidth: 1))
    }

    private var currentStreetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: NSLocalizedString("hand.current_step_title", comment: ""), selectedStreet.title))
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.primaryText)

            if selectedStreet != .preflop {
                boardCardPicker
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.surfaceStroke, lineWidth: 1))
    }

    private var boardCardPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: NSLocalizedString("hand.board_card_count", comment: ""), requiredBoardCardCount))
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.secondaryText)

            HStack(spacing: 10) {
                ForEach(0..<requiredBoardCardCount, id: \.self) { index in
                    Button {
                        selectedBoardCardSlot = index
                    } label: {
                        Text(boardCard(at: index, for: selectedStreet) ?? String(index + 1))
                            .font(.title3.weight(.black))
                            .foregroundStyle(selectedBoardCardSlot == index ? Color.white : Theme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(selectedBoardCardSlot == index ? Theme.accent : Theme.surface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(ranks, id: \.self) { rank in
                    Button {
                        selectBoardRank(rank)
                    } label: {
                        Text(rank)
                            .font(.caption.weight(.black))
                            .foregroundStyle(Theme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                ForEach(suits, id: \.symbol) { suit in
                    Button {
                        selectBoardSuit(suit.symbol)
                    } label: {
                        Text(suit.symbol)
                            .font(.title3.weight(.black))
                            .foregroundStyle(suitColor(suit.symbol))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(suit.name))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface.opacity(0.72)))
    }

    private var quickActionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("hand.quick_action")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Text(String(format: NSLocalizedString("hand.quick_action_subtitle", comment: ""), selectedStreet.title))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }

            playerCountControl
            PokerTablePositionPicker(
                positions: currentActionPositions,
                selectedPosition: $selectedPosition,
                chipsText: chipsText
            )
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: NSLocalizedString("hand.current_position_action", comment: ""), selectedPosition))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.secondaryText)

                if currentActionPositions.isEmpty {
                    Text("hand.no_active_players")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
                } else {
                    actionChoiceGrid
                        .disabled(!canRecordAction)
                        .opacity(canRecordAction ? 1 : 0.45)
                    if !canRecordAction {
                        Text("hand.board_required")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }

            if selectedStreet != .river {
                Button {
                    moveToNextStreet()
                } label: {
                    Label(String(format: NSLocalizedString("hand.finish_step", comment: ""), selectedStreet.title, nextStreetTitle), systemImage: "arrow.right.circle")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveToNextStreet)
            }

            if !canMoveToNextStreet, selectedStreet != .river {
                Text("hand.step_locked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.surfaceStroke, lineWidth: 1))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("hand.timeline")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.primaryText)

            ForEach(HandStreet.allCases) { street in
                if let streetRecord = draft.streets.first(where: { $0.street == street }),
                   !streetRecord.actions.isEmpty || !streetRecord.boardText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(streetRecord.boardText.isEmpty ? street.title : "\(street.title) \(streetRecord.boardText)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.accent)

                        ForEach(streetRecord.actions) { action in
                            HStack(spacing: 10) {
                                Text(action.displayText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(role: .destructive) {
                                    removeAction(action.id, from: street)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface))
                        }
                    }
                }
            }

            if draft.actionCount == 0 {
                Text("hand.timeline_empty")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.surfaceStroke, lineWidth: 1))
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("hand.note")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.primaryText)
            TextField(NSLocalizedString("hand.note_placeholder", comment: ""), text: $draft.note, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        }
        .foregroundStyle(Theme.primaryText)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.surfaceStroke, lineWidth: 1))
    }

    private var playerCountControl: some View {
        HStack(spacing: 8) {
            Text("hand.players")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.secondaryText)

            Spacer(minLength: 0)

            ForEach(6...9, id: \.self) { count in
                Button {
                    guard !isPlayerCountLocked else { return }
                    selectedPlayerCount = count
                    let positions = positionsForPlayerCount(count)
                    if !positions.contains(selectedPosition) {
                        selectedPosition = positions.first ?? "UTG"
                    }
                    draft.playerCount = count
                    draft.updatedAt = Date()
                } label: {
                    Text("\(count)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(selectedPlayerCount == count ? Color.white : Theme.primaryText)
                        .frame(width: 34, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedPlayerCount == count ? Theme.accent : Theme.surface)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isPlayerCountLocked)
            }
        }
        .opacity(isPlayerCountLocked ? 0.55 : 1)
    }

    private var actionChoiceGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(contextualActionChoices) { choice in
                Button {
                    addAction(choice)
                } label: {
                    VStack(spacing: 4) {
                        Text(choice.title)
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if !choice.subtitle.isEmpty {
                            Text(choice.subtitle)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(choice.tint)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var contextualActionChoices: [HandActionChoice] {
        if hasAllInAction {
            return [
                HandActionChoice(title: "Call", subtitle: "", action: "Call", amount: "", tint: Theme.accent),
                HandActionChoice(title: "Fold", subtitle: "", action: "Fold", amount: "", tint: Theme.healthRed)
            ]
        }
        if hasOutstandingBet {
            return [
                HandActionChoice(title: "Raise", subtitle: "2x", action: "Raise", amount: "2x", tint: Theme.healthOrange),
                HandActionChoice(title: "Raise", subtitle: "3x", action: "Raise", amount: "3x", tint: Theme.healthOrange),
                HandActionChoice(title: "Raise", subtitle: "4x", action: "Raise", amount: "4x", tint: Theme.healthOrange),
                HandActionChoice(title: "Call", subtitle: "", action: "Call", amount: "", tint: Theme.accent),
                HandActionChoice(title: "Fold", subtitle: "", action: "Fold", amount: "", tint: Theme.healthRed)
            ]
        }
        return [
            HandActionChoice(title: "Bet", subtitle: "1/3", action: "Bet", amount: "1/3 pot", tint: Theme.accent),
            HandActionChoice(title: "Bet", subtitle: "2/3", action: "Bet", amount: "2/3 pot", tint: Theme.accent),
            HandActionChoice(title: "All-in", subtitle: "", action: "All-in", amount: "", tint: Theme.healthRed),
            HandActionChoice(title: "Check", subtitle: "", action: "Check", amount: "", tint: Theme.healthGreen),
            HandActionChoice(title: "Fold", subtitle: "", action: "Fold", amount: "", tint: Theme.healthRed)
        ]
    }

    private var hasAllInAction: Bool {
        currentStreetActions.contains { $0.action == "All-in" }
    }

    private var hasOutstandingBet: Bool {
        currentStreetActions.contains { action in
            ["Bet", "Raise", "All-in"].contains(action.action)
        }
    }

    private var currentStreetActions: [HandActionRecord] {
        draft.streets.first(where: { $0.street == selectedStreet })?.actions ?? []
    }

    private var currentActionPositions: [String] {
        actionPositions(for: selectedStreet)
    }

    private var currentPendingActionPositions: [String] {
        let actedPositions = Set(currentStreetActions.map(\.position))
        return currentActionPositions.filter { !actedPositions.contains($0) }
    }

    private var canRecordAction: Bool {
        selectedStreet == .preflop || hasRequiredBoardCards(for: selectedStreet)
    }

    private var isPlayerCountLocked: Bool {
        selectedStreet != .preflop || hasConfigured(.preflop)
    }

    private var requiredBoardCardCount: Int {
        switch selectedStreet {
        case .preflop:
            return 0
        case .flop:
            return 3
        case .turn, .river:
            return 1
        }
    }

    private func tokenGrid(items: [String], selection: Binding<String>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection.wrappedValue = item
                } label: {
                    Text(item)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selection.wrappedValue == item ? Color.white : Theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selection.wrappedValue == item ? Theme.accent : Theme.surface)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func boardBinding(for street: HandStreet) -> Binding<String> {
        Binding(
            get: {
                draft.streets.first(where: { $0.street == street })?.boardText ?? ""
            },
            set: { value in
                guard let index = draft.streets.firstIndex(where: { $0.street == street }) else { return }
                draft.streets[index].boardText = value
                draft.updatedAt = Date()
            }
        )
    }

    private var nextStreetTitle: String {
        guard let index = HandStreet.allCases.firstIndex(of: selectedStreet),
              index + 1 < HandStreet.allCases.count else {
            return selectedStreet.title
        }
        return HandStreet.allCases[index + 1].title
    }

    private var canMoveToNextStreet: Bool {
        guard selectedStreet != .river else {
            return false
        }
        if selectedStreet != .preflop, !hasRequiredBoardCards(for: selectedStreet) {
            return false
        }
        return currentStreetActions.count >= currentActionPositions.count && !currentActionPositions.isEmpty
    }

    private func hasConfigured(_ street: HandStreet) -> Bool {
        guard let streetRecord = draft.streets.first(where: { $0.street == street }) else {
            return false
        }
        return !streetRecord.actions.isEmpty
    }

    private func moveToNextStreet() {
        guard canMoveToNextStreet else { return }
        guard let index = HandStreet.allCases.firstIndex(of: selectedStreet),
              index + 1 < HandStreet.allCases.count else {
            return
        }
        selectedStreet = HandStreet.allCases[index + 1]
        selectedPosition = actionPositions(for: selectedStreet).first ?? selectedPosition
    }

    private func moveToPreviousStreet() {
        guard let index = HandStreet.allCases.firstIndex(of: selectedStreet),
              index > 0 else {
            return
        }
        selectedStreet = HandStreet.allCases[index - 1]
    }

    private func streetStepFill(for street: HandStreet) -> Color {
        guard let streetIndex = HandStreet.allCases.firstIndex(of: street),
              let selectedIndex = HandStreet.allCases.firstIndex(of: selectedStreet) else {
            return Theme.surfaceStroke
        }
        if streetIndex < selectedIndex || hasConfigured(street) {
            return Theme.healthGreen
        }
        if street == selectedStreet {
            return Theme.accent
        }
        return Theme.surfaceStroke
    }

    private func positionsForPlayerCount(_ count: Int) -> [String] {
        switch count {
        case 6:
            return ["UTG", "HJ", "CO", "BTN", "SB", "BB"]
        case 7:
            return ["UTG", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
        case 8:
            return ["UTG", "UTG+1", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
        default:
            return ["UTG", "UTG+1", "MP", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
        }
    }

    private func actionPositions(for street: HandStreet) -> [String] {
        let positions = positionsForPlayerCount(selectedPlayerCount)
        if street == .preflop {
            return positions
        }
        let unavailablePositions = Set(actions(before: street).compactMap { action -> String? in
            ["Fold", "All-in"].contains(action.action) ? action.position : nil
        })
        return postflopOrder(for: positions).filter { !unavailablePositions.contains($0) }
    }

    private func postflopOrder(for positions: [String]) -> [String] {
        guard let buttonIndex = positions.firstIndex(of: "BTN") else {
            return positions
        }
        return Array(positions[(buttonIndex + 1)...]) + Array(positions[..<(buttonIndex + 1)])
    }

    private func actions(before street: HandStreet) -> [HandActionRecord] {
        guard let targetIndex = HandStreet.allCases.firstIndex(of: street) else {
            return []
        }
        return draft.streets.flatMap { streetRecord -> [HandActionRecord] in
            guard let index = HandStreet.allCases.firstIndex(of: streetRecord.street), index < targetIndex else {
                return []
            }
            return streetRecord.actions
        }
    }

    private func boardCards(for street: HandStreet) -> [String] {
        draft.streets
            .first(where: { $0.street == street })?
            .boardText
            .split(separator: " ")
            .map(String.init) ?? []
    }

    private func boardCard(at index: Int, for street: HandStreet) -> String? {
        let cards = boardCards(for: street)
        guard index >= 0, index < cards.count else { return nil }
        return cards[index]
    }

    private func hasRequiredBoardCards(for street: HandStreet) -> Bool {
        let requiredCount: Int
        switch street {
        case .preflop:
            requiredCount = 0
        case .flop:
            requiredCount = 3
        case .turn, .river:
            requiredCount = 1
        }
        return boardCards(for: street).filter { !$0.isEmpty }.count >= requiredCount
    }

    private func heroCards() -> [String] {
        draft.heroCards
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func heroCard(at index: Int) -> String? {
        let cards = heroCards()
        guard index >= 0, index < cards.count else { return nil }
        return cards[index]
    }

    private func selectHeroRank(_ rank: String) {
        let current = heroCard(at: selectedHeroCardSlot) ?? ""
        let suit = current.last.map(String.init).flatMap { suits.map(\.symbol).contains($0) ? $0 : nil } ?? ""
        setHeroCard("\(rank)\(suit)", at: selectedHeroCardSlot)
    }

    private func selectHeroSuit(_ suit: String) {
        let current = heroCard(at: selectedHeroCardSlot) ?? ""
        let rank = current.first.map(String.init) ?? "A"
        setHeroCard("\(rank)\(suit)", at: selectedHeroCardSlot)
        if selectedHeroCardSlot == 0, heroCard(at: 1) == nil {
            selectedHeroCardSlot = 1
        }
    }

    private func setHeroCard(_ card: String, at index: Int) {
        var cards = heroCards()
        while cards.count < 2 {
            cards.append("")
        }
        cards[index] = card
        draft.heroCards = cards.filter { !$0.isEmpty }.joined(separator: " ")
        draft.updatedAt = Date()
    }

    private func selectBoardRank(_ rank: String) {
        let current = boardCard(at: selectedBoardCardSlot, for: selectedStreet) ?? ""
        let suit = current.last.map(String.init).flatMap { suits.map(\.symbol).contains($0) ? $0 : nil } ?? ""
        setBoardCard("\(rank)\(suit)", at: selectedBoardCardSlot)
    }

    private func selectBoardSuit(_ suit: String) {
        let current = boardCard(at: selectedBoardCardSlot, for: selectedStreet) ?? ""
        let rank = current.first.map(String.init) ?? "A"
        setBoardCard("\(rank)\(suit)", at: selectedBoardCardSlot)
        if selectedBoardCardSlot + 1 < requiredBoardCardCount,
           boardCard(at: selectedBoardCardSlot + 1, for: selectedStreet) == nil {
            selectedBoardCardSlot += 1
        }
    }

    private func setBoardCard(_ card: String, at index: Int) {
        guard selectedStreet != .preflop,
              index >= 0,
              index < requiredBoardCardCount,
              let streetIndex = draft.streets.firstIndex(where: { $0.street == selectedStreet }) else {
            return
        }
        var cards = boardCards(for: selectedStreet)
        while cards.count < requiredBoardCardCount {
            cards.append("")
        }
        cards[index] = card
        draft.streets[streetIndex].boardText = cards.filter { !$0.isEmpty }.joined(separator: " ")
        draft.updatedAt = Date()
    }

    private func suitColor(_ suit: String) -> Color {
        switch suit {
        case "♥":
            return Theme.healthRed
        case "♦":
            return Theme.accent
        case "♣":
            return Theme.healthGreen
        default:
            return Theme.primaryText
        }
    }

    private func addAction(_ choice: HandActionChoice) {
        guard canRecordAction else { return }
        guard currentActionPositions.contains(selectedPosition) else { return }
        guard !currentStreetActions.contains(where: { $0.position == selectedPosition }) else { return }
        guard let index = draft.streets.firstIndex(where: { $0.street == selectedStreet }) else { return }
        draft.streets[index].actions.append(
            HandActionRecord(
                id: UUID(),
                position: selectedPosition,
                action: choice.action,
                amount: choice.amount,
                note: "",
                createdAt: Date()
            )
        )
        draft.updatedAt = Date()
        moveToNextPosition()
    }

    private func moveToNextPosition() {
        let positions = currentActionPositions
        guard let index = positions.firstIndex(of: selectedPosition) else {
            selectedPosition = positions.first ?? "UTG"
            return
        }
        let actedPositions = Set(currentStreetActions.map(\.position))
        let nextPositions = Array(positions[(index + 1)...]) + Array(positions[..<index])
        if let nextPosition = nextPositions.first(where: { !actedPositions.contains($0) }) {
            selectedPosition = nextPosition
            return
        }
        if selectedStreet != .river, canMoveToNextStreet {
            moveToNextStreet()
            return
        }
        selectedPosition = positions[(index + 1) % positions.count]
    }

    private func removeAction(_ actionID: UUID, from street: HandStreet) {
        guard let index = draft.streets.firstIndex(where: { $0.street == street }) else { return }
        draft.streets[index].actions.removeAll { $0.id == actionID }
        draft.updatedAt = Date()
    }

    private func saveAndDismiss() {
        applyEditableMeta(to: &draft)
        draft.updatedAt = Date()
        onSave(draft)
        dismiss()
    }

    private func applyEditableMeta(to record: inout HandActionLineRecord) {
        let sb = numericValue(from: smallBlindText)
        let bb = numericValue(from: bigBlindText)
        let chips = numericValue(from: chipsText)
        if sb > 0 {
            record.smallBlind = sb
        }
        if bb > 0 {
            record.bigBlind = bb
        }
        if chips > 0 {
            record.chips = chips
        }
        if record.bigBlind > 0, record.chips > 0 {
            record.stackBB = Double(record.chips) / Double(record.bigBlind)
        }
        record.playerCount = selectedPlayerCount
    }

    private func numericValue(from text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
    }
}

private struct HandMetaPill: View {
    let iconName: String
    let text: String

    var body: some View {
        Label(text, systemImage: iconName)
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule(style: .continuous).fill(Theme.surface))
    }
}

private struct HandActionChoice: Identifiable {
    var id: String { "\(action)-\(amount)-\(title)" }
    let title: String
    let subtitle: String
    let action: String
    let amount: String
    let tint: Color
}

private struct PokerTablePositionPicker: View {
    let positions: [String]
    @Binding var selectedPosition: String
    let chipsText: String

    private var displayChips: String {
        chipsText.isEmpty ? "--" : chipsText
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: min(size.width, size.height) * 0.42, style: .continuous)
                    .stroke(Theme.surfaceStroke.opacity(0.72), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: min(size.width, size.height) * 0.42, style: .continuous)
                            .fill(Theme.tableFelt.opacity(0.32))
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 34)

                VStack(spacing: 5) {
                    Text("hand.table_center")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.secondaryText)
                    Text(selectedPosition)
                        .font(.title3.weight(.black))
                        .foregroundStyle(Theme.primaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule(style: .continuous).fill(Theme.background.opacity(0.52)))

                ForEach(Array(positions.enumerated()), id: \.offset) { index, position in
                    Button {
                        selectedPosition = position
                    } label: {
                        VStack(spacing: 2) {
                            Text(position)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                            Text(displayChips)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                        }
                        .foregroundStyle(selectedPosition == position ? Color.white : Theme.primaryText)
                        .frame(width: seatSize(for: positions.count), height: seatSize(for: positions.count))
                        .background(
                            Circle()
                                .fill(selectedPosition == position ? Theme.accent.opacity(0.92) : Theme.background.opacity(0.88))
                        )
                        .overlay(
                            Circle()
                                .stroke(selectedPosition == position ? Theme.chipGold : Theme.surfaceStroke.opacity(0.9), lineWidth: selectedPosition == position ? 2 : 1.5)
                        )
                        .shadow(color: selectedPosition == position ? Theme.accent.opacity(0.32) : .clear, radius: 12, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .position(seatPosition(index: index, count: positions.count, in: size))
                }
            }
        }
        .accessibilityIdentifier("hand.table.positionPicker")
    }

    private func seatSize(for count: Int) -> CGFloat {
        count >= 8 ? 54 : 60
    }

    private func seatPosition(index: Int, count: Int, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radiusX = max(80, size.width * 0.42)
        let radiusY = max(54, size.height * 0.34)
        let startAngle = -CGFloat.pi / 2
        let angle = startAngle + (2 * CGFloat.pi * CGFloat(index) / CGFloat(count))
        return CGPoint(
            x: center.x + cos(angle) * radiusX,
            y: center.y + sin(angle) * radiusY
        )
    }
}

private struct HandEditableNumberField: View {
    let titleKey: String
    @Binding var text: String
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label {
                Text(LocalizedStringKey(titleKey))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } icon: {
                Image(systemName: iconName)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(Theme.secondaryText)

            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
    }
}
