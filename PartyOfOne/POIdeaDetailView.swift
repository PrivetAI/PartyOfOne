import SwiftUI

struct POIdeaDetailView: View {
    @EnvironmentObject var store: POStore
    @Environment(\.presentationMode) private var presentationMode
    let idea: POIdea

    @State private var showPlanner = false
    @State private var confirmExclude = false
    @State private var justPlanned: Int?

    var body: some View {
        let contentWidth = POScreen.width - 40

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    POBackButton { presentationMode.wrappedValue.dismiss() }
                    Spacer(minLength: 0)
                    if store.notForMe.contains(idea.id) {
                        POChip(text: "Not for me", color: POTheme.terracotta, glyph: "close")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                POCollectionArt(seedText: idea.id,
                                accent: POTheme.settingColor(idea.setting),
                                glyph: POGlyphDrawing.settingGlyph(idea.setting),
                                width: contentWidth,
                                height: POScreen.isCompact ? 84 : 104)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                Text(idea.title)
                    .font(POFont.display(POScreen.isCompact ? 23 : 26))
                    .foregroundColor(POTheme.plumDeep)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                Text(idea.blurb)
                    .font(POFont.body(15))
                    .foregroundColor(POTheme.ink.opacity(0.88))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                if let planned = justPlanned {
                    POCard(tint: POTheme.teal.opacity(0.10)) {
                        HStack(spacing: 10) {
                            POGlyph(name: "check", size: 20, color: POTheme.teal, lineWidth: 2.2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("In your Plans")
                                    .font(POFont.semibold(14))
                                    .foregroundColor(POTheme.teal)
                                Text(POClock.longString(planned))
                                    .font(POFont.body(12))
                                    .foregroundColor(POTheme.inkSoft)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                }

                POSectionTitle(text: "The tags")
                POCard {
                    VStack(spacing: 0) {
                        tagRow("Budget", idea.budget.label + " — " + idea.budget.blurb,
                               POTheme.budgetColor(idea.budget), "coin")
                        divider
                        tagRow("How long", idea.duration.label, POTheme.plum, "clock")
                        divider
                        tagRow("Energy", idea.energy.label, POTheme.energyColor(idea.energy), "flame")
                        divider
                        tagRow("Setting", idea.setting.label, POTheme.settingColor(idea.setting),
                               POGlyphDrawing.settingGlyph(idea.setting))
                        divider
                        tagRow("Company", idea.exposure.longLabel, POTheme.exposureColor(idea.exposure),
                               POGlyphDrawing.exposureGlyph(idea.exposure))
                        divider
                        tagRow("Weather", idea.weather.label, POTheme.teal,
                               POGlyphDrawing.weatherGlyph(idea.weather))
                        divider
                        tagRow("Season", idea.season.label, POTheme.gold, "leaf")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POSectionTitle(text: "Before you go", accessory: "\(idea.prep.count) item\(idea.prep.count == 1 ? "" : "s")")
                POCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(idea.prep.enumerated()), id: \.offset) { pair in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(POTheme.plumSoft)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(pair.element)
                                    .font(POFont.body(14))
                                    .foregroundColor(POTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Text("The list becomes tickable once this is on a date.")
                            .font(POFont.body(11))
                            .foregroundColor(POTheme.inkFaint)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                if !memberCollections.isEmpty {
                    POSectionTitle(text: "Part of")
                    VStack(spacing: 8) {
                        ForEach(memberCollections) { collection in
                            HStack(spacing: 10) {
                                POBadgeView(glyph: collection.badgeName,
                                            earned: store.isCollectionComplete(collection),
                                            size: 34)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(collection.name)
                                        .font(POFont.semibold(14))
                                        .foregroundColor(POTheme.plumDeep)
                                    let progress = store.collectionProgress(collection)
                                    Text("\(progress.done) of \(progress.total) done")
                                        .font(POFont.body(11))
                                        .foregroundColor(POTheme.inkSoft)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(POTheme.card)
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(POTheme.hairline, lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }

                if !pastEntries.isEmpty {
                    POSectionTitle(text: "You have done this", accessory: "\(pastEntries.count)×")
                    VStack(spacing: 8) {
                        ForEach(pastEntries) { entry in
                            HStack(spacing: 12) {
                                PORadar(recharge: entry.recharge, novelty: entry.novelty,
                                        comfort: entry.comfort, worth: entry.worth, side: 52)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(POClock.mediumString(entry.dayKey))
                                        .font(POFont.semibold(13))
                                        .foregroundColor(POTheme.ink)
                                    Text(entry.mood.isEmpty ? "No mood recorded" : entry.mood)
                                        .font(POFont.body(12))
                                        .foregroundColor(POTheme.inkSoft)
                                    Text("Recharge \(entry.recharge) of 5 · spent \(POFormat.money(entry.spent, symbol: store.currencySymbol))")
                                        .font(POFont.mono(11))
                                        .foregroundColor(POTheme.inkFaint)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(POTheme.card)
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(POTheme.hairline, lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }

                VStack(spacing: 10) {
                    // Once a plan exists the button locks: addPlan does no dedupe, so a
                    // second tap would silently produce an identical second card.
                    POPrimaryButton(title: justPlanned == nil ? "Plan this" : "Already planned",
                                    glyph: justPlanned == nil ? "calendar" : "check",
                                    enabled: justPlanned == nil) { showPlanner = true }
                    if store.notForMe.contains(idea.id) {
                        POSecondaryButton(title: "Put it back in the deck", glyph: "check", color: POTheme.teal) {
                            store.restoreIdea(idea.id)
                        }
                    } else {
                        POSecondaryButton(title: "Not for me", glyph: "close", color: POTheme.inkSoft) {
                            confirmExclude = true
                        }
                    }
                }
                .padding(.horizontal, 20)

                Color.clear.frame(height: 34)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showPlanner) {
            PODatePickerSheet(idea: idea, weekStartsMonday: store.weekStartsMonday) { dayKey, minute in
                _ = store.addPlan(ideaID: idea.id, dayKey: dayKey, minuteOfDay: minute)
                justPlanned = dayKey
                showPlanner = false
            } onCancel: {
                showPlanner = false
            }
        }
        .alert(isPresented: $confirmExclude) {
            Alert(title: Text("Take this out of the deck?"),
                  message: Text("It stops appearing in draws. Settings keeps the list and you can put it back any time."),
                  primaryButton: .default(Text("Not for me")) {
                      store.excludeIdea(idea.id)
                  },
                  secondaryButton: .cancel(Text("Keep it")))
        }
    }

    private var divider: some View {
        Rectangle().fill(POTheme.hairline).frame(height: 1).padding(.vertical, 2)
    }

    private func tagRow(_ label: String, _ value: String, _ color: Color, _ glyph: String) -> some View {
        HStack(spacing: 10) {
            POGlyph(name: glyph, size: 17, color: color, lineWidth: 1.6)
                .frame(width: 22)
            Text(label)
                .font(POFont.body(13))
                .foregroundColor(POTheme.inkSoft)
                .frame(width: 74, alignment: .leading)
            Text(value)
                .font(POFont.semibold(13))
                .foregroundColor(POTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 7)
    }

    private var memberCollections: [POCollection] {
        POContent.collections.filter { $0.ideaIDs.contains(idea.id) }
    }

    private var pastEntries: [POEntry] {
        store.entries.filter { $0.ideaID == idea.id }.sorted { $0.dayKey > $1.dayKey }
    }
}

// MARK: - Custom date picker sheet

struct PODatePickerSheet: View {
    let idea: POIdea
    let weekStartsMonday: Bool
    let onPick: (Int, Int?) -> Void
    let onCancel: () -> Void

    @State private var year: Int
    @State private var month: Int
    @State private var selectedDay: Int
    @State private var minute: Int?

    /// `initialDayKey` is what Reschedule passes so the sheet opens on the plan's
    /// own date instead of always on today. A date already gone is clamped to
    /// today, since the day grid disables every past cell.
    init(idea: POIdea,
         weekStartsMonday: Bool,
         initialDayKey: Int? = nil,
         initialMinute: Int? = nil,
         onPick: @escaping (Int, Int?) -> Void,
         onCancel: @escaping () -> Void) {
        self.idea = idea
        self.weekStartsMonday = weekStartsMonday
        self.onPick = onPick
        self.onCancel = onCancel
        let base = max(initialDayKey ?? POClock.todayKey, POClock.todayKey)
        _year = State(initialValue: POClock.year(of: base))
        _month = State(initialValue: POClock.month(of: base))
        _selectedDay = State(initialValue: base % 100)
        _minute = State(initialValue: initialMinute)
    }

    private struct TimeOption: Identifiable {
        let id: Int
        let label: String
        let minute: Int?
    }

    private let timeOptions: [TimeOption] = [
        TimeOption(id: 0, label: "No time", minute: nil),
        TimeOption(id: 1, label: "Early, 7:00 AM", minute: 7 * 60),
        TimeOption(id: 2, label: "Morning, 10:00 AM", minute: 10 * 60),
        TimeOption(id: 3, label: "Midday, 12:30 PM", minute: 12 * 60 + 30),
        TimeOption(id: 4, label: "Afternoon, 3:00 PM", minute: 15 * 60),
        TimeOption(id: 5, label: "Evening, 6:30 PM", minute: 18 * 60 + 30),
        TimeOption(id: 6, label: "Late, 9:00 PM", minute: 21 * 60),
    ]

    var body: some View {
        let panelWidth = POScreen.width - 40

        ZStack(alignment: .top) {
            POTheme.paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Give it a date")
                            .font(POFont.display(24))
                            .foregroundColor(POTheme.plumDeep)
                        Spacer(minLength: 0)
                        POGlyphButton(glyph: "close", size: 18, color: POTheme.inkSoft, action: onCancel)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 4)

                    Text(idea.title)
                        .font(POFont.body(14))
                        .foregroundColor(POTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    POCard(padding: 14) {
                        VStack(spacing: 12) {
                            HStack {
                                POGlyphButton(glyph: "back", size: 16, color: POTheme.plum) { step(-1) }
                                Spacer(minLength: 0)
                                Text(POClock.monthFormatter.string(from: POClock.date(from: year * 10000 + month * 100 + 1)))
                                    .font(POFont.title(17))
                                    .foregroundColor(POTheme.plumDeep)
                                Spacer(minLength: 0)
                                POGlyphButton(glyph: "chevron", size: 16, color: POTheme.plum) { step(1) }
                            }
                            POCalendarGrid(year: year,
                                           month: month,
                                           selectedDay: $selectedDay,
                                           width: panelWidth - 28,
                                           weekStartsMonday: weekStartsMonday)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    POSectionTitle(text: "Time, if you want one")
                    POCard(padding: 14) {
                        POWrapRow(items: timeOptions,
                                  width: panelWidth - 28,
                                  spacing: 7,
                                  estimatedItemWidth: { POText.pillWidth($0.label, hasGlyph: false) }) { option in
                            POFilterPill(label: option.label,
                                         selected: minute == option.minute,
                                         color: POTheme.teal) {
                                minute = option.minute
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    POPrimaryButton(title: summaryLabel, glyph: "check", enabled: selectionIsFuture) {
                        guard selectionIsFuture else { return }
                        onPick(selectedKey, minute)
                    }
                    .padding(.horizontal, 20)

                    Text("Nothing gets sent anywhere and nothing pings you. It simply sits in Plans until you say it happened.")
                        .font(POFont.body(11))
                        .foregroundColor(POTheme.inkFaint)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 30)
                        .padding(.top, 12)

                    Color.clear.frame(height: 30)
                }
            }
        }
    }

    private var clampedDay: Int {
        max(1, min(daysInMonth, selectedDay))
    }

    private var daysInMonth: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date) else { return 28 }
        return range.count
    }

    private var selectedKey: Int {
        year * 10000 + month * 100 + clampedDay
    }

    /// The grid disables past cells but never moves `selectedDay` off them, so the
    /// confirm button has to check the date it is about to hand over.
    private var selectionIsFuture: Bool {
        selectedKey >= POClock.todayKey
    }

    private var summaryLabel: String {
        let key = selectedKey
        if let minute = minute {
            return "Plan for " + POClock.mediumString(key) + ", " + POClock.timeString(minute)
        }
        return "Plan for " + POClock.mediumString(key)
    }

    private func step(_ delta: Int) {
        var m = month + delta
        var y = year
        if m > 12 { m = 1; y += 1 }
        if m < 1 { m = 12; y -= 1 }
        // Keep the picker inside a sane window rather than allowing endless paging.
        let currentKey = POClock.todayKey
        let lowerBound = POClock.year(of: currentKey) * 12 + POClock.month(of: currentKey)
        let candidate = y * 12 + m
        if candidate < lowerBound || candidate > lowerBound + 24 { return }
        month = m
        year = y
        selectedDay = min(selectedDay, daysInMonthFor(year: y, month: m))
    }

    private func daysInMonthFor(year: Int, month: Int) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date) else { return 28 }
        return range.count
    }
}

struct POCalendarGrid: View {
    let year: Int
    let month: Int
    @Binding var selectedDay: Int
    let width: CGFloat
    let weekStartsMonday: Bool

    var body: some View {
        let spacing: CGFloat = 5
        let cellSize = max(30, (max(180, width) - spacing * 6) / 7)
        let blanks = POInsightEngine.leadingBlanks(year: year, month: month, weekStartsMonday: weekStartsMonday)
        let days = daysInMonth
        let rows = Int(ceil(Double(days + blanks) / 7.0))
        let todayKey = POClock.todayKey

        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(Array(labels.enumerated()), id: \.offset) { pair in
                    Text(pair.element)
                        .font(POFont.mono(10))
                        .foregroundColor(POTheme.inkFaint)
                        .frame(width: cellSize)
                }
            }
            ForEach(0..<max(1, rows), id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { col in
                        let day = row * 7 + col - blanks + 1
                        if day >= 1 && day <= days {
                            dayButton(day: day, size: cellSize, todayKey: todayKey)
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private var labels: [String] {
        weekStartsMonday ? ["M", "T", "W", "T", "F", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
    }

    private func dayButton(day: Int, size: CGFloat, todayKey: Int) -> some View {
        let key = year * 10000 + month * 100 + day
        let isPast = key < todayKey
        let isToday = key == todayKey
        let isSelected = day == selectedDay
        return Button(action: { if !isPast { selectedDay = day } }) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(isSelected ? POTheme.plum : (isToday ? POTheme.gold.opacity(0.20) : Color.clear))
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isToday && !isSelected ? POTheme.gold : Color.clear, lineWidth: 1)
                Text("\(day)")
                    .font(POFont.medium(14))
                    .foregroundColor(isSelected ? POTheme.paper
                                     : (isPast ? POTheme.inkFaint.opacity(0.5) : POTheme.ink))
            }
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPast)
    }

    private var daysInMonth: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date) else { return 28 }
        return range.count
    }
}
