//
//  SettingsView.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import SwiftUI

struct SettingsView: View {
    let appTabPadding: CGFloat

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    header

                    SettingsSection(title: "Goals") {
                        SettingsRow(
                            title: "Daily calories",
                            value: "2,200 kcal",
                            symbolName: "flame.fill"
                        )

                        SettingsRow(
                            title: "Protein target",
                            value: "140 g",
                            symbolName: "dumbbell.fill"
                        )
                    }

                    SettingsSection(title: "Preferences") {
                        SettingsRow(
                            title: "Units",
                            value: "Imperial",
                            symbolName: "ruler"
                        )

                        SettingsRow(
                            title: "Reduce motion",
                            value: "System",
                            symbolName: "circle.lefthalf.filled"
                        )
                    }

                    SettingsSection(title: "Data") {
                        SettingsRow(
                            title: "Food database",
                            value: "Demo",
                            symbolName: "tray.full"
                        )

                        SettingsRow(
                            title: "Health sync",
                            value: "Off",
                            symbolName: "heart.text.square"
                        )
                    }
                }
                .padding(AppTheme.Spacing.screen)
                .padding(.top, 2)
                .padding(.bottom, appTabPadding)
            }
        }
        .foregroundStyle(AppTheme.primaryText)
        .tint(AppTheme.accent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(AppTheme.Typography.header)
                .foregroundStyle(AppTheme.primaryText)

            Text("Manage goals, preferences, and app data.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.mutedText)
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(spacing: 0) {
                content
            }
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
                .strokeBorder(AppTheme.border, lineWidth: AppTheme.Stroke.hairline)
            }
        }
    }
}

private struct SettingsRow: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 22)

            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.primaryText)

            Spacer(minLength: 12)

            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.mutedText)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.mutedText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}

#Preview {
    SettingsView(appTabPadding: 90)
}
