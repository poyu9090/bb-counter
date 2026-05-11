import Foundation

struct BlindStructure: Codable, Equatable, Identifiable {
	var id: String
	var name: String
	var levels: [BlindLevel]

	init(id: String = UUID().uuidString, name: String, levels: [BlindLevel]) {
		self.id = id
		self.name = name
		self.levels = levels
	}
}

struct BlindLevel: Codable, Equatable, Hashable {
	var sb: Int
	var bb: Int
}

enum BlindStructureValidation {
	static func validate(name: String, levels: [BlindLevel]) -> String? {
		let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmedName.isEmpty {
			return NSLocalizedString("timer.validation_name_required", comment: "")
		}
		if levels.isEmpty {
			return NSLocalizedString("timer.validation_levels_required", comment: "")
		}
		for (idx, level) in levels.enumerated() {
			if level.sb <= 0 || level.bb <= 0 {
				return NSLocalizedString("timer.validation_positive", comment: "")
			}
			if level.bb < level.sb {
				return String(format: NSLocalizedString("timer.validation_bb_lt_sb", comment: ""), idx + 1)
			}
			if idx > 0 {
				let previous = levels[idx - 1]
				if level.bb <= previous.bb {
					return String(format: NSLocalizedString("timer.validation_not_increasing", comment: ""), idx + 1)
				}
				if level == previous {
					return String(format: NSLocalizedString("timer.validation_duplicate", comment: ""), idx + 1)
				}
			}
		}
		return nil
	}
}

enum BlindStructureCodec {
	static func decodeStructures(from string: String) -> [BlindStructure] {
		guard let data = string.data(using: .utf8), !data.isEmpty else { return [] }
		return (try? JSONDecoder().decode([BlindStructure].self, from: data)) ?? []
	}

	static func encodeStructures(_ structures: [BlindStructure]) -> String {
		guard let data = try? JSONEncoder().encode(structures) else { return "[]" }
		return String(data: data, encoding: .utf8) ?? "[]"
	}

	static func decodeLegacyLevels(from string: String) -> [BlindLevel] {
		let parts = string.split(separator: ",").compactMap { Int($0) }
		var levels: [BlindLevel] = []
		var index = 0
		while index + 1 < parts.count {
			levels.append(BlindLevel(sb: parts[index], bb: parts[index + 1]))
			index += 2
		}
		return levels
	}

	static func encodeLevels(_ levels: [BlindLevel]) -> String {
		levels.flatMap { ["\($0.sb)", "\($0.bb)"] }.joined(separator: ",")
	}

	static func decodeLevels(from string: String) -> [BlindLevel] {
		decodeLegacyLevels(from: string)
	}
}
