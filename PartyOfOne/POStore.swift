import Foundation
import SwiftUI

/// Everything the user has done, wants to do, or refuses to do.
/// Persisted as JSON blobs in UserDefaults — local only, no network, no cloud.
final class POStore: ObservableObject {

    // MARK: Persisted state

    @Published var plans: [POPlan] = [] { didSet { persistPlans() } }
    @Published var entries: [POEntry] = [] { didSet { persistEntries() } }
    @Published var notForMe: Set<String> = [] { didSet { persistNotForMe() } }
    @Published var filters = POFilters() { didSet { persistFilters() } }

    @Published var currencySymbol: String = "$" { didSet { defaults.set(currencySymbol, forKey: Keys.currency) } }
    @Published var weekStartsMonday: Bool = true { didSet { defaults.set(weekStartsMonday, forKey: Keys.weekStart) } }
    @Published var hasOnboarded: Bool = false { didSet { defaults.set(hasOnboarded, forKey: Keys.onboarded) } }
    @Published var confettiOnDone: Bool = true { didSet { defaults.set(confettiOnDone, forKey: Keys.confetti) } }
    @Published var deprioritiseRecent: Bool = true { didSet { defaults.set(deprioritiseRecent, forKey: Keys.deprioritise) } }

    private let defaults = UserDefaults.standard
    private var loading = true

    private enum Keys {
        static let plans = "po_plans_v1"
        static let entries = "po_entries_v1"
        static let notForMe = "po_notforme_v1"
        static let filters = "po_filters_v1"
        static let currency = "po_currency_v1"
        static let weekStart = "po_weekstart_v1"
        static let onboarded = "po_onboarded_v1"
        static let confetti = "po_confetti_v1"
        static let deprioritise = "po_deprioritise_v1"
    }

    init() {
        load()
        loading = false
    }

    // MARK: Load / persist

    private func load() {
        let dec = JSONDecoder()
        if let data = defaults.data(forKey: Keys.plans),
           let decoded = try? dec.decode([POPlan].self, from: data) {
            plans = decoded.filter { POContent.idea($0.ideaID) != nil }
        }
        if let data = defaults.data(forKey: Keys.entries),
           let decoded = try? dec.decode([POEntry].self, from: data) {
            // Kept unconditionally. An entry whose idea id no longer resolves still
            // holds the user's own scores and notes, and the journal renders it as
            // "An outing"; pruning here would re-persist the loss on the next edit.
            entries = decoded
        }
        if let data = defaults.data(forKey: Keys.notForMe),
           let decoded = try? dec.decode([String].self, from: data) {
            notForMe = Set(decoded)
        }
        if let data = defaults.data(forKey: Keys.filters),
           let decoded = try? dec.decode(POFilters.self, from: data) {
            filters = decoded
        }
        currencySymbol = defaults.string(forKey: Keys.currency) ?? "$"
        weekStartsMonday = defaults.object(forKey: Keys.weekStart) as? Bool ?? true
        hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        confettiOnDone = defaults.object(forKey: Keys.confetti) as? Bool ?? true
        deprioritiseRecent = defaults.object(forKey: Keys.deprioritise) as? Bool ?? true
    }

    private func persistPlans() {
        guard !loading else { return }
        if let data = try? JSONEncoder().encode(plans) { defaults.set(data, forKey: Keys.plans) }
    }

    private func persistEntries() {
        guard !loading else { return }
        if let data = try? JSONEncoder().encode(entries) { defaults.set(data, forKey: Keys.entries) }
    }

    private func persistNotForMe() {
        guard !loading else { return }
        if let data = try? JSONEncoder().encode(Array(notForMe).sorted()) {
            defaults.set(data, forKey: Keys.notForMe)
        }
    }

    private func persistFilters() {
        guard !loading else { return }
        if let data = try? JSONEncoder().encode(filters) { defaults.set(data, forKey: Keys.filters) }
    }

    // MARK: Derived collections

