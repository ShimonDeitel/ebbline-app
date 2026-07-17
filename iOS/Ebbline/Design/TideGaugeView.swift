import SwiftUI

/// The animation hook: a vertical tide-gauge meter whose liquid teal fill
/// rises or recedes with a real wavy top edge whenever `value` changes, plus
/// a continuous idle ripple and a radial pulse at the fill line on every
/// change.
struct TideGaugeView: View {
    var value: Double
    var maxValue: Double
    var isWarning: Bool = false

    @State private var fillFraction: CGFloat = 0
    @State private var pulses: [RipplePulse] = []

    private struct RipplePulse: Identifiable {
        let id = UUID()
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let fillHeight = height * fillFraction

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: width / 2, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: width / 2, style: .continuous)
                            .stroke(EbblineTheme.foam.opacity(0.28), lineWidth: 2)
                    )

                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    WaveShape(amplitude: 6, wavelength: max(width * 0.7, 40), phase: t * 1.6)
                        .fill(isWarning ? EbblineTheme.shortfallGradient : EbblineTheme.waterGradient)
                        .frame(height: fillHeight)
                }
                .frame(height: height, alignment: .bottom)
                .allowsHitTesting(false)

                ForEach(pulses) { pulse in
                    RipplePulseView()
                        .offset(y: -fillHeight)
                        .id(pulse.id)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: width / 2, style: .continuous))
            .onAppear {
                fillFraction = fraction(for: value)
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeInOut(duration: 0.8)) {
                    fillFraction = fraction(for: newValue)
                }
                pulses.append(RipplePulse())
                if pulses.count > 4 { pulses.removeFirst(pulses.count - 4) }
            }
        }
    }

    private func fraction(for value: Double) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(max(0, min(1, value / maxValue)))
    }
}

/// A single soft ripple: an expanding, fading ring at the fill line.
private struct RipplePulseView: View {
    @State private var expanded = false

    var body: some View {
        Circle()
            .stroke(EbblineTheme.foam.opacity(expanded ? 0 : 0.65), lineWidth: 3)
            .frame(width: expanded ? 150 : 18, height: expanded ? 150 : 18)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) {
                    expanded = true
                }
            }
    }
}
