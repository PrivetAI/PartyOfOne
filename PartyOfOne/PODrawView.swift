import SwiftUI

private enum PODealPhase {
    case idle
    case shuffling
    case revealing
}

struct PODrawView: View {
    @EnvironmentObject var store: POStore
    @Binding var pendingRequest: POFilters?

    @State private var dealt: [POIdea] = []
    @State private var revealFlags: [Bool] = [false, false, false]
    @State private var phase: PODealPhase = .idle
    @State private var shuffleSpin: Double = 0
    @State private var lastShown: Set<String> = []
    @State private var filtersOpen = false
    @State private var dealCount = 0

    private var monthNow: Int { POClock.month(of: POClock.todayKey) }

    private var pool: [POIdea] {
        PODrawEngine.eligible(all: POContent.ideas,
                              filters: store.filters,
                              excluded: store.notForMe,
                              monthNow: monthNow)
    }

    var body: some View {
        let cardWidth = POScreen.width - 40

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                POScreenHeader(title: "Draw",
                               subtitle: subtitleText) {
                    POGlyphButton(glyph: filtersOpen ? "chevron-down" : "sliders",
                                  size: 20,
                                  color: store.filters.isEmpty ? POTheme.plum : POTheme.terracotta) {
                        withAnimation(.easeOut(duration: 0.22)) { filtersOpen.toggle() }
                    }
                }

                if filtersOpen {
                    POFilterPanel(width: cardWidth)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .transition(.opacity)
                }

                if pool.isEmpty {
                    emptyPoolState
                        .padding(.top, 10)
                } else if dealt.isEmpty {
                    idleState(cardWidth: cardWidth)
                } else {
                    VStack(spacing: 14) {
                        ForEach(Array(dealt.enumerated()), id: \.element.id) { pair in
                            let index = pair.offset
                            let idea = pair.element
                            NavigationLink(destination: POIdeaDetailView(idea: idea)) {
                                PODealCard(idea: idea, width: cardWidth, index: index)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(revealFlags[safe: index] == true ? 1 : 0)
                            .scaleEffect(revealFlags[safe: index] == true ? 1 : 0.92)
                            .rotation3DEffect(.degrees(revealFlags[safe: index] == true ? 0 : -72),
                                              axis: (x: 0, y: 1, z: 0),
                                              anchor: .leading,
                                              perspective: 0.55)
                            .offset(y: revealFlags[safe: index] == true ? 0 : 26)
                        }
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 10) {
                        POSecondaryButton(title: "Redeal", glyph: "shuffle") { deal(excludingCurrent: true) }
                        POSecondaryButton(title: "Clear", glyph: "close", color: POTheme.inkSoft) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                dealt = []
                                revealFlags = [false, false, false]
                                phase = .idle
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                    Text(footnote)
                        .font(POFont.body(12))
                        .foregroundColor(POTheme.inkFaint)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 28)
                        .padding(.top, 14)
                }

                Color.clear.frame(height: 28)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            pruneDealt()
            consumePendingRequest()
        }
        // A hand dealt under the old filters must not survive a filter change, and
        // a card excluded from the idea screen must not stay on the table.
        .onChange(of: store.filters) { _ in pruneDealt() }
        .onChange(of: store.notForMe) { _ in pruneDealt() }
    }

