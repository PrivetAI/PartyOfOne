import SwiftUI

struct POOnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        let pages = POContent.onboarding

        ZStack {
            POTheme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    Button(action: onFinish) {
                        Text("Skip")
                            .font(POFont.semibold(14))
                            .foregroundColor(POTheme.inkSoft)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 14)
                .padding(.trailing, 8)

                Spacer(minLength: 0)

                if let current = pages[safe: page] {
                    VStack(spacing: POScreen.isCompact ? 16 : 24) {
                        POOnboardArt(kind: current.art)
                            .frame(height: POScreen.isCompact ? 130 : 176)
                            .frame(minHeight: 120)

                        VStack(spacing: 10) {
                            Text(current.title)
                                .font(POFont.display(POScreen.isCompact ? 23 : 27))
                                .foregroundColor(POTheme.plumDeep)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(current.body)
                                .font(POFont.body(15))
                                .foregroundColor(POTheme.inkSoft)
                                .lineSpacing(4)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 30)
                    }
                    .transition(.opacity)
                }

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? POTheme.plum : POTheme.hairline)
                            .frame(width: i == page ? 20 : 7, height: 7)
                    }
                }
                .padding(.bottom, 20)

                HStack(spacing: 10) {
                    if page > 0 {
                        POSecondaryButton(title: "Back", glyph: "back", color: POTheme.inkSoft) {
                            withAnimation(.easeOut(duration: 0.2)) { page -= 1 }
                        }
                    }
                    POPrimaryButton(title: page == pages.count - 1 ? "Deal me in" : "Next",
                                    glyph: page == pages.count - 1 ? "cards" : nil) {
                        if page == pages.count - 1 {
                            onFinish()
                        } else {
                            withAnimation(.easeOut(duration: 0.2)) { page += 1 }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
    }
}

/// Canvas art for each onboarding page.
struct POOnboardArt: View {
    let kind: String

    var body: some View {
        Canvas { ctx, size in
            guard size.width > 20, size.height > 20 else { return }
            let w = size.width
            let h = size.height
            let cx = w / 2
            let cy = h / 2

            switch kind {
            case "table":
                var halo = Path()
                halo.addEllipse(in: CGRect(x: cx - h * 0.44, y: cy - h * 0.44, width: h * 0.88, height: h * 0.88))
                ctx.fill(halo, with: .color(POTheme.gold.opacity(0.14)))
                drawGlyph("table", ctx: ctx, center: CGPoint(x: cx, y: cy), side: h * 0.72,
                          color: POTheme.plumDeep)

            case "cards":
                for i in 0..<3 {
                    let t = Double(i) - 1
                    let cardW = h * 0.40
                    let cardH = h * 0.62
                    var p = Path()
                    p.addRoundedRect(in: CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH),
                                     cornerSize: CGSize(width: 10, height: 10))
                    let transform = CGAffineTransform(translationX: cx + CGFloat(t) * cardW * 0.72, y: cy)
                        .rotated(by: CGFloat(t * 0.18))
                    let shaped = p.applying(transform)
                    ctx.fill(shaped, with: .color(POTheme.card))
                    let colours = [POTheme.terracotta, POTheme.plum, POTheme.teal]
                    ctx.stroke(shaped, with: .color(colours[i]), lineWidth: 1.6)
                    var pip = Path()
                    pip.addEllipse(in: CGRect(x: -8, y: -8, width: 16, height: 16))
                    ctx.fill(pip.applying(transform), with: .color(colours[i].opacity(0.55)))
                }

            case "calendar":
                var frame = Path()
                let fw = h * 0.78, fh = h * 0.68
                frame.addRoundedRect(in: CGRect(x: cx - fw / 2, y: cy - fh / 2 + 6, width: fw, height: fh),
                                     cornerSize: CGSize(width: 12, height: 12))
                ctx.fill(frame, with: .color(POTheme.card))
                ctx.stroke(frame, with: .color(POTheme.plum), lineWidth: 1.6)
                var bar = Path()
                bar.move(to: CGPoint(x: cx - fw / 2, y: cy - fh / 2 + 6 + fh * 0.26))
                bar.addLine(to: CGPoint(x: cx + fw / 2, y: cy - fh / 2 + 6 + fh * 0.26))
                ctx.stroke(bar, with: .color(POTheme.plum.opacity(0.6)), lineWidth: 1.2)
                for r in 0..<3 {
                    for c in 0..<5 {
                        let x = cx - fw / 2 + fw * (0.14 + Double(c) * 0.18)
                        let y = cy - fh / 2 + 6 + fh * (0.42 + Double(r) * 0.20)
                        var dot = Path()
                        let marked = (r == 1 && c == 2)
                        dot.addEllipse(in: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
                        ctx.fill(dot, with: .color(marked ? POTheme.terracotta : POTheme.hairline))
                    }
                }

            case "sliders":
                for i in 0..<4 {
                    let y = cy - h * 0.26 + CGFloat(i) * h * 0.17
                    var track = Path()
                    track.move(to: CGPoint(x: cx - w * 0.26, y: y))
                    track.addLine(to: CGPoint(x: cx + w * 0.26, y: y))
                    ctx.stroke(track, with: .color(POTheme.hairline),
                               style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    let fillTo = [0.86, 0.48, 0.66, 0.30][i]
                    var bar = Path()
                    bar.move(to: CGPoint(x: cx - w * 0.26, y: y))
                    bar.addLine(to: CGPoint(x: cx - w * 0.26 + w * 0.52 * CGFloat(fillTo), y: y))
                    let colours = [POTheme.teal, POTheme.terracotta, POTheme.plum, POTheme.gold]
                    ctx.stroke(bar, with: .color(colours[i]),
                               style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    var knob = Path()
                    knob.addEllipse(in: CGRect(x: cx - w * 0.26 + w * 0.52 * CGFloat(fillTo) - 7,
                                               y: y - 7, width: 14, height: 14))
                    ctx.fill(knob, with: .color(colours[i]))
                }

            default: // "bars"
                let widths = [0.86, 0.70, 0.52, 0.34, 0.20]
                let colours = [POTheme.teal, POTheme.plum, POTheme.gold, POTheme.terracotta, POTheme.plumSoft]
                for i in 0..<5 {
                    let y = cy - h * 0.30 + CGFloat(i) * h * 0.15
                    var bar = Path()
                    bar.addRoundedRect(in: CGRect(x: cx - w * 0.28, y: y - 7,
                                                  width: w * 0.56 * CGFloat(widths[i]), height: 14),
                                       cornerSize: CGSize(width: 7, height: 7))
                    ctx.fill(bar, with: .color(colours[i]))
                    var count = ctx.resolve(Text("\(12 - i * 2)").font(POFont.mono(10)))
                    count.shading = .color(POTheme.inkFaint)
                    ctx.draw(count, at: CGPoint(x: cx + w * 0.30, y: y), anchor: .leading)
                }
            }
        }
    }

    private func drawGlyph(_ name: String, ctx: GraphicsContext, center: CGPoint, side: CGFloat, color: Color) {
        var sub = ctx
        sub.translateBy(x: center.x - side / 2, y: center.y - side / 2)
        POGlyphDrawing.draw(name: name, in: sub, side: side, color: color,
                            lineWidth: 1.8 * (side / 24), filled: false)
    }
}
