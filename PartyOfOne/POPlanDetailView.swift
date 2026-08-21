import SwiftUI

private enum POPlanSheet: Identifiable {
    case reschedule
    case reflect
    var id: Int {
        switch self {
        case .reschedule: return 1
        case .reflect: return 2
        }
    }
}

struct POPlanDetailView: View {
    @EnvironmentObject var store: POStore
    @Environment(\.presentationMode) private var presentationMode
    let planID: String

    // iOS 15 honours only the LAST .sheet on a view, so both sheets come
    // through one item-driven modifier.
    @State private var sheet: POPlanSheet?
    @State private var confirmCancel = false
    @State private var focusedField: Int?
    @State private var budgetText: String = ""
    @State private var notesText: String = ""
    @State private var loadedFromStore = false

    private var plan: POPlan? { store.plans.first { $0.id == planID } }

    var body: some View {
        Group {
            if let plan = plan, let idea = POContent.idea(plan.ideaID) {
                content(plan: plan, idea: idea)
            } else {
                VStack(spacing: 16) {
                    POEmptyState(glyph: "check",
                                 title: "That one is done",
                                 message: "The plan has been scored and filed. You will find it in the Journal.")
                    POSecondaryButton(title: "Back to Plans") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(POTheme.paper.ignoresSafeArea())
                .navigationBarHidden(true)
            }
        }
    }

    private func content(plan: POPlan, idea: POIdea) -> some View {
        let days = POClock.daysBetween(POClock.todayKey, plan.dayKey)

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    POBackButton { presentationMode.wrappedValue.dismiss() }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    Text(idea.title)
                        .font(POFont.display(POScreen.isCompact ? 22 : 25))
                        .foregroundColor(POTheme.plumDeep)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        POGlyph(name: "calendar", size: 15, color: POTheme.plum, lineWidth: 1.7)
                        Text(POClock.longString(plan.dayKey)
                             + (plan.minuteOfDay.map { ", " + POClock.timeString($0) } ?? ""))
                            .font(POFont.body(13))
                            .foregroundColor(POTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(countdown(days))
                        .font(POFont.semibold(13))
                        .foregroundColor(days < 0 ? POTheme.terracotta : POTheme.teal)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                Text(idea.blurb)
                    .font(POFont.body(14.5))
                    .foregroundColor(POTheme.ink.opacity(0.88))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                if !idea.prep.isEmpty {
                    POSectionTitle(text: "Prep",
                                   accessory: "\(checkedCount(plan, idea)) of \(idea.prep.count)")
                    POCard {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(idea.prep.enumerated()), id: \.offset) { pair in
                                POCheckRow(text: pair.element,
                                           checked: plan.checkedPrep.contains(pair.offset)) {
                                    store.togglePrep(planID: plan.id, index: pair.offset)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }

                POSectionTitle(text: "Your notes")
                POCard {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Budget you are giving it")
                                .font(POFont.semibold(13))
                                .foregroundColor(POTheme.ink)
                            POTextField(placeholder: "Optional — e.g. 25",
                                        text: $budgetText,
                                        keyboard: .decimalPad,
                                        fieldID: 1,
                                        focused: $focusedField)
                            Text("Shown in \(store.currencySymbol). Nothing is charged and nothing leaves the phone.")
                                .font(POFont.body(11))
                                .foregroundColor(POTheme.inkFaint)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Anything to remember")
                                .font(POFont.semibold(13))
                                .foregroundColor(POTheme.ink)
                            POTextArea(placeholder: "Opening times, which entrance, what to take…",
                                       text: $notesText,
                                       minHeight: 92,
                                       fieldID: 2,
                                       focused: $focusedField)
                        }
                        POSecondaryButton(title: "Save notes", glyph: "check", color: POTheme.teal) {
                            focusedField = nil
                            saveNotes(plan)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                VStack(spacing: 10) {
                    POPrimaryButton(title: "I did it", glyph: "check", color: POTheme.teal) {
                        focusedField = nil
                        saveNotes(plan)
                        sheet = .reflect
                    }
                    POSecondaryButton(title: "Reschedule", glyph: "calendar") {
                        focusedField = nil
                        sheet = .reschedule
                    }
                    POSecondaryButton(title: "Cancel this plan", glyph: "trash", color: POTheme.terracotta) {
                        focusedField = nil
                        confirmCancel = true
                    }
                }
                .padding(.horizontal, 20)

                Color.clear.frame(height: 40)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            guard !loadedFromStore else { return }
            loadedFromStore = true
            budgetText = plan.plannedBudget.map { POFormat.money($0, symbol: "") } ?? ""
            notesText = plan.notes
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .reschedule:
                PODatePickerSheet(idea: idea,
                                  weekStartsMonday: store.weekStartsMonday,
                                  initialDayKey: plan.dayKey,
                                  initialMinute: plan.minuteOfDay) { dayKey, minute in
                    var updated = plan
                    updated.dayKey = dayKey
                    updated.minuteOfDay = minute
                    store.updatePlan(updated)
                    sheet = nil
                } onCancel: {
                    sheet = nil
                }
            case .reflect:
                POReflectionSheet(idea: idea,
                                  defaultDayKey: min(plan.dayKey, POClock.todayKey),
                                  suggestedSpend: plan.plannedBudget,
                                  currency: store.currencySymbol,
                                  promptSeed: store.entries.count,
                                  showConfetti: store.confettiOnDone) { entry in
                    // Close the sheet first: completing the plan removes it from the
                    // store, which tears down the view that owns this modifier.
                    sheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        store.completePlan(plan, with: entry)
                        presentationMode.wrappedValue.dismiss()
                    }
                } onCancel: {
                    sheet = nil
                }
            }
        }
        .alert(isPresented: $confirmCancel) {
            Alert(title: Text("Cancel this plan?"),
                  message: Text("It comes off the calendar. The idea stays in the deck and nothing is recorded as done."),
                  primaryButton: .destructive(Text("Cancel plan")) {
                      store.removePlan(id: plan.id)
                      presentationMode.wrappedValue.dismiss()
                  },
                  secondaryButton: .cancel(Text("Keep it")))
        }
    }

    private func checkedCount(_ plan: POPlan, _ idea: POIdea) -> Int {
        plan.checkedPrep.filter { $0 >= 0 && $0 < idea.prep.count }.count
    }

    private func countdown(_ days: Int) -> String {
        if days == 0 { return "That is today." }
        if days == 1 { return "That is tomorrow." }
        if days > 1 { return "In \(days) days." }
        if days == -1 { return "That was yesterday. Score it when you are ready." }
        return "That was \(-days) days ago. Score it when you are ready."
    }

    private func saveNotes(_ plan: POPlan) {
        var updated = plan
        updated.notes = notesText
        let cleaned = budgetText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: store.currencySymbol, with: "")
            .trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty {
            updated.plannedBudget = nil
        } else if let value = Double(cleaned), value.isFinite, value >= 0 {
            updated.plannedBudget = value
        }
        store.updatePlan(updated)
    }
}
