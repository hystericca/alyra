import SwiftUI

struct LogEntryView: View {
    let date: Date
    let appTabPadding: CGFloat
    let unitSystem: UnitSystem
    let onSaveFood: (FoodLogEntry) -> Void
    let onSaveWeight: (WeightLogEntry) -> Void

    @State private var entryType = LogEntryType.food
    @State private var foodName = ""
    @State private var brand = ""
    @State private var mealTime = MealTime.breakfast
    @State private var servingGrams = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var weightValue = ""
    @State private var weightNote = ""

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    header
                    typePicker

                    switch entryType {
                    case .food:
                        foodForm
                        saveButton(title: "Save food", isEnabled: isFoodSaveEnabled, action: saveFood)

                    case .weight:
                        weightForm
                        saveButton(title: "Save weight", isEnabled: isWeightSaveEnabled, action: saveWeight)
                    }
                }
                .padding(AppTheme.Spacing.screen)
                .padding(.top, 2)
                .padding(.bottom, appTabPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(AppTheme.primaryText)
        .tint(AppTheme.accent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Log Entry")
                .font(AppTheme.Typography.header)
                .foregroundStyle(AppTheme.primaryText)

            Text(date.formatted(Date.FormatStyle.dateTime.weekday(.wide).month(.wide).day()))
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var typePicker: some View {
        HStack(spacing: 8) {
            ForEach(LogEntryType.allCases) { type in
                Button {
                    entryType = type
                } label: {
                    Label(type.rawValue, systemImage: type.symbolName)
                        .font(AppTheme.Typography.bodyStrong)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .foregroundStyle(entryType == type ? AppTheme.primaryText : AppTheme.mutedText)
                        .background(entryType == type ? AppTheme.controlFill : .clear)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppTheme.Radius.control,
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(entryType == type ? [.isSelected] : [])
            }
        }
        .padding(4)
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
        .accessibilityLabel("Entry type")
    }

    private var foodForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
            VStack(alignment: .leading, spacing: 16) {
                LogTextField(
                    title: "Food",
                    placeholder: "Greek yogurt",
                    text: $foodName,
                    keyboardType: .default
                )

                LogTextField(
                    title: "Brand",
                    placeholder: "Optional",
                    text: $brand,
                    keyboardType: .default
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal")
                        .font(AppTheme.Typography.eyebrow)
                        .foregroundStyle(AppTheme.mutedText)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Picker("Meal", selection: $mealTime) {
                        ForEach(MealTime.allCases) { meal in
                            Text(meal.rawValue).tag(meal)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .alyraInputPanel()

            VStack(alignment: .leading, spacing: 16) {
                LogTextField(
                    title: "Serving",
                    placeholder: "0",
                    text: $servingGrams,
                    keyboardType: .decimalPad,
                    suffix: "g"
                )

                LogTextField(
                    title: "Calories",
                    placeholder: "0",
                    text: $calories,
                    keyboardType: .decimalPad,
                    suffix: "kcal"
                )

                HStack(spacing: 12) {
                    LogTextField(
                        title: "Protein",
                        placeholder: "0",
                        text: $protein,
                        keyboardType: .decimalPad,
                        suffix: "g"
                    )

                    LogTextField(
                        title: "Carbs",
                        placeholder: "0",
                        text: $carbs,
                        keyboardType: .decimalPad,
                        suffix: "g"
                    )
                }

                HStack(spacing: 12) {
                    LogTextField(
                        title: "Fat",
                        placeholder: "0",
                        text: $fat,
                        keyboardType: .decimalPad,
                        suffix: "g"
                    )

                    LogTextField(
                        title: "Fiber",
                        placeholder: "0",
                        text: $fiber,
                        keyboardType: .decimalPad,
                        suffix: "g"
                    )
                }
            }
            .alyraInputPanel()
        }
    }

    private var weightForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            LogTextField(
                title: "Weight",
                placeholder: "0",
                text: $weightValue,
                keyboardType: .decimalPad,
                suffix: unitSystem.weightUnitName
            )

            LogTextField(
                title: "Note",
                placeholder: "Optional",
                text: $weightNote,
                keyboardType: .default
            )
        }
        .alyraInputPanel()
    }

    private func saveButton(
        title: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.bodyStrong)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(AppTheme.background)
                .background(isEnabled ? AppTheme.primaryText : AppTheme.mutedText)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.Radius.control,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var isFoodSaveEnabled: Bool {
        !foodName.trimmed.isEmpty
            && servingGrams.doubleValue != nil
            && calories.doubleValue != nil
            && protein.doubleValue != nil
            && carbs.doubleValue != nil
            && fat.doubleValue != nil
    }

    private var isWeightSaveEnabled: Bool {
        weightValue.doubleValue != nil
    }

    private func saveFood() {
        guard
            isFoodSaveEnabled,
            let servingGrams = servingGrams.doubleValue,
            let calories = calories.doubleValue,
            let protein = protein.doubleValue,
            let carbs = carbs.doubleValue,
            let fat = fat.doubleValue
        else {
            return
        }

        onSaveFood(
            FoodLogEntry(
                id: UUID(),
                foodName: foodName.trimmed,
                brand: brand.trimmed,
                mealTime: mealTime,
                loggedAt: date,
                servingGrams: servingGrams,
                nutrients: NutritionFacts(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    fiber: fiber.doubleValue ?? 0
                )
            )
        )

        resetFoodForm()
    }

    private func saveWeight() {
        guard let weightValue = weightValue.doubleValue else {
            return
        }

        onSaveWeight(
            WeightLogEntry(
                id: UUID(),
                loggedAt: date,
                displayWeight: weightValue,
                unitSystem: unitSystem,
                note: weightNote.trimmed
            )
        )

        resetWeightForm()
    }

    private func resetFoodForm() {
        foodName = ""
        brand = ""
        servingGrams = ""
        calories = ""
        protein = ""
        carbs = ""
        fat = ""
        fiber = ""
    }

    private func resetWeightForm() {
        weightValue = ""
        weightNote = ""
    }
}

private struct LogTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    var suffix: String?

    private var autocapitalization: TextInputAutocapitalization {
        switch keyboardType {
        case .default:
            return .words
        default:
            return .never
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.mutedText)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .font(AppTheme.Typography.body)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(keyboardType != .default)

                if let suffix {
                    Text(suffix)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(AppTheme.controlFill)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    func alyraInputPanel() -> some View {
        padding(14)
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

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var doubleValue: Double? {
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else {
            return nil
        }

        return value
    }
}

#Preview {
    LogEntryView(
        date: .now,
        appTabPadding: 90,
        unitSystem: .imperial,
        onSaveFood: { _ in },
        onSaveWeight: { _ in }
    )
}
