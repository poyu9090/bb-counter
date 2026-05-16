import Foundation

struct ChipChangeRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let previousChips: Int
    let newChips: Int
    let changedAt: Date

    var delta: Int {
        newChips - previousChips
    }
}