    var upcomingPlans: [POPlan] {
        let today = POClock.todayKey
        return plans.filter { $0.dayKey >= today }
            .sorted { lhs, rhs in
                if lhs.dayKey != rhs.dayKey { return lhs.dayKey < rhs.dayKey }
                return (lhs.minuteOfDay ?? 0) < (rhs.minuteOfDay ?? 0)
            }
    }

    var overduePlans: [POPlan] {
        let today = POClock.todayKey
        return plans.filter { $0.dayKey < today }.sorted { $0.dayKey > $1.dayKey }
    }

    var sortedEntries: [POEntry] {
        entries.sorted { lhs, rhs in
            if lhs.dayKey != rhs.dayKey { return lhs.dayKey > rhs.dayKey }
            return lhs.id > rhs.id
        }
    }

    var doneIdeaIDs: Set<String> { Set(entries.map { $0.ideaID }) }

    var plannedIdeaIDs: Set<String> { Set(plans.map { $0.ideaID }) }

    /// Most recent day key an idea was completed on, if ever.
    var lastDoneByIdea: [String: Int] {
        var map: [String: Int] = [:]
        for e in entries {
            if let existing = map[e.ideaID] {
                map[e.ideaID] = max(existing, e.dayKey)
            } else {
                map[e.ideaID] = e.dayKey
            }
        }
        return map
    }

    // MARK: Mutations

    func addPlan(ideaID: String, dayKey: Int, minuteOfDay: Int?) -> POPlan {
        let plan = POPlan(ideaID: ideaID,
                          dayKey: dayKey,
                          minuteOfDay: minuteOfDay,
                          createdDayKey: POClock.todayKey)
        plans.append(plan)
        return plan
    }

    func updatePlan(_ plan: POPlan) {
        guard let idx = plans.firstIndex(where: { $0.id == plan.id }) else { return }
        plans[idx] = plan
    }

    func removePlan(id: String) {
        plans.removeAll { $0.id == id }
    }

    func togglePrep(planID: String, index: Int) {
        guard let idx = plans.firstIndex(where: { $0.id == planID }) else { return }
        var checked = plans[idx].checkedPrep
        if let at = checked.firstIndex(of: index) {
            checked.remove(at: at)
        } else {
            checked.append(index)
        }
        plans[idx].checkedPrep = checked.sorted()
    }

    func completePlan(_ plan: POPlan, with entry: POEntry) {
        var stored = entry
        stored.ideaID = plan.ideaID
        entries.append(stored)
        plans.removeAll { $0.id == plan.id }
    }

    func addStandaloneEntry(_ entry: POEntry) {
        entries.append(entry)
    }

    func updateEntry(_ entry: POEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
    }

    func deleteEntry(id: String) {
        entries.removeAll { $0.id == id }
    }

    func excludeIdea(_ id: String) {
        notForMe.insert(id)
    }

    func restoreIdea(_ id: String) {
        notForMe.remove(id)
    }

    func resetEverything() {
        loading = true
        plans = []
        entries = []
        notForMe = []
        filters = POFilters()
        currencySymbol = "$"
        weekStartsMonday = true
        confettiOnDone = true
        deprioritiseRecent = true
        loading = false
        persistPlans()
        persistEntries()
        persistNotForMe()
        persistFilters()
        defaults.set(currencySymbol, forKey: Keys.currency)
        defaults.set(weekStartsMonday, forKey: Keys.weekStart)
        defaults.set(confettiOnDone, forKey: Keys.confetti)
        defaults.set(deprioritiseRecent, forKey: Keys.deprioritise)
    }

    // MARK: Collection progress

    func collectionProgress(_ collection: POCollection) -> (done: Int, total: Int) {
        let done = doneIdeaIDs
        let resolved = POContent.ideas(collection.ideaIDs)
        let count = resolved.filter { done.contains($0.id) }.count
        return (count, resolved.count)
    }

    func isCollectionComplete(_ collection: POCollection) -> Bool {
        let p = collectionProgress(collection)
        return p.total > 0 && p.done >= p.total
    }

    var earnedBadgeCount: Int {
        POContent.collections.filter { isCollectionComplete($0) }.count
    }
}
