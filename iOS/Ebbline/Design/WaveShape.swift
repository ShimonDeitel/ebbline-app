import SwiftUI

/// A filled band whose top edge is a real sine wave. Used as the liquid fill
/// of the tide gauge and anywhere else a "progress" surface is needed —
/// Ebbline never uses a flat rectangle for these.
struct WaveShape: Shape {
    var amplitude: CGFloat
    var wavelength: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard rect.width > 0, rect.height >= 0 else { return path }

        let width = rect.width
        let crestY = rect.minY + amplitude
        path.move(to: CGPoint(x: rect.minX, y: crestY))

        let step: CGFloat = max(2, width / 120)
        var x: CGFloat = 0
        while x <= width {
            let relative = x / max(wavelength, 1)
            let sine = sin(relative * 2 * .pi + phase)
            let y = crestY + sine * amplitude
            path.addLine(to: CGPoint(x: rect.minX + x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A thin wavy line — the bespoke replacement for `Divider()` / straight
/// progress rules throughout Ebbline.
struct WaveDivider: Shape {
    var amplitude: CGFloat = 3
    var wavelength: CGFloat = 40
    var phase: CGFloat = 0

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard rect.width > 0 else { return path }
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: midY))
        let step: CGFloat = max(2, rect.width / 100)
        var x: CGFloat = 0
        while x <= rect.width {
            let relative = x / max(wavelength, 1)
            let sine = sin(relative * 2 * .pi + phase)
            let y = midY + sine * amplitude
            path.addLine(to: CGPoint(x: rect.minX + x, y: y))
            x += step
        }
        return path
    }
}
