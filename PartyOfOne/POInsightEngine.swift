import Foundation

enum POInsightAxis: String, CaseIterable, Identifiable {
    case budget, duration, energy, setting, exposure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .budget: return "Budget"
        case .duration: return "Duration"
        case .energy: return "Energy"
        case .setting: return "Setting"
        case .exposure: return "Company"
        }
    }
    var allValues: [String] {
        switch self {
        case .budget: return POBudget.allCases.map { $0.rawValue }
        case .duration: return PODuration.allCases.map { $0.rawValue }
        case .energy: return POEnergy.allCases.map { $0.rawValue }
        case .setting: return POSetting.allCases.map { $0.rawValue }
        case .exposure: return POExposure.allCases.map { $0.rawValue }
        }
    }
    func label(_ raw: String) -> String {
        switch self {
        case .budget: return POBudget(rawValue: raw)?.label ?? raw
        case .duration: return PODuration(rawValue: raw)?.label ?? raw
        case .energy: return POEnergy(rawValue: raw)?.label ?? raw
        case .setting: return POSetting(rawValue: raw)?.label ?? raw
        case .exposure: return POExposure(rawValue: raw)?.label ?? raw
        }
    }
    func value(of idea: POIdea) -> String {
        switch self {
        case .budget: return idea.budget.rawValue
        case .duration: return idea.duration.rawValue
        case .energy: return idea.energy.rawValue
        case .setting: return idea.setting.rawValue
        case .exposure: return idea.exposure.rawValue
        }
    }
}

/// One row of the profile: a tag value, its mean Recharge score and how many
/// outings that average is standing on.
struct POTagStat: Identifiable {
    let axis: POInsightAxis
    let value: String
    let label: String
    let meanRecharge: Double?
    let meanWorth: Double?
    let samples: Int

    var id: String { axis.rawValue + "." + value }
    /// Below this the app says "still learning" rather than pretending to know.
    var isConfident: Bool { samples >= 3 }
}

struct POScatterPoint: Identifiable {
    let id: String
    let spent: Double
    let recharge: Double
    let title: String
    let dayKey: Int
}

struct POMonthCell: Identifiable {
    let id: String
    let dayKey: Int
    let day: Int
    let count: Int
    let meanRecharge: Double?
}

struct POBestDay {
    let phrase: String
    let sampleCount: Int
    let confident: Bool
}

enum POInsightEngine {

    // MARK: Tag statistics

    static func tagStats(entries: [POEntry], axis: POInsightAxis) -> [POTagStat] {
        var recharge: [String: [Double]] = [:]
        var worth: [String: [Double]] = [:]
        for e in entries {
            guard let idea = POContent.idea(e.ideaID) else { continue }
            let v = axis.value(of: idea)
            recharge[v, default: []].append(Double(e.recharge))
            worth[v, default: []].append(Double(e.worth))
        }
        return axis.allValues.map { v in
            let r = recharge[v] ?? []
            let w = worth[v] ?? []
            return POTagStat(axis: axis,
                             value: v,
                             label: axis.label(v),
                             meanRecharge: POMath.mean(r),
                             meanWorth: POMath.mean(w),
                             samples: r.count)
        }
    }

    /// Ranked, confident rows first, then the thin ones, then the untried.
    static func rankedTagStats(entries: [POEntry], axis: POInsightAxis) -> [POTagStat] {
        tagStats(entries: entries, axis: axis).sorted { a, b in
            if a.isConfident != b.isConfident { return a.isConfident }
            let am = a.meanRecharge ?? -1
            let bm = b.meanRecharge ?? -1
            if am != bm { return am > bm }
            if a.samples != b.samples { return a.samples > b.samples }
            return a.label < b.label
        }
    }

    // MARK: Best kind of solo day

