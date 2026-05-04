import SwiftUI
import Combine

// ═══════════════════════════════════════════════════
//  GELT — Reusable Components
// ═══════════════════════════════════════════════════

// ─── Gold Progress Bar ──────────────────────────────
struct GoldBar: View {
    let value: Double
    let max: Double
    var height: CGFloat = 4
    
    private var over: Bool { value > max && max > 0 }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height)
                    .fill(Theme.faint.opacity(0.3))
                RoundedRectangle(cornerRadius: height)
                    .fill(over ? AnyShapeStyle(Theme.red) : AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.gold.opacity(0.8)], startPoint: .leading, endPoint: .trailing)))
                    .frame(width: max > 0 ? geo.size.width * min(1, CGFloat(value / max)) : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}

// ─── Card ───────────────────────────────────────────
struct GeltCard<Content: View>: View {
    var gold: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(gold ? Theme.gold.opacity(0.3) : Theme.cardBorder, lineWidth: 1)
            )
    }
}

// ─── Labels ─────────────────────────────────────────
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(1.5)
            .foregroundColor(Theme.faint)
            .textCase(.uppercase)
    }
}

struct GoldLabel: View {
    let text: String
    var size: CGFloat = 14
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold))
            .foregroundColor(Theme.gold)
    }
}

struct DimText: View {
    let text: String
    var size: CGFloat = 11
    var body: some View {
        Text(text)
            .font(.system(size: size))
            .foregroundColor(Theme.dim)
    }
}

// ─── Pill Badge ─────────────────────────────────────
struct Pill: View {
    let text: String
    var gold: Bool = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundColor(gold ? Theme.gold : Theme.dim)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(gold ? Theme.goldDim : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// ─── Sparkline Bar Chart ────────────────────────────
struct SparkBars: View {
    let data: [(label: String, amount: Double)]
    var height: CGFloat = 44
    
    var body: some View {
        let maxVal = data.map(\.amount).max() ?? 1
        HStack(spacing: 3) {
            ForEach(Array(data.enumerated()), id: \.offset) { i, d in
                VStack(spacing: 3) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(d.amount > 0
                              ? LinearGradient(colors: [Theme.gold, Theme.gold.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                              : LinearGradient(colors: [Theme.faint.opacity(0.2), Theme.faint.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                        .frame(height: maxVal > 0 ? max(2, CGFloat(d.amount / maxVal) * (height - 14)) : 2)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.05), value: d.amount)
                    Text(d.label)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.faint)
                }
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

// ─── Stat Tile ──────────────────────────────────────
struct StatTile: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            SectionLabel(text: label)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// ─── Gold FAB ───────────────────────────────────────
struct GoldFAB: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.bg)
                .frame(width: 50, height: 50)
                .background(Theme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Theme.gold.opacity(0.4), radius: 12, y: 4)
        }
    }
}

// ─── Gold Button Style ──────────────────────────────
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .tracking(0.3)
            .foregroundColor(Theme.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LinearGradient(colors: [Theme.gold, Color(hex: "a08040")], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// ─── Ghost Button Style ─────────────────────────────
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Theme.dim)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.cardBorder, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

// ─── Animated Number ────────────────────────────────
struct AnimatedMoney: View {
    let amount: Double
    let color: Color
    var size: CGFloat = 38
    
    var body: some View {
        Text(amount.money)
            .font(.system(size: size, weight: .bold, design: .serif))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}
