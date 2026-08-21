import SwiftUI

// MARK: - Four-axis radar

/// A small radar for one entry's four scores. `side` is passed in explicitly —
/// a Canvas closure's own size is not the parent's size.
struct PORadar: View {
    let recharge: Int
    let novelty: Int
    let comfort: Int
    let worth: Int
    var side: CGFloat = 84
    var showLabels: Bool = false

    private var values: [Double] {
        [Double(recharge), Double(novelty), Double(comfort), Double(worth)]
            .map { POMath.clamp($0, 0, 5) }
    }

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            guard s > 4 else { return }
            let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let labelPad: CGFloat = showLabels ? s * 0.20 : 0
            let radius = (s / 2) - 2 - labelPad
            guard radius > 2 else { return }

            // Rings
            for ring in 1...5 {
                let r = radius * CGFloat(ring) / 5
                var p = Path()
                for i in 0..<4 {
                    let a = -Double.pi / 2 + Double(i) * Double.pi / 2
                    let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
                ctx.stroke(p, with: .color(POTheme.hairline), lineWidth: ring == 5 ? 1.2 : 0.6)
            }
            // Spokes
            for i in 0..<4 {
                let a = -Double.pi / 2 + Double(i) * Double.pi / 2
                var p = Path()
                p.move(to: c)
                p.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * radius, y: c.y + CGFloat(sin(a)) * radius))
                ctx.stroke(p, with: .color(POTheme.hairline), lineWidth: 0.6)
            }
            // Shape
            var shape = Path()
            for (i, v) in values.enumerated() {
                let a = -Double.pi / 2 + Double(i) * Double.pi / 2
                let r = radius * CGFloat(v / 5)
                let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                if i == 0 { shape.move(to: pt) } else { shape.addLine(to: pt) }
            }
            shape.closeSubpath()
            ctx.fill(shape, with: .color(POTheme.plum.opacity(0.28)))
            ctx.stroke(shape, with: .color(POTheme.plum), lineWidth: 1.6)

            for (i, v) in values.enumerated() {
                let a = -Double.pi / 2 + Double(i) * Double.pi / 2
                let r = radius * CGFloat(v / 5)
                let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                var dot = Path()
                dot.addEllipse(in: CGRect(x: pt.x - 2.4, y: pt.y - 2.4, width: 4.8, height: 4.8))
                ctx.fill(dot, with: .color(POTheme.plumDeep))
            }

            if showLabels {
                let titles = ["Recharge", "Novelty", "Comfort", "Worth"]
                for (i, title) in titles.enumerated() {
                    let a = -Double.pi / 2 + Double(i) * Double.pi / 2
                    let r = radius + labelPad * 0.55
                    let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                    var text = ctx.resolve(Text(title).font(POFont.semibold(9)))
                    text.shading = .color(POTheme.inkSoft)
                    ctx.draw(text, at: pt, anchor: .center)
                }
            }
        }
        .frame(width: side, height: side)
    }
}

// MARK: - Ranked horizontal bars

struct POTagBarRow: View {
    let stat: POTagStat
    let width: CGFloat
    var accent: Color = POTheme.plum

