import Foundation

// MARK: - Forgiving decode helpers
//
// Every saved struct decodes field-by-field with a fallback so that adding a new
// field in a future version can never wipe the user's data.
extension KeyedDecodingContainer {
    // `try?` flattens the Optional that decodeIfPresent returns, so a missing key
    // and a malformed value both land on the fallback.
    func poValue<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        if let value = try? decodeIfPresent(T.self, forKey: key) { return value }
        return fallback
    }

    func poOptional<T: Decodable>(_ key: Key, _ type: T.Type) -> T? {
        if let value = try? decodeIfPresent(T.self, forKey: key) { return value }
        return nil
    }
}

// MARK: - Tag axes

enum POBudget: String, Codable, CaseIterable, Identifiable {
    case free, low, moderate, splurge
    var id: String { rawValue }
    var label: String {
        switch self {
        case .free: return "Free"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .splurge: return "Splurge"
        }
    }
    /// One-line prose for the tag row. Not a glyph name — nothing draws from it.
    var blurb: String {
        switch self {
        case .free: return "no spend"
        case .low: return "pocket change"
        case .moderate: return "a proper outing"
        case .splurge: return "worth saving for"
        }
    }
    var rank: Int {
        switch self {
        case .free: return 0
        case .low: return 1
        case .moderate: return 2
        case .splurge: return 3
        }
    }
}

enum PODuration: String, Codable, CaseIterable, Identifiable {
    case half, couple, halfDay, fullDay
    var id: String { rawValue }
    var label: String {
        switch self {
        case .half: return "30 min"
        case .couple: return "1-2 h"
        case .halfDay: return "Half day"
        case .fullDay: return "Full day"
        }
    }
    var minutes: Int {
        switch self {
        case .half: return 30
        case .couple: return 90
        case .halfDay: return 240
        case .fullDay: return 480
        }
    }
}

enum POEnergy: String, Codable, CaseIterable, Identifiable {
    case restful, gentle, active, adventurous
    var id: String { rawValue }
    var label: String {
        switch self {
        case .restful: return "Restful"
        case .gentle: return "Gentle"
        case .active: return "Active"
        case .adventurous: return "Adventurous"
        }
    }
}

enum POSetting: String, Codable, CaseIterable, Identifiable {
    case home, outdoors, city, culture, water, food, making, moving
    var id: String { rawValue }
    var label: String {
        switch self {
        case .home: return "Home"
        case .outdoors: return "Outdoors"
        case .city: return "City"
        case .culture: return "Culture"
        case .water: return "Water"
        case .food: return "Food"
        case .making: return "Making"
        case .moving: return "Moving"
        }
    }
}

enum POSeason: String, Codable, CaseIterable, Identifiable {
    case any, spring, summer, autumn, winter
    var id: String { rawValue }
    var label: String {
        switch self {
        case .any: return "Any season"
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        }
    }
    /// Months (1-12) the season covers in the northern hemisphere.
    var months: [Int] {
        switch self {
        case .any: return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        case .spring: return [3, 4, 5]
        case .summer: return [6, 7, 8]
        case .autumn: return [9, 10, 11]
        case .winter: return [12, 1, 2]
        }
    }
}

enum POWeather: String, Codable, CaseIterable, Identifiable {
    case indoorSafe, needsDry, needsSun, needsCold
    var id: String { rawValue }
    var label: String {
        switch self {
        case .indoorSafe: return "Indoor-safe"
        case .needsDry: return "Needs dry"
        case .needsSun: return "Needs sun"
        case .needsCold: return "Needs cold"
        }
    }
}

enum POExposure: String, Codable, CaseIterable, Identifiable {
    case solitary, strangers, talking
    var id: String { rawValue }
    var label: String {
        switch self {
        case .solitary: return "Fully private"
        case .strangers: return "Among strangers"
        case .talking: return "Some talking"
        }
    }
    var longLabel: String {
        switch self {
        case .solitary: return "Fully private"
        case .strangers: return "Among strangers"
        case .talking: return "Requires talking to someone"
        }
    }
}

// MARK: - The idea

struct POIdea: Identifiable, Hashable {
    let id: String
    let title: String
    let blurb: String
    let budget: POBudget
    let duration: PODuration
    let energy: POEnergy
    let setting: POSetting
    let season: POSeason
    let weather: POWeather
    let exposure: POExposure
    let prep: [String]

