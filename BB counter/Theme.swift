import SwiftUI

enum Theme {
    static let background = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let surface = Color.white.opacity(0.06)
    static let surfaceElevated = Color.white.opacity(0.09)
    static let surfaceStroke = Color.white.opacity(0.12)
    static let tableFelt = Color(red: 0.05, green: 0.28, blue: 0.21)

    static let primaryText = Color.white.opacity(0.92)
    static let secondaryText = Color.white.opacity(0.64)

    static let accent = Color(red: 0.50, green: 0.70, blue: 1.00)
    static let chipGold = Color(red: 1.00, green: 0.74, blue: 0.32)

    static let healthRed = Color(red: 1.00, green: 0.40, blue: 0.40)
    static let healthOrange = Color(red: 1.00, green: 0.75, blue: 0.30)
    static let healthYellow = Color(red: 0.95, green: 0.88, blue: 0.38)
    static let healthGreen = Color(red: 0.45, green: 0.85, blue: 0.55)
}
