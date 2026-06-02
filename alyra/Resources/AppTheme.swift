//
//  AppTheme.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

enum AppTheme {
    static let preferredColorScheme: ColorScheme = .dark

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24

        static let screen: CGFloat = lg
        static let section: CGFloat = xl
        static let stack: CGFloat = md
    }

    enum Radius {
        static let card: CGFloat = 8
        static let control: CGFloat = 8
    }

    enum Stroke {
        static let hairline: CGFloat = 0.5
        static let panel: CGFloat = 1.0
    }

    enum Typography {
        private static let regular = "IBMPlexSans"
        private static let medium = "IBMPlexSans-Medium"
        private static let semibold = "IBMPlexSans-SmBld"

        static let eyebrow = Font.custom(semibold, size: 11, relativeTo: .caption2)
        static let caption = Font.custom(regular, size: 12, relativeTo: .caption)
        static let body = Font.custom(regular, size: 15, relativeTo: .body)
        static let bodyStrong = Font.custom(medium, size: 15, relativeTo: .body)
        static let sectionTitle = Font.custom(medium, size: 17, relativeTo: .headline)
        static let sectionHeader = Font.custom(medium, size: 26, relativeTo: .title2)
        static let sectionIcon = Font.system(size: 23, weight: .medium)
        static let metric = Font.custom(medium, size: 22, relativeTo: .title3)
        static let mealHeader = sectionHeader
        static let header = Font.custom(semibold, size: 30, relativeTo: .largeTitle)
        static let gaugeNumber = Font.custom(semibold, size: 72, relativeTo: .largeTitle)
        static let gaugeUnit = Font.custom(regular, size: 12, relativeTo: .caption)
    }

    enum Motion {
        static func contentChange(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .smooth(duration: 0.24)
        }

        static func press(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .smooth(duration: 0.12)
        }

        static func dateChange(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .smooth(duration: 0.22)
        }

        static func delete(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .smooth(duration: 0.22)
        }

        static func dateTransition(
            insertionEdge: Edge,
            removalEdge: Edge,
            reduceMotion: Bool
        ) -> AnyTransition {
            guard !reduceMotion else { return .identity }

            return .asymmetric(
                insertion: .opacity
                    .combined(with: .move(edge: insertionEdge))
                    .combined(with: .scale(scale: 0.98, anchor: .center)),
                removal: .opacity
                    .combined(with: .move(edge: removalEdge))
                    .combined(with: .scale(scale: 0.98, anchor: .center))
            )
        }

        static func rowTransition(reduceMotion: Bool) -> AnyTransition {
            reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.98))
        }
    }

    enum Navigation {
        static let railCornerRadius: CGFloat = 16
        static let railHorizontalPadding: CGFloat = 16
        static let railInnerPadding: CGFloat = 4
        static let railBottomPadding: CGFloat = 10
        static let itemCornerRadius: CGFloat = 12
        static let itemHeight: CGFloat = 44

        static func railHeight(bottomInset: CGFloat) -> CGFloat {
            itemHeight + railInnerPadding * 2 + railBottomPadding + bottomInset
        }

        static func contentInset(bottomInset: CGFloat) -> CGFloat {
            railHeight(bottomInset: bottomInset) + 18
        }
    }

    enum Control {
        static let minimumHitSize: CGFloat = 44
        static let fieldHeight: CGFloat = 48
        static let compactFieldHeight: CGFloat = 38
    }

    static let background = Color(light: 0xFFFFFF, dark: 0x000000)
    static let surface = Color(light: 0xFFFFFF, dark: 0x000000)
    static let surfaceRaised = Color(light: 0xFFFFFF, dark: 0x000000)

    static let primaryText = Color(light: 0x000000, dark: 0xFFFFFF)
    static let secondaryText = Color(
        light: 0x000000,
        dark: 0xFFFFFF,
        lightOpacity: 0.82,
        darkOpacity: 0.86
    )
    static let mutedText = Color(
        light: 0x000000,
        dark: 0xFFFFFF,
        lightOpacity: 0.58,
        darkOpacity: 0.66
    )

    static let border = Color(
        light: 0x000000,
        dark: 0xFFFFFF,
        lightOpacity: 0.055,
        darkOpacity: 0.075
    )

    static let separator = Color(
        light: 0x000000,
        dark: 0xFFFFFF,
        lightOpacity: 0.035,
        darkOpacity: 0.055
    )

    static let strongBorder = Color(
        light: 0x000000,
        dark: 0xFFFFFF,
        lightOpacity: 0.095,
        darkOpacity: 0.12
    )

    static let controlFill = Color(
        light: 0x000000,
        dark: 0xFFFFFF,
        lightOpacity: 0.025,
        darkOpacity: 0.040
    )

    static let accent = Color(light: 0x000000, dark: 0xFFFFFF)

    static let tickTrack = Color(
        light: 0x000000,
        dark: 0xFFFFFF,
        lightOpacity: 0.08,
        darkOpacity: 0.10
    )

    static func dataProgressGradient(_ kind: DataGradientKind) -> LinearGradient {
        LinearGradient(
            colors: dataColors(kind),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func dataAngularGradient(
        _ kind: DataGradientKind,
        startAngle: Angle,
        endAngle: Angle
    ) -> AngularGradient {
        AngularGradient(
            colors: dataColors(kind),
            center: .center,
            startAngle: startAngle,
            endAngle: endAngle
        )
    }

    static func dataAccent(_ kind: DataGradientKind) -> Color {
        dataColor(kind, fraction: 0.22)
    }

    static func dataGradientColors(_ kind: DataGradientKind) -> [Color] {
        dataColors(kind)
    }

    static func dataAreaGradientColors(_ kind: DataGradientKind) -> [Color] {
        [
            dataColor(kind, fraction: 0.12).opacity(0.14),
            dataColor(kind, fraction: 0.62).opacity(0.06),
            background.opacity(0.04),
        ]
    }

    private static func dataColor(
        _ kind: DataGradientKind,
        fraction: Double
    ) -> Color {
        let clampedFraction = min(max(fraction, 0), 1)
        let stops = dataHexStops(kind)

        return Color(
            light: interpolateHex(stops.light.0, stops.light.1, fraction: clampedFraction),
            dark: interpolateHex(stops.dark.0, stops.dark.1, fraction: clampedFraction)
        )
    }

    private static func dataColors(_ kind: DataGradientKind) -> [Color] {
        [
            Color(
                light: dataHexStops(kind).light.0,
                dark: dataHexStops(kind).dark.0
            ),
            Color(
                light: dataHexStops(kind).light.1,
                dark: dataHexStops(kind).dark.1
            ),
        ]
    }

    private static func dataHexStops(
        _ kind: DataGradientKind
    ) -> (light: (UInt, UInt), dark: (UInt, UInt)) {
        switch kind {
        case .energy, .protein, .weight,
             .carbs, .fat, .expenditure,
             .balancePositive, .balanceNegative,
             .poultry, .yogurt, .berries, .shake,
             .generic:
            return ((0x000000, 0x000000), (0xFFFFFF, 0xFFFFFF))
        }
    }

    private static func interpolateHex(
        _ start: UInt,
        _ end: UInt,
        fraction: Double
    ) -> UInt {
        let red = interpolateChannel(start >> 16, end >> 16, fraction: fraction)
        let green = interpolateChannel(start >> 8, end >> 8, fraction: fraction)
        let blue = interpolateChannel(start, end, fraction: fraction)

        return (red << 16) | (green << 8) | blue
    }

    private static func interpolateChannel(
        _ start: UInt,
        _ end: UInt,
        fraction: Double
    ) -> UInt {
        let startValue = Double(start & 0xFF)
        let endValue = Double(end & 0xFF)

        return UInt((startValue + (endValue - startValue) * fraction).rounded())
    }
}

struct AlyraIconButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var foreground: Color = AppTheme.secondaryText

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(
                width: AppTheme.Control.minimumHitSize,
                height: AppTheme.Control.minimumHitSize
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .offset(y: configuration.isPressed && !reduceMotion ? 1 : 0)
            .animation(
                AppTheme.Motion.press(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}

struct AlyraGhostIconButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var foreground: Color = AppTheme.mutedText

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(
                width: AppTheme.Control.minimumHitSize,
                height: AppTheme.Control.minimumHitSize
            )
            .contentShape(Rectangle())
            .background(configuration.isPressed ? AppTheme.controlFill : .clear)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(
                AppTheme.Motion.press(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}

extension View {
    func alyraIconButtonStyle(
        foreground: Color = AppTheme.secondaryText
    ) -> some View {
        buttonStyle(AlyraIconButtonStyle(foreground: foreground))
    }

    func alyraGhostIconButtonStyle(
        foreground: Color = AppTheme.mutedText
    ) -> some View {
        buttonStyle(AlyraGhostIconButtonStyle(foreground: foreground))
    }
}

#if canImport(UIKit)
    extension Color {
        fileprivate init(
            light: UInt,
            dark: UInt,
            lightOpacity: CGFloat = 1,
            darkOpacity: CGFloat = 1
        ) {
            self.init(
                uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(hex: dark, alpha: darkOpacity)
                        : UIColor(hex: light, alpha: lightOpacity)
                }
            )
        }
    }

    extension UIColor {
        fileprivate convenience init(hex: UInt, alpha: CGFloat = 1) {
            self.init(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: alpha
            )
        }
    }
#else
    extension Color {
        fileprivate init(
            light: UInt,
            dark: UInt,
            lightOpacity: CGFloat = 1,
            darkOpacity: CGFloat = 1
        ) {
            self.init(
                red: Double((dark >> 16) & 0xFF) / 255,
                green: Double((dark >> 8) & 0xFF) / 255,
                blue: Double(dark & 0xFF) / 255,
                opacity: Double(darkOpacity)
            )
        }
    }
#endif
