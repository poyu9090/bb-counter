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
        if bigBlind > 0 {
            lines.append(String(format: NSLocalizedString("hand.share.big_blind", comment: ""), "\(bigBlind)"))
        }
        if !heroCards.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append(String(format: NSLocalizedString("hand.share.hero", comment: ""), heroCards))
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
            lines.append(NSLocalizedString("hand.note", comment: ""))
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

    /// 街名跟隨 App 語系；位置與動作（UTG、Open、3-Bet…）維持英文，那是牌局筆記的通用寫法。
    var title: String {
        NSLocalizedString("hand.street.\(rawValue)", comment: "")
    }
}

/// 依已記錄的動作推算底池與待跟注額（單位：bb）。
/// 盲注視為 SB 0.5bb、BB 1bb；All-in 以手牌建立時的籌碼深度估算，估算過的結果會標記 `isEstimated`。
struct HandPotSnapshot: Equatable {
    var potBB: Double
    var currentBetBB: Double
    var contributed: [String: Double]
    var isEstimated: Bool

    func toCall(for position: String) -> Double {
        max(0, currentBetBB - (contributed[position] ?? 0))
    }
}

enum HandPotMath {
    static func snapshot(for record: HandActionLineRecord, through street: HandStreet) -> HandPotSnapshot {
        guard let targetIndex = HandStreet.allCases.firstIndex(of: street) else {
            return HandPotSnapshot(potBB: 0, currentBetBB: 0, contributed: [:], isEstimated: false)
        }

        var pot: Double = 0
        var currentBet: Double = 0
        var contributed: [String: Double] = [:]
        var isEstimated = false
        let allInSize = record.stackBB > 0 ? record.stackBB : 100

        for streetCase in HandStreet.allCases.prefix(targetIndex + 1) {
            if streetCase == .preflop {
                contributed = ["SB": 0.5, "BB": 1]
                currentBet = 1
                pot = 1.5
            } else {
                contributed = [:]
                currentBet = 0
            }

            let actions = record.streets.first(where: { $0.street == streetCase })?.actions ?? []
            for action in actions {
                let already = contributed[action.position] ?? 0
                guard let target = targetBet(
                    for: action,
                    currentBet: currentBet,
                    pot: pot,
                    allInSize: allInSize,
                    isEstimated: &isEstimated
                ) else {
                    continue
                }
                let delta = max(0, target - already)
                pot += delta
                contributed[action.position] = max(already, target)
                currentBet = max(currentBet, target)
            }
        }

        return HandPotSnapshot(potBB: pot, currentBetBB: currentBet, contributed: contributed, isEstimated: isEstimated)
    }

    /// 回傳這個動作把該玩家本街的投入「加到多少」，nil 代表不用進池（Check / Fold）。
    private static func targetBet(
        for action: HandActionRecord,
        currentBet: Double,
        pot: Double,
        allInSize: Double,
        isEstimated: inout Bool
    ) -> Double? {
        switch action.action {
        case "Check", "Fold":
            return nil
        case "All-in":
            isEstimated = true
            return max(currentBet, allInSize)
        case "Call":
            if let explicit = bbValue(from: action.amount) {
                return max(currentBet, explicit)
            }
            return currentBet
        default:
            if let explicit = bbValue(from: action.amount) {
                return explicit
            }
            if let fraction = potFraction(from: action.amount) {
                return currentBet + fraction * pot
            }
            if let multiplier = multiplier(from: action.amount) {
                return multiplier * currentBet
            }
            return currentBet
        }
    }

    /// "4.5bb"、"4.5bb (1/2 pot)" → 4.5
    static func bbValue(from amount: String) -> Double? {
        guard let range = amount.range(of: "bb") else { return nil }
        let digits = amount[..<range.lowerBound].filter { $0.isNumber || $0 == "." }
        return Double(digits)
    }

    /// "1/2 pot" → 0.5、"pot" → 1
    static func potFraction(from amount: String) -> Double? {
        guard amount.contains("pot") else { return nil }
        let parts = amount.split(separator: " ").first.map(String.init) ?? ""
        guard parts.contains("/") else { return amount.hasPrefix("pot") ? 1 : nil }
        let numbers = parts.split(separator: "/").compactMap { Double($0) }
        guard numbers.count == 2, numbers[1] != 0 else { return nil }
        return numbers[0] / numbers[1]
    }

    /// "2x" → 2
    static func multiplier(from amount: String) -> Double? {
        guard amount.hasSuffix("x") else { return nil }
        return Double(amount.dropLast())
    }

    /// 以 0.5bb 為單位取整後輸出，例如 "4.5bb"、"9bb"。
    static func formatted(_ value: Double) -> String {
        let rounded = (value * 2).rounded() / 2
        if rounded == rounded.rounded() {
            return "\(Int(rounded))bb"
        }
        return String(format: "%.1fbb", rounded)
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
