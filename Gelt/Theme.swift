import SwiftUI

// ═══════════════════════════════════════════════════
//  GELT — Design Tokens (Black & Gold)
// ═══════════════════════════════════════════════════

struct Theme {
    // Backgrounds
    static let bg = Color(hex: "050508")
    static let bg2 = Color(hex: "0c0c10")
    static let card = Color(hex: "111116")
    static let cardBorder = Color(hex: "1c1c22")
    
    // Gold
    static let gold = Color(hex: "c9a55c")
    static let goldDim = Color(hex: "c9a55c").opacity(0.12)
    static let goldFaint = Color(hex: "c9a55c").opacity(0.06)
    
    // Text
    static let cream = Color(hex: "f0ebe0")
    static let text = Color(hex: "d4d0c8")
    static let dim = Color(hex: "6b6770")
    static let faint = Color(hex: "3a383f")
    
    // Semantic
    static let green = Color(hex: "5ecc7b")
    static let greenDim = Color(hex: "5ecc7b").opacity(0.1)
    static let red = Color(hex: "e05252")
    static let redDim = Color(hex: "e05252").opacity(0.1)
    static let purple = Color(hex: "a78bfa")
    
    // Category Colors
    static let catColors: [Color] = [
        Color(hex: "06b6d4"), Color(hex: "8b5cf6"), Color(hex: "f59e0b"),
        Color(hex: "10b981"), Color(hex: "f43f5e"), Color(hex: "6366f1"),
        Color(hex: "ec4899"), Color(hex: "14b8a6"), Color(hex: "eab308"),
        Color(hex: "3b82f6"),
    ]
    
    static func catColor(_ index: Int) -> Color {
        catColors[index % catColors.count]
    }
}

// ─── Color Hex Extension ────────────────────────────
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// ─── Formatters ─────────────────────────────────────
extension Double {
    var money: String {
        let neg = self < 0
        let formatted = String(format: "$%@", abs(self).formatted(.number.precision(.fractionLength(2)).grouping(.automatic)))
        return neg ? "-\(formatted)" : formatted
    }
    
    var moneyShort: String {
        let abs = abs(self)
        if abs >= 10000 {
            return (self < 0 ? "-" : "") + "$\(String(format: "%.1f", abs / 1000))k"
        }
        return self.money
    }
}
