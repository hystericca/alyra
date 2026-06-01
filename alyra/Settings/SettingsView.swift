import SwiftUI

enum AppSettingsKeys {
    static let dailyCalories = "alyra.settings.dailyCalories"
    static let proteinTarget = "alyra.settings.proteinTarget"
    static let carbsTarget = "alyra.settings.carbsTarget"
    static let fatTarget = "alyra.settings.fatTarget"
    static let unitSystem = "alyra.settings.unitSystem"
}

private enum UnitSystem: String, CaseIterable, Identifiable {
    case imperial = "Imperial"
    case metric = "Metric"

    var id: String { rawValue }
}

struct SettingsView: View {
    let appTabPadding: CGFloat

    @AppStorage(AppSettingsKeys.dailyCalories) private var dailyCalories = 2_200.0
    @AppStorage(AppSettingsKeys.proteinTarget) private var proteinTarget = 140.0
    @AppStorage(AppSettingsKeys.carbsTarget) private var carbsTarget = 250.0
    @AppStorage(AppSettingsKeys.fatTarget) private var fatTarget = 70.0
    @AppStorage(AppSettingsKeys.unitSystem) private var unitSystem = UnitSystem.imperial.rawValue

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    header

                    SettingsSection(title: "Goals") {
                        GoalStepperRow(
                            title: "Daily calories",
                            value: $dailyCalories,
                            range: 1_000...5_000,
                            step: 50,
                            unit: "kcal",
                            symbolName: "flame.fill"
                        )

                        SettingsDivider()

                        GoalStepperRow(
                            title: "Protein target",
                            value: $proteinTarget,
                            range: 40...300,
                            step: 5,
                            unit: "g",
                            symbolName: "dumbbell.fill"
                        )

                        SettingsDivider()

                        GoalStepperRow(
                            title: "Carbs target",
                            value: $carbsTarget,
                            range: 40...500,
                            step: 5,
                            unit: "g",
                            symbolName: "bolt.fill"
                        )

                        SettingsDivider()

                        GoalStepperRow(
                            title: "Fat target",
                            value: $fatTarget,
                            range: 20...200,
                            step: 5,
                            unit: "g",
                            symbolName: "drop.fill"
                        )
                    }

                    SettingsSection(title: "Preferences") {
                        UnitPickerRow(selection: $unitSystem)
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

            Text("Set the daily goals used by your dashboard.")
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

private struct GoalStepperRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let symbolName: String

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            SettingsValueLabel(
                title: title,
                value: "\(DashboardNumberText.wholeNumber(value)) \(unit)",
                symbolName: symbolName
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

private struct UnitPickerRow: View {
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsValueLabel(
                title: "Units",
                value: selection,
                symbolName: "ruler"
            )

            Picker("Units", selection: $selection) {
                ForEach(UnitSystem.allCases) { system in
                    Text(system.rawValue).tag(system.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

private struct SettingsValueLabel: View {
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
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.separator)
            .frame(height: AppTheme.Stroke.hairline)
            .padding(.leading, 48)
    }
}

#Preview {
    SettingsView(appTabPadding: 90)
}
