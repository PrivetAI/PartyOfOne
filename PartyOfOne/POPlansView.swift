import SwiftUI

struct POPlansView: View {
    @EnvironmentObject var store: POStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                POScreenHeader(title: "Plans", subtitle: headerSubtitle)

                if store.plans.isEmpty && store.entries.isEmpty {
                    POEmptyState(glyph: "calendar",
                                 title: "Nothing booked in",
                                 message: "Deal yourself three cards, pick one, and give it a date. A plan with a date on it behaves completely differently from an idea in a list.")
                        .padding(.top, 20)
                } else {
                    if !store.overduePlans.isEmpty {
                        POSectionTitle(text: "Waiting on a verdict",
                                       accessory: "\(store.overduePlans.count)")
                        VStack(spacing: 10) {
                            ForEach(store.overduePlans) { plan in
                                planLink(plan, overdue: true)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                    }

                    if !store.upcomingPlans.isEmpty {
                        POSectionTitle(text: "Coming up", accessory: "\(store.upcomingPlans.count)")
                        VStack(spacing: 10) {
                            ForEach(store.upcomingPlans) { plan in
                                planLink(plan, overdue: false)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                    } else if store.overduePlans.isEmpty {
                        POCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nothing coming up")
                                    .font(POFont.title(17))
                                    .foregroundColor(POTheme.plumDeep)
                                Text("You have \(store.entries.count) outing\(store.entries.count == 1 ? "" : "s") behind you and none ahead. The Draw tab is two taps away.")
                                    .font(POFont.body(13))
                                    .foregroundColor(POTheme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                    }

                    if !beenThere.isEmpty {
                        POSectionTitle(text: "Been there", accessory: "\(beenThere.count)")
                        VStack(spacing: 8) {
                            ForEach(beenThere.prefix(12)) { entry in
                                beenThereRow(entry)
                            }
                        }
                        .padding(.horizontal, 20)
                        if beenThere.count > 12 {
                            Text("The Journal tab has all \(beenThere.count) of them.")
                                .font(POFont.body(12))
                                .foregroundColor(POTheme.inkFaint)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 10)
                        }
                    }
                }

                Color.clear.frame(height: 30)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var headerSubtitle: String {
        let up = store.upcomingPlans.count
        let over = store.overduePlans.count
        if up == 0 && over == 0 { return "Nothing on the books." }
        var parts: [String] = []
        if up > 0 { parts.append("\(up) ahead") }
        if over > 0 { parts.append("\(over) waiting to be scored") }
        return parts.joined(separator: " · ")
    }

    private var beenThere: [POEntry] { store.sortedEntries }

    private func planLink(_ plan: POPlan, overdue: Bool) -> some View {
        Group {
            if let idea = POContent.idea(plan.ideaID) {
                NavigationLink(destination: POPlanDetailView(planID: plan.id)) {
                    POPlanCard(plan: plan, idea: idea, overdue: overdue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func beenThereRow(_ entry: POEntry) -> some View {
        Group {
            if let idea = POContent.idea(entry.ideaID) {
                NavigationLink(destination: POEntryDetailView(entryID: entry.id)) {
                    HStack(spacing: 12) {
                        PORadar(recharge: entry.recharge, novelty: entry.novelty,
                                comfort: entry.comfort, worth: entry.worth, side: 46)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(idea.title)
                                .font(POFont.semibold(13.5))
                                .foregroundColor(POTheme.plumDeep)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(POClock.mediumString(entry.dayKey)
                                 + (entry.mood.isEmpty ? "" : " · " + entry.mood))
                                .font(POFont.body(11.5))
                                .foregroundColor(POTheme.inkSoft)
                        }
                        Spacer(minLength: 0)
                        POGlyph(name: "chevron", size: 13, color: POTheme.inkFaint, lineWidth: 1.8)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(POTheme.card)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(POTheme.hairline, lineWidth: 1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Plan card

struct POPlanCard: View {
    let plan: POPlan
    let idea: POIdea
    let overdue: Bool

    var body: some View {
        let days = POClock.daysBetween(POClock.todayKey, plan.dayKey)
        let prepTotal = idea.prep.count
        let prepDone = plan.checkedPrep.filter { $0 >= 0 && $0 < prepTotal }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 1) {
                    Text(shortMonth)
                        .font(POFont.semibold(10))
                        .tracking(0.8)
                        .foregroundColor(overdue ? POTheme.terracotta : POTheme.plum)
                    Text("\(plan.dayKey % 100)")
                        .font(POFont.display(22))
                        .foregroundColor(overdue ? POTheme.terracotta : POTheme.plumDeep)
                }
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((overdue ? POTheme.terracotta : POTheme.plum).opacity(0.10))
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(idea.title)
                        .font(POFont.title(16))
                        .foregroundColor(POTheme.plumDeep)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(countdownText(days: days))
                        .font(POFont.semibold(12))
                        .foregroundColor(overdue ? POTheme.terracotta : POTheme.teal)
                    if let minute = plan.minuteOfDay {
                        Text(POClock.timeString(minute))
                            .font(POFont.mono(11))
                            .foregroundColor(POTheme.inkSoft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                POGlyph(name: "chevron", size: 14, color: POTheme.inkFaint, lineWidth: 1.8)
                    .padding(.top, 4)
            }

            HStack(spacing: 6) {
                POChip(text: idea.duration.label, color: POTheme.plum, glyph: "clock", compact: true)
                POChip(text: idea.budget.label, color: POTheme.budgetColor(idea.budget), glyph: "coin", compact: true)
                if prepTotal > 0 {
                    POChip(text: "Prep \(prepDone)/\(prepTotal)",
                           color: prepDone == prepTotal ? POTheme.teal : POTheme.inkSoft,
                           glyph: "check",
                           compact: true)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(POTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(overdue ? POTheme.terracotta.opacity(0.4) : POTheme.hairline, lineWidth: 1))
                .shadow(color: POTheme.shadow, radius: 7, x: 0, y: 3)
        )
    }

    private var shortMonth: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM"
        return f.string(from: POClock.date(from: plan.dayKey)).uppercased()
    }

    private func countdownText(days: Int) -> String {
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days == -1 { return "Yesterday — how was it?" }
        if days > 1 { return "In \(days) days" }
        return "\(-days) days ago — how was it?"
    }
}
