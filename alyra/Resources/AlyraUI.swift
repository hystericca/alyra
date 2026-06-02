//
//  AlyraUI.swift
//  alyra
//
//  Created by Viktor Luna on 6/1/26.
//

import SwiftUI

enum AlyraPanelBorder {
    case subtle
    case strong

    var color: Color {
        switch self {
        case .subtle: AppTheme.border
        case .strong: AppTheme.strongBorder
        }
    }
}

struct AlyraSeparator: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, AppTheme.separator, AppTheme.separator, .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: AppTheme.Stroke.hairline)
    }
}

struct AlyraSectionTitle: View {
    let title: String
    var symbolName: String?
    var trailingText: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(AppTheme.Typography.sectionIcon)
                    .foregroundStyle(AppTheme.mutedText)
                    .frame(width: 28, alignment: .leading)
            }

            Text(title)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: AppTheme.Spacing.sm)

            if let trailingText {
                Text(trailingText)
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundStyle(AppTheme.mutedText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
    }
}

private struct AlyraPanelModifier: ViewModifier {
    let padding: CGFloat
    let border: AlyraPanelBorder

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surfaceRaised)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.card,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.card,
                    style: .continuous
                )
                .strokeBorder(border.color, lineWidth: AppTheme.Stroke.hairline)
            }
    }
}

private struct AlyraInputPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, AppTheme.Spacing.xs)
    }
}

extension View {
    func alyraPanel(
        padding: CGFloat = AppTheme.Spacing.md,
        border: AlyraPanelBorder = .subtle
    ) -> some View {
        modifier(AlyraPanelModifier(padding: padding, border: border))
    }

    func alyraInputPanel() -> some View {
        modifier(AlyraInputPanelModifier())
    }
}
