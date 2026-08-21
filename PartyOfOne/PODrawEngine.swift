import Foundation

/// Which filter is doing the damage when nothing matches.
struct PONarrowFilter {
    let axisName: String
    let survivors: Int
}

enum PODrawEngine {

    // MARK: Matching

    static func matches(_ idea: POIdea, filters: POFilters, monthNow: Int) -> Bool {
        if !filters.budgets.isEmpty && !filters.budgets.contains(idea.budget.rawValue) { return false }
        if !filters.durations.isEmpty && !filters.durations.contains(idea.duration.rawValue) { return false }
        if !filters.energies.isEmpty && !filters.energies.contains(idea.energy.rawValue) { return false }
        if !filters.settings.isEmpty && !filters.settings.contains(idea.setting.rawValue) { return false }
        if !filters.exposures.isEmpty && !filters.exposures.contains(idea.exposure.rawValue) { return false }
        if !filters.weatherToday.isEmpty {
            // The weather toggles describe today. An idea qualifies if its requirement
            // is satisfied by one of the conditions the user ticked, and indoor-safe
            // ideas always qualify.
            if idea.weather != .indoorSafe && !filters.weatherToday.contains(idea.weather.rawValue) {
                return false
            }
        }
        if filters.seasonAware {
            if idea.season != .any && !idea.season.months.contains(monthNow) { return false }
        }
        return true
    }

    static func eligible(all: [POIdea], filters: POFilters, excluded: Set<String>, monthNow: Int) -> [POIdea] {
        all.filter { !excluded.contains($0.id) && matches($0, filters: filters, monthNow: monthNow) }
    }

    /// Which single axis, if relaxed, would open the pool up the most.
    /// Used to write an honest empty state instead of "no results".
    static func narrowest(all: [POIdea], filters: POFilters, excluded: Set<String>, monthNow: Int) -> PONarrowFilter? {
        var best: PONarrowFilter?
        func consider(_ name: String, _ relaxed: POFilters) {
            let count = eligible(all: all, filters: relaxed, excluded: excluded, monthNow: monthNow).count
            if count > 0 {
                if best == nil || count > (best?.survivors ?? 0) {
                    best = PONarrowFilter(axisName: name, survivors: count)
                }
            }
        }
        if !filters.budgets.isEmpty { var f = filters; f.budgets = []; consider("Budget", f) }
        if !filters.durations.isEmpty { var f = filters; f.durations = []; consider("Duration", f) }
        if !filters.energies.isEmpty { var f = filters; f.energies = []; consider("Energy", f) }
        if !filters.settings.isEmpty { var f = filters; f.settings = []; consider("Setting", f) }
        if !filters.exposures.isEmpty { var f = filters; f.exposures = []; consider("Company", f) }
        if !filters.weatherToday.isEmpty { var f = filters; f.weatherToday = []; consider("Weather today", f) }
        if filters.seasonAware { var f = filters; f.seasonAware = false; consider("Season fit", f) }
        return best
    }

    // MARK: Weighted draw

    /// Weight for an idea. Never zero, so nothing is ever hard-excluded by
    /// history alone — recent repeats simply sink.
    static func weight(for idea: POIdea,
                       lastDone: [String: Int],
                       plannedIDs: Set<String>,
                       deprioritiseRecent: Bool,
                       todayKey: Int) -> Double {
        var w = 1.0
        if plannedIDs.contains(idea.id) { w *= 0.15 }
        if deprioritiseRecent, let done = lastDone[idea.id] {
            let days = POClock.daysBetween(done, todayKey)
            if days >= 0 && days < 60 {
                // 0.12 at zero days, rising back towards 1.0 at sixty.
                let t = POMath.clamp(Double(days) / 60.0, 0, 1)
                w *= 0.12 + 0.88 * t
            } else {
                w *= 0.7 // done before, just a while ago
            }
        }
        return max(0.02, w)
    }

    /// Deal up to three, weighted, without repeats inside the deal.
    static func deal(from pool: [POIdea],
                     excludingRecentlyShown shown: Set<String>,
                     lastDone: [String: Int],
                     plannedIDs: Set<String>,
                     deprioritiseRecent: Bool,
                     todayKey: Int,
                     count: Int = 3) -> [POIdea] {
        guard !pool.isEmpty else { return [] }

        // Prefer cards the user has not just seen, but fall back if that empties the pool.
        var candidates = pool.filter { !shown.contains($0.id) }
        if candidates.count < count { candidates = pool }

        var chosen: [POIdea] = []
        var remaining = candidates
        let target = min(count, remaining.count)

        while chosen.count < target && !remaining.isEmpty {
            let weights = remaining.map {
                weight(for: $0,
                       lastDone: lastDone,
                       plannedIDs: plannedIDs,
                       deprioritiseRecent: deprioritiseRecent,
                       todayKey: todayKey)
            }
            let total = weights.reduce(0, +)
            guard total > 0 else {
                if let any = remaining.first {
                    chosen.append(any)
                    remaining.removeFirst()
                }
                continue
            }
            var roll = Double.random(in: 0..<total)
            var pickedIndex = remaining.count - 1
            for (i, w) in weights.enumerated() {
                if roll < w { pickedIndex = i; break }
                roll -= w
            }
            chosen.append(remaining[pickedIndex])
            remaining.remove(at: pickedIndex)
        }
        return chosen
    }

    /// A filter set that targets exactly one tag value — used by the blind-spot
    /// shortcut on the You tab.
    static func filtersTargeting(axis: POInsightAxis, value: String) -> POFilters {
        var f = POFilters()
        switch axis {
        case .budget: f.budgets = [value]
        case .duration: f.durations = [value]
        case .energy: f.energies = [value]
        case .setting: f.settings = [value]
        case .exposure: f.exposures = [value]
        }
        return f
    }
}
