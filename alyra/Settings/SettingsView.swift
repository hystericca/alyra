import SwiftUI

enum AppSettingsKeys {
    static let dailyCalories = "alyra.settings.dailyCalories"
    static let proteinTarget = "alyra.settings.proteinTarget"
    static let carbsTarget = "alyra.settings.carbsTarget"
    static let fatTarget = "alyra.settings.fatTarget"
    static let unitSystem = "alyra.settings.unitSystem"
    static let healthKitNutritionWrite = "alyra.settings.healthKitNutritionSync"
    static let healthKitWeightWrite = "alyra.settings.healthKitWeightSync"
}

struct SettingsView: View {
    let appTabPadding: CGFloat
    var onImportAppleHealthWeights: () async throws -> WeightImportResult = {
        WeightImportResult(scanned: 0, inserted: 0, updated: 0)
    }

    @AppStorage(AppSettingsKeys.dailyCalories) private var dailyCalories = 2_200.0
    @AppStorage(AppSettingsKeys.proteinTarget) private var proteinTarget = 140.0
    @AppStorage(AppSettingsKeys.carbsTarget) private var carbsTarget = 250.0
    @AppStorage(AppSettingsKeys.fatTarget) private var fatTarget = 70.0
    @AppStorage(AppSettingsKeys.unitSystem) private var unitSystem = UnitSystem.imperial.rawValue
    @AppStorage(AppSettingsKeys.healthKitNutritionWrite) private var healthKitNutritionWrite = false
    @AppStorage(AppSettingsKeys.healthKitWeightWrite) private var healthKitWeightWrite = false
    @State private var healthKitStatusMessage = HealthKitSyncService.availability.message
    @State private var importMessage = "Import body mass samples that Apple Health allows Alyra to read."
    @State private var isImportingWeights = false

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

                    SettingsSection(title: "Apple Health") {
                        HealthKitPermissionRow(
                            statusMessage: healthKitStatusMessage,
                            isAvailable: HealthKitSyncService.availability.isAvailable,
                            action: requestHealthKitAuthorization
                        )

                        SettingsDivider()

                        HealthKitSyncToggleRow(
                            title: "Write food logs to Apple Health",
                            detail: "Alyra will attempt to write calories, protein, carbs, fat, and fiber after Apple Health grants write access.",
                            symbolName: "fork.knife",
                            isOn: $healthKitNutritionWrite
                        )

                        SettingsDivider()

                        HealthKitSyncToggleRow(
                            title: "Write weight logs to Apple Health",
                            detail: "Alyra will attempt to write manual weight logs after Apple Health grants write access.",
                            symbolName: "scalemass",
                            isOn: $healthKitWeightWrite
                        )

                        SettingsDivider()

                        HealthKitImportRow(
                            title: "Import Apple Health weight",
                            detail: importMessage,
                            symbolName: "square.and.arrow.down",
                            isImporting: isImportingWeights,
                            isAvailable: HealthKitSyncService.availability.isAvailable,
                            action: importAppleHealthWeights
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

    private func requestHealthKitAuthorization() {
        Task {
            do {
                try await HealthKitSyncService.requestAuthorization(scopes: [.nutrition, .weight])
                await MainActor.run {
                    healthKitStatusMessage = "Authorization requested. Apple Health controls each permission separately."
                }
            } catch {
                await MainActor.run {
                    healthKitStatusMessage = "Authorization failed. Check Health permissions and app capability."
                }
            }
        }
    }

    private func importAppleHealthWeights() {
        guard !isImportingWeights else { return }

        isImportingWeights = true

        Task {
            do {
                let result = try await onImportAppleHealthWeights()

                await MainActor.run {
                    importMessage = result.summary
                    isImportingWeights = false
                }
            } catch {
                await MainActor.run {
                    importMessage = "Import failed. Confirm read access in Apple Health, then try again."
                    isImportingWeights = false
                }
            }
        }
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
            .alyraPanel(padding: 0)
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

private struct HealthKitPermissionRow: View {
    let statusMessage: String
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsValueLabel(
                title: "Permissions",
                value: isAvailable ? "Available" : "Unavailable",
                symbolName: "heart.text.square"
            )

            Text(statusMessage)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Text("Request Apple Health Access")
                    .font(AppTheme.Typography.bodyStrong)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(AppTheme.background)
                    .background(isAvailable ? AppTheme.primaryText : AppTheme.mutedText)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.Radius.control,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isAvailable)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

private struct HealthKitSyncToggleRow: View {
    let title: String
    let detail: String
    let symbolName: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(detail)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}

private struct HealthKitImportRow: View {
    let title: String
    let detail: String
    let symbolName: String
    let isImporting: Bool
    let isAvailable: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(detail)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: action) {
                Text(isImporting ? "Importing..." : "Import Weight Samples")
                    .font(AppTheme.Typography.bodyStrong)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(AppTheme.primaryText)
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: AppTheme.Radius.control,
                            style: .continuous
                        )
                        .strokeBorder(AppTheme.border, lineWidth: AppTheme.Stroke.hairline)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isAvailable || isImporting)
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
