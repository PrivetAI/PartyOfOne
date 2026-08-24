import SwiftUI

struct POSettingsView: View {
    @EnvironmentObject var store: POStore
    @Binding var showOnboarding: Bool

    @State private var showPrivacy = false
    @State private var confirmReset = false

    private let currencyOptions = ["$", "£", "€", "¥", "kr", "zł", "₹", "R$", "A$", "C$"]

    var body: some View {
        let panelWidth = POScreen.width - 40

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                POScreenHeader(title: "Settings",
                               subtitle: "Everything here lives on this phone and nowhere else.")

                POSectionTitle(text: "Display")
                POCard {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Currency symbol")
                                .font(POFont.semibold(14))
                                .foregroundColor(POTheme.ink)
                            Text("Cosmetic only. The app does not convert anything and never touches a payment system.")
                                .font(POFont.body(11.5))
                                .foregroundColor(POTheme.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                            POWrapRow(items: currencyItems,
                                      width: panelWidth - 32,
                                      spacing: 7,
                                      estimatedItemWidth: { max(50, POText.pillWidth($0.symbol, hasGlyph: false)) }) { item in
                                POFilterPill(label: item.symbol,
                                             selected: store.currencySymbol == item.symbol,
                                             color: POTheme.gold) {
                                    store.currencySymbol = item.symbol
                                }
                            }
                        }
                        Rectangle().fill(POTheme.hairline).frame(height: 1)
                        POToggleRow(title: "Weeks start on Monday",
                                    subtitle: "Used by the streak counter and the month grid.",
                                    isOn: Binding(get: { store.weekStartsMonday },
                                                  set: { store.weekStartsMonday = $0 }))
                        Rectangle().fill(POTheme.hairline).frame(height: 1)
                        POToggleRow(title: "Confetti when you file an outing",
                                    subtitle: "Drawn, briefly, and then it goes away.",
                                    isOn: Binding(get: { store.confettiOnDone },
                                                  set: { store.confettiOnDone = $0 }))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POSectionTitle(text: "The draw")
                POCard {
                    VStack(alignment: .leading, spacing: 14) {
                        POToggleRow(title: "Push recent repeats down the deck",
                                    subtitle: "Anything done in the last sixty days becomes much less likely, without disappearing.",
                                    isOn: Binding(get: { store.deprioritiseRecent },
                                                  set: { store.deprioritiseRecent = $0 }))
                        Rectangle().fill(POTheme.hairline).frame(height: 1)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Saved filters")
                                .font(POFont.semibold(14))
                                .foregroundColor(POTheme.ink)
                            if store.filters.isEmpty {
                                Text("No filters set. The Draw tab is working with all \(POContent.count) outings.")
                                    .font(POFont.body(12.5))
                                    .foregroundColor(POTheme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("\(store.filters.activeCount) filter\(store.filters.activeCount == 1 ? "" : "s") are carried between sessions. They live on the Draw tab.")
                                    .font(POFont.body(12.5))
                                    .foregroundColor(POTheme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                POSecondaryButton(title: "Clear saved filters", glyph: "close",
                                                  color: POTheme.terracotta) {
                                    store.filters = POFilters()
                                }
                            }
                        }
                        Rectangle().fill(POTheme.hairline).frame(height: 1)
                        NavigationLink(destination: PONotForMeView()) {
                            HStack(spacing: 10) {
                                POGlyph(name: "close", size: 17, color: POTheme.terracotta, lineWidth: 1.8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Not for me")
                                        .font(POFont.semibold(14))
                                        .foregroundColor(POTheme.ink)
                                    Text(store.notForMe.isEmpty
                                         ? "Nothing excluded"
                                         : "\(store.notForMe.count) idea\(store.notForMe.count == 1 ? "" : "s") excluded from draws")
                                        .font(POFont.body(11.5))
                                        .foregroundColor(POTheme.inkSoft)
                                }
                                Spacer(minLength: 0)
                                POGlyph(name: "chevron", size: 13, color: POTheme.inkFaint, lineWidth: 1.8)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POSectionTitle(text: "About")
                POCard {
                    VStack(alignment: .leading, spacing: 12) {
                        settingsAction(glyph: "cards", title: "How this app works",
                                       subtitle: "Re-open the five-card explainer.") {
                            showOnboarding = true
                        }
                        Rectangle().fill(POTheme.hairline).frame(height: 1)
                        NavigationLink(destination: POAboutView()) {
                            HStack(spacing: 10) {
                                POGlyph(name: "table", size: 17, color: POTheme.plum, lineWidth: 1.7)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("What this app believes")
                                        .font(POFont.semibold(14))
                                        .foregroundColor(POTheme.ink)
                                    Text("The short version, and the numbers behind it.")
                                        .font(POFont.body(11.5))
                                        .foregroundColor(POTheme.inkSoft)
                                }
                                Spacer(minLength: 0)
                                POGlyph(name: "chevron", size: 13, color: POTheme.inkFaint, lineWidth: 1.8)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Rectangle().fill(POTheme.hairline).frame(height: 1)
                        settingsAction(glyph: "book", title: "Privacy Policy",
                                       subtitle: "Opens in a panel inside the app.") {
                            showPrivacy = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POSectionTitle(text: "Data")
                POCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            POStatTile(value: "\(store.entries.count)", label: "Entries", color: POTheme.plum)
                            POStatTile(value: "\(store.plans.count)", label: "Plans", color: POTheme.teal)
                            POStatTile(value: "\(store.notForMe.count)", label: "Excluded", color: POTheme.terracotta)
                        }
                        Text("All of it is stored on this device. Nothing is uploaded, nothing is shared, and there is no account to make.")
                            .font(POFont.body(12))
                            .foregroundColor(POTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        POSecondaryButton(title: "Reset all data", glyph: "trash", color: POTheme.terracotta) {
                            confirmReset = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                Text("Party of One · version 1.0\n\(POContent.count) outings · \(POContent.collections.count) collections · \(POContent.prompts.count) prompts")
                    .font(POFont.body(11))
                    .foregroundColor(POTheme.inkFaint)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                Color.clear.frame(height: 30)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showPrivacy) {
            POWebPanel(urlString: "https://partiesofone.org/click.php")
                .edgesIgnoringSafeArea(.bottom)   // never .all
        }
        .alert(isPresented: $confirmReset) {
            Alert(title: Text("Reset everything?"),
                  message: Text("Every plan, every journal entry, every excluded idea and every setting goes back to how the app arrived. The welcome tour stays behind you — it will not run again. It cannot be undone."),
                  primaryButton: .destructive(Text("Reset")) {
                      store.resetEverything()
                  },
                  secondaryButton: .cancel(Text("Keep my data")))
        }
    }

    private struct CurrencyItem: Identifiable {
        let id: Int
        let symbol: String
    }

    private var currencyItems: [CurrencyItem] {
        currencyOptions.enumerated().map { CurrencyItem(id: $0.offset, symbol: $0.element) }
    }

    private func settingsAction(glyph: String,
                                title: String,
                                subtitle: String,
                                action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                POGlyph(name: glyph, size: 17, color: POTheme.plum, lineWidth: 1.7)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(POFont.semibold(14))
                        .foregroundColor(POTheme.ink)
                    Text(subtitle)
                        .font(POFont.body(11.5))
                        .foregroundColor(POTheme.inkSoft)
                }
                Spacer(minLength: 0)
                POGlyph(name: "chevron", size: 13, color: POTheme.inkFaint, lineWidth: 1.8)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Not for me

struct PONotForMeView: View {
    @EnvironmentObject var store: POStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    POBackButton { presentationMode.wrappedValue.dismiss() }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 10)

                POScreenHeader(title: "Not for me",
                               subtitle: "Ideas you have taken out of the deck. Nothing here is judged and everything here can go back.")

                if excluded.isEmpty {
                    POEmptyState(glyph: "check",
                                 title: "The whole deck is in play",
                                 message: "You have not excluded anything. If an idea keeps coming up and you keep ignoring it, open it and mark it Not for me — the draw will stop offering it.")
                } else {
                    VStack(spacing: 9) {
                        ForEach(excluded) { idea in
                            HStack(spacing: 11) {
                                POGlyph(name: POGlyphDrawing.settingGlyph(idea.setting),
                                        size: 19,
                                        color: POTheme.settingColor(idea.setting),
                                        lineWidth: 1.6)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(idea.title)
                                        .font(POFont.semibold(13.5))
                                        .foregroundColor(POTheme.ink)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(idea.tagLine)
                                        .font(POFont.body(11))
                                        .foregroundColor(POTheme.inkFaint)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Button(action: { store.restoreIdea(idea.id) }) {
                                    Text("Put back")
                                        .font(POFont.semibold(12))
                                        .foregroundColor(POTheme.teal)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 7)
                                        .background(Capsule().fill(POTheme.teal.opacity(0.12)))
                                        .contentShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(11)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(POTheme.card)
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(POTheme.hairline, lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    POSecondaryButton(title: "Put all \(excluded.count) back", glyph: "check", color: POTheme.teal) {
                        store.notForMe = []
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                Color.clear.frame(height: 30)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var excluded: [POIdea] {
        POContent.ideas.filter { store.notForMe.contains($0.id) }
    }
}

// MARK: - About

struct POAboutView: View {
    @EnvironmentObject var store: POStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    POBackButton { presentationMode.wrappedValue.dismiss() }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)

                HStack {
                    Spacer(minLength: 0)
                    POGlyph(name: "table", size: 76, color: POTheme.plumDeep, lineWidth: 1.8)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 16)

                Text("A table for one is a good table")
                    .font(POFont.display(POScreen.isCompact ? 24 : 27))
                    .foregroundColor(POTheme.plumDeep)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 14) {
                    paragraph("This app takes it as settled that time on your own is something worth planning properly, the same way you would plan an evening with anyone else. It is not a rehearsal, it is not a fallback, and it is not a self-improvement program.")
                    paragraph("So there are no streaks you can break, no daily targets, and no scolding when a month goes by empty. A blank month is a blank month.")
                    paragraph("What the app does do is keep score of what actually suits you. Four numbers after each outing, and after ten or so it can tell you something you did not already know — usually that the expensive ones were not the good ones, and that the tag you have been avoiding is the one you like best.")
                    paragraph("Every number on the You tab prints how many outings it is standing on. One good Tuesday is not a pattern and the app will not pretend otherwise.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                POSectionTitle(text: "What is in the box")
                POCard {
                    VStack(alignment: .leading, spacing: 9) {
                        factRow("Outings", "\(POContent.count)")
                        factRow("Collections", "\(POContent.collections.count)")
                        factRow("Reflection prompts", "\(POContent.prompts.count)")
                        factRow("Mood words", "\(POContent.moods.count)")
                        factRow("Tag axes", "\(POInsightAxis.allCases.count) scored, 7 total")
                        factRow("Network calls", "One, at launch. That is all.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POCard(tint: POTheme.paperDeep) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your data")
                            .font(POFont.semibold(14))
                            .foregroundColor(POTheme.ink)
                        Text("Plans, journal entries and settings are stored on this device only. There is no account, no sync, no analytics and nothing to opt out of.")
                            .font(POFont.body(12.5))
                            .foregroundColor(POTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 20)

                Color.clear.frame(height: 34)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(POFont.body(14.5))
            .foregroundColor(POTheme.ink.opacity(0.86))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func factRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(POFont.body(13))
                .foregroundColor(POTheme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(POFont.mono(13))
                .foregroundColor(POTheme.plumDeep)
        }
    }
}
