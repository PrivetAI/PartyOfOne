import Foundation

/// Facade over the two library halves plus the collections, moods and prompts.
enum POContent {

    static let ideas: [POIdea] = POLibraryA.all + POLibraryB.all

    private static let index: [String: POIdea] = {
        var map: [String: POIdea] = [:]
        for idea in ideas { map[idea.id] = idea }
        return map
    }()

    static func idea(_ id: String) -> POIdea? { index[id] }

    static func ideas(_ ids: [String]) -> [POIdea] { ids.compactMap { index[$0] } }

    static var count: Int { ideas.count }

    // MARK: - Mood words

    static let moods: [String] = [
        "Calm", "Charged", "Content", "Curious",
        "Dreamy", "Elated", "Grounded", "Light",
        "Pensive", "Proud", "Quiet", "Restored",
        "Restless", "Softened", "Sparky", "Wistful"
    ]

    // MARK: - Reflection prompts

    static let prompts: [String] = [
        "What surprised you?",
        "When did you stop checking your phone?",
        "What was the best ten minutes of it?",
        "Was there a moment you nearly went home early?",
        "What did you notice that you would have missed with company?",
        "What would you change if you did it again?",
        "What did it cost, and was that the right amount?",
        "What was harder than you expected?",
        "What was easier than you expected?",
        "Describe one thing you saw in enough detail to remember it.",
        "Did you speak to anyone? How did that go?",
        "What did you take home with you, literal or otherwise?",
        "When did time start moving differently?",
        "What was the first thing you did on arriving?",
        "Would you want this again in a different season?",
        "What did you eat, and where?",
        "What did it sound like?",
        "Was there a part you did only out of loyalty to the plan?",
        "What did you learn that you had not set out to learn?",
        "With two more hours, what would you have done?",
        "What one small thing would you tell your future self about today?",
        "Did it turn out to be the kind of day you needed?",
        "What was the weather doing, and did it matter?",
        "What would you tell someone who was thinking of trying this?"
    ]

    static func prompt(_ index: Int) -> String {
        guard !prompts.isEmpty else { return "How was it?" }
        let i = ((index % prompts.count) + prompts.count) % prompts.count
        return prompts[i]
    }

    // MARK: - Collections

