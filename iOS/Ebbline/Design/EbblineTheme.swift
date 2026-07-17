import SwiftUI

/// Bespoke aqua-to-teal palette. Coral is reserved strictly for
/// shortfall/warning states — it never appears anywhere else in the UI.
enum EbblineTheme {
    static let deepTeal = Color(red: 0x0B / 255, green: 0x4F / 255, blue: 0x5C / 255)
    static let midTeal = Color(red: 0x0E / 255, green: 0x6C / 255, blue: 0x74 / 255)
    static let aqua = Color(red: 0x2F / 255, green: 0xD3 / 255, blue: 0xC7 / 255)
    static let brightAqua = Color(red: 0x3E / 255, green: 0xE8 / 255, blue: 0xCE / 255)
    static let foam = Color(red: 0xBF / 255, green: 0xF3 / 255, blue: 0xEA / 255)
    static let ink = Color(red: 0x06 / 255, green: 0x2B / 255, blue: 0x33 / 255)
    static let coral = Color(red: 0xFF / 255, green: 0x7A / 255, blue: 0x59 / 255)

    static let backgroundGradient = LinearGradient(
        colors: [deepTeal, midTeal],
        startPoint: .top,
        endPoint: .bottom
    )

    static let waterGradient = LinearGradient(
        colors: [brightAqua, aqua],
        startPoint: .top,
        endPoint: .bottom
    )

    static let shortfallGradient = LinearGradient(
        colors: [coral, Color(red: 0xE0 / 255, green: 0x4F / 255, blue: 0x3A / 255)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Standard glassy panel: `.ultraThinMaterial` with a teal tint over it.
    static func glassPanel(cornerRadius: CGFloat = 24) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(deepTeal.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(foam.opacity(0.25), lineWidth: 1)
            )
    }
}

extension View {
    /// Applies the standard Ebbline glass-panel background.
    func ebblineGlass(cornerRadius: CGFloat = 24) -> some View {
        self.background(EbblineTheme.glassPanel(cornerRadius: cornerRadius))
    }
}
