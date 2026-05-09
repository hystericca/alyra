import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

enum AppTheme {
    #if canImport(UIKit)
        static let background = Color(uiColor: .systemBackground)
        static let surface = Color(uiColor: .secondarySystemBackground)
        static let elevatedSurface = Color(uiColor: .tertiarySystemBackground)
    #elseif canImport(AppKit)
        static let background = Color(nsColor: .windowBackgroundColor)
        static let surface = Color(nsColor: .underPageBackgroundColor)
        static let elevatedSurface = Color(nsColor: .controlBackgroundColor)
    #else
        static let background = Color.white
        static let surface = Color.primary.opacity(0.04)
        static let elevatedSurface = Color.primary.opacity(0.07)
    #endif

    static let border = Color.primary.opacity(0.08)
    static let mutedText = Color.secondary

    static let cardRadius: CGFloat = 8
    static let controlRadius: CGFloat = 8
}

extension View {
    func melaCard() -> some View {
        self
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }

    @ViewBuilder
    func melaInlineNavigationTitle() -> some View {
        #if os(iOS)
            self.navigationBarTitleDisplayMode(.inline)
        #else
            self
        #endif
    }
}
