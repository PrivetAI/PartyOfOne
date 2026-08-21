import SwiftUI

enum POTab: Int, CaseIterable {
    case draw, plans, journal, you, settings

    var title: String {
        switch self {
        case .draw: return "Draw"
        case .plans: return "Plans"
        case .journal: return "Journal"
        case .you: return "You"
        case .settings: return "Settings"
        }
    }

    var glyph: String {
        switch self {
        case .draw: return "cards"
        case .plans: return "calendar"
        case .journal: return "book"
        case .you: return "bars"
        case .settings: return "dial"
        }
    }

    /// The dial and the bar glyphs read badly when filled, so they stay outlined
    /// even when their tab is selected.
    var prefersFilledWhenSelected: Bool {
        switch self {
        case .settings, .you: return false
        default: return true
        }
    }
}

struct PORootView: View {
    @EnvironmentObject var store: POStore
    @State private var tab: POTab = .draw
    @State private var showOnboarding = false
    /// Set by the You tab's blind-spot shortcut, consumed by the Draw tab.
    @State private var pendingDrawRequest: POFilters?

    var body: some View {
        ZStack(alignment: .top) {
            POTheme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .draw:
                        NavigationView { PODrawView(pendingRequest: $pendingDrawRequest) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case .plans:
                        NavigationView { POPlansView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case .journal:
                        NavigationView { POJournalView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case .you:
                        NavigationView { POYouView(tab: $tab, pendingRequest: $pendingDrawRequest) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case .settings:
                        NavigationView { POSettingsView(showOnboarding: $showOnboarding) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                POTabBar(tab: $tab)
            }

            // LAST sibling: paints over anything scrolling up under the clock.
            POStatusStrip()
        }
        .sheet(isPresented: $showOnboarding, onDismiss: {
            // Covers the swipe-down dismissal too, which never reaches onFinish.
            store.hasOnboarded = true
        }) {
            POOnboardingView(onFinish: {
                showOnboarding = false
                store.hasOnboarded = true
            })
        }
        .onAppear {
            if !store.hasOnboarded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showOnboarding = true
                }
            }
        }
    }
}

struct POTabBar: View {
    @Binding var tab: POTab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(POTheme.hairline)
                .frame(height: 1)
            HStack(spacing: 0) {
                ForEach(POTab.allCases, id: \.rawValue) { item in
                    Button(action: {
                        if tab != item {
                            withAnimation(.easeOut(duration: 0.14)) { tab = item }
                        }
                    }) {
                        VStack(spacing: 4) {
                            POGlyph(name: item.glyph,
                                    size: 23,
                                    color: tab == item ? POTheme.plum : POTheme.inkFaint,
                                    lineWidth: 1.7,
                                    filled: tab == item && item.prefersFilledWhenSelected)
                            Text(item.title)
                                .font(POFont.semibold(10))
                                .foregroundColor(tab == item ? POTheme.plum : POTheme.inkFaint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 9)
                        .padding(.bottom, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(POTheme.card.edgesIgnoringSafeArea(.bottom))
    }
}
