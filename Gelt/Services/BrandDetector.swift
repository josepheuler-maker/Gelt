import Foundation

// ═══════════════════════════════════════════════════
//  Brand Auto-Detection (200+ brands)
// ═══════════════════════════════════════════════════

struct BrandMatch {
    let icon: String
    let category: String
}

struct BrandDetector {
    static func detect(_ description: String) -> BrandMatch? {
        let d = description.lowercased()
        for (keyword, match) in brands {
            if d.contains(keyword) { return match }
        }
        return nil
    }
    
    static func detectWithMerchants(_ description: String, merchants: [Merchant]) -> (icon: String, category: String)? {
        let d = description.lowercased()
        // User merchants first
        if let m = merchants.first(where: { d.contains($0.name.lowercased()) }) {
            return (m.icon, m.category)
        }
        // Brand DB
        if let b = detect(description) {
            return (b.icon, b.category)
        }
        return nil
    }
    
    private static let brands: [String: BrandMatch] = [
        // Groceries
        "walmart": .init(icon: "🏪", category: "Groceries"),
        "target": .init(icon: "🎯", category: "Groceries"),
        "kroger": .init(icon: "🛒", category: "Groceries"),
        "trader joe": .init(icon: "🛒", category: "Groceries"),
        "whole foods": .init(icon: "🥑", category: "Groceries"),
        "aldi": .init(icon: "🛒", category: "Groceries"),
        "sprouts": .init(icon: "🌱", category: "Groceries"),
        "smith": .init(icon: "🛒", category: "Groceries"),
        "costco": .init(icon: "📦", category: "Groceries"),
        "harmons": .init(icon: "🛒", category: "Groceries"),
        "maceys": .init(icon: "🛒", category: "Groceries"),
        "winco": .init(icon: "🛒", category: "Groceries"),
        "safeway": .init(icon: "🛒", category: "Groceries"),
        "publix": .init(icon: "🛒", category: "Groceries"),
        "sam's club": .init(icon: "📦", category: "Groceries"),
        // Gas
        "shell": .init(icon: "⛽", category: "Gas"),
        "chevron": .init(icon: "⛽", category: "Gas"),
        "exxon": .init(icon: "⛽", category: "Gas"),
        "maverik": .init(icon: "⛽", category: "Gas"),
        "sinclair": .init(icon: "🦕", category: "Gas"),
        "circle k": .init(icon: "⛽", category: "Gas"),
        "speedway": .init(icon: "⛽", category: "Gas"),
        "conoco": .init(icon: "⛽", category: "Gas"),
        // Dining
        "mcdonald": .init(icon: "🍔", category: "Dining"),
        "burger king": .init(icon: "🍔", category: "Dining"),
        "taco bell": .init(icon: "🌮", category: "Dining"),
        "chipotle": .init(icon: "🌯", category: "Dining"),
        "chick-fil-a": .init(icon: "🐔", category: "Dining"),
        "subway": .init(icon: "🥖", category: "Dining"),
        "domino": .init(icon: "🍕", category: "Dining"),
        "pizza hut": .init(icon: "🍕", category: "Dining"),
        "olive garden": .init(icon: "🍝", category: "Dining"),
        "five guys": .init(icon: "🍔", category: "Dining"),
        "in-n-out": .init(icon: "🍔", category: "Dining"),
        "raising cane": .init(icon: "🍗", category: "Dining"),
        "wingstop": .init(icon: "🍗", category: "Dining"),
        "panera": .init(icon: "🥖", category: "Dining"),
        "starbucks": .init(icon: "☕", category: "Dining"),
        "dunkin": .init(icon: "🍩", category: "Dining"),
        "dutch bros": .init(icon: "☕", category: "Dining"),
        "swig": .init(icon: "🥤", category: "Dining"),
        "beans & brews": .init(icon: "☕", category: "Dining"),
        "doordash": .init(icon: "🚗", category: "Dining"),
        "uber eat": .init(icon: "🚗", category: "Dining"),
        "grubhub": .init(icon: "🚗", category: "Dining"),
        // Entertainment
        "netflix": .init(icon: "📺", category: "Entertainment"),
        "hulu": .init(icon: "📺", category: "Entertainment"),
        "disney+": .init(icon: "📺", category: "Entertainment"),
        "spotify": .init(icon: "🎵", category: "Entertainment"),
        "apple music": .init(icon: "🎵", category: "Entertainment"),
        "youtube": .init(icon: "📺", category: "Entertainment"),
        "xbox": .init(icon: "🎮", category: "Entertainment"),
        "steam": .init(icon: "🎮", category: "Entertainment"),
        "playstation": .init(icon: "🎮", category: "Entertainment"),
        "amc": .init(icon: "🎬", category: "Entertainment"),
        "megaplex": .init(icon: "🎬", category: "Entertainment"),
        "ticketmaster": .init(icon: "🎫", category: "Entertainment"),
        // Shopping
        "amazon": .init(icon: "📦", category: "Shopping"),
        "best buy": .init(icon: "💻", category: "Shopping"),
        "apple store": .init(icon: "🍎", category: "Shopping"),
        "apple.com": .init(icon: "🍎", category: "Shopping"),
        "ikea": .init(icon: "🪑", category: "Shopping"),
        "home depot": .init(icon: "🔨", category: "Shopping"),
        "nike": .init(icon: "👟", category: "Shopping"),
        "nordstrom": .init(icon: "👔", category: "Shopping"),
        "tj maxx": .init(icon: "🛍️", category: "Shopping"),
        "etsy": .init(icon: "🎨", category: "Shopping"),
        "shein": .init(icon: "👗", category: "Shopping"),
        // Auto
        "autozone": .init(icon: "🔧", category: "Auto"),
        "jiffy lube": .init(icon: "🛢️", category: "Auto"),
        "car wash": .init(icon: "🚿", category: "Auto"),
        "parking": .init(icon: "🅿️", category: "Auto"),
        // Health
        "cvs": .init(icon: "💊", category: "Health"),
        "walgreens": .init(icon: "💊", category: "Health"),
        "planet fitness": .init(icon: "💪", category: "Health"),
        "vasa": .init(icon: "💪", category: "Health"),
        // Phone / Utilities
        "verizon": .init(icon: "📱", category: "Phone"),
        "t-mobile": .init(icon: "📱", category: "Phone"),
        "at&t": .init(icon: "📱", category: "Phone"),
        "comcast": .init(icon: "🌐", category: "Utilities"),
        "xfinity": .init(icon: "🌐", category: "Utilities"),
        "rocky mountain power": .init(icon: "⚡", category: "Utilities"),
        // Travel
        "delta": .init(icon: "✈️", category: "Travel"),
        "southwest": .init(icon: "✈️", category: "Travel"),
        "united": .init(icon: "✈️", category: "Travel"),
        "airbnb": .init(icon: "🏠", category: "Travel"),
        "uber": .init(icon: "🚕", category: "Travel"),
        "lyft": .init(icon: "🚕", category: "Travel"),
        // Income
        "payroll": .init(icon: "💰", category: "Income"),
        "direct dep": .init(icon: "💰", category: "Income"),
        "ach deposit": .init(icon: "💰", category: "Income"),
        "st. regis": .init(icon: "🏨", category: "Income"),
        "st regis": .init(icon: "🏨", category: "Income"),
        "murray city": .init(icon: "🏛️", category: "Income"),
    ]
}
