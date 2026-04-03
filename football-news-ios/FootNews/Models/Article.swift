import Foundation
import SwiftUI

// MARK: - Article

struct Article: Identifiable, Codable, Equatable {
    let id: String
    let sourceId: String
    let title: String
    let articleURL: URL
    let summary: String?
    let publishedAt: Date
    let author: String?
    let imageURL: URL?

    // Scoring
    let sourceReliability: Int
    let clickbaitScore: Double    // 0.0–1.0
    let finalScore: Double        // 1.0–5.0
    let clickbaitFlags: [String]

    // Computed
    var relativeDate: String {
        let diff = Date.now.timeIntervalSince(publishedAt)
        let mins = Int(diff / 60)
        if mins < 1 { return "à l'instant" }
        if mins < 60 { return "il y a \(mins) min" }
        let hrs = mins / 60
        if hrs < 24 { return "il y a \(hrs)h" }
        return "il y a \(hrs / 24)j"
    }

    var scoreLabel: String { Article.label(for: finalScore) }
    var scoreColor: Color  { Article.color(for: finalScore) }

    static func label(for score: Double) -> String {
        switch score {
        case 4.5...: return "Très fiable"
        case 3.5...: return "Fiable"
        case 2.5...: return "À vérifier"
        case 1.5...: return "Peu fiable"
        default:     return "Putaclick"
        }
    }

    static func color(for score: Double) -> Color {
        switch score {
        case 4.5...: return Color(hex: "#22c55e")
        case 3.5...: return Color(hex: "#84cc16")
        case 2.5...: return Color(hex: "#f59e0b")
        case 1.5...: return Color(hex: "#f97316")
        default:     return Color(hex: "#ef4444")
        }
    }
}

// MARK: - Color from hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