    static func bestDay(entries: [POEntry]) -> POBestDay {
        guard !entries.isEmpty else {
            return POBestDay(phrase: "", sampleCount: 0, confident: false)
        }
        var parts: [String] = []
        var thinnest = Int.max
        for axis in [POInsightAxis.energy, .setting, .duration, .budget, .exposure] {
            let stats = tagStats(entries: entries, axis: axis)
                .filter { $0.samples > 0 }
                .sorted { (a, b) -> Bool in
                    let am = a.meanRecharge ?? 0
                    let bm = b.meanRecharge ?? 0
                    if am != bm { return am > bm }
                    return a.samples > b.samples
                }
            guard let top = stats.first else { continue }
            thinnest = min(thinnest, top.samples)
            parts.append(phrase(for: axis, value: top.value, label: top.label))
        }
        guard !parts.isEmpty else {
            return POBestDay(phrase: "", sampleCount: 0, confident: false)
        }
        if thinnest == Int.max { thinnest = 0 }
        return POBestDay(phrase: parts.joined(separator: ", "),
                         sampleCount: entries.count,
                         confident: entries.count >= 8 && thinnest >= 2)
    }

    private static func phrase(for axis: POInsightAxis, value: String, label: String) -> String {
        switch axis {
        case .budget:
            switch POBudget(rawValue: value) ?? .free {
            case .free: return "costing nothing"
            case .low: return "on a small budget"
            case .moderate: return "worth paying for"
            case .splurge: return "properly extravagant"
            }
        case .duration:
            switch PODuration(rawValue: value) ?? .couple {
            case .half: return "half an hour long"
            case .couple: return "an hour or two long"
            case .halfDay: return "half a day long"
            case .fullDay: return "all day"
            }
        case .energy: return label.lowercased()
        case .setting:
            switch POSetting(rawValue: value) ?? .home {
            case .home: return "at home"
            case .outdoors: return "outdoors"
            case .city: return "out in the city"
            case .culture: return "somewhere cultural"
            case .water: return "near water"
            case .food: return "built around food"
            case .making: return "making something"
            case .moving: return "physically moving"
            }
        case .exposure:
            switch POExposure(rawValue: value) ?? .solitary {
            case .solitary: return "completely private"
            case .strangers: return "among strangers"
            case .talking: return "with a bit of conversation"
            }
        }
    }

    // MARK: Recharge vs cost

    static func scatter(entries: [POEntry]) -> [POScatterPoint] {
        entries.compactMap { e in
            guard let idea = POContent.idea(e.ideaID) else { return nil }
            guard e.spent.isFinite, e.spent >= 0 else { return nil }
            return POScatterPoint(id: e.id,
                                  spent: e.spent,
                                  recharge: Double(e.recharge),
                                  title: idea.title,
                                  dayKey: e.dayKey)
        }
    }

    /// Mean Recharge for the cheap half vs the expensive half, when there is
    /// enough spread to say anything at all.
    static func costVerdict(entries: [POEntry]) -> String? {
        let points = scatter(entries: entries)
        guard points.count >= 6 else { return nil }
        let sorted = points.sorted { $0.spent < $1.spent }
        // Six free outings are six identical amounts: the halves cost the same and
        // there is no cheap-versus-dear conclusion to draw from them.
        guard let cheapest = sorted.first?.spent,
              let dearest = sorted.last?.spent,
              dearest - cheapest > 0.01 else { return nil }
        let half = sorted.count / 2
        let cheap = Array(sorted.prefix(half))
        let dear = Array(sorted.suffix(sorted.count - half))
        guard let cheapMean = POMath.mean(cheap.map { $0.recharge }),
              let dearMean = POMath.mean(dear.map { $0.recharge }) else { return nil }
        let diff = cheapMean - dearMean
        if abs(diff) < 0.25 {
            return "Spending more does not move your Recharge score either way. That is useful to know."
        }
        if diff > 0 {
            return "Your cheaper half averages " + POFormat.score(cheapMean)
                + " on Recharge; the expensive half averages " + POFormat.score(dearMean)
                + ". The money is not what is doing the work."
        }
        return "Your more expensive outings average " + POFormat.score(dearMean)
            + " on Recharge against " + POFormat.score(cheapMean)
            + " for the cheaper half. Yours is a taste worth budgeting for."
    }

    // MARK: Streak