    var tagLine: String {
        "\(duration.label) · \(budget.label) · \(energy.label)"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: POIdea, rhs: POIdea) -> Bool { lhs.id == rhs.id }
}

/// Compact constructor used by the library files.
func POMake(_ id: String,
            _ title: String,
            _ blurb: String,
            _ budget: POBudget,
            _ duration: PODuration,
            _ energy: POEnergy,
            _ setting: POSetting,
            _ season: POSeason,
            _ weather: POWeather,
            _ exposure: POExposure,
            _ prep: [String]) -> POIdea {
    POIdea(id: id, title: title, blurb: blurb, budget: budget, duration: duration,
           energy: energy, setting: setting, season: season, weather: weather,
           exposure: exposure, prep: prep)
}

// MARK: - Collections

struct POCollection: Identifiable, Hashable {
    let id: String
    let name: String
    let intro: String
    let badgeName: String
    let ideaIDs: [String]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: POCollection, rhs: POCollection) -> Bool { lhs.id == rhs.id }
}

// MARK: - Plans

struct POPlan: Identifiable, Codable, Equatable {
    var id: String
    var ideaID: String
    /// yyyymmdd integer day key — never compare raw Dates.
    var dayKey: Int
    /// Minutes past midnight, or nil when the user did not set a time.
    var minuteOfDay: Int?
    var checkedPrep: [Int]
    var plannedBudget: Double?
    var notes: String
    var createdDayKey: Int

    init(id: String = UUID().uuidString,
         ideaID: String,
         dayKey: Int,
         minuteOfDay: Int? = nil,
         checkedPrep: [Int] = [],
         plannedBudget: Double? = nil,
         notes: String = "",
         createdDayKey: Int) {
        self.id = id
        self.ideaID = ideaID
        self.dayKey = dayKey
        self.minuteOfDay = minuteOfDay
        self.checkedPrep = checkedPrep
        self.plannedBudget = plannedBudget
        self.notes = notes
        self.createdDayKey = createdDayKey
    }

    // Defensive decoding: every field optional so adding one never wipes saved data.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.poValue(.id, UUID().uuidString)
        ideaID = c.poValue(.ideaID, "")
        dayKey = c.poValue(.dayKey, POClock.dayKey(for: Date()))
        minuteOfDay = c.poOptional(.minuteOfDay, Int.self)
        checkedPrep = c.poValue(.checkedPrep, [Int]())
        plannedBudget = c.poOptional(.plannedBudget, Double.self)
        notes = c.poValue(.notes, "")
        createdDayKey = c.poValue(.createdDayKey, dayKey)
    }

    enum CodingKeys: String, CodingKey {
        case id, ideaID, dayKey, minuteOfDay, checkedPrep, plannedBudget, notes, createdDayKey
    }
}

// MARK: - Journal entries

struct POEntry: Identifiable, Codable, Equatable {
    var id: String
    var ideaID: String
    var dayKey: Int
    var recharge: Int      // 1...5
    var novelty: Int       // 1...5
    var comfort: Int       // 1...5
    var worth: Int         // 1...5
    var mood: String
    var promptID: Int
    var reflection: String
    var spent: Double

    init(id: String = UUID().uuidString,
         ideaID: String,
         dayKey: Int,
         recharge: Int = 3,
         novelty: Int = 3,
         comfort: Int = 3,
         worth: Int = 3,
         mood: String = "",
         promptID: Int = 0,
         reflection: String = "",
         spent: Double = 0) {
        self.id = id
        self.ideaID = ideaID
        self.dayKey = dayKey
        self.recharge = recharge
        self.novelty = novelty
        self.comfort = comfort
        self.worth = worth
        self.mood = mood
        self.promptID = promptID
        self.reflection = reflection
        self.spent = spent
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.poValue(.id, UUID().uuidString)
        ideaID = c.poValue(.ideaID, "")
        dayKey = c.poValue(.dayKey, POClock.dayKey(for: Date()))
        recharge = c.poValue(.recharge, 3)
        novelty = c.poValue(.novelty, 3)
        comfort = c.poValue(.comfort, 3)
        worth = c.poValue(.worth, 3)
        mood = c.poValue(.mood, "")
        promptID = c.poValue(.promptID, 0)
        reflection = c.poValue(.reflection, "")
        spent = c.poValue(.spent, 0)
    }

