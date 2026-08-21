import SwiftUI

/// Every icon in this app is drawn here. No SF Symbols, no emoji, no image assets.
/// Each glyph draws inside a unit square and is scaled by the caller.
struct POGlyph: View {
    let name: String
    var size: CGFloat = 24
    var color: Color = POTheme.ink
    var lineWidth: CGFloat = 1.6
    var filled: Bool = false

    var body: some View {
        Canvas { ctx, canvasSize in
            // Never trust the closure size to equal the requested size; anchor to
            // the smaller dimension of whatever we are actually given.
            let s = min(canvasSize.width, canvasSize.height)
            guard s > 0 else { return }
            POGlyphDrawing.draw(name: name,
                                in: ctx,
                                side: s,
                                color: color,
                                lineWidth: lineWidth * (s / 24),
                                filled: filled)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

enum POGlyphDrawing {

    // swiftlint:disable:next cyclomatic_complexity
    static func draw(name: String,
                     in ctx: GraphicsContext,
                     side s: CGFloat,
                     color: Color,
                     lineWidth lw: CGFloat,
                     filled: Bool) {
        let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
        func line(_ p: Path) { ctx.stroke(p, with: .color(color), style: stroke) }
        func fill(_ p: Path) { ctx.fill(p, with: .color(color)) }

        switch name {

        case "cards":
            var back = Path()
            back.addRoundedRect(in: CGRect(x: s * 0.10, y: s * 0.24, width: s * 0.42, height: s * 0.58),
                                cornerSize: CGSize(width: s * 0.06, height: s * 0.06))
            var front = Path()
            front.addRoundedRect(in: CGRect(x: s * 0.44, y: s * 0.16, width: s * 0.44, height: s * 0.62),
                                 cornerSize: CGSize(width: s * 0.06, height: s * 0.06))
            if filled {
                ctx.fill(back, with: .color(color.opacity(0.35)))
                fill(front)
            } else {
                line(back)
                ctx.fill(front, with: .color(POTheme.paper))
                line(front)
                var pip = Path()
                pip.addEllipse(in: CGRect(x: s * 0.60, y: s * 0.40, width: s * 0.12, height: s * 0.12))
                fill(pip)
            }

        case "calendar":
            var frame = Path()
            frame.addRoundedRect(in: CGRect(x: s * 0.14, y: s * 0.22, width: s * 0.72, height: s * 0.62),
                                 cornerSize: CGSize(width: s * 0.08, height: s * 0.08))
            line(frame)
            var bar = Path()
            bar.move(to: CGPoint(x: s * 0.14, y: s * 0.40))
            bar.addLine(to: CGPoint(x: s * 0.86, y: s * 0.40))
            line(bar)
            var pegs = Path()
            pegs.move(to: CGPoint(x: s * 0.32, y: s * 0.14))
            pegs.addLine(to: CGPoint(x: s * 0.32, y: s * 0.28))
            pegs.move(to: CGPoint(x: s * 0.68, y: s * 0.14))
            pegs.addLine(to: CGPoint(x: s * 0.68, y: s * 0.28))
            line(pegs)
            if filled {
                var dot = Path()
                dot.addEllipse(in: CGRect(x: s * 0.44, y: s * 0.54, width: s * 0.14, height: s * 0.14))
                fill(dot)
            }

        case "book":
            var spine = Path()
            spine.move(to: CGPoint(x: s * 0.50, y: s * 0.26))
            spine.addLine(to: CGPoint(x: s * 0.50, y: s * 0.82))
            var left = Path()
            left.move(to: CGPoint(x: s * 0.50, y: s * 0.26))
            left.addCurve(to: CGPoint(x: s * 0.12, y: s * 0.22),
                          control1: CGPoint(x: s * 0.34, y: s * 0.16),
                          control2: CGPoint(x: s * 0.20, y: s * 0.18))
            left.addLine(to: CGPoint(x: s * 0.12, y: s * 0.76))
            left.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.82),
                          control1: CGPoint(x: s * 0.22, y: s * 0.74),
                          control2: CGPoint(x: s * 0.36, y: s * 0.74))
            var right = Path()
            right.move(to: CGPoint(x: s * 0.50, y: s * 0.26))
            right.addCurve(to: CGPoint(x: s * 0.88, y: s * 0.22),
                           control1: CGPoint(x: s * 0.66, y: s * 0.16),
                           control2: CGPoint(x: s * 0.80, y: s * 0.18))
            right.addLine(to: CGPoint(x: s * 0.88, y: s * 0.76))
            right.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.82),
                           control1: CGPoint(x: s * 0.78, y: s * 0.74),
                           control2: CGPoint(x: s * 0.64, y: s * 0.74))
            if filled {
                ctx.fill(left, with: .color(color.opacity(0.35)))
                ctx.fill(right, with: .color(color.opacity(0.35)))
            }
            line(left); line(right); line(spine)

        case "person":
            var head = Path()
            head.addEllipse(in: CGRect(x: s * 0.36, y: s * 0.16, width: s * 0.28, height: s * 0.28))
            var body = Path()
            body.move(to: CGPoint(x: s * 0.16, y: s * 0.84))
            body.addCurve(to: CGPoint(x: s * 0.84, y: s * 0.84),
                          control1: CGPoint(x: s * 0.20, y: s * 0.54),
                          control2: CGPoint(x: s * 0.80, y: s * 0.54))
            if filled { fill(head); fill(body) } else { line(head); line(body) }

        case "dial":
            var ring = Path()
            ring.addEllipse(in: CGRect(x: s * 0.14, y: s * 0.14, width: s * 0.72, height: s * 0.72))
            line(ring)
            var hand = Path()
            hand.move(to: CGPoint(x: s * 0.50, y: s * 0.50))
            hand.addLine(to: CGPoint(x: s * 0.70, y: s * 0.34))
            line(hand)
            for i in 0..<8 {
                let a = Double(i) / 8.0 * 2 * Double.pi
                var tick = Path()
                let r1 = s * 0.40, r2 = s * 0.46
                tick.move(to: CGPoint(x: s * 0.5 + CGFloat(cos(a)) * r1, y: s * 0.5 + CGFloat(sin(a)) * r1))
                tick.addLine(to: CGPoint(x: s * 0.5 + CGFloat(cos(a)) * r2, y: s * 0.5 + CGFloat(sin(a)) * r2))
                line(tick)
            }

        case "table":
            // A small round café table with one chair — the app's own emblem.
            var top = Path()
            top.addEllipse(in: CGRect(x: s * 0.16, y: s * 0.40, width: s * 0.52, height: s * 0.14))
            var stem = Path()
            stem.move(to: CGPoint(x: s * 0.42, y: s * 0.50))
            stem.addLine(to: CGPoint(x: s * 0.42, y: s * 0.82))
            var foot = Path()
            foot.move(to: CGPoint(x: s * 0.28, y: s * 0.84))
            foot.addLine(to: CGPoint(x: s * 0.56, y: s * 0.84))
            var chairBack = Path()
            chairBack.move(to: CGPoint(x: s * 0.80, y: s * 0.30))
            chairBack.addLine(to: CGPoint(x: s * 0.80, y: s * 0.62))
            var seat = Path()
            seat.move(to: CGPoint(x: s * 0.68, y: s * 0.62))
            seat.addLine(to: CGPoint(x: s * 0.90, y: s * 0.62))
            var legs = Path()
            legs.move(to: CGPoint(x: s * 0.71, y: s * 0.62))
            legs.addLine(to: CGPoint(x: s * 0.71, y: s * 0.84))
            legs.move(to: CGPoint(x: s * 0.87, y: s * 0.62))
            legs.addLine(to: CGPoint(x: s * 0.87, y: s * 0.84))
            if filled { fill(top) } else { line(top) }
            line(stem); line(foot); line(chairBack); line(seat); line(legs)
            var candle = Path()
            candle.move(to: CGPoint(x: s * 0.42, y: s * 0.40))
            candle.addLine(to: CGPoint(x: s * 0.42, y: s * 0.26))
            line(candle)
            var flame = Path()
            flame.move(to: CGPoint(x: s * 0.42, y: s * 0.12))
            flame.addQuadCurve(to: CGPoint(x: s * 0.42, y: s * 0.26), control: CGPoint(x: s * 0.52, y: s * 0.20))
            flame.addQuadCurve(to: CGPoint(x: s * 0.42, y: s * 0.12), control: CGPoint(x: s * 0.32, y: s * 0.20))
            fill(flame)

        case "coin":
            var outer = Path()
            outer.addEllipse(in: CGRect(x: s * 0.14, y: s * 0.14, width: s * 0.72, height: s * 0.72))
            var inner = Path()
            inner.addEllipse(in: CGRect(x: s * 0.30, y: s * 0.30, width: s * 0.40, height: s * 0.40))
            if filled { fill(outer); ctx.fill(inner, with: .color(POTheme.paper)) } else { line(outer); line(inner) }

        case "flame":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.50, y: s * 0.10))
            p.addCurve(to: CGPoint(x: s * 0.80, y: s * 0.58),
                       control1: CGPoint(x: s * 0.66, y: s * 0.28),
                       control2: CGPoint(x: s * 0.80, y: s * 0.40))
            p.addCurve(to: CGPoint(x: s * 0.20, y: s * 0.58),
                       control1: CGPoint(x: s * 0.80, y: s * 0.84),
                       control2: CGPoint(x: s * 0.20, y: s * 0.84))
            p.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.10),
                       control1: CGPoint(x: s * 0.20, y: s * 0.36),
                       control2: CGPoint(x: s * 0.40, y: s * 0.30))
            if filled { fill(p) } else { line(p) }

        case "eye":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.10, y: s * 0.50))
            p.addQuadCurve(to: CGPoint(x: s * 0.90, y: s * 0.50), control: CGPoint(x: s * 0.50, y: s * 0.14))
            p.addQuadCurve(to: CGPoint(x: s * 0.10, y: s * 0.50), control: CGPoint(x: s * 0.50, y: s * 0.86))
            var iris = Path()
            iris.addEllipse(in: CGRect(x: s * 0.40, y: s * 0.40, width: s * 0.20, height: s * 0.20))
            if filled { fill(p); ctx.fill(iris, with: .color(POTheme.paper)) } else { line(p); fill(iris) }

        case "arch":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.20, y: s * 0.86))
            p.addLine(to: CGPoint(x: s * 0.20, y: s * 0.46))
            p.addQuadCurve(to: CGPoint(x: s * 0.80, y: s * 0.46), control: CGPoint(x: s * 0.50, y: s * 0.06))
            p.addLine(to: CGPoint(x: s * 0.80, y: s * 0.86))
            if filled { fill(p) } else { line(p) }
            var base = Path()
            base.move(to: CGPoint(x: s * 0.10, y: s * 0.88))
            base.addLine(to: CGPoint(x: s * 0.90, y: s * 0.88))
            line(base)

        case "path":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.30, y: s * 0.90))
            p.addCurve(to: CGPoint(x: s * 0.70, y: s * 0.12),
                       control1: CGPoint(x: s * 0.85, y: s * 0.66),
                       control2: CGPoint(x: s * 0.15, y: s * 0.40))
            line(p)
            var dot = Path()
            dot.addEllipse(in: CGRect(x: s * 0.62, y: s * 0.04, width: s * 0.16, height: s * 0.16))
            fill(dot)

        case "hand":
            var palm = Path()
            palm.addRoundedRect(in: CGRect(x: s * 0.28, y: s * 0.44, width: s * 0.44, height: s * 0.42),
                                cornerSize: CGSize(width: s * 0.14, height: s * 0.14))
            if filled { fill(palm) } else { line(palm) }
            for i in 0..<3 {
                var f = Path()
                let x = s * (0.36 + Double(i) * 0.14)
                f.move(to: CGPoint(x: x, y: s * 0.46))
                f.addLine(to: CGPoint(x: x, y: s * 0.18))
                line(f)
            }

        case "wave":
            for i in 0..<3 {
                var p = Path()
                let y = s * (0.34 + Double(i) * 0.20)
                p.move(to: CGPoint(x: s * 0.10, y: y))
                p.addQuadCurve(to: CGPoint(x: s * 0.50, y: y), control: CGPoint(x: s * 0.30, y: y - s * 0.14))
                p.addQuadCurve(to: CGPoint(x: s * 0.90, y: y), control: CGPoint(x: s * 0.70, y: y + s * 0.14))
                line(p)
            }

        case "door":
            var frame = Path()
            frame.addRoundedRect(in: CGRect(x: s * 0.24, y: s * 0.12, width: s * 0.52, height: s * 0.76),
                                 cornerSize: CGSize(width: s * 0.06, height: s * 0.06))
            if filled { fill(frame) } else { line(frame) }
            var knob = Path()
            knob.addEllipse(in: CGRect(x: s * 0.62, y: s * 0.48, width: s * 0.09, height: s * 0.09))
            if filled { ctx.fill(knob, with: .color(POTheme.paper)) } else { fill(knob) }

        case "leaf":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.18, y: s * 0.84))
            p.addCurve(to: CGPoint(x: s * 0.84, y: s * 0.18),
                       control1: CGPoint(x: s * 0.18, y: s * 0.34),
                       control2: CGPoint(x: s * 0.44, y: s * 0.18))
            p.addCurve(to: CGPoint(x: s * 0.18, y: s * 0.84),
                       control1: CGPoint(x: s * 0.84, y: s * 0.62),
                       control2: CGPoint(x: s * 0.62, y: s * 0.84))
            if filled { fill(p) } else { line(p) }
            var vein = Path()
            vein.move(to: CGPoint(x: s * 0.22, y: s * 0.80))
            vein.addLine(to: CGPoint(x: s * 0.74, y: s * 0.28))
            line(vein)

        case "gem":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.50, y: s * 0.88))
            p.addLine(to: CGPoint(x: s * 0.12, y: s * 0.40))
            p.addLine(to: CGPoint(x: s * 0.28, y: s * 0.14))
            p.addLine(to: CGPoint(x: s * 0.72, y: s * 0.14))
            p.addLine(to: CGPoint(x: s * 0.88, y: s * 0.40))
            p.closeSubpath()
            if filled { fill(p) } else { line(p) }
            var facets = Path()
            facets.move(to: CGPoint(x: s * 0.12, y: s * 0.40))
            facets.addLine(to: CGPoint(x: s * 0.88, y: s * 0.40))
            facets.move(to: CGPoint(x: s * 0.28, y: s * 0.14))
            facets.addLine(to: CGPoint(x: s * 0.50, y: s * 0.88))
            facets.move(to: CGPoint(x: s * 0.72, y: s * 0.14))
            facets.addLine(to: CGPoint(x: s * 0.50, y: s * 0.88))
            ctx.stroke(facets, with: .color(filled ? POTheme.paper.opacity(0.7) : color.opacity(0.5)),
                       style: StrokeStyle(lineWidth: lw * 0.7))

        case "check":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.20, y: s * 0.52))
            p.addLine(to: CGPoint(x: s * 0.42, y: s * 0.74))
            p.addLine(to: CGPoint(x: s * 0.80, y: s * 0.26))
            line(p)

        case "plus":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.50, y: s * 0.20))
            p.addLine(to: CGPoint(x: s * 0.50, y: s * 0.80))
            p.move(to: CGPoint(x: s * 0.20, y: s * 0.50))
            p.addLine(to: CGPoint(x: s * 0.80, y: s * 0.50))
            line(p)

        case "close":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.26, y: s * 0.26))
            p.addLine(to: CGPoint(x: s * 0.74, y: s * 0.74))
            p.move(to: CGPoint(x: s * 0.74, y: s * 0.26))
            p.addLine(to: CGPoint(x: s * 0.26, y: s * 0.74))
            line(p)

        case "chevron":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.38, y: s * 0.22))
            p.addLine(to: CGPoint(x: s * 0.66, y: s * 0.50))
            p.addLine(to: CGPoint(x: s * 0.38, y: s * 0.78))
            line(p)

        case "chevron-down":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.22, y: s * 0.40))
            p.addLine(to: CGPoint(x: s * 0.50, y: s * 0.66))
            p.addLine(to: CGPoint(x: s * 0.78, y: s * 0.40))
            line(p)

        case "back":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.62, y: s * 0.22))
            p.addLine(to: CGPoint(x: s * 0.34, y: s * 0.50))
            p.addLine(to: CGPoint(x: s * 0.62, y: s * 0.78))
            line(p)

        case "search":
            var ring = Path()
            ring.addEllipse(in: CGRect(x: s * 0.16, y: s * 0.16, width: s * 0.50, height: s * 0.50))
            line(ring)
            var tail = Path()
            tail.move(to: CGPoint(x: s * 0.62, y: s * 0.62))
            tail.addLine(to: CGPoint(x: s * 0.84, y: s * 0.84))
            line(tail)

        case "shuffle":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.14, y: s * 0.30))
            p.addLine(to: CGPoint(x: s * 0.36, y: s * 0.30))
            p.addCurve(to: CGPoint(x: s * 0.64, y: s * 0.70),
                       control1: CGPoint(x: s * 0.52, y: s * 0.30),
                       control2: CGPoint(x: s * 0.48, y: s * 0.70))
            p.addLine(to: CGPoint(x: s * 0.84, y: s * 0.70))
            line(p)
            var p2 = Path()
            p2.move(to: CGPoint(x: s * 0.14, y: s * 0.70))
            p2.addLine(to: CGPoint(x: s * 0.36, y: s * 0.70))
            p2.addCurve(to: CGPoint(x: s * 0.64, y: s * 0.30),
                        control1: CGPoint(x: s * 0.52, y: s * 0.70),
                        control2: CGPoint(x: s * 0.48, y: s * 0.30))
            p2.addLine(to: CGPoint(x: s * 0.84, y: s * 0.30))
            line(p2)
            var head = Path()
            head.move(to: CGPoint(x: s * 0.74, y: s * 0.20))
            head.addLine(to: CGPoint(x: s * 0.88, y: s * 0.30))
            head.addLine(to: CGPoint(x: s * 0.74, y: s * 0.40))
            line(head)
            var head2 = Path()
            head2.move(to: CGPoint(x: s * 0.74, y: s * 0.60))
            head2.addLine(to: CGPoint(x: s * 0.88, y: s * 0.70))
            head2.addLine(to: CGPoint(x: s * 0.74, y: s * 0.80))
            line(head2)

        case "clock":
            var ring = Path()
            ring.addEllipse(in: CGRect(x: s * 0.14, y: s * 0.14, width: s * 0.72, height: s * 0.72))
            line(ring)
            var hands = Path()
            hands.move(to: CGPoint(x: s * 0.50, y: s * 0.30))
            hands.addLine(to: CGPoint(x: s * 0.50, y: s * 0.52))
            hands.addLine(to: CGPoint(x: s * 0.68, y: s * 0.60))
            line(hands)

        case "pin":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.50, y: s * 0.90))
            p.addCurve(to: CGPoint(x: s * 0.20, y: s * 0.38),
                       control1: CGPoint(x: s * 0.30, y: s * 0.66),
                       control2: CGPoint(x: s * 0.20, y: s * 0.52))
            p.addArc(center: CGPoint(x: s * 0.50, y: s * 0.38), radius: s * 0.30,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.90),
                       control1: CGPoint(x: s * 0.80, y: s * 0.52),
                       control2: CGPoint(x: s * 0.70, y: s * 0.66))
            line(p)
            var hole = Path()
            hole.addEllipse(in: CGRect(x: s * 0.40, y: s * 0.28, width: s * 0.20, height: s * 0.20))
            line(hole)

        case "star":
            var p = Path()
            let cx = s * 0.5, cy = s * 0.52, r1 = s * 0.40, r2 = s * 0.17
            for i in 0..<10 {
                let a = -Double.pi / 2 + Double(i) * Double.pi / 5
                let r = (i % 2 == 0) ? r1 : r2
                let pt = CGPoint(x: cx + CGFloat(cos(a)) * r, y: cy + CGFloat(sin(a)) * r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            if filled { fill(p) } else { line(p) }

        case "trash":
            var body = Path()
            body.move(to: CGPoint(x: s * 0.24, y: s * 0.30))
            body.addLine(to: CGPoint(x: s * 0.30, y: s * 0.84))
            body.addLine(to: CGPoint(x: s * 0.70, y: s * 0.84))
            body.addLine(to: CGPoint(x: s * 0.76, y: s * 0.30))
            line(body)
            var lid = Path()
            lid.move(to: CGPoint(x: s * 0.16, y: s * 0.30))
            lid.addLine(to: CGPoint(x: s * 0.84, y: s * 0.30))
            lid.move(to: CGPoint(x: s * 0.40, y: s * 0.30))
            lid.addLine(to: CGPoint(x: s * 0.42, y: s * 0.18))
            lid.addLine(to: CGPoint(x: s * 0.58, y: s * 0.18))
            lid.addLine(to: CGPoint(x: s * 0.60, y: s * 0.30))
            line(lid)

        case "pencil":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.18, y: s * 0.82))
            p.addLine(to: CGPoint(x: s * 0.26, y: s * 0.60))
            p.addLine(to: CGPoint(x: s * 0.66, y: s * 0.20))
            p.addLine(to: CGPoint(x: s * 0.80, y: s * 0.34))
            p.addLine(to: CGPoint(x: s * 0.40, y: s * 0.74))
            p.closeSubpath()
            line(p)

        case "bars":
            for i in 0..<3 {
                var p = Path()
                let y = s * (0.28 + Double(i) * 0.22)
                let w = s * (0.66 - Double(i) * 0.18)
                p.addRoundedRect(in: CGRect(x: s * 0.14, y: y - s * 0.06, width: w, height: s * 0.12),
                                 cornerSize: CGSize(width: s * 0.06, height: s * 0.06))
                ctx.fill(p, with: .color(color.opacity(1.0 - Double(i) * 0.22)))
            }

        case "sliders":
            for i in 0..<3 {
                let y = s * (0.28 + Double(i) * 0.22)
                var track = Path()
                track.move(to: CGPoint(x: s * 0.12, y: y))
                track.addLine(to: CGPoint(x: s * 0.88, y: y))
                ctx.stroke(track, with: .color(color.opacity(0.4)), style: StrokeStyle(lineWidth: lw, lineCap: .round))
                var knob = Path()
                let kx = s * (0.30 + Double(i) * 0.22)
                knob.addEllipse(in: CGRect(x: kx - s * 0.08, y: y - s * 0.08, width: s * 0.16, height: s * 0.16))
                fill(knob)
            }

        case "home":
            var roof = Path()
            roof.move(to: CGPoint(x: s * 0.12, y: s * 0.48))
            roof.addLine(to: CGPoint(x: s * 0.50, y: s * 0.14))
            roof.addLine(to: CGPoint(x: s * 0.88, y: s * 0.48))
            line(roof)
            var walls = Path()
            walls.move(to: CGPoint(x: s * 0.22, y: s * 0.44))
            walls.addLine(to: CGPoint(x: s * 0.22, y: s * 0.86))
            walls.addLine(to: CGPoint(x: s * 0.78, y: s * 0.86))
            walls.addLine(to: CGPoint(x: s * 0.78, y: s * 0.44))
            line(walls)

        case "tree":
            var trunk = Path()
            trunk.move(to: CGPoint(x: s * 0.50, y: s * 0.88))
            trunk.addLine(to: CGPoint(x: s * 0.50, y: s * 0.52))
            line(trunk)
            var crown = Path()
            crown.addEllipse(in: CGRect(x: s * 0.20, y: s * 0.12, width: s * 0.60, height: s * 0.48))
            if filled { fill(crown) } else { line(crown) }

        case "building":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.20, y: s * 0.88))
            p.addLine(to: CGPoint(x: s * 0.20, y: s * 0.26))
            p.addLine(to: CGPoint(x: s * 0.52, y: s * 0.26))
            p.addLine(to: CGPoint(x: s * 0.52, y: s * 0.46))
            p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.46))
            p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.88))
            p.closeSubpath()
            line(p)
            for r in 0..<2 {
                for c in 0..<2 {
                    var w = Path()
                    w.addRect(CGRect(x: s * (0.27 + Double(c) * 0.13), y: s * (0.36 + Double(r) * 0.18),
                                     width: s * 0.07, height: s * 0.09))
                    fill(w)
                }
            }

        case "cup":
            var body = Path()
            body.move(to: CGPoint(x: s * 0.22, y: s * 0.34))
            body.addLine(to: CGPoint(x: s * 0.30, y: s * 0.80))
            body.addLine(to: CGPoint(x: s * 0.62, y: s * 0.80))
            body.addLine(to: CGPoint(x: s * 0.70, y: s * 0.34))
            body.closeSubpath()
            if filled { fill(body) } else { line(body) }
            var handle = Path()
            handle.move(to: CGPoint(x: s * 0.70, y: s * 0.42))
            handle.addQuadCurve(to: CGPoint(x: s * 0.66, y: s * 0.66), control: CGPoint(x: s * 0.90, y: s * 0.54))
            line(handle)

        case "brush":
            var handle = Path()
            handle.move(to: CGPoint(x: s * 0.70, y: s * 0.16))
            handle.addLine(to: CGPoint(x: s * 0.40, y: s * 0.54))
            line(handle)
            var head = Path()
            head.move(to: CGPoint(x: s * 0.42, y: s * 0.48))
            head.addLine(to: CGPoint(x: s * 0.20, y: s * 0.72))
            head.addLine(to: CGPoint(x: s * 0.34, y: s * 0.86))
            head.addLine(to: CGPoint(x: s * 0.54, y: s * 0.62))
            head.closeSubpath()
            if filled { fill(head) } else { line(head) }

        case "boot":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.32, y: s * 0.14))
            p.addLine(to: CGPoint(x: s * 0.32, y: s * 0.62))
            p.addLine(to: CGPoint(x: s * 0.20, y: s * 0.72))
            p.addLine(to: CGPoint(x: s * 0.20, y: s * 0.84))
            p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.84))
            p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.72))
            p.addLine(to: CGPoint(x: s * 0.54, y: s * 0.60))
            p.addLine(to: CGPoint(x: s * 0.54, y: s * 0.14))
            p.closeSubpath()
            if filled { fill(p) } else { line(p) }

        case "mask":
            // Culture: a simple theatre mask outline.
            var p = Path()
            p.move(to: CGPoint(x: s * 0.18, y: s * 0.24))
            p.addLine(to: CGPoint(x: s * 0.82, y: s * 0.24))
            p.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.88),
                       control1: CGPoint(x: s * 0.82, y: s * 0.66),
                       control2: CGPoint(x: s * 0.68, y: s * 0.88))
            p.addCurve(to: CGPoint(x: s * 0.18, y: s * 0.24),
                       control1: CGPoint(x: s * 0.32, y: s * 0.88),
                       control2: CGPoint(x: s * 0.18, y: s * 0.66))
            if filled { fill(p) } else { line(p) }
            var eyes = Path()
            eyes.addEllipse(in: CGRect(x: s * 0.32, y: s * 0.40, width: s * 0.10, height: s * 0.08))
            eyes.addEllipse(in: CGRect(x: s * 0.58, y: s * 0.40, width: s * 0.10, height: s * 0.08))
            ctx.fill(eyes, with: .color(filled ? POTheme.paper : color))

        case "runner":
            var head = Path()
            head.addEllipse(in: CGRect(x: s * 0.52, y: s * 0.12, width: s * 0.18, height: s * 0.18))
            fill(head)
            var body = Path()
            body.move(to: CGPoint(x: s * 0.58, y: s * 0.32))
            body.addLine(to: CGPoint(x: s * 0.44, y: s * 0.52))
            body.addLine(to: CGPoint(x: s * 0.56, y: s * 0.68))
            body.addLine(to: CGPoint(x: s * 0.50, y: s * 0.88))
            line(body)
            var arm = Path()
            arm.move(to: CGPoint(x: s * 0.52, y: s * 0.38))
            arm.addLine(to: CGPoint(x: s * 0.26, y: s * 0.46))
            arm.move(to: CGPoint(x: s * 0.54, y: s * 0.40))
            arm.addLine(to: CGPoint(x: s * 0.78, y: s * 0.32))
            line(arm)
            var leg = Path()
            leg.move(to: CGPoint(x: s * 0.44, y: s * 0.52))
            leg.addLine(to: CGPoint(x: s * 0.20, y: s * 0.76))
            line(leg)

        case "sun":
            var core = Path()
            core.addEllipse(in: CGRect(x: s * 0.30, y: s * 0.30, width: s * 0.40, height: s * 0.40))
            if filled { fill(core) } else { line(core) }
            for i in 0..<8 {
                let a = Double(i) / 8.0 * 2 * Double.pi
                var ray = Path()
                ray.move(to: CGPoint(x: s * 0.5 + CGFloat(cos(a)) * s * 0.46, y: s * 0.5 + CGFloat(sin(a)) * s * 0.46))
                ray.addLine(to: CGPoint(x: s * 0.5 + CGFloat(cos(a)) * s * 0.36, y: s * 0.5 + CGFloat(sin(a)) * s * 0.36))
                line(ray)
            }

        case "cloud":
            var p = Path()
            p.addEllipse(in: CGRect(x: s * 0.14, y: s * 0.44, width: s * 0.34, height: s * 0.30))
            p.addEllipse(in: CGRect(x: s * 0.34, y: s * 0.32, width: s * 0.38, height: s * 0.36))
            p.addEllipse(in: CGRect(x: s * 0.56, y: s * 0.44, width: s * 0.32, height: s * 0.30))
            p.addRect(CGRect(x: s * 0.24, y: s * 0.56, width: s * 0.54, height: s * 0.16))
            if filled { fill(p) } else { ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: lw)) }

        case "drop":
            var p = Path()
            p.move(to: CGPoint(x: s * 0.50, y: s * 0.10))
            p.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.88),
                       control1: CGPoint(x: s * 0.90, y: s * 0.48),
                       control2: CGPoint(x: s * 0.80, y: s * 0.88))
            p.addCurve(to: CGPoint(x: s * 0.50, y: s * 0.10),
                       control1: CGPoint(x: s * 0.20, y: s * 0.88),
                       control2: CGPoint(x: s * 0.10, y: s * 0.48))
            if filled { fill(p) } else { line(p) }

        case "snow":
            for i in 0..<3 {
                let a = Double(i) / 3.0 * Double.pi
                var p = Path()
                p.move(to: CGPoint(x: s * 0.5 - CGFloat(cos(a)) * s * 0.38, y: s * 0.5 - CGFloat(sin(a)) * s * 0.38))
                p.addLine(to: CGPoint(x: s * 0.5 + CGFloat(cos(a)) * s * 0.38, y: s * 0.5 + CGFloat(sin(a)) * s * 0.38))
                line(p)
            }

        default:
            var p = Path()
            p.addEllipse(in: CGRect(x: s * 0.28, y: s * 0.28, width: s * 0.44, height: s * 0.44))
            line(p)
        }
    }

    /// The glyph name for each Setting tag value.
    static func settingGlyph(_ s: POSetting) -> String {
        switch s {
        case .home: return "home"
        case .outdoors: return "tree"
        case .city: return "building"
        case .culture: return "mask"
        case .water: return "wave"
        case .food: return "cup"
        case .making: return "brush"
        case .moving: return "runner"
        }
    }

    static func weatherGlyph(_ w: POWeather) -> String {
        switch w {
        case .indoorSafe: return "home"
        case .needsDry: return "cloud"
        case .needsSun: return "sun"
        case .needsCold: return "snow"
        }
    }

    static func exposureGlyph(_ e: POExposure) -> String {
        switch e {
        case .solitary: return "door"
        case .strangers: return "person"
        case .talking: return "cup"
        }
    }
}