    /// Consecutive weeks, counting back from this week, with at least one outing.
    static func weekStreak(entries: [POEntry], weekStartsMonday: Bool) -> Int {
        guard !entries.isEmpty else { return 0 }
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.firstWeekday = weekStartsMonday ? 2 : 1
        let weeksWithOutings: Set<Int> = Set(entries.compactMap { e in
            weekIndex(for: e.dayKey, calendar: cal)
        })
        guard let thisWeek = weekIndex(for: POClock.todayKey, calendar: cal) else { return 0 }
        var streak = 0
        var cursor = thisWeek
        // A week with nothing in it yet does not break a streak that ended last week.
        if !weeksWithOutings.contains(cursor) { cursor -= 1 }
        while weeksWithOutings.contains(cursor) {
            streak += 1
            cursor -= 1
        }
        return streak
    }

    private static func weekIndex(for dayKey: Int, calendar: Calendar) -> Int? {
        let date = POClock.date(from: dayKey)
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return nil }
        let days = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: start).day ?? 0
        return days / 7
    }

    // MARK: Totals

    static func totalSpent(entries: [POEntry]) -> Double {
        entries.reduce(0) { $0 + (($1.spent.isFinite && $1.spent > 0) ? $1.spent : 0) }
    }

    static func monthsActive(entries: [POEntry]) -> Int {
        Set(entries.map { POClock.year(of: $0.dayKey) * 100 + POClock.month(of: $0.dayKey) }).count
    }

    static func meanRecharge(entries: [POEntry]) -> Double? {
        POMath.mean(entries.map { Double($0.recharge) })
    }

    // MARK: Month grid

    static func monthCells(entries: [POEntry], year: Int, month: Int) -> [POMonthCell] {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }
        var byDay: [Int: [POEntry]] = [:]
        for e in entries where POClock.year(of: e.dayKey) == year && POClock.month(of: e.dayKey) == month {
            byDay[e.dayKey % 100, default: []].append(e)
        }
        return range.map { day in
            let list = byDay[day] ?? []
            return POMonthCell(id: "\(year)-\(month)-\(day)",
                               dayKey: year * 10000 + month * 100 + day,
                               day: day,
                               count: list.count,
                               meanRecharge: POMath.mean(list.map { Double($0.recharge) }))
        }
    }

    /// Weekday index (0-based from the configured week start) of the 1st of the month.
    static func leadingBlanks(year: Int, month: Int, weekStartsMonday: Bool) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.firstWeekday = weekStartsMonday ? 2 : 1
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let first = cal.date(from: comps) else { return 0 }
        let weekday = cal.component(.weekday, from: first) // 1 = Sunday
        let shift = weekStartsMonday ? 2 : 1
        return ((weekday - shift) + 7) % 7
    }

    // MARK: Blind spots

    struct POBlindSpot: Identifiable {
        let axis: POInsightAxis
        let value: String
        let label: String
        let availableIdeas: Int
        var id: String { axis.rawValue + "." + value }
    }

    static func blindSpots(entries: [POEntry], excluded: Set<String>) -> [POBlindSpot] {
        var result: [POBlindSpot] = []
        for axis in POInsightAxis.allCases {
            let stats = tagStats(entries: entries, axis: axis)
            for s in stats where s.samples == 0 {
                let pool = POContent.ideas.filter {
                    !excluded.contains($0.id) && axis.value(of: $0) == s.value
                }
                if !pool.isEmpty {
                    result.append(POBlindSpot(axis: axis,
                                              value: s.value,
                                              label: s.label,
                                              availableIdeas: pool.count))
                }
            }
        }
        return result
    }

    // MARK: Journal helpers

    static func moodCounts(entries: [POEntry]) -> [(mood: String, count: Int)] {
        var counts: [String: Int] = [:]
        for e in entries where !e.mood.isEmpty {
            counts[e.mood, default: 0] += 1
        }
        return counts.map { (mood: $0.key, count: $0.value) }
            .sorted { a, b in
                if a.count != b.count { return a.count > b.count }
                return a.mood < b.mood
            }
    }
}
