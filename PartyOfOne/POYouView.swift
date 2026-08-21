import SwiftUI

struct POYouView: View {
    @EnvironmentObject var store: POStore
    @Binding var tab: POTab
    @Binding var pendingRequest: POFilters?

    @State private var axis: POInsightAxis = .setting
    @State private var gridYear: Int = POClock.year(of: POClock.todayKey)
    @State private var gridMonth: Int = POClock.month(of: POClock.todayKey)

    var body: some View {
        let panelWidth = POScreen.width - 40

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                POScreenHeader(title: "You", subtitle: headerSubtitle)

                if store.entries.isEmpty {
                    POEmptyState(glyph: "bars",
                                 title: "Nothing to read yet",
                                 message: "This tab needs outings to work with. Do three and it starts guessing; do ten and it starts being right.")
                        .padding(.top, 14)
                    blindSpotsSection(panelWidth: panelWidth, headline: "Somewhere to start")
                } else {
                    bestDaySection(panelWidth: panelWidth)
                    totalsSection(panelWidth: panelWidth)
                    profileSection(panelWidth: panelWidth)
                    scatterSection(panelWidth: panelWidth)
                    heatSection(panelWidth: panelWidth)
                    collectionsSection(panelWidth: panelWidth)
                    blindSpotsSection(panelWidth: panelWidth, headline: "Never tried")
                }

                Color.clear.frame(height: 30)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var headerSubtitle: String {
        if store.entries.isEmpty { return "Your profile builds itself from what you file." }
        let streak = POInsightEngine.weekStreak(entries: store.entries, weekStartsMonday: store.weekStartsMonday)
        if streak > 1 { return "\(store.entries.count) outings · \(streak) weeks running" }
        return "\(store.entries.count) outing\(store.entries.count == 1 ? "" : "s") on record"
    }

    // MARK: Best day

    private func bestDaySection(panelWidth: CGFloat) -> some View {
        let best = POInsightEngine.bestDay(entries: store.entries)
        return VStack(alignment: .leading, spacing: 0) {
            POSectionTitle(text: "Your best kind of solo day")
            POCard {
                VStack(alignment: .leading, spacing: 10) {
                    if best.phrase.isEmpty {
                        Text("Not enough filed yet to say anything honest.")
                            .font(POFont.body(14))
                            .foregroundColor(POTheme.inkSoft)
                    } else {
                        Text(best.confident ? "So far, your best days look like:" : "Early guess, on thin evidence:")
                            .font(POFont.body(13))
                            .foregroundColor(POTheme.inkSoft)
                        Text(best.phrase + ".")
                            .font(POFont.title(POScreen.isCompact ? 18 : 20))
                            .foregroundColor(POTheme.plumDeep)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Based on \(best.sampleCount) outing\(best.sampleCount == 1 ? "" : "s")."
                             + (best.confident ? "" : " Treat it as a hunch until there are eight or so."))
                            .font(POFont.body(12))
                            .foregroundColor(POTheme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    // MARK: Totals

    private func totalsSection(panelWidth: CGFloat) -> some View {
        let streak = POInsightEngine.weekStreak(entries: store.entries, weekStartsMonday: store.weekStartsMonday)
        let total = POInsightEngine.totalSpent(entries: store.entries)
        let months = POInsightEngine.monthsActive(entries: store.entries)
        let mean = POInsightEngine.meanRecharge(entries: store.entries)
        return VStack(alignment: .leading, spacing: 0) {
            POSectionTitle(text: "The count")
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    POStatTile(value: "\(store.entries.count)", label: "Outings", color: POTheme.plum)
                    POStatTile(value: "\(streak)", label: streak == 1 ? "Week running" : "Weeks running",
                               color: POTheme.teal)
                    POStatTile(value: POFormat.score(mean), label: "Mean Recharge", color: POTheme.terracotta)
                }
                HStack(spacing: 10) {
                    POStatTile(value: POFormat.money(total, symbol: store.currencySymbol),
                               label: "Spent in total", color: POTheme.gold)
                    POStatTile(value: "\(months)", label: months == 1 ? "Month active" : "Months active",
                               color: POTheme.plumDeep)
                    POStatTile(value: "\(store.earnedBadgeCount)/\(POContent.collections.count)",
                               label: "Badges earned", color: POTheme.plum)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    // MARK: Profile bars

    private func profileSection(panelWidth: CGFloat) -> some View {
        let stats = POInsightEngine.rankedTagStats(entries: store.entries, axis: axis)
        return VStack(alignment: .leading, spacing: 0) {
            POSectionTitle(text: "Your profile", accessory: "mean Recharge")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(POInsightAxis.allCases) { candidate in
                        POFilterPill(label: candidate.title,
                                     selected: axis == candidate,
                                     color: POTheme.plum) {
                            withAnimation(.easeOut(duration: 0.18)) { axis = candidate }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 12)

            POCard {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(stats) { stat in
                        POTagBarRow(stat: stat,
                                    width: panelWidth - 32,
                                    accent: accentFor(stat))
                    }
                    Text("A tag needs three outings before the app will treat its average as anything. The count on the right is how much the bar is standing on.")
                        .font(POFont.body(11))
                        .foregroundColor(POTheme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    private func accentFor(_ stat: POTagStat) -> Color {
        switch stat.axis {
        case .setting:
            return POTheme.settingColor(POSetting(rawValue: stat.value) ?? .home)
        case .budget:
            return POTheme.budgetColor(POBudget(rawValue: stat.value) ?? .free)
        case .energy:
            return POTheme.energyColor(POEnergy(rawValue: stat.value) ?? .gentle)
        case .exposure:
            return POTheme.exposureColor(POExposure(rawValue: stat.value) ?? .solitary)
        case .duration:
            return POTheme.plum
        }
    }

    // MARK: Scatter

    private func scatterSection(panelWidth: CGFloat) -> some View {
        let points = POInsightEngine.scatter(entries: store.entries)
        let verdict = POInsightEngine.costVerdict(entries: store.entries)
        return VStack(alignment: .leading, spacing: 0) {
            POSectionTitle(text: "Recharge against cost")
            POCard {
                VStack(alignment: .leading, spacing: 12) {
                    if points.count < 2 {
                        Text("Two outings and this chart starts working. It is usually the one that changes how people spend.")
                            .font(POFont.body(13))
                            .foregroundColor(POTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        POScatterChart(points: points,
                                       width: panelWidth - 32,
                                       height: POScreen.isCompact ? 150 : 176,
                                       currency: store.currencySymbol)
                        if let verdict = verdict {
                            Text(verdict)
                                .font(POFont.body(13))
                                .foregroundColor(POTheme.ink.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Six outings with a spread of prices and this will start drawing a conclusion for you.")
                                .font(POFont.body(12))
                                .foregroundColor(POTheme.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    // MARK: Heat grid

    private func heatSection(panelWidth: CGFloat) -> some View {
        let cells = POInsightEngine.monthCells(entries: store.entries, year: gridYear, month: gridMonth)
        let blanks = POInsightEngine.leadingBlanks(year: gridYear, month: gridMonth,
                                                   weekStartsMonday: store.weekStartsMonday)
        let inMonth = cells.reduce(0) { $0 + $1.count }
        return VStack(alignment: .leading, spacing: 0) {
            POSectionTitle(text: "The months")
            POCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        POGlyphButton(glyph: "back", size: 14, color: POTheme.plum) { stepMonth(-1) }
                        Spacer(minLength: 0)
                        Text(POClock.monthFormatter.string(from: POClock.date(from: gridYear * 10000 + gridMonth * 100 + 1)))
                            .font(POFont.title(16))
                            .foregroundColor(POTheme.plumDeep)
                        Spacer(minLength: 0)
                        POGlyphButton(glyph: "chevron", size: 14, color: POTheme.plum) { stepMonth(1) }
                    }
                    POMonthGrid(cells: cells,
                                leadingBlanks: blanks,
                                width: panelWidth - 32,
                                weekStartsMonday: store.weekStartsMonday)
                    Text(inMonth == 0
                         ? "Nothing this month. A blank month is not a failure, it is just a blank month."
                         : "\(inMonth) outing\(inMonth == 1 ? "" : "s") this month. Warmer squares scored higher on Recharge.")
                        .font(POFont.body(12))
                        .foregroundColor(POTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    private func stepMonth(_ delta: Int) {
        var m = gridMonth + delta
        var y = gridYear
        if m > 12 { m = 1; y += 1 }
        if m < 1 { m = 12; y -= 1 }
        let today = POClock.todayKey
        let upper = POClock.year(of: today) * 12 + POClock.month(of: today)
        let candidate = y * 12 + m
        if candidate > upper { return }
        if candidate < upper - 60 { return }
        gridMonth = m
        gridYear = y
    }

    // MARK: Collections

    private func collectionsSection(panelWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            POSectionTitle(text: "Collections",
                           accessory: "\(store.earnedBadgeCount) of \(POContent.collections.count)")
            VStack(spacing: 10) {
                ForEach(POContent.collections) { collection in
                    NavigationLink(destination: POCollectionDetailView(collectionID: collection.id)) {
                        collectionRow(collection, width: panelWidth)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    private func collectionRow(_ collection: POCollection, width: CGFloat) -> some View {
        let progress = store.collectionProgress(collection)
        let complete = store.isCollectionComplete(collection)
        let fraction = progress.total > 0 ? Double(progress.done) / Double(progress.total) : 0
        return HStack(spacing: 12) {
            POBadgeView(glyph: collection.badgeName, earned: complete, size: 44)
            VStack(alignment: .leading, spacing: 5) {
                Text(collection.name)
                    .font(POFont.semibold(15))
                    .foregroundColor(POTheme.plumDeep)
                Canvas { ctx, size in
                    guard size.width > 2, size.height > 1 else { return }
                    var track = Path()
                    track.addRoundedRect(in: CGRect(origin: .zero, size: size),
                                         cornerSize: CGSize(width: size.height / 2, height: size.height / 2))
                    ctx.fill(track, with: .color(POTheme.paperDeep))
                    let w = size.width * CGFloat(POMath.clamp(fraction, 0, 1))
                    if w > 0.5 {
                        var bar = Path()
                        bar.addRoundedRect(in: CGRect(x: 0, y: 0, width: max(size.height, w), height: size.height),
                                           cornerSize: CGSize(width: size.height / 2, height: size.height / 2))
                        ctx.fill(bar, with: .color(complete ? POTheme.gold : POTheme.plum))
                    }
                }
                .frame(height: 7)
                Text("\(progress.done) of \(progress.total)" + (complete ? " — badge earned" : ""))
                    .font(POFont.mono(11))
                    .foregroundColor(complete ? POTheme.gold : POTheme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            POGlyph(name: "chevron", size: 13, color: POTheme.inkFaint, lineWidth: 1.8)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(POTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(complete ? POTheme.gold.opacity(0.5) : POTheme.hairline, lineWidth: 1))
        )
    }

    // MARK: Blind spots

    private func blindSpotsSection(panelWidth: CGFloat, headline: String) -> some View {
        let allSpots = POInsightEngine.blindSpots(entries: store.entries, excluded: store.notForMe)
        // With nothing filed every tag value is a blind spot, which is 23 rows of
        // noise. On the empty state show only the Setting axis.
        let spots = store.entries.isEmpty ? allSpots.filter { $0.axis == .setting } : allSpots
        return Group {
            if spots.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    POSectionTitle(text: headline)
                    POCard {
                        Text("You have tried at least one outing on every tag value the app knows about. That is genuinely unusual.")
                            .font(POFont.body(13))
                            .foregroundColor(POTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    POSectionTitle(text: headline, accessory: "\(spots.count)")
                    POCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tag values with nothing filed against them. One tap deals you three cards from that corner of the deck.")
                                .font(POFont.body(12.5))
                                .foregroundColor(POTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            VStack(spacing: 7) {
                                ForEach(spots) { spot in
                                    Button(action: {
                                        pendingRequest = PODrawEngine.filtersTargeting(axis: spot.axis,
                                                                                       value: spot.value)
                                        tab = .draw
                                    }) {
                                        HStack(spacing: 8) {
                                            Text(spot.axis.title)
                                                .font(POFont.body(11))
                                                .foregroundColor(POTheme.inkFaint)
                                                .frame(width: 62, alignment: .leading)
                                            Text(spot.label)
                                                .font(POFont.semibold(13))
                                                .foregroundColor(POTheme.plumDeep)
                                            Spacer(minLength: 4)
                                            Text("\(spot.availableIdeas) ideas")
                                                .font(POFont.mono(10))
                                                .foregroundColor(POTheme.inkFaint)
                                            POGlyph(name: "cards", size: 15, color: POTheme.plum, lineWidth: 1.6)
                                        }
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 9)
                                        .background(
                                            RoundedRectangle(cornerRadius: 11)
                                                .fill(POTheme.paperDeep)
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 11))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }
            }
        }
    }
}
