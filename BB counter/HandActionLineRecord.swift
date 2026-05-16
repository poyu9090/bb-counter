import Foundation

struct HandActionLineRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var smallBlind: Int
    var bigBlind: Int
    var chips: Int
    var stackBB: Double
    var playerCount: Int
    var heroCards: String
    var note: String
    var streets: [HandActionStreetRecord]
    var createdAt: Date
    var updatedAt: Date

    static func new(smallBlind: Int, bigBlind: Int, stackBB: Double) -> HandActionLineRecord {
        HandActionLineRecord(
            id: UUID(),
            title: "",
            smallBlind: smallBlind,
            bigBlind: bigBlind,
            chips: Int((stackBB * Double(bigBlind)).rounded()),
            stackBB: stackBB,
            playerCount: 6,
            heroCards: "",
            note: "",
            streets: HandStreet.allCases.map { HandActionStreetRecord(street: $0, boardText: "", actions: []) },
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Hand" : title
    }

    var actionCount: Int {
        streets.reduce(0) { $0 + $1.actions.count }
    }

    var shareText: String {
        var lines: [String] = []
        lines.append(displayTitle)
        if smallBlind > 0, bigBlind > 0 {
            lines.append("Blinds: \(smallBlind) / \(bigBlind)")
        }
        if chips > 0 {
            lines.append("Chips: \(chips)")
        }
        if stackBB > 0 {
            lines.append("Stack: \(formattedBB(stackBB)) BB")
        }
        if !heroCards.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Hero: \(heroCards)")
        }
        lines.append("")

        for street in streets {
            let board = street.boardText.trimmingCharacters(in: .whitespacesAndNewlines)
            let header = board.isEmpty ? street.street.title : "\(street.street.title) \(board)"
            if !street.actions.isEmpty || !board.isEmpty {
                lines.append(header)
                lines.append(contentsOf: street.actions.map(\.displayText))
                lines.append("")
            }
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNote.isEmpty {
            lines.append("Note")
            lines.append(trimmedNote)
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedBB(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case smallBlind
        case bigBlind
        case chips
        case stackBB
        case playerCount
        case heroCards
        case note
        case streets
        case createdAt
        case updatedAt
    }

    init(
        id: UUID,
        title: String,
        smallBlind: Int,
        bigBlind: Int,
        chips: Int,
        stackBB: Double,
        playerCount: Int,
        heroCards: String,
        note: String,
        streets: [HandActionStreetRecord],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.chips = chips
        self.stackBB = stackBB
        self.playerCount = playerCount
        self.heroCards = heroCards
        self.note = note
        self.streets = streets
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        smallBlind = try container.decode(Int.self, forKey: .smallBlind)
        bigBlind = try container.decode(Int.self, forKey: .bigBlind)
        stackBB = try container.decode(Double.self, forKey: .stackBB)
        chips = try container.decodeIfPresent(Int.self, forKey: .chips) ?? Int((stackBB * Double(bigBlind)).rounded())
        playerCount = try container.decodeIfPresent(Int.self, forKey: .playerCount) ?? 6
        heroCards = try container.decode(String.self, forKey: .heroCards)
        note = try container.decode(String.self, forKey: .note)
        streets = try container.decode([HandActionStreetRecord].self, forKey: .streets)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct HandActionStreetRecord: Identifiable, Codable, Equatable {
    var id: HandStreet { street }
    var street: HandStreet
    var boardText: String
    var actions: [HandActionRecord]
}

struct HandActionRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var position: String
    var action: String
    var amount: String
    var note: String
    var createdAt: Date

    var displayText: String {
        [position, action, amount, note]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

enum HandStreet: String, CaseIterable, Codable, Identifiable {
    case preflop
    case flop
    case turn
    case river

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preflop:
            return "Preflop"
        case .flop:
            return "Flop"
        case .turn:
            return "Turn"
        case .river:
            return "River"
        }
    }
}

enum HandActionLineCodec {
    static func decode(_ payload: String) -> [HandActionLineRecord] {
        guard let data = payload.data(using: .utf8),
              let records = try? JSONDecoder().decode([HandActionLineRecord].self, from: data) else {
            return []
        }
        return records
    }

    static func encode(_ records: [HandActionLineRecord]) -> String {
        guard let data = try? JSONEncoder().encode(records),
              let payload = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return payload
    }
}
