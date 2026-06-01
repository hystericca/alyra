import SwiftUI

struct LogEntryView: View {
    let date: Date
    let editingFoodEntry: FoodLogEntry?
    let appTabPadding: CGFloat
    let unitSystem: UnitSystem
    let onSaveFood: (FoodLogEntry) -> Void
    let onSaveWeight: (WeightLogEntry) -> Void

    @State private var loggedAt: Date
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

    init(
        date: Date,
        editingFoodEntry: FoodLogEntry? = nil,
        appTabPadding: CGFloat,
        unitSystem: UnitSystem,
        onSaveFood: @escaping (FoodLogEntry) -> Void,
        onSaveWeight: @escaping (WeightLogEntry) -> Void
    ) {
        self.date = date
        self.editingFoodEntry = editingFoodEntry
        self.appTabPadding = appTabPadding
        self.unitSystem = unitSystem
        self.onSaveFood = onSaveFood
        self.onSaveWeight = onSaveWeight
        _loggedAt = State(initialValue: editingFoodEntry?.loggedAt ?? date)
        _foodName = State(initialValue: editingFoodEntry?.foodName ?? "")
        _brand = State(initialValue: editingFoodEntry?.brand ?? "")
        _mealTime = State(initialValue: editingFoodEntry?.mealTime ?? .breakfast)
        _servingGrams = State(
            initialValue: editingFoodEntry.map { DashboardNumberText.wholeNumber($0.servingGrams) } ?? ""
        )
        _calories = State(
            initialValue: editingFoodEntry.map { DashboardNumberText.wholeNumber($0.nutrients.calories) } ?? ""
        )
        _protein = State(
            initialValue: editingFoodEntry.map { DashboardNumberText.wholeNumber($0.nutrients.protein) } ?? ""
        )
        _carbs = State(
            initialValue: editingFoodEntry.map { DashboardNumberText.wholeNumber($0.nutrients.carbs) } ?? ""
        )
        _fat = State(
            initialValue: editingFoodEntry.map { DashboardNumberText.wholeNumber($0.nutrients.fat) } ?? ""
        )
        _fiber = State(
            initialValue: editingFoodEntry.map { DashboardNumberText.wholeNumber($0.nutrients.fiber) } ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    header
                    if editingFoodEntry == nil {
                        typePicker
                    }
                    timestampPicker

                    switch entryType {
                    case .food:
                        foodForm
                        saveButton(
                            title: editingFoodEntry == nil ? "Save food" : "Save changes",
                            isEnabled: isFoodSaveEnabled,
                            action: saveFood
                        )

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
            Text(editingFoodEntry == nil ? "Log Entry" : "Edit Food")
                .font(AppTheme.Typography.header)
                .foregroundStyle(AppTheme.primaryText)

            Text(loggedAt.formatted(Date.FormatStyle.dateTime.weekday(.wide).month(.wide).day().hour().minute()))
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

    private var timestampPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Logged at")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.mutedText)
                .textCase(.uppercase)
                .tracking(0.8)

            DatePicker(
                selection: $loggedAt,
                displayedComponents: .date
            ) {
                LogFieldLabel(title: "Date", symbolName: "calendar")
            }
            .font(AppTheme.Typography.body)

            DatePicker(
                selection: $loggedAt,
                displayedComponents: .hourAndMinute
            ) {
                LogFieldLabel(title: "Time", symbolName: "clock")
            }
            .font(AppTheme.Typography.body)
        }
        .alyraInputPanel()
    }

    private var foodForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
            VStack(alignment: .leading, spacing: 16) {
                LogTextField(
                    title: "Food",
                    symbolName: "fork.knife",
                    placeholder: "Greek yogurt",
                    text: $foodName,
                    keyboardType: .default
                )

                LogTextField(
                    title: "Brand",
                    symbolName: "tag",
                    placeholder: "Optional",
                    text: $brand,
                    keyboardType: .default
                )

                VStack(alignment: .leading, spacing: 8) {
                    LogFieldLabel(title: "Meal", symbolName: "fork.knife.circle")

                    MealTimePicker(selection: $mealTime)
                }
            }
            .alyraInputPanel()

            VStack(alignment: .leading, spacing: 16) {
                LogTextField(
                    title: "Serving",
                    symbolName: "scalemass",
                    placeholder: "0",
                    text: $servingGrams,
                    keyboardType: .decimalPad,
                    suffix: "g"
                )

                LogTextField(
                    title: "Calories",
                    symbolName: "flame",
                    placeholder: "0",
                    text: $calories,
                    keyboardType: .decimalPad,
                    suffix: "kcal"
                )

                HStack(spacing: 12) {
                    LogTextField(
                        title: "Protein",
                        symbolName: "dumbbell.fill",
                        placeholder: "0",
                        text: $protein,
                        keyboardType: .decimalPad,
                        suffix: "g"
                    )

                    LogTextField(
                        title: "Carbs",
                        symbolName: "bolt.fill",
                        placeholder: "0",
                        text: $carbs,
                        keyboardType: .decimalPad,
                        suffix: "g"
                    )
                }

                HStack(spacing: 12) {
                    LogTextField(
                        title: "Fat",
                        symbolName: "drop.fill",
                        placeholder: "0",
                        text: $fat,
                        keyboardType: .decimalPad,
                        suffix: "g"
                    )

                    LogTextField(
                        title: "Fiber",
                        symbolName: "leaf.fill",
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
                symbolName: "scalemass",
                placeholder: "0",
                text: $weightValue,
                keyboardType: .decimalPad,
                suffix: unitSystem.weightUnitName
            )

            LogTextField(
                title: "Note",
                symbolName: "note.text",
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
                id: editingFoodEntry?.id ?? UUID(),
                foodName: foodName.trimmed,
                brand: brand.trimmed,
                mealTime: mealTime,
                loggedAt: loggedAt,
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
                loggedAt: loggedAt,
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
    let symbolName: String
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
            LogFieldLabel(title: title, symbolName: symbolName)

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

private struct LogFieldLabel: View {
    let title: String
    let symbolName: String

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(AppTheme.Typography.eyebrow)
            .foregroundStyle(AppTheme.mutedText)
            .textCase(.uppercase)
            .tracking(0.8)
            .labelStyle(.titleAndIcon)
    }
}

private struct MealTimePicker: View {
    @Binding var selection: MealTime

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(MealTime.allCases) { meal in
                Button {
                    selection = meal
                } label: {
                    Label(meal.rawValue, systemImage: meal.dashboardSymbolName)
                        .font(AppTheme.Typography.bodyStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .foregroundStyle(selection == meal ? AppTheme.primaryText : AppTheme.mutedText)
                        .background(selection == meal ? AppTheme.controlFill : .clear)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppTheme.Radius.control,
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == meal ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(AppTheme.controlFill.opacity(0.7))
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppTheme.Radius.card,
                style: .continuous
            )
        )
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