    var body: some View {
        let barWidth = max(60, width)
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(stat.label)
                    .font(POFont.semibold(13))
                    .foregroundColor(POTheme.ink)
                Spacer(minLength: 4)
                if stat.samples == 0 {
                    Text("never tried")
                        .font(POFont.body(11))
                        .foregroundColor(POTheme.inkFaint)
                } else if !stat.isConfident {
                    Text("still learning")
                        .font(POFont.body(11))
                        .foregroundColor(POTheme.terracotta)
                } else {
                    Text(POFormat.score(stat.meanRecharge))
                        .font(POFont.mono(13))
                        .foregroundColor(accent)
                }
                Text(stat.samples == 1 ? "1 outing" : "\(stat.samples) outings")
                    .font(POFont.mono(10))
                    .foregroundColor(POTheme.inkFaint)
                    .frame(width: 66, alignment: .trailing)
            }
            Canvas { ctx, size in
                let h = size.height
                guard size.width > 1, h > 1 else { return }
                var track = Path()
                track.addRoundedRect(in: CGRect(x: 0, y: 0, width: size.width, height: h),
                                     cornerSize: CGSize(width: h / 2, height: h / 2))
                ctx.fill(track, with: .color(POTheme.paperDeep))

                guard let mean = stat.meanRecharge, stat.samples > 0 else { return }
                let frac = POMath.clamp(mean / 5.0, 0, 1)
                let w = max(h, size.width * CGFloat(frac))
                var bar = Path()
                bar.addRoundedRect(in: CGRect(x: 0, y: 0, width: w, height: h),
                                   cornerSize: CGSize(width: h / 2, height: h / 2))
                ctx.fill(bar, with: .color(stat.isConfident ? accent : accent.opacity(0.35)))

                // Tick marks at each whole score so the scale is readable.
                for i in 1..<5 {
                    let x = size.width * CGFloat(i) / 5
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: 0))
                    tick.addLine(to: CGPoint(x: x, y: h))
                    ctx.stroke(tick, with: .color(POTheme.paper.opacity(0.7)), lineWidth: 1)
                }
            }
            .frame(width: barWidth, height: 12)
        }
    }
}

// MARK: - Recharge vs cost scatter

struct POScatterChart: View {
    let points: [POScatterPoint]
    let width: CGFloat
    let height: CGFloat
    let currency: String

    var body: some View {
        let maxSpend = max(1, points.map { $0.spent }.max() ?? 1)
        VStack(alignment: .leading, spacing: 6) {
            Canvas { ctx, size in
                let w = size.width
                let h = size.height
                guard w > 20, h > 20 else { return }
                let padL: CGFloat = 26
                let padB: CGFloat = 18
                let plotW = w - padL - 6
                let plotH = h - padB - 8
                guard plotW > 10, plotH > 10 else { return }

                // Horizontal guides for each Recharge value.
                for v in 1...5 {
                    let y = 8 + plotH * CGFloat(5 - v) / 4
                    var line = Path()
                    line.move(to: CGPoint(x: padL, y: y))
                    line.addLine(to: CGPoint(x: padL + plotW, y: y))
                    ctx.stroke(line, with: .color(POTheme.hairline), lineWidth: 0.7)
                    var label = ctx.resolve(Text("\(v)").font(POFont.mono(9)))
                    label.shading = .color(POTheme.inkFaint)
                    ctx.draw(label, at: CGPoint(x: padL - 10, y: y), anchor: .center)
                }
                // Axis
                var axis = Path()
                axis.move(to: CGPoint(x: padL, y: 8))
                axis.addLine(to: CGPoint(x: padL, y: 8 + plotH))
                axis.addLine(to: CGPoint(x: padL + plotW, y: 8 + plotH))
                ctx.stroke(axis, with: .color(POTheme.inkFaint), lineWidth: 1)

                for p in points {
                    let fx = POMath.clamp(p.spent / maxSpend, 0, 1)
                    let x = padL + plotW * CGFloat(fx)
                    let fy = POMath.clamp((p.recharge - 1) / 4, 0, 1)
                    let y = 8 + plotH * CGFloat(1 - fy)
                    var dot = Path()
                    dot.addEllipse(in: CGRect(x: x - 4.5, y: y - 4.5, width: 9, height: 9))
                    ctx.fill(dot, with: .color(POTheme.scoreColor(p.recharge).opacity(0.8)))
                    ctx.stroke(dot, with: .color(POTheme.paper), lineWidth: 1.2)
                }

                var zero = ctx.resolve(Text(POFormat.money(0, symbol: currency)).font(POFont.mono(9)))
                zero.shading = .color(POTheme.inkFaint)
                ctx.draw(zero, at: CGPoint(x: padL + 2, y: h - 6), anchor: .leading)
                var top = ctx.resolve(Text(POFormat.money(maxSpend, symbol: currency)).font(POFont.mono(9)))
                top.shading = .color(POTheme.inkFaint)
                ctx.draw(top, at: CGPoint(x: padL + plotW, y: h - 6), anchor: .trailing)
            }
            .frame(width: width, height: height)
            HStack {
                Text("Recharge, vertical")
                    .font(POFont.body(10))
                    .foregroundColor(POTheme.inkFaint)
                Spacer(minLength: 4)
                Text("Amount spent, horizontal")
                    .font(POFont.body(10))
                    .foregroundColor(POTheme.inkFaint)
            }
            .frame(width: width)
        }
    }
}

