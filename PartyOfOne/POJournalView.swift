import SwiftUI

struct POJournalView: View {
    @EnvironmentObject var store: POStore

    @State private var query: String = ""
    @State private var moodFilter: String = ""
    @State private var settingFilter: String = ""
    @State private var minScore: Int = 1
    @State private var focusedField: Int?
    @State private var filtersOpen = false

    var body: some View {
        let panelWidth = POScreen.width - 40

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                POScreenHeader(title: "Journal", subtitle: subtitle) {
                    // With nothing filed there is nothing to filter and the panel is
                    // never rendered, so the button must not be offered either.
                    if !store.entries.isEmpty {
                        POGlyphButton(glyph: filtersOpen ? "chevron-down" : "sliders",
                                      size: 20,
                                      color: hasFilters ? POTheme.terracotta : POTheme.plum) {
                            withAnimation(.easeOut(duration: 0.2)) { filtersOpen.toggle() }
                        }
                    }
                }

                if store.entries.isEmpty {
                    POEmptyState(glyph: "book",
                                 title: "Nothing filed yet",
                                 message: "Every outing you mark as done lands here with its four scores, its mood word and whatever you wrote about it. The first entry is the hard one.")
                        .padding(.top, 16)
                } else {
                    HStack(spacing: 8) {
                        POGlyph(name: "search", size: 16, color: POTheme.inkSoft, lineWidth: 1.7)
                        POTextField(placeholder: "Search what you wrote",
                                    text: $query,
                                    fieldID: 1,
                                    focused: $focusedField)
                        if !query.isEmpty {
                            POGlyphButton(glyph: "close", size: 14, color: POTheme.inkSoft) {
                                query = ""
                                focusedField = nil
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    if filtersOpen {
                        POCard(padding: 14) {
                            VStack(alignment: .leading, spacing: 14) {
                                filterSection(title: "Mood",
                                              items: moodItems(panelWidth),
                                              selected: moodFilter) { value in
                                    moodFilter = (moodFilter == value) ? "" : value
                                }
                                filterSection(title: "Setting",
                                              items: settingItems(panelWidth),
                                              selected: settingFilter) { value in
                                    settingFilter = (settingFilter == value) ? "" : value
                                }
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("MINIMUM RECHARGE")
                                        .font(POFont.semibold(10))
                                        .tracking(1.1)
                                        .foregroundColor(POTheme.inkSoft)
                                    HStack(spacing: 6) {
                                        ForEach(1...5, id: \.self) { v in
                                            POFilterPill(label: v == 1 ? "Any" : "\(v)+",
                                                         selected: minScore == v,
                                                         color: POTheme.teal) {
                                                minScore = v
                                            }
                                        }
                                        Spacer(minLength: 0)
                                    }
                                }
                                if hasFilters {
                                    POSecondaryButton(title: "Clear journal filters",
                                                      glyph: "close",
                                                      color: POTheme.terracotta) {
                                        moodFilter = ""
                                        settingFilter = ""
                                        minScore = 1
                                        query = ""
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                    }

                    if filtered.isEmpty {
                        POCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No entries match")
                                    .font(POFont.title(17))
                                    .foregroundColor(POTheme.plumDeep)
                                Text(noMatchMessage)
                                    .font(POFont.body(13))
                                    .foregroundColor(POTheme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ForEach(groupedKeys, id: \.self) { key in
                            POSectionTitle(text: monthLabel(key),
                                           accessory: "\(grouped[key]?.count ?? 0)")
                            VStack(spacing: 10) {
                                ForEach(grouped[key] ?? []) { entry in
                                    NavigationLink(destination: POEntryDetailView(entryID: entry.id)) {
                                        POJournalCard(entry: entry, currency: store.currencySymbol)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 14)
                        }
                    }
                }

                Color.clear.frame(height: 30)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: Filtering

    private var hasFilters: Bool {
        !moodFilter.isEmpty || !settingFilter.isEmpty || minScore > 1 || !query.isEmpty
    }

    private var filtered: [POEntry] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        return store.sortedEntries.filter { entry in
            if entry.recharge < minScore { return false }
            if !moodFilter.isEmpty && entry.mood != moodFilter { return false }
            if !settingFilter.isEmpty {
                guard let idea = POContent.idea(entry.ideaID),
                      idea.setting.rawValue == settingFilter else { return false }
            }
            if !needle.isEmpty {
                let title = POContent.idea(entry.ideaID)?.title.lowercased() ?? ""
                if !entry.reflection.lowercased().contains(needle)
                    && !title.contains(needle)
                    && !entry.mood.lowercased().contains(needle) {
                    return false
                }
            }
            return true
        }
    }

    private var grouped: [Int: [POEntry]] {
        Dictionary(grouping: filtered) { POClock.year(of: $0.dayKey) * 100 + POClock.month(of: $0.dayKey) }
    }

    private var groupedKeys: [Int] {
        grouped.keys.sorted(by: >)
    }

    private func monthLabel(_ key: Int) -> String {
        let dayKey = (key / 100) * 10000 + (key % 100) * 100 + 1
        return POClock.monthFormatter.string(from: POClock.date(from: dayKey))
    }

    private var subtitle: String {
        if store.entries.isEmpty { return "No outings filed yet." }
        let mean = POInsightEngine.meanRecharge(entries: store.entries)
        return "\(store.entries.count) filed · mean Recharge \(POFormat.score(mean))"
    }

    private var noMatchMessage: String {
        if !query.isEmpty {
            return "Nothing you have written mentions “\(query)”. Try a shorter word, or clear the search."
        }
        if !moodFilter.isEmpty {
            return "You have not filed anything as \(moodFilter) at that Recharge level yet."
        }
        return "Loosen one of the journal filters and they will come back."
    }

    // MARK: Filter chips

    private struct FilterItem: Identifiable {
        let id: String
        let label: String
        let color: Color
        let glyph: String?
    }

    private func moodItems(_ width: CGFloat) -> [FilterItem] {
        POInsightEngine.moodCounts(entries: store.entries).map {
            FilterItem(id: $0.mood, label: "\($0.mood) \($0.count)", color: POTheme.plum, glyph: nil)
        }
    }

    private func settingItems(_ width: CGFloat) -> [FilterItem] {
        let used = Set(store.entries.compactMap { POContent.idea($0.ideaID)?.setting })
        return POSetting.allCases.filter { used.contains($0) }.map {
            FilterItem(id: $0.rawValue,
                       label: $0.label,
                       color: POTheme.settingColor($0),
                       glyph: POGlyphDrawing.settingGlyph($0))
        }
    }

    private func filterSection(title: String,
                               items: [FilterItem],
                               selected: String,
                               onTap: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(POFont.semibold(10))
                .tracking(1.1)
                .foregroundColor(POTheme.inkSoft)
            if items.isEmpty {
                Text("Nothing recorded on this axis yet.")
                    .font(POFont.body(12))
                    .foregroundColor(POTheme.inkFaint)
            } else {
                POWrapRow(items: items,
                          width: POScreen.width - 68,
                          spacing: 6,
                          estimatedItemWidth: { POText.pillWidth($0.label, hasGlyph: $0.glyph != nil) }) { item in
                    POFilterPill(label: item.label,
                                 selected: selected == item.id,
                                 color: item.color,
                                 glyph: item.glyph) {
                        onTap(item.id)
                    }
                }
            }
        }
    }
}

// MARK: - Journal card

struct POJournalCard: View {
    let entry: POEntry
    let currency: String

    var body: some View {
        let idea = POContent.idea(entry.ideaID)
        return HStack(alignment: .top, spacing: 12) {
            PORadar(recharge: entry.recharge, novelty: entry.novelty,
                    comfort: entry.comfort, worth: entry.worth, side: 62)
            VStack(alignment: .leading, spacing: 5) {
                Text(idea?.title ?? "An outing")
                    .font(POFont.title(15.5))
                    .foregroundColor(POTheme.plumDeep)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(POClock.mediumString(entry.dayKey))
                        .font(POFont.mono(11))
                        .foregroundColor(POTheme.inkSoft)
                    if !entry.mood.isEmpty {
                        POChip(text: entry.mood, color: POTheme.plum, compact: true)
                    }
                    if entry.spent > 0 {
                        POChip(text: POFormat.money(entry.spent, symbol: currency),
                               color: POTheme.gold, compact: true)
                    }
                }
                if !entry.reflection.isEmpty {
                    Text(entry.reflection)
                        .font(POFont.body(12.5))
                        .foregroundColor(POTheme.ink.opacity(0.8))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            POGlyph(name: "chevron", size: 13, color: POTheme.inkFaint, lineWidth: 1.8)
                .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(POTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(POTheme.hairline, lineWidth: 1))
                .shadow(color: POTheme.shadow, radius: 6, x: 0, y: 3)
        )
    }
}
