import SwiftUI

/// Splash shown while the launch check runs. Draws the app's own emblem —
/// a small round table with one chair and a lit candle.
struct POLoadingScreen: View {
    @State private var glow: Double = 0.35
    @State private var sweep: CGFloat = 0

    var body: some View {
        ZStack {
            POTheme.paper.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(POTheme.gold.opacity(glow * 0.28))
                        .frame(width: 168, height: 168)
                        .blur(radius: 18)
                    Circle()
                        .stroke(POTheme.plumSoft.opacity(0.35), lineWidth: 1)
                        .frame(width: 150, height: 150)
                    POGlyph(name: "table", size: 96, color: POTheme.plumDeep, lineWidth: 1.8)
                }

                VStack(spacing: 6) {
                    Text("Party of One")
                        .font(POFont.display(30))
                        .foregroundColor(POTheme.plumDeep)
                    Text("A table for one is a good table")
                        .font(POFont.body(14))
                        .foregroundColor(POTheme.inkSoft)
                }

                Spacer(minLength: 0)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(POTheme.hairline)
                        Capsule()
                            .fill(POTheme.plum)
                            .frame(width: max(12, geo.size.width * 0.34))
                            .offset(x: sweep * (geo.size.width * 1.34) - geo.size.width * 0.34)
                    }
                    .clipShape(Capsule())
                }
                .frame(width: min(220, POScreen.width * 0.55), height: 4)
                .padding(.bottom, 54)
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                glow = 1.0
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                sweep = 1.0
            }
        }
    }
}