    /// Drop any card in the current hand that no longer satisfies the filters or
    /// has since been marked "not for me".
    private func pruneDealt() {
        guard !dealt.isEmpty else { return }
        let survivors = dealt.filter {
            !store.notForMe.contains($0.id)
                && PODrawEngine.matches($0, filters: store.filters, monthNow: monthNow)
        }
        guard survivors.count != dealt.count else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            dealt = survivors
            revealFlags = Array(repeating: true, count: max(3, survivors.count))
            phase = .idle
        }
        lastShown = Set(survivors.map { $0.id })
    }

    // MARK: Idle / empty

    /// The slot the deck artwork lives in. The art is told this height rather than
    /// deriving one from its own width, which overflowed the slot by 40 pt on SE.
    private var deckArtHeight: CGFloat { POScreen.isCompact ? 140 : 168 }

    private func idleState(cardWidth: CGFloat) -> some View {
        VStack(spacing: 18) {
            ZStack {
                PODeckArt(width: min(cardWidth, 300), height: deckArtHeight, spin: shuffleSpin)
            }
            .frame(height: deckArtHeight)

            VStack(spacing: 6) {
                Text(phase == .shuffling ? "Shuffling" : "Three cards, then you pick one")
                    .font(POFont.title(19))
                    .foregroundColor(POTheme.plumDeep)
                Text(phase == .shuffling
                     ? "Give it a second."
                     : "\(pool.count) outings match your filters right now. Browsing all of them is how you end up doing none of them.")
                    .font(POFont.body(13))
                    .foregroundColor(POTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            POPrimaryButton(title: "Deal three", glyph: "cards", enabled: phase != .shuffling) {
                deal(excludingCurrent: false)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var emptyPoolState: some View {
        let narrow = PODrawEngine.narrowest(all: POContent.ideas,
                                            filters: store.filters,
                                            excluded: store.notForMe,
                                            monthNow: monthNow)
        return POCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    POGlyph(name: "search", size: 22, color: POTheme.terracotta, lineWidth: 1.7)
                    Text("Nothing matches")
                        .font(POFont.title(18))
                        .foregroundColor(POTheme.plumDeep)
                }
                if let narrow = narrow {
                    Text("Your \(narrow.axisName) filter is the tight one. Drop it and \(narrow.survivors) outings come back.")
                        .font(POFont.body(14))
                        .foregroundColor(POTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !store.notForMe.isEmpty && store.filters.isEmpty {
                    Text("Every idea is currently on your Not for me list. Settings has the list, and everything on it can be put back.")
                        .font(POFont.body(14))
                        .foregroundColor(POTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No combination of your current filters leaves anything to deal. Loosen one and try again.")
                        .font(POFont.body(14))
                        .foregroundColor(POTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                POSecondaryButton(title: "Clear all filters", glyph: "close") {
                    withAnimation { store.filters = POFilters() }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Text

    private var subtitleText: String {
        if store.filters.isEmpty {
            if store.notForMe.isEmpty {
                return "\(POContent.count) outings, no filters set."
            }
            return "\(pool.count) outings in the deck, \(store.notForMe.count) set aside."
        }
        return "\(pool.count) of \(POContent.count) match \(store.filters.activeCount) filter\(store.filters.activeCount == 1 ? "" : "s")."
    }

    private var footnote: String {
        let done = store.doneIdeaIDs.count
        if done == 0 {
            return "Anything you have already done in the last two months sinks down the deck rather than disappearing."
        }
        return "Deal \(dealCount) today. Recently done outings are still in the deck, just further down it."
    }

    // MARK: Dealing

    private func deal(excludingCurrent: Bool) {
        let currentPool = pool
        guard !currentPool.isEmpty else { return }

        var exclude = lastShown
        if excludingCurrent {
            exclude = Set(dealt.map { $0.id })
        }

        phase = .shuffling
        revealFlags = [false, false, false]
        withAnimation(.easeInOut(duration: 0.42)) { shuffleSpin += 1 }

        let picked = PODrawEngine.deal(from: currentPool,
                                       excludingRecentlyShown: exclude,
                                       lastDone: store.lastDoneByIdea,
                                       plannedIDs: store.plannedIdeaIDs,
                                       deprioritiseRecent: store.deprioritiseRecent,
                                       todayKey: POClock.todayKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.44) {
            dealt = picked
            lastShown = Set(picked.map { $0.id })
            revealFlags = Array(repeating: false, count: max(3, picked.count))
            phase = .revealing
            dealCount += 1
            for i in picked.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.13) {
                    withAnimation(.spring(response: 0.44, dampingFraction: 0.76)) {
                        if i < revealFlags.count { revealFlags[i] = true }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(picked.count) * 0.13 + 0.3) {
                phase = .idle
            }
        }
    }

    private func consumePendingRequest() {
        guard let request = pendingRequest else { return }
        pendingRequest = nil
        store.filters = request
        dealt = []
        revealFlags = [false, false, false]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            deal(excludingCurrent: false)
        }
    }
}

// MARK: - The card

struct PODealCard: View {
    @EnvironmentObject var store: POStore
    let idea: POIdea
    let width: CGFloat
    let index: Int

    var body: some View {
        // Every nested horizontal inset has to come out of the width before it
        // reaches a fixed-size child.
        let innerWidth = width - 32
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(POTheme.settingColor(idea.setting).opacity(0.14))
                    POGlyph(name: POGlyphDrawing.settingGlyph(idea.setting),
                            size: 26,
                            color: POTheme.settingColor(idea.setting),
                            lineWidth: 1.6)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(idea.title)
                        .font(POFont.title(17))
                        .foregroundColor(POTheme.plumDeep)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text(idea.tagLine)
                        .font(POFont.body(12))
                        .foregroundColor(POTheme.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 10)

            Text(idea.blurb)
                .font(POFont.body(13.5))
                .foregroundColor(POTheme.ink.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            POWrapRow(items: chipItems,
                      width: innerWidth,
                      spacing: 6,
                      estimatedItemWidth: { item in
                          POText.chipWidth(item.text, hasGlyph: item.glyph != nil, compact: true)
                      }) { item in
                POChip(text: item.text, color: item.color, glyph: item.glyph, compact: true)
            }

            HStack(spacing: 6) {
                if store.doneIdeaIDs.contains(idea.id) {
                    POChip(text: "Been there", color: POTheme.teal, glyph: "check", compact: true)
                }
                if store.plannedIdeaIDs.contains(idea.id) {
                    POChip(text: "Already planned", color: POTheme.gold, glyph: "calendar", compact: true)
                }
                Spacer(minLength: 0)
                Text("Open")
                    .font(POFont.semibold(12))
                    .foregroundColor(POTheme.plum)
                POGlyph(name: "chevron", size: 12, color: POTheme.plum, lineWidth: 2)
            }
            .padding(.top, 12)
        }
        .padding(16)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(POTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(POTheme.settingColor(idea.setting).opacity(0.25), lineWidth: 1)
                )
                .shadow(color: POTheme.shadow, radius: 10, x: 0, y: 5)
        )
    }

    private struct ChipItem: Identifiable {
        let id: Int
        let text: String
        let color: Color
        let glyph: String?
    }

    private var chipItems: [ChipItem] {
        [
            ChipItem(id: 0, text: idea.setting.label, color: POTheme.settingColor(idea.setting),
                     glyph: POGlyphDrawing.settingGlyph(idea.setting)),
            ChipItem(id: 1, text: idea.energy.label, color: POTheme.energyColor(idea.energy), glyph: nil),
            ChipItem(id: 2, text: idea.exposure.label, color: POTheme.exposureColor(idea.exposure),
                     glyph: POGlyphDrawing.exposureGlyph(idea.exposure)),
            ChipItem(id: 3, text: idea.weather.label, color: POTheme.inkSoft,
                     glyph: POGlyphDrawing.weatherGlyph(idea.weather)),
        ]
    }
}

// MARK: - Deck artwork

struct PODeckArt: View, Animatable {
    var width: CGFloat
    var height: CGFloat
    var spin: Double

    var animatableData: Double {
        get { spin }
        set { spin = newValue }
    }

    var body: some View {
        Canvas { ctx, size in
            guard size.width > 10, size.height > 10 else { return }
            let cardW = size.width * 0.36
            let cardH = size.height * 0.78
            let cx = size.width / 2
            let cy = size.height / 2
            let palette = [POTheme.plum, POTheme.terracotta, POTheme.gold, POTheme.teal, POTheme.plumSoft]
            for i in 0..<5 {
                let t = Double(i) - 2
                let angle = (t * 0.14) + sin(spin * 3.14159 + Double(i)) * 0.05
                let dx = CGFloat(t) * cardW * 0.30
                let dy = CGFloat(abs(t)) * 5
                var p = Path()
                p.addRoundedRect(in: CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH),
                                 cornerSize: CGSize(width: 10, height: 10))
                let transform = CGAffineTransform(translationX: cx + dx, y: cy + dy)
                    .rotated(by: CGFloat(angle))
                let shaped = p.applying(transform)
                ctx.fill(shaped, with: .color(POTheme.card))
                ctx.stroke(shaped, with: .color(palette[i % palette.count].opacity(0.55)), lineWidth: 1.4)

                var inner = Path()
                inner.addRoundedRect(in: CGRect(x: -cardW / 2 + 9, y: -cardH / 2 + 9,
                                                width: cardW - 18, height: cardH - 18),
                                     cornerSize: CGSize(width: 6, height: 6))
                ctx.stroke(inner.applying(transform),
                           with: .color(palette[i % palette.count].opacity(0.28)),
                           lineWidth: 1)

                var pip = Path()
                pip.addEllipse(in: CGRect(x: -6, y: -6, width: 12, height: 12))
                ctx.fill(pip.applying(transform), with: .color(palette[i % palette.count].opacity(0.5)))
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Filter panel

struct POFilterPanel: View {
    @EnvironmentObject var store: POStore
    let width: CGFloat

    var body: some View {
        POCard(padding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                axisSection(title: "Budget",
                            values: POBudget.allCases.map { ($0.rawValue, $0.label, POTheme.budgetColor($0), nil) },
                            selection: Binding(get: { store.filters.budgets },
                                               set: { store.filters.budgets = $0 }))

                axisSection(title: "How long",
                            values: PODuration.allCases.map { ($0.rawValue, $0.label, POTheme.plum, "clock") },
                            selection: Binding(get: { store.filters.durations },
                                               set: { store.filters.durations = $0 }))

                axisSection(title: "Energy",
                            values: POEnergy.allCases.map { ($0.rawValue, $0.label, POTheme.energyColor($0), nil) },
                            selection: Binding(get: { store.filters.energies },
                                               set: { store.filters.energies = $0 }))

                axisSection(title: "Setting",
                            values: POSetting.allCases.map {
                                ($0.rawValue, $0.label, POTheme.settingColor($0), POGlyphDrawing.settingGlyph($0))
                            },
                            selection: Binding(get: { store.filters.settings },
                                               set: { store.filters.settings = $0 }))

                axisSection(title: "Company",
                            values: POExposure.allCases.map {
                                ($0.rawValue, $0.longLabel, POTheme.exposureColor($0), POGlyphDrawing.exposureGlyph($0))
                            },
                            selection: Binding(get: { store.filters.exposures },
                                               set: { store.filters.exposures = $0 }))

                axisSection(title: "Weather today",
                            values: [POWeather.needsDry, .needsSun, .needsCold].map {
                                ($0.rawValue, weatherPrompt($0), POTheme.teal, POGlyphDrawing.weatherGlyph($0))
                            },
                            selection: Binding(get: { store.filters.weatherToday },
                                               set: { store.filters.weatherToday = $0 }))

                Text("Indoor-safe outings always survive the weather filter.")
                    .font(POFont.body(11))
                    .foregroundColor(POTheme.inkFaint)

                POToggleRow(title: "Match the season",
                            subtitle: "Hide outings tagged for a different time of year.",
                            isOn: Binding(get: { store.filters.seasonAware },
                                          set: { store.filters.seasonAware = $0 }))

                if !store.filters.isEmpty {
                    POSecondaryButton(title: "Clear all filters", glyph: "close", color: POTheme.terracotta) {
                        withAnimation { store.filters = POFilters() }
                    }
                }
            }
        }
    }

    private func weatherPrompt(_ w: POWeather) -> String {
        switch w {
        case .needsDry: return "It is dry"
        case .needsSun: return "It is sunny"
        case .needsCold: return "It is cold"
        case .indoorSafe: return "Indoors"
        }
    }

    private struct PillItem: Identifiable {
        let id: String
        let label: String
        let color: Color
        let glyph: String?
    }

    private func axisSection(title: String,
                             values: [(String, String, Color, String?)],
                             selection: Binding<Set<String>>) -> some View {
        let items = values.map { PillItem(id: $0.0, label: $0.1, color: $0.2, glyph: $0.3) }
        return VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(POFont.semibold(10))
                .tracking(1.1)
                .foregroundColor(POTheme.inkSoft)
            POWrapRow(items: items,
                      width: width - 28,
                      spacing: 6,
                      estimatedItemWidth: { item in
                          POText.pillWidth(item.label, hasGlyph: item.glyph != nil)
                      }) { item in
                POFilterPill(label: item.label,
                             selected: selection.wrappedValue.contains(item.id),
                             color: item.color,
                             glyph: item.glyph) {
                    var set = selection.wrappedValue
                    if set.contains(item.id) { set.remove(item.id) } else { set.insert(item.id) }
                    selection.wrappedValue = set
                }
            }
        }
    }
}

// MARK: - Safe indexing

extension Array {
    subscript(safe index: Int) -> Element? {
        (index >= 0 && index < count) ? self[index] : nil
    }
}
