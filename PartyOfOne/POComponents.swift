import SwiftUI

// MARK: - Status bar strip
//
// Every screen hides the navigation bar, so scrolled content would otherwise
// slide up under the clock. This strip is added as the LAST sibling of the root
// ZStack so it always paints over whatever is scrolling beneath it.
// The height comes from a GeometryReader rather than from a static read of the
// key window: this struct has no stored properties, so nothing would invalidate
// it on rotation and the strip would keep whatever height it was born with
// (launch in landscape → 0 pt → the strip stays 0 pt in portrait). The proxy is
// re-evaluated on every layout pass, so both orientations stay correct.
struct POStatusStrip: View {
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                POTheme.paper
                    .frame(height: max(proxy.safeAreaInsets.top, POSafeArea.top))
                Spacer(minLength: 0)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .allowsHitTesting(false)
    }
}

enum POSafeArea {
    static var top: CGFloat {
        let inset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets.top
        // No floor, and no guess when there is no window yet: iPhone hides the
        // status bar in landscape, where the inset is 0 and any strip at all would
        // sit on top of the header. POStatusStrip's GeometryReader is the primary
        // source; this is only its backstop.
        return inset ?? 0
    }

    static var bottom: CGFloat {
        let inset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets.bottom
        return inset ?? 0
    }

    /// Left + right inset combined. Zero in portrait; 88–118 pt in landscape on a
    /// notched iPhone, which is why fixed-width children have to subtract it.
    static var horizontal: CGFloat {
        let insets = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets
        guard let insets = insets else { return 0 }
        return insets.left + insets.right
    }
}

// MARK: - Headers

struct POScreenHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    let trailing: () -> Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(POFont.display(POScreen.isCompact ? 26 : 30))
                    .foregroundColor(POTheme.plumDeep)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(POFont.body(13))
                        .foregroundColor(POTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }
}

extension POScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() })
    }
}

struct POSectionTitle: View {
    let text: String
    var accessory: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(text.uppercased())
                .font(POFont.semibold(11))
                .tracking(1.2)
                .foregroundColor(POTheme.inkSoft)
            Rectangle()
                .fill(POTheme.hairline)
                .frame(height: 1)
            if let accessory = accessory {
                Text(accessory)
                    .font(POFont.mono(11))
                    .foregroundColor(POTheme.inkFaint)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
}

// MARK: - Cards

struct POCard<Content: View>: View {
    var padding: CGFloat = 16
    var tint: Color = POTheme.card
    let content: () -> Content

