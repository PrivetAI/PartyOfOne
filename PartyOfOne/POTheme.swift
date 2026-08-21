import SwiftUI

/// The dusk palette. Every colour is fixed — the device light/dark setting must
/// never change a single pixel of this app.
enum POTheme {
    static let paper = Color(red: 0.976, green: 0.961, blue: 0.937)      // soft off-white
    static let paperDeep = Color(red: 0.949, green: 0.925, blue: 0.890)  // recessed panels
    static let card = Color(red: 1.0, green: 0.996, blue: 0.988)

    static let plum = Color(red: 0.373, green: 0.192, blue: 0.376)
    static let plumDeep = Color(red: 0.239, green: 0.114, blue: 0.259)
    static let plumSoft = Color(red: 0.643, green: 0.478, blue: 0.639)

    static let terracotta = Color(red: 0.808, green: 0.427, blue: 0.298)
    static let terracottaSoft = Color(red: 0.933, green: 0.741, blue: 0.663)

    static let gold = Color(red: 0.808, green: 0.647, blue: 0.298)
    static let goldSoft = Color(red: 0.945, green: 0.878, blue: 0.741)

    static let teal = Color(red: 0.114, green: 0.353, blue: 0.365)
    static let tealSoft = Color(red: 0.639, green: 0.769, blue: 0.760)

    static let ink = Color(red: 0.157, green: 0.125, blue: 0.153)
    static let inkSoft = Color(red: 0.412, green: 0.376, blue: 0.400)
    static let inkFaint = Color(red: 0.647, green: 0.616, blue: 0.635)
    static let hairline = Color(red: 0.867, green: 0.839, blue: 0.804)

    static let shadow = Color(red: 0.239, green: 0.114, blue: 0.259).opacity(0.10)

    /// Accent colour per setting axis — used for chips, bars and collection art.
    static func settingColor(_ s: POSetting) -> Color {
        switch s {
        case .home: return plum
        case .outdoors: return teal
        case .city: return plumDeep
        case .culture: return terracotta
        case .water: return Color(red: 0.243, green: 0.478, blue: 0.541)
        case .food: return Color(red: 0.729, green: 0.396, blue: 0.376)
        case .making: return gold
        case .moving: return Color(red: 0.478, green: 0.541, blue: 0.318)
        }
    }

    static func budgetColor(_ b: POBudget) -> Color {
        switch b {
        case .free: return teal
        case .low: return Color(red: 0.400, green: 0.545, blue: 0.451)
        case .moderate: return gold
        case .splurge: return terracotta
        }
    }

    static func energyColor(_ e: POEnergy) -> Color {
        switch e {
        case .restful: return Color(red: 0.478, green: 0.463, blue: 0.616)
        case .gentle: return tealSoft
        case .active: return gold
        case .adventurous: return terracotta
        }
    }

    static func exposureColor(_ e: POExposure) -> Color {
        switch e {
        case .solitary: return plum
        case .strangers: return Color(red: 0.302, green: 0.478, blue: 0.514)
        case .talking: return terracotta
        }
    }

    /// Score 1...5 to a colour ramp (teal → gold → terracotta on the low end).
    static func scoreColor(_ v: Double) -> Color {
        let t = POMath.clamp(v, 1, 5)
        if t < 3 {
            return Color(red: 0.808 - (t - 1) * 0.0, green: 0.427 + (t - 1) * 0.11, blue: 0.298)
        }
        let k = (t - 3) / 2
        return Color(red: 0.808 - k * 0.694, green: 0.647 - k * 0.294, blue: 0.298 + k * 0.067)
    }
}

// MARK: - Typography

enum POFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .serif) }
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .default) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .default) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .default) }
    static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}

// MARK: - Screen metrics

enum POScreen {
    /// Genuinely usable width: the screen minus the window's horizontal safe-area
    /// insets. In landscape those are 44–59 pt per side on a notched iPhone, and a
    /// fixed-width child sized off the raw screen width runs off the right edge.
    static var width: CGFloat { max(200, UIScreen.main.bounds.width - POSafeArea.horizontal) }
    static var height: CGFloat { UIScreen.main.bounds.height }
    /// True on iPhone SE-class widths, where fixed hero layouts collapse.
    static var isCompact: Bool { UIScreen.main.bounds.width <= 380 || UIScreen.main.bounds.height <= 700 }
}

// MARK: - Text measurement
//
// POWrapRow has to know how wide an item will be *before* it lays it out, and a
// characters-times-a-constant guess under-measures wide glyphs ("Outdoors" came
// out as "Outd…"). Measure the real string instead.
enum POText {
    static func width(_ text: String, size: CGFloat, weight: UIFont.Weight = .semibold) -> CGFloat {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let measured = (text as NSString).size(withAttributes: [.font: font]).width
        return measured.isFinite ? ceil(measured) : CGFloat(text.count) * size * 0.7
    }

    /// Width of a `POFilterPill`: 12 pt padding each side, plus a 12 pt glyph and
    /// its 5 pt spacing when there is one. Two points of slack for the stroke.
    static func pillWidth(_ label: String, hasGlyph: Bool) -> CGFloat {
        width(label, size: 12) + 24 + (hasGlyph ? 17 : 0) + 2
    }

    /// Width of a `POChip`.
    static func chipWidth(_ text: String, hasGlyph: Bool, compact: Bool) -> CGFloat {
        let font: CGFloat = compact ? 10 : 11
        let pad: CGFloat = compact ? 14 : 18
        let glyph: CGFloat = hasGlyph ? (compact ? 14 : 16) : 0
        return width(text, size: font) + pad + glyph + 2
    }
}

// MARK: - Number formatting

enum POFormat {
    static let moneyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()

    static let scoreFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    /// Symbols that trail the amount in their own locales — "25 kr", not "kr25".
    static let suffixSymbols: Set<String> = ["kr", "zł"]

    static func money(_ value: Double, symbol: String) -> String {
        guard value.isFinite else { return "—" }
        let rounded = (value * 100).rounded() / 100
        let text = moneyFormatter.string(from: NSNumber(value: rounded)) ?? "0"
        if suffixSymbols.contains(symbol) { return text + " " + symbol }
        return symbol + text
    }

    static func score(_ value: Double?) -> String {
        guard let v = value, v.isFinite else { return "—" }
        return scoreFormatter.string(from: NSNumber(value: v)) ?? "—"
    }

    static func whole(_ value: Int) -> String {
        moneyFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