    static let collections: [POCollection] = [
        POCollection(
            id: "cheap-thrills",
            name: "Cheap Thrills",
            intro: "Ten outings that cost nothing, or near enough — the dearest of them is a bus fare. Not budget versions of better days: these are the ones that would not improve if you threw money at them.",
            badgeName: "coin",
            ideaIDs: [
                "out-last-stop", "city-lost-deliberate", "out-dawn-walk", "home-window-hour",
                "city-department-store", "out-tree-sit", "move-dance-kitchen", "cult-one-painting",
                "food-pantry-challenge", "out-sunset-spot"
            ]),

        POCollection(
            id: "winter-indoors",
            name: "Winter Indoors",
            intro: "For the stretch of the year when it is dark at four and the sensible answer is to stay in. Staying in on purpose is a completely different thing from staying in by default.",
            badgeName: "flame",
            ideaIDs: [
                "home-jigsaw-night", "home-bath-book", "food-bread-bake", "home-blanket-double",
                "make-model-kit", "home-sleep-early", "water-sauna-plunge", "home-map-wall",
                "cult-cathedral-sit", "home-tasting-flight"
            ]),

        POCollection(
            id: "no-screen",
            name: "A Day Without a Screen",
            intro: "Nine outings that work better with the phone in a drawer. No purity test attached — take it for the map home if you need to. Just do not take it for company.",
            badgeName: "eye",
            ideaIDs: [
                "home-record-side", "out-orienteer", "cult-poetry-memorise", "home-letter-past",
                "cult-museum-sketch", "out-birdwatch-hour", "make-draw-100", "city-library-day",
                "move-run-new-route"
            ]),

        POCollection(
            id: "culture-month",
            name: "Culture Month",
            intro: "Ten ways into the arts that do not require you to have an opinion first. Cheap seats, quiet rooms, and the standing ticket that costs less than a takeaway.",
            badgeName: "arch",
            ideaIDs: [
                "cult-one-painting", "cult-concert-cheap", "cult-museum-weird", "cult-foreign-film",
                "cult-opera-standing", "cult-gallery-late", "cult-open-mic", "cult-play-solo",
                "cult-dance-watch", "cult-lecture-public"
            ]),

        POCollection(
            id: "nine-walks",
            name: "Nine Walks",
            intro: "Nine different reasons to leave the house on foot. Same legs, nine completely different afternoons.",
            badgeName: "path",
            ideaIDs: [
                "out-last-stop", "city-one-street", "move-walk-night", "out-park-full-lap",
                "move-walk-alphabet", "cult-sculpture-walk", "water-river-walk", "move-walk-water",
                "out-rain-walk"
            ]),

        POCollection(
            id: "make-something",
            name: "Make Something",
            intro: "Ten outings that end with an object. It does not have to be good. It has to exist, and it has to have been made by you on a day you chose.",
            badgeName: "hand",
            ideaIDs: [
                "make-zine", "make-terrarium", "make-print-block", "make-mend-visible",
                "make-bread-board", "make-pottery-class", "make-shelf-build", "food-fermentation",
                "make-recipe-own", "make-candle-dye"
            ]),

        POCollection(
            id: "water",
            name: "Water",
            intro: "Ten outings organized entirely around being near, on or in it. Water fixes an unreasonable number of things and asks very little in return.",
            badgeName: "wave",
            ideaIDs: [
                "water-cold-swim", "water-lido-lengths", "water-ferry-cheap", "water-rockpool",
                "water-tide-watch", "water-harbour-boats", "water-paddle-hire", "water-fountain-sit",
                "move-swim-lake", "water-boat-trip"
            ]),

        POCollection(
            id: "first-time",
            name: "First Time Alone",
            intro: "If turning up somewhere by yourself still feels like a stunt, start here. Nine outings where arriving alone is completely unremarkable and nobody will look up.",
            badgeName: "door",
            ideaIDs: [
                "city-cinema-afternoon", "food-magazine-cafe", "city-library-day", "city-hotel-lobby",
                "cult-gallery-late", "food-breakfast-out", "city-station-watch", "move-swim-early",
                "city-record-shop"
            ]),

        POCollection(
            id: "reset-weekend",
            name: "Reset Weekend",
            intro: "Eight outings for when the week has been long and you would like the next one to start differently. Slow, cheap, mostly quiet.",
            badgeName: "leaf",
            ideaIDs: [
                "home-shelf-tea", "out-hill-nothing", "move-stretch-hour", "home-inbox-zero-ritual",
                "home-sleep-early", "out-dawn-walk", "home-floor-picnic", "home-desk-rearrange"
            ]),

        POCollection(
            id: "small-luxuries",
            name: "Small Luxuries",
            intro: "Nine outings that cost real money and are worth it anyway. A table for one at a good restaurant is not a consolation prize — it is the best seat in the house and it is yours.",
            badgeName: "gem",
            ideaIDs: [
                "food-counter-dinner", "city-hotel-night", "food-tasting-menu", "water-hot-springs",
                "city-viewpoint-paid", "food-cocktail-one", "cult-vinyl-listening", "city-stationery-splurge",
                "food-picnic-cheese"
            ]),
    ]

    static func collection(_ id: String) -> POCollection? {
        collections.first { $0.id == id }
    }

    // MARK: - Onboarding pages

    struct POOnboardPage: Identifiable {
        let id: Int
        let title: String
        let body: String
        let art: String
    }

    static let onboarding: [POOnboardPage] = [
        POOnboardPage(id: 0,
                      title: "A table for one is a good table",
                      body: "Party of One keeps a list of things worth doing on your own, and a record of which of them actually suited you. That second part is the useful bit — nobody else can work it out for you.",
                      art: "table"),
        POOnboardPage(id: 1,
                      title: "Deal, don't browse",
                      body: "Set your constraints — money, hours, energy, how much company you can face — and the app deals you three cards. Three is enough to choose from and few enough to actually choose.",
                      art: "cards"),
        POOnboardPage(id: 2,
                      title: "Then commit to one",
                      body: "Pick a card, give it a date, and it moves to Plans with its own prep list. A plan with a date on it is a different animal from an idea in a list.",
                      art: "calendar"),
        POOnboardPage(id: 3,
                      title: "Score it honestly afterwards",
                      body: "Four sliders when you get home: how recharged you feel, how new it was, how comfortable, and whether it was worth what it cost. Thirty seconds of honesty each time.",
                      art: "sliders"),
        POOnboardPage(id: 4,
                      title: "The pattern shows up around outing ten",
                      body: "The You tab ranks every tag by your own average Recharge score and prints the sample count beside it, so a single good Tuesday can never masquerade as a pattern.",
                      art: "bars"),
    ]
}