    init(padding: CGFloat = 16, tint: Color = POTheme.card, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.tint = tint
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(POTheme.hairline, lineWidth: 1)
                    )
                    .shadow(color: POTheme.shadow, radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Chips

struct POChip: View {
    let text: String
    var color: Color = POTheme.plum
    var glyph: String?
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let glyph = glyph {
                POGlyph(name: glyph, size: compact ? 10 : 12, color: color, lineWidth: 1.5)
            }
            Text(text)
                .font(POFont.semibold(compact ? 10 : 11))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 7 : 9)
        .padding(.vertical, compact ? 3 : 5)
        .background(
            Capsule().fill(color.opacity(0.12))
        )
        .overlay(
            Capsule().stroke(color.opacity(0.28), lineWidth: 1)
        )
    }
}

struct POFilterPill: View {
    let label: String
    let selected: Bool
    var color: Color = POTheme.plum
    var glyph: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let glyph = glyph {
                    POGlyph(name: glyph, size: 12,
                            color: selected ? POTheme.paper : color, lineWidth: 1.5)
                }
                Text(label)
                    .font(POFont.semibold(12))
                    .foregroundColor(selected ? POTheme.paper : POTheme.ink)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(selected ? color : POTheme.card)
            )
            .overlay(
                Capsule().stroke(selected ? color : POTheme.hairline, lineWidth: 1)
            )
            // Tap area lives on the label, before any positioning modifier.
            .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Buttons

struct POPrimaryButton: View {
    let title: String
    var glyph: String?
    var color: Color = POTheme.plum
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            HStack(spacing: 8) {
                if let glyph = glyph {
                    POGlyph(name: glyph, size: 18, color: POTheme.paper, lineWidth: 1.8)
                }
                Text(title)
                    .font(POFont.semibold(16))
                    .foregroundColor(POTheme.paper)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(enabled ? color : POTheme.inkFaint)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(enabled ? 1 : 0.7)
    }
}

struct POSecondaryButton: View {
    let title: String
    var glyph: String?
    var color: Color = POTheme.plum
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let glyph = glyph {
                    POGlyph(name: glyph, size: 16, color: color, lineWidth: 1.7)
                }
                Text(title)
                    .font(POFont.semibold(15))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.35), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A bare glyph button. The label always carries an explicit hit shape —
/// a Canvas over a clear background has no tap area of its own.
struct POGlyphButton: View {
    let glyph: String
    var size: CGFloat = 22
    var color: Color = POTheme.plum
    var background: Color = POTheme.card
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            POGlyph(name: glyph, size: size, color: color, lineWidth: 1.8)
                .frame(width: size + 20, height: size + 20)
                .background(Circle().fill(background))
                .overlay(Circle().stroke(POTheme.hairline, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct POBackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                POGlyph(name: "back", size: 16, color: POTheme.plum, lineWidth: 2)
                Text("Back")
                    .font(POFont.semibold(14))
                    .foregroundColor(POTheme.plum)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(POTheme.plum.opacity(0.08)))
            .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty states

struct POEmptyState: View {
    let glyph: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            POGlyph(name: glyph, size: 54, color: POTheme.plumSoft, lineWidth: 1.4)
                .padding(.bottom, 2)
            Text(title)
                .font(POFont.title(19))
                .foregroundColor(POTheme.plumDeep)
                .multilineTextAlignment(.center)
            Text(message)
                .font(POFont.body(14))
                .foregroundColor(POTheme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle = actionTitle, let action = action {
                POSecondaryButton(title: actionTitle, action: action)
                    .padding(.top, 4)
                    .frame(maxWidth: 260)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 34)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Score slider (1...5, custom, no system control)

struct POScoreSlider: View {
    let title: String
    let caption: String
    @Binding var value: Int
    var color: Color = POTheme.plum

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(POFont.semibold(15))
                    .foregroundColor(POTheme.ink)
                Spacer(minLength: 6)
                Text(caption)
                    .font(POFont.body(12))
                    .foregroundColor(POTheme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { step in
                    Button(action: { value = step }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(step <= value ? color : POTheme.paperDeep)
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(step <= value ? color : POTheme.hairline, lineWidth: 1)
                            Text("\(step)")
                                .font(POFont.semibold(14))
                                .foregroundColor(step <= value ? POTheme.paper : POTheme.inkFaint)
                        }
                        .frame(height: 40)
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Checkbox row

struct POCheckRow: View {
    let text: String
    let checked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(checked ? POTheme.teal : POTheme.paperDeep)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(checked ? POTheme.teal : POTheme.hairline, lineWidth: 1.2)
                    if checked {
                        POGlyph(name: "check", size: 16, color: POTheme.paper, lineWidth: 2.2)
                    }
                }
                .frame(width: 22, height: 22)
                Text(text)
                    .font(POFont.body(14))
                    .foregroundColor(checked ? POTheme.inkSoft : POTheme.ink)
                    .strikethrough(checked, color: POTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Toggle row (custom, no system Toggle styling reliance)

struct POToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { withAnimation(.easeOut(duration: 0.16)) { isOn.toggle() } }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(POFont.medium(15))
                        .foregroundColor(POTheme.ink)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(POFont.body(12))
                            .foregroundColor(POTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? POTheme.teal : POTheme.hairline)
                        .frame(width: 46, height: 27)
                    Circle()
                        .fill(POTheme.paper)
                        .frame(width: 21, height: 21)
                        .padding(.horizontal, 3)
                        .shadow(color: POTheme.shadow, radius: 2, x: 0, y: 1)
                }
                .frame(width: 46, height: 27)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat tile

struct POStatTile: View {
    let value: String
    let label: String
    var color: Color = POTheme.plum

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(POFont.display(22))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(POFont.body(11))
                .foregroundColor(POTheme.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(POTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(POTheme.hairline, lineWidth: 1))
        )
    }
}

// MARK: - Confetti

/// Canvas-drawn celebration. Deterministic seeded shapes so it never flickers
/// between frames, animated by a single progress value.
struct POConfetti: View, Animatable {
    var progress: Double
    var seed: Int = 7

    /// Without this SwiftUI would not interpolate a plain stored property, so the
    /// Canvas would jump straight to the end state instead of animating.
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { ctx, size in
            guard size.width > 0, size.height > 0 else { return }
            var rng = POSeededRandom(seed: UInt64(seed &+ 1))
            let palette: [Color] = [POTheme.plum, POTheme.gold, POTheme.terracotta,
                                    POTheme.teal, POTheme.plumSoft]
            let count = 46
            for i in 0..<count {
                let x0 = rng.nextDouble() * Double(size.width)
                let drift = (rng.nextDouble() - 0.5) * 90
                let delay = rng.nextDouble() * 0.35
                let spin = rng.nextDouble() * 6.28
                let colour = palette[i % palette.count]
                let t = POMath.clamp((progress - delay) / max(0.0001, 1 - delay), 0, 1)
                guard t > 0 else { continue }
                let y = -20 + t * (Double(size.height) + 60)
                let x = x0 + drift * t
                let w = 6 + rng.nextDouble() * 5
                let h = 3 + rng.nextDouble() * 6
                let angle = spin + t * 7
                var p = Path()
                p.addRoundedRect(in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h),
                                 cornerSize: CGSize(width: 1.5, height: 1.5))
                let transform = CGAffineTransform(translationX: CGFloat(x), y: CGFloat(y))
                    .rotated(by: CGFloat(angle))
                let fade = t > 0.82 ? (1 - (t - 0.82) / 0.18) : 1
                ctx.fill(p.applying(transform), with: .color(colour.opacity(POMath.clamp(fade, 0, 1))))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Tiny deterministic PRNG so Canvas art is stable across redraws.
struct POSeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    mutating func nextDouble() -> Double {
        Double(next() % 1_000_000) / 1_000_000.0
    }
}

// MARK: - Badge

struct POBadgeView: View {
    let glyph: String
    let earned: Bool
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(earned ? POTheme.gold.opacity(0.18) : POTheme.paperDeep)
            Circle()
                .stroke(earned ? POTheme.gold : POTheme.hairline,
                        style: StrokeStyle(lineWidth: earned ? 2 : 1, dash: earned ? [] : [3, 3]))
            POGlyph(name: glyph,
                    size: size * 0.52,
                    color: earned ? POTheme.plumDeep : POTheme.inkFaint,
                    lineWidth: 1.5,
                    filled: earned)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Text field wrapper
//
// In a multi-field form only the first TextField takes a tap unless focus is
// driven explicitly, so every field here goes through this wrapper.
struct POTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    let fieldID: Int
    @Binding var focused: Int?

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(POFont.body(15))
                    .foregroundColor(POTheme.inkFaint)
                    .allowsHitTesting(false)
            }
            POFocusableField(text: $text,
                             keyboard: keyboard,
                             fieldID: fieldID,
                             focused: $focused)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(POTheme.paperDeep)
                .overlay(RoundedRectangle(cornerRadius: 11)
                    .stroke(focused == fieldID ? POTheme.plum.opacity(0.6) : POTheme.hairline, lineWidth: 1))
        )
        .contentShape(Rectangle())
        .onTapGesture { focused = fieldID }
    }
}

private struct POFocusableField: View {
    @Binding var text: String
    let keyboard: UIKeyboardType
    let fieldID: Int
    @Binding var focused: Int?
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text)
            .font(POFont.body(15))
            .foregroundColor(POTheme.ink)
            .keyboardType(keyboard)
            .disableAutocorrection(false)
            .focused($isFocused)
            .onChange(of: focused) { newValue in
                isFocused = (newValue == fieldID)
            }
            .onChange(of: isFocused) { newValue in
                if newValue { focused = fieldID }
                else if focused == fieldID { focused = nil }
            }
    }
}

/// Multi-line notes field, same focus discipline.
struct POTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 96
    let fieldID: Int
    @Binding var focused: Int?
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 11)
                .fill(POTheme.paperDeep)
                .overlay(RoundedRectangle(cornerRadius: 11)
                    .stroke(focused == fieldID ? POTheme.plum.opacity(0.6) : POTheme.hairline, lineWidth: 1))
            if text.isEmpty {
                Text(placeholder)
                    .font(POFont.body(15))
                    .foregroundColor(POTheme.inkFaint)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(POFont.body(15))
                .foregroundColor(POTheme.ink)
                .focused($isFocused)
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .background(Color.clear)
                .onChange(of: focused) { newValue in
                    isFocused = (newValue == fieldID)
                }
                .onChange(of: isFocused) { newValue in
                    if newValue { focused = fieldID }
                    else if focused == fieldID { focused = nil }
                }
        }
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
        .onTapGesture { focused = fieldID }
    }
}

// MARK: - Wrapping chip row

/// Simple flow layout for chips that wraps at a given width. AnyLayout and Grid
/// are iOS 16, so this is done by hand.
struct POWrapRow<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let width: CGFloat
    let spacing: CGFloat
    let estimatedItemWidth: (Item) -> CGFloat
    let content: (Item) -> Content

    var body: some View {
        let rows = buildRows()
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { pair in
                HStack(spacing: spacing) {
                    ForEach(pair.element) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func buildRows() -> [[Item]] {
        var rows: [[Item]] = []
        var current: [Item] = []
        var used: CGFloat = 0
        let available = max(80, width)
        for item in items {
            let w = estimatedItemWidth(item)
            if !current.isEmpty && used + w + spacing > available {
                rows.append(current)
                current = [item]
                used = w
            } else {
                if !current.isEmpty { used += spacing }
                current.append(item)
                used += w
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}
