import SwiftUI

struct POCollectionDetailView: View {
    @EnvironmentObject var store: POStore
    @Environment(\.presentationMode) private var presentationMode
    let collectionID: String

    var body: some View {
        Group {
            if let collection = POContent.collection(collectionID) {
                content(collection)
            } else {
                POEmptyState(glyph: "gem", title: "Not found", message: "That collection is no longer in the app.")
                    .background(POTheme.paper.ignoresSafeArea())
                    .navigationBarHidden(true)
            }
        }
    }

    private func content(_ collection: POCollection) -> some View {
        let panelWidth = POScreen.width - 40
        let ideas = POContent.ideas(collection.ideaIDs)
        let done = store.doneIdeaIDs
        let progress = store.collectionProgress(collection)
        let complete = store.isCollectionComplete(collection)
        let accent = accentColor(collection)

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    POBackButton { presentationMode.wrappedValue.dismiss() }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                POCollectionArt(seedText: collection.id,
                                accent: accent,
                                glyph: collection.badgeName,
                                width: panelWidth,
                                height: POScreen.isCompact ? 96 : 118)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                Text(collection.name)
                    .font(POFont.display(POScreen.isCompact ? 24 : 27))
                    .foregroundColor(POTheme.plumDeep)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                Text(collection.intro)
                    .font(POFont.body(15))
                    .foregroundColor(POTheme.ink.opacity(0.86))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                POCard(tint: complete ? POTheme.gold.opacity(0.12) : POTheme.card) {
                    HStack(spacing: 14) {
                        POBadgeView(glyph: collection.badgeName, earned: complete, size: 54)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(complete ? "Badge earned" : "\(progress.done) of \(progress.total) done")
                                .font(POFont.title(17))
                                .foregroundColor(complete ? POTheme.gold : POTheme.plumDeep)
                            Text(complete
                                 ? "All of them, filed and scored. The badge is yours and it stays."
                                 : "\(progress.total - progress.done) to go. There is no time limit and no streak to break.")
                                .font(POFont.body(12.5))
                                .foregroundColor(POTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                POSectionTitle(text: "The set", accessory: "\(ideas.count)")
                VStack(spacing: 9) {
                    ForEach(ideas) { idea in
                        NavigationLink(destination: POIdeaDetailView(idea: idea)) {
                            HStack(spacing: 11) {
                                ZStack {
                                    Circle()
                                        .fill(done.contains(idea.id)
                                              ? POTheme.teal
                                              : POTheme.settingColor(idea.setting).opacity(0.12))
                                    if done.contains(idea.id) {
                                        POGlyph(name: "check", size: 16, color: POTheme.paper, lineWidth: 2.2)
                                    } else {
                                        POGlyph(name: POGlyphDrawing.settingGlyph(idea.setting),
                                                size: 17,
                                                color: POTheme.settingColor(idea.setting),
                                                lineWidth: 1.6)
                                    }
                                }
                                .frame(width: 34, height: 34)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(idea.title)
                                        .font(POFont.semibold(13.5))
                                        .foregroundColor(done.contains(idea.id) ? POTheme.inkSoft : POTheme.plumDeep)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(idea.tagLine)
                                        .font(POFont.body(11))
                                        .foregroundColor(POTheme.inkFaint)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                POGlyph(name: "chevron", size: 12, color: POTheme.inkFaint, lineWidth: 1.8)
                            }
                            .padding(11)
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
                .padding(.horizontal, 20)

                Color.clear.frame(height: 34)
            }
        }
        .background(POTheme.paper.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func accentColor(_ collection: POCollection) -> Color {
        switch collection.id {
        case "cheap-thrills": return POTheme.teal
        case "winter-indoors": return POTheme.terracotta
        case "no-screen": return POTheme.plumDeep
        case "culture-month": return POTheme.plum
        case "nine-walks": return Color(red: 0.478, green: 0.541, blue: 0.318)
        case "make-something": return POTheme.gold
        case "water": return Color(red: 0.243, green: 0.478, blue: 0.541)
        case "first-time": return POTheme.plumSoft
        case "reset-weekend": return Color(red: 0.400, green: 0.545, blue: 0.451)
        default: return POTheme.gold
        }
    }
}
