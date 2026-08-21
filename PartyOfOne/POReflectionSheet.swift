import SwiftUI

struct POReflectionSheet: View {
    let idea: POIdea
    let defaultDayKey: Int
    let suggestedSpend: Double?
    let currency: String
    let promptSeed: Int
    let showConfetti: Bool
    let onSave: (POEntry) -> Void
    let onCancel: () -> Void

    @State private var recharge = 3
    @State private var novelty = 3
    @State private var comfort = 3
    @State private var worth = 3
    @State private var mood: String = ""
    @State private var reflection: String = ""
    @State private var spentText: String = ""
    @State private var promptIndex: Int = 0
    @State private var focusedField: Int?
    @State private var celebrating = false
    @State private var confettiProgress: Double = 0
    @State private var primed = false

    var body: some View {
        ZStack {
            POTheme.paper.ignoresSafeArea()
            if celebrating {
                celebration
            } else {
                form
            }
            if celebrating && showConfetti {
                POConfetti(progress: confettiProgress, seed: promptSeed + 3)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: Form

    private var form: some View {
        let panelWidth = POScreen.width - 40

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How was it?")
                            .font(POFont.display(24))
                            .foregroundColor(POTheme.plumDeep)
                        Text(idea.title)
                            .font(POFont.body(13))
                            .foregroundColor(POTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    POGlyphButton(glyph: "close", size: 18, color: POTheme.inkSoft, action: onCancel)
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 16)

                POCard {
                    VStack(alignment: .leading, spacing: 18) {
                        POScoreSlider(title: "Recharge",
                                      caption: rechargeCaption,
                                      value: $recharge,
                                      color: POTheme.teal)
                        POScoreSlider(title: "Novelty",
                                      caption: noveltyCaption,
                                      value: $novelty,
                                      color: POTheme.terracotta)
                        POScoreSlider(title: "Comfort",
                                      caption: comfortCaption,
                                      value: $comfort,
                                      color: POTheme.plum)
                        POScoreSlider(title: "Worth the cost",
                                      caption: worthCaption,
                                      value: $worth,
                                      color: POTheme.gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                HStack(spacing: 14) {
                    PORadar(recharge: recharge, novelty: novelty, comfort: comfort, worth: worth,
                            side: POScreen.isCompact ? 96 : 110, showLabels: true)
                    Text("Recharge is the one the You tab ranks everything by. Be honest with it and the app gets useful faster.")
                        .font(POFont.body(12))
                        .foregroundColor(POTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                POSectionTitle(text: "One word for it")
                POCard(padding: 14) {
                    POWrapRow(items: moodItems,
                              width: panelWidth - 28,
                              spacing: 7,
                              estimatedItemWidth: { POText.pillWidth($0.word, hasGlyph: false) }) { item in
                        POFilterPill(label: item.word,
                                     selected: mood == item.word,
                                     color: POTheme.plum) {
                            mood = (mood == item.word) ? "" : item.word
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POSectionTitle(text: "The question")
                POCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(POContent.prompt(promptIndex))
                                .font(POFont.title(16))
                                .foregroundColor(POTheme.plumDeep)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button(action: { promptIndex += 1 }) {
                                POGlyph(name: "shuffle", size: 17, color: POTheme.plum, lineWidth: 1.7)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(POTheme.plum.opacity(0.10)))
                                    .contentShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        POTextArea(placeholder: "As much or as little as you like.",
                                   text: $reflection,
                                   minHeight: 110,
                                   fieldID: 1,
                                   focused: $focusedField)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POSectionTitle(text: "What it actually cost")
                POCard {
                    VStack(alignment: .leading, spacing: 8) {
                        POTextField(placeholder: "0",
                                    text: $spentText,
                                    keyboard: .decimalPad,
                                    fieldID: 2,
                                    focused: $focusedField)
                        if let suggested = suggestedSpend {
                            Text("You budgeted \(POFormat.money(suggested, symbol: currency)) for it.")
                                .font(POFont.body(11))
                                .foregroundColor(POTheme.inkFaint)
                        } else {
                            Text("Leave it at nothing if it was free. Free is allowed to score five.")
                                .font(POFont.body(11))
                                .foregroundColor(POTheme.inkFaint)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                POPrimaryButton(title: "File it", glyph: "check", color: POTheme.teal) {
                    focusedField = nil
                    save()
                }
                .padding(.horizontal, 20)

                Color.clear.frame(height: 36)
            }
        }
        .onAppear {
            guard !primed else { return }
            primed = true
            promptIndex = promptSeed
            if let suggested = suggestedSpend, suggested > 0 {
                spentText = POFormat.money(suggested, symbol: "")
            }
        }
    }

    // MARK: Celebration

    private var celebration: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(POTheme.gold.opacity(0.16))
                    .frame(width: 140, height: 140)
                POGlyph(name: "table", size: 80, color: POTheme.plumDeep, lineWidth: 1.8)
            }
            Text("Filed")
                .font(POFont.display(30))
                .foregroundColor(POTheme.plumDeep)
            Text(closingLine)
                .font(POFont.body(15))
                .foregroundColor(POTheme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 34)
            Spacer(minLength: 0)
        }
    }

    private var closingLine: String {
        switch recharge {
        case 5: return "Five out of five. Whatever that was, do it again."
        case 4: return "That one went well. It is now part of the pattern."
        case 3: return "Perfectly decent. Not every outing has to be a revelation."
        case 2: return "Noted, without judgement. The tags remember so you do not have to."
        default: return "Filed anyway. A dud is data too, and it stops you repeating it."
        }
    }

    // MARK: Captions

    private var rechargeCaption: String {
        switch recharge {
        case 1: return "More tired than before"
        case 2: return "Not much left in it"
        case 3: return "Levelled out"
        case 4: return "Noticeably better"
        default: return "Completely restored"
        }
    }

    private var noveltyCaption: String {
        switch novelty {
        case 1: return "Done it a hundred times"
        case 2: return "Familiar ground"
        case 3: return "A new version of a known thing"
        case 4: return "Mostly unfamiliar"
        default: return "Never done anything like it"
        }
    }

    private var comfortCaption: String {
        switch comfort {
        case 1: return "Squirmed the whole time"
        case 2: return "Took a while to settle"
        case 3: return "Fine once started"
        case 4: return "Easy going"
        default: return "Completely at home"
        }
    }

    private var worthCaption: String {
        switch worth {
        case 1: return "Not worth what it cost"
        case 2: return "A bit steep"
        case 3: return "Fair enough"
        case 4: return "Good value"
        default: return "Would pay double"
        }
    }

    private struct MoodItem: Identifiable {
        let id: Int
        let word: String
    }

    private var moodItems: [MoodItem] {
        POContent.moods.enumerated().map { MoodItem(id: $0.offset, word: $0.element) }
    }

    // MARK: Save

    private func save() {
        let cleaned = spentText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: currency, with: "")
            .trimmingCharacters(in: .whitespaces)
        var spent: Double = 0
        if let value = Double(cleaned), value.isFinite, value >= 0 { spent = value }

        let entry = POEntry(ideaID: idea.id,
                            dayKey: defaultDayKey,
                            recharge: recharge,
                            novelty: novelty,
                            comfort: comfort,
                            worth: worth,
                            mood: mood,
                            promptID: promptIndex,
                            reflection: reflection.trimmingCharacters(in: .whitespacesAndNewlines),
                            spent: spent)

        withAnimation(.easeOut(duration: 0.25)) { celebrating = true }
        withAnimation(.linear(duration: 1.5)) { confettiProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            onSave(entry)
        }
    }
}