    enum CodingKeys: String, CodingKey {
        case id, ideaID, dayKey, recharge, novelty, comfort, worth, mood, promptID, reflection, spent
    }

    var averageScore: Double {
        Double(recharge + novelty + comfort + worth) / 4.0
    }
}

// MARK: - Filters

struct POFilters: Codable, Equatable {
    var budgets: Set<String>
    var durations: Set<String>
    var energies: Set<String>
    var settings: Set<String>
    var exposures: Set<String>
    var weatherToday: Set<String>
    var seasonAware: Bool

    init(budgets: Set<String> = [],
         durations: Set<String> = [],
         energies: Set<String> = [],
         settings: Set<String> = [],
         exposures: Set<String> = [],
         weatherToday: Set<String> = [],
         seasonAware: Bool = false) {
        self.budgets = budgets
        self.durations = durations
        self.energies = energies
        self.settings = settings
        self.exposures = exposures
        self.weatherToday = weatherToday
        self.seasonAware = seasonAware
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        budgets = c.poValue(.budgets, Set<String>())
        durations = c.poValue(.durations, Set<String>())
        energies = c.poValue(.energies, Set<String>())
        settings = c.poValue(.settings, Set<String>())
        exposures = c.poValue(.exposures, Set<String>())
        weatherToday = c.poValue(.weatherToday, Set<String>())
        seasonAware = c.poValue(.seasonAware, false)
    }

    enum CodingKeys: String, CodingKey {
        case budgets, durations, energies, settings, exposures, weatherToday, seasonAware
    }

    var isEmpty: Bool {
        budgets.isEmpty && durations.isEmpty && energies.isEmpty
            && settings.isEmpty && exposures.isEmpty && weatherToday.isEmpty && !seasonAware
    }

    var activeCount: Int {
        budgets.count + durations.count + energies.count
            + settings.count + exposures.count + weatherToday.count + (seasonAware ? 1 : 0)
    }
}

// MARK: - Day key helpers

enum POClock {
    static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en_US_POSIX")
        c.timeZone = TimeZone.current
        return c
    }()

    static func dayKey(for date: Date) -> Int {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2000
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return y * 10000 + m * 100 + d
    }

    static func date(from key: Int) -> Date {
        var comps = DateComponents()
        comps.year = key / 10000
        comps.month = (key / 100) % 100
        comps.day = key % 100
        comps.hour = 12
        return calendar.date(from: comps) ?? Date()
    }

    static var todayKey: Int { dayKey(for: Date()) }

    /// Whole days between two day keys (b - a). Negative when b is in the past.
    static func daysBetween(_ a: Int, _ b: Int) -> Int {
        let da = calendar.startOfDay(for: date(from: a))
        let db = calendar.startOfDay(for: date(from: b))
        let comps = calendar.dateComponents([.day], from: da, to: db)
        return comps.day ?? 0
    }

    static func month(of key: Int) -> Int { (key / 100) % 100 }
    static func year(of key: Int) -> Int { key / 10000 }

    static let longFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f
    }()

    static let mediumFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d"
        return f
    }()

    static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static func longString(_ key: Int) -> String { longFormatter.string(from: date(from: key)) }
    static func mediumString(_ key: Int) -> String { mediumFormatter.string(from: date(from: key)) }
    static func shortString(_ key: Int) -> String { shortFormatter.string(from: date(from: key)) }

    static func timeString(_ minuteOfDay: Int) -> String {
        let clamped = max(0, min(23 * 60 + 59, minuteOfDay))
        let h = clamped / 60
        let m = clamped % 60
        let suffix = h < 12 ? "AM" : "PM"
        var display = h % 12
        if display == 0 { display = 12 }
        return String(format: "%d:%02d %@", display, m, suffix)
    }

    static func seasonForMonth(_ month: Int) -> POSeason {
        switch month {
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .autumn
        default: return .winter
        }
    }
}

// MARK: - Safe math

enum POMath {
    static func safeDivide(_ a: Double, _ b: Double) -> Double? {
        guard b != 0, a.isFinite, b.isFinite else { return nil }
        let r = a / b
        return r.isFinite ? r : nil
    }

    static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return safeDivide(values.reduce(0, +), Double(values.count))
    }

    static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        if hi <= lo { return lo }
        return Swift.min(hi, Swift.max(lo, v.isFinite ? v : lo))
    }
}
