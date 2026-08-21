import SwiftUI

struct POEntryDetailView: View {
    @EnvironmentObject var store: POStore
    @Environment(\.presentationMode) private var presentationMode
    let entryID: String

    @State private var editing = false
    @State private var recharge = 3
    @State private var novelty = 3
    @State private var comfort = 3
    @State private var worth = 3
    @State private var mood = ""
    @State private var reflection = ""
    @State private var spentText = ""
    @State private var focusedField: Int?
    @State private var confirmDelete = false
    @State private var primed = false

    private var entry: POEntry? { store.entries.first { $0.id == entryID } }

    var body: some View {
        Group {
            if let entry = entry {
                content(entry)
            } else {
                VStack(spacing: 16) {
                    POEmptyState(glyph: "book",
                                 title: "Deleted",
                                 message: "That entry is no longer in your journal.")
                    POSecondaryButton(title: "Back") { presentationMode.wrappedValue.dismiss() }
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(POTheme.paper.ignoresSafeArea())
                .navigationBarHidden(true)
            }
        }
    }

    private func content(_ entry: POEntry) -> some View {
        let idea = POContent.idea(entry.ideaID)
        let panelWidth = POScreen.width - 40

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    POBackButton { presentationMode.wrappedValue.dismiss() }
                    Spacer(minLength: 0)
                    Button(action: {
                        if editing {
                            commit(entry)
                        } else {
                            load(entry)
                        }
                        withAnimation(.easeOut(duration: 0.2)) { editing.toggle() }
                    }) {
                        HStack(spacing: 5) {
                            POGlyph(name: editing ? "check" : "pencil", size: 14,
                                    color: editing ? POTheme.teal : POTheme.plum, lineWidth: 1.8)
                            Text(editing ? "Save" : "Edit")
                                .font(POFont.semibold(14))
                                .foregroundColor(editing ? POTheme.teal : POTheme.plum)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill((editing ? POTheme.teal : POTheme.plum).opacity(0.10)))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 5) {
                    Text(idea?.title ?? "An outing")
                        .font(POFont.display(POScreen.isCompact ? 22 : 25))
                        .foregroundColor(POTheme.plumDeep)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(POClock.longString(entry.dayKey))
                        .font(POFont.body(13))
                        .foregroundColor(POTheme.inkSoft)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                if let idea = idea {
                    POWrapRow(items: chipItems(idea),
                              width: panelWidth,
                              spacing: 6,
                              estimatedItemWidth: { POText.chipWidth($0.text, hasGlyph: $0.glyph != nil, compact: true) }) { item in
                        POChip(text: item.text, color: item.color, glyph: item.glyph, compact: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                if editing {
                    editingBody(entry, panelWidth: panelWidth)
                } else {
                    readingBody(entry, panelWidth: panelWidth)
                }

                Color.clear.frame(height: 40)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            guard !primed else { return }
            primed = true
            load(entry)
        }
        .alert(isPresented: $confirmDelete) {
            Alert(title: Text("Delete this entry?"),
                  message: Text("The outing stops counting towards your profile and your collections. This cannot be undone."),
                  primaryButton: .destructive(Text("Delete")) {
                      store.deleteEntry(id: entry.id)
                      presentationMode.wrappedValue.dismiss()
                  },
                  secondaryButton: .cancel(Text("Keep it")))
        }
    }

    // MARK: Reading

    private func readingBody(_ entry: POEntry, panelWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            POCard {
                HStack(alignment: .center, spacing: 16) {
                    PORadar(recharge: entry.recharge, novelty: entry.novelty,
                            comfort: entry.comfort, worth: entry.worth,
                            side: POScreen.isCompact ? 100 : 118, showLabels: true)
                    VStack(alignment: .leading, spacing: 7) {
                        POScorePips(label: "Recharge", value: entry.recharge, color: POTheme.teal)
                        POScorePips(label: "Novelty", value: entry.novelty, color: POTheme.terracotta)
                        POScorePips(label: "Comfort", value: entry.comfort, color: POTheme.plum)
                        POScorePips(label: "Worth", value: entry.worth, color: POTheme.gold)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            HStack(spacing: 10) {
                POStatTile(value: entry.mood.isEmpty ? "—" : entry.mood, label: "Mood", color: POTheme.plum)
                POStatTile(value: POFormat.money(entry.spent, symbol: store.currencySymbol),
                           label: "Spent", color: POTheme.gold)
                POStatTile(value: POFormat.score(entry.averageScore), label: "Mean of four", color: POTheme.teal)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

            POSectionTitle(text: "The question")
            POCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(POContent.prompt(entry.promptID))
                        .font(POFont.title(16))
                        .foregroundColor(POTheme.plumDeep)
                        .fixedSize(horizontal: false, vertical: true)
                    if entry.reflection.isEmpty {
                        Text("You left this one blank. Entirely allowed.")
                            .font(POFont.body(13))
                            .foregroundColor(POTheme.inkFaint)
                    } else {
                        Text(entry.reflection)
                            .font(POFont.body(15))
                            .foregroundColor(POTheme.ink.opacity(0.88))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

            POSecondaryButton(title: "Delete this entry", glyph: "trash", color: POTheme.terracotta) {
                confirmDelete = true
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Editing

    private func editingBody(_ entry: POEntry, panelWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            POCard {
                VStack(alignment: .leading, spacing: 18) {
                    POScoreSlider(title: "Recharge", caption: "1 drained, 5 restored",
                                  value: $recharge, color: POTheme.teal)
                    POScoreSlider(title: "Novelty", caption: "1 familiar, 5 brand new",
                                  value: $novelty, color: POTheme.terracotta)
                    POScoreSlider(title: "Comfort", caption: "1 squirming, 5 at home",
                                  value: $comfort, color: POTheme.plum)
                    POScoreSlider(title: "Worth the cost", caption: "1 not worth it, 5 would pay double",
                                  value: $worth, color: POTheme.gold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            POSectionTitle(text: "Mood")
            POCard(padding: 14) {
                POWrapRow(items: moodItems,
                          width: panelWidth - 28,
                          spacing: 7,
                          estimatedItemWidth: { POText.pillWidth($0.word, hasGlyph: false) }) { item in
                    POFilterPill(label: item.word, selected: mood == item.word, color: POTheme.plum) {
                        mood = (mood == item.word) ? "" : item.word
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            POSectionTitle(text: "What you wrote")
            POCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(POContent.prompt(entry.promptID))
                        .font(POFont.title(15))
                        .foregroundColor(POTheme.plumDeep)
                        .fixedSize(horizontal: false, vertical: true)
                    POTextArea(placeholder: "As much or as little as you like.",
                               text: $reflection,
                               minHeight: 120,
                               fieldID: 1,
                               focused: $focusedField)
                    Text("Amount spent")
                        .font(POFont.semibold(13))
                        .foregroundColor(POTheme.ink)
                    POTextField(placeholder: "0",
                                text: $spentText,
                                keyboard: .decimalPad,
                                fieldID: 2,
                                focused: $focusedField)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            POPrimaryButton(title: "Save changes", glyph: "check", color: POTheme.teal) {
                focusedField = nil
                commit(entry)
                withAnimation(.easeOut(duration: 0.2)) { editing = false }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: State plumbing

    private func load(_ entry: POEntry) {
        recharge = entry.recharge
        novelty = entry.novelty
        comfort = entry.comfort
        worth = entry.worth
        mood = entry.mood
        reflection = entry.reflection
        spentText = entry.spent > 0 ? POFormat.money(entry.spent, symbol: "") : ""
    }

    private func commit(_ entry: POEntry) {
        var updated = entry
        updated.recharge = max(1, min(5, recharge))
        updated.novelty = max(1, min(5, novelty))
        updated.comfort = max(1, min(5, comfort))
        updated.worth = max(1, min(5, worth))
        updated.mood = mood
        updated.reflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = spentText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: store.currencySymbol, with: "")
            .trimmingCharacters(in: .whitespaces)
        if let value = Double(cleaned), value.isFinite, value >= 0 {
            updated.spent = value
        } else if cleaned.isEmpty {
            updated.spent = 0
        }
        store.updateEntry(updated)
    }

    private struct MoodItem: Identifiable {
        let id: Int
        let word: String
    }

    private var moodItems: [MoodItem] {
        POContent.moods.enumerated().map { MoodItem(id: $0.offset, word: $0.element) }
    }

    private struct ChipItem: Identifiable {
        let id: Int
        let text: String
        let color: Color
        let glyph: String?
    }

    private func chipItems(_ idea: POIdea) -> [ChipItem] {
        [
            ChipItem(id: 0, text: idea.setting.label, color: POTheme.settingColor(idea.setting),
                     glyph: POGlyphDrawing.settingGlyph(idea.setting)),
            ChipItem(id: 1, text: idea.energy.label, color: POTheme.energyColor(idea.energy), glyph: nil),
            ChipItem(id: 2, text: idea.duration.label, color: POTheme.plum, glyph: "clock"),
            ChipItem(id: 3, text: idea.budget.label, color: POTheme.budgetColor(idea.budget), glyph: "coin"),
            ChipItem(id: 4, text: idea.exposure.label, color: POTheme.exposureColor(idea.exposure),
                     glyph: POGlyphDrawing.exposureGlyph(idea.exposure)),
        ]
    }
}