// MARK: - Month heat grid

struct POMonthGrid: View {
    let cells: [POMonthCell]
    let leadingBlanks: Int
    let width: CGFloat
    let weekStartsMonday: Bool

    private var dayLabels: [String] {
        weekStartsMonday
            ? ["M", "T", "W", "T", "F", "S", "S"]
            : ["S", "M", "T", "W", "T", "F", "S"]
    }

    var body: some View {
        let spacing: CGFloat = 5
        let cellSize = max(14, (max(120, width) - spacing * 6) / 7)
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { pair in
                    Text(pair.element)
                        .font(POFont.mono(9))
                        .foregroundColor(POTheme.inkFaint)
                        .frame(width: cellSize)
                }
            }
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col - leadingBlanks
                        if index >= 0 && index < cells.count {
                            cellView(cells[index], size: cellSize)
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private var rowCount: Int {
        let total = cells.count + leadingBlanks
        return max(1, Int(ceil(Double(total) / 7.0)))
    }

    private func cellView(_ cell: POMonthCell, size: CGFloat) -> some View {
        let fill: Color
        if cell.count == 0 {
            fill = POTheme.paperDeep
        } else if let mean = cell.meanRecharge {
            fill = POTheme.scoreColor(mean).opacity(0.85)
        } else {
            fill = POTheme.plumSoft
        }
        return ZStack {
            RoundedRectangle(cornerRadius: 5).fill(fill)
            RoundedRectangle(cornerRadius: 5).stroke(POTheme.hairline, lineWidth: 0.6)
            Text("\(cell.day)")
                .font(POFont.mono(9))
                .foregroundColor(cell.count == 0 ? POTheme.inkFaint : POTheme.paper)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mini score row (used on journal cards)

struct POScorePips: View {
    let label: String
    let value: Int
    var color: Color = POTheme.plum

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(POFont.body(11))
                .foregroundColor(POTheme.inkSoft)
                .frame(width: 62, alignment: .leading)
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= value ? color : POTheme.hairline)
                        .frame(width: 7, height: 7)
                }
            }
        }
    }
}

// MARK: - Collection header art

/// A procedurally drawn header for each collection — no image assets, and it
/// varies deterministically by collection id.
struct POCollectionArt: View {
    let seedText: String
    let accent: Color
    let glyph: String
    let width: CGFloat
    var height: CGFloat = 92

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                guard size.width > 2, size.height > 2 else { return }
                var rng = POSeededRandom(seed: UInt64(abs(seedText.hashValue % 100000) + 3))
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(accent.opacity(0.12)))
                for i in 0..<7 {
                    let r = CGFloat(20 + rng.nextDouble() * 70)
                    let x = CGFloat(rng.nextDouble()) * size.width
                    let y = CGFloat(rng.nextDouble()) * size.height
                    var p = Path()
                    p.addEllipse(in: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r))
                    ctx.stroke(p, with: .color(accent.opacity(0.16 + Double(i % 3) * 0.06)),
                               lineWidth: 1.2)
                }
                for i in 0..<4 {
                    var p = Path()
                    let y = size.height * CGFloat(0.2 + Double(i) * 0.2)
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addQuadCurve(to: CGPoint(x: size.width, y: y),
                                   control: CGPoint(x: size.width / 2,
                                                    y: y + CGFloat((rng.nextDouble() - 0.5) * 40)))
                    ctx.stroke(p, with: .color(accent.opacity(0.14)), lineWidth: 1)
                }
            }
            .frame(width: width, height: height)
            POGlyph(name: glyph, size: height * 0.5, color: accent.opacity(0.85), lineWidth: 1.6)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
