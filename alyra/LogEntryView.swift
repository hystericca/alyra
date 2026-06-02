import SwiftUI

struct LogEntryView: View {
    let date: Date
    let editingFoodEntry: FoodLogEntry?
    let appTabPadding: CGFloat
    let unitSystem: UnitSystem
    let foodHistory: [FoodLogEntry]
    let onSaveFood: (FoodLogEntry) -> Void
    let onSaveWeight: (WeightLogEntry) -> Void

    @FocusState private var focusedField: LogInputField?
    @State private var loggedAt: Date
    @State private var entryType = LogEntryType.food
    @State private var foodName = ""
    @State private var brand = ""
    @State private var foodIconKind = FoodIconKind.generic
    @State private var mealTime = MealTime.breakfast
    @State private var servingGrams = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var weightValue = ""
    @State private var weightNote = ""
    @State private var quickAddServingGrams: [String: String] = [:]

    init(
        date: Date,
        editingFoodEntry: FoodLogEntry? = nil,
        appTabPadding: CGFloat,
        unitSystem: UnitSystem,
        foodHistory: [FoodLogEntry] = [],
        onSaveFood: @escaping (FoodLogEntry) -> Void,
        onSaveWeight: @escaping (WeightLogEntry) -> Void
    ) {
        self.date = date
        self.editingFoodEntry = editingFoodEntry
        self.appTabPadding = appTabPadding
        self.unitSystem = unitSystem
        self.foodHistory = foodHistory
        self.onSaveFood = onSaveFood
        self.onSaveWeight = onSaveWeight
        _loggedAt = State(initialValue: editingFoodEntry?.loggedAt ?? date)
        _foodName = State(initialValue: editingFoodEntry?.foodName ?? "")
        _brand = State(initialValue: editingFoodEntry?.brand ?? "")
        _foodIconKind = State(initialValue: editingFoodEntry?.iconKind ?? .generic)
        _mealTime = State(initialValue: editingFoodEntry?.mealTime ?? MealTime.defaultFor(date: date))
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
                VStack(alignment: .leading, spacing: LogEntryLayout.sectionSpacing) {
                    header

                    if editingFoodEntry == nil {
                        typePicker
                    }

                    timestampPicker

                    switch entryType {
                    case .food:
                        mealTimeSection
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    focusedField = nil
                }
                .font(AppTheme.Typography.bodyStrong)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
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
        .alyraPanel(padding: 0)
        .accessibilityLabel("Entry type")
    }

    private var timestampPicker: some View {
        LogFormSection(title: "Logged at", symbolName: "calendar.badge.clock") {
            VStack(alignment: .leading, spacing: LogEntryLayout.fieldSpacing) {
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
        }
    }

    private var mealTimeSection: some View {
        VStack(alignment: .leading, spacing: LogEntryLayout.tightSpacing) {
            LogFieldLabel(title: "Meal", symbolName: "fork.knife.circle")

            MealTimePicker(selection: $mealTime)
        }
        .alyraInputPanel()
    }

    private var foodForm: some View {
        VStack(alignment: .leading, spacing: LogEntryLayout.sectionSpacing) {
            if editingFoodEntry == nil, !quickAddTemplates.isEmpty {
                quickAddSection
            }

            VStack(alignment: .leading, spacing: LogEntryLayout.fieldSpacing) {
                LogTextField(
                    title: "Food",
                    symbolName: "fork.knife",
                    placeholder: "Greek yogurt",
                    text: $foodName,
                    keyboardType: .default,
                    field: .foodName,
                    focusedField: $focusedField
                )

                LogTextField(
                    title: "Brand",
                    symbolName: "tag",
                    placeholder: "Optional",
                    text: $brand,
                    keyboardType: .default,
                    field: .brand,
                    focusedField: $focusedField
                )

                FoodIconSelectorView(selection: $foodIconKind)
            }
            .alyraInputPanel()

            VStack(alignment: .leading, spacing: LogEntryLayout.fieldSpacing) {
                LogTextField(
                    title: "Serving",
                    symbolName: "scalemass",
                    placeholder: "0",
                    text: $servingGrams,
                    keyboardType: .decimalPad,
                    field: .servingGrams,
                    focusedField: $focusedField,
                    suffix: "g"
                )

                LogTextField(
                    title: "Calories",
                    symbolName: "flame",
                    placeholder: "0",
                    text: $calories,
                    keyboardType: .decimalPad,
                    field: .calories,
                    focusedField: $focusedField,
                    suffix: "kcal"
                )

                HStack(spacing: LogEntryLayout.columnSpacing) {
                    LogTextField(
                        title: "Protein",
                        symbolName: "dumbbell.fill",
                        placeholder: "0",
                        text: $protein,
                        keyboardType: .decimalPad,
                        field: .protein,
                        focusedField: $focusedField,
                        suffix: "g"
                    )

                    LogTextField(
                        title: "Carbs",
                        symbolName: "bolt.fill",
                        placeholder: "0",
                        text: $carbs,
                        keyboardType: .decimalPad,
                        field: .carbs,
                        focusedField: $focusedField,
                        suffix: "g"
                    )
                }

                HStack(spacing: LogEntryLayout.columnSpacing) {
                    LogTextField(
                        title: "Fat",
                        symbolName: "drop.fill",
                        placeholder: "0",
                        text: $fat,
                        keyboardType: .decimalPad,
                        field: .fat,
                        focusedField: $focusedField,
                        suffix: "g"
                    )

                    LogTextField(
                        title: "Fiber",
                        symbolName: "leaf.fill",
                        placeholder: "0",
                        text: $fiber,
                        keyboardType: .decimalPad,
                        field: .fiber,
                        focusedField: $focusedField,
                        suffix: "g"
                    )
                }
            }
            .alyraInputPanel()
        }
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: LogEntryLayout.tightSpacing) {
            HStack(alignment: .firstTextBaseline) {
                LogFieldLabel(title: "Quick add", symbolName: "clock.arrow.circlepath")

                Spacer()

                Text(mealTime.rawValue)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }

            VStack(spacing: 0) {
                ForEach(quickAddTemplates) { template in
                    if template.id != quickAddTemplates.first?.id {
                        Divider()
                            .overlay(AppTheme.separator)
                    }

                    QuickAddFoodRow(
                        template: template,
                        grams: quickAddGramsBinding(for: template),
                        focusedField: $focusedField,
                        caloriesText: quickAddCaloriesText(for: template),
                        action: { quickAdd(template) }
                    )
                }
            }
            .alyraPanel(padding: 0, border: .strong)
        }
    }

    private var weightForm: some View {
        VStack(alignment: .leading, spacing: LogEntryLayout.fieldSpacing) {
            LogTextField(
                title: "Weight",
                symbolName: "scalemass",
                placeholder: "0",
                text: $weightValue,
                keyboardType: .decimalPad,
                field: .weight,
                focusedField: $focusedField,
                suffix: unitSystem.weightUnitName
            )

            LogTextField(
                title: "Note",
                symbolName: "note.text",
                placeholder: "Optional",
                text: $weightNote,
                keyboardType: .default,
                field: .weightNote,
                focusedField: $focusedField
            )
        }
        .alyraInputPanel()
    }

    private var quickAddTemplates: [FoodQuickAddTemplate] {
        Nutrition.quickAddTemplates(from: foodHistory, mealTime: mealTime)
    }

    private func quickAddGramsBinding(for template: FoodQuickAddTemplate) -> Binding<String> {
        Binding(
            get: {
                quickAddServingGrams[template.id]
                    ?? DashboardNumberText.wholeNumber(template.defaultServingGrams)
            },
            set: { value in
                quickAddServingGrams[template.id] = value
            }
        )
    }

    private func quickAddCaloriesText(for template: FoodQuickAddTemplate) -> String {
        let grams = quickAddServingGrams[template.id]?.doubleValue ?? template.defaultServingGrams
        let calories = template.nutrients(for: grams).calories
        return "\(DashboardNumberText.wholeNumber(calories)) kcal"
    }

    private func quickAdd(_ template: FoodQuickAddTemplate) {
        let grams = quickAddServingGrams[template.id]?.doubleValue ?? template.defaultServingGrams
        guard grams > 0 else { return }

        onSaveFood(
            template.entry(
                servingGrams: grams,
                loggedAt: loggedAt,
                mealTime: mealTime
            )
        )
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
                .frame(height: LogEntryLayout.saveButtonHeight)
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

        let nutrients = NutritionFacts(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber.doubleValue ?? 0
        )
        let foodProfile = foodProfileForSave(
            nutrients: nutrients,
            servingGrams: servingGrams
        )

        onSaveFood(
            FoodLogEntry(
                id: editingFoodEntry?.id ?? UUID(),
                foodName: foodName.trimmed,
                brand: brand.trimmed,
                iconKind: foodIconKind,
                foodReference: foodProfile.foodReference,
                foodProfile: foodProfile,
                mealTime: mealTime,
                loggedAt: loggedAt,
                servingGrams: servingGrams,
                nutrients: nutrients
            )
        )

        resetFoodForm()
    }

    private func foodProfileForSave(
        nutrients: NutritionFacts,
        servingGrams: Double
    ) -> FoodProfileSnapshot {
        if let editingFoodEntry {
            return editingFoodEntry.foodProfile.renamedIfNeeded(
                foodName: foodName.trimmed,
                brand: brand.trimmed,
                iconKind: foodIconKind,
                nutrients: nutrients,
                servingGrams: servingGrams
            )
        }

        return .manual(
            foodName: foodName.trimmed,
            brand: brand.trimmed,
            iconKind: foodIconKind,
            nutrients: nutrients,
            servingGrams: servingGrams
        )
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
        foodIconKind = .generic
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

private enum LogEntryLayout {
    static let sectionSpacing = AppTheme.Spacing.lg
    static let fieldSpacing = AppTheme.Spacing.md
    static let tightSpacing = AppTheme.Spacing.sm
    static let columnSpacing = AppTheme.Spacing.md
    static let fieldHeight = AppTheme.Control.fieldHeight
    static let compactFieldHeight = AppTheme.Control.compactFieldHeight
    static let saveButtonHeight: CGFloat = 50
}

private enum LogInputField: Hashable {
    case foodName
    case brand
    case servingGrams
    case calories
    case protein
    case carbs
    case fat
    case fiber
    case quickAddGrams(String)
    case weight
    case weightNote
}

private struct LogTextField: View {
    let title: String
    let symbolName: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let field: LogInputField
    let focusedField: FocusState<LogInputField?>.Binding
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
                    .foregroundStyle(AppTheme.primaryText)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .focused(focusedField, equals: field)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(keyboardType != .default)

                if let suffix {
                    Text(suffix)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: LogEntryLayout.fieldHeight)
            .background(AppTheme.surfaceRaised)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
                .strokeBorder(AppTheme.strongBorder, lineWidth: AppTheme.Stroke.hairline)
            }
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

private struct LogFormSection<Content: View>: View {
    let title: String
    let symbolName: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: LogEntryLayout.tightSpacing) {
            LogFieldLabel(title: title, symbolName: symbolName)
            content
        }
        .alyraInputPanel()
    }
}

private struct QuickAddFoodRow: View {
    let template: FoodQuickAddTemplate
    @Binding var grams: String
    let focusedField: FocusState<LogInputField?>.Binding
    let caloriesText: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.iconKind.symbolName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(template.foodName)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                Text("\(template.displayDetail) - \(caloriesText)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                TextField("0", text: $grams)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.primaryText)
                    .textFieldStyle(.plain)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: .quickAddGrams(template.id))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 48)

                Text("g")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }
            .padding(.horizontal, 9)
            .frame(height: LogEntryLayout.compactFieldHeight)
            .background(AppTheme.background)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
                .strokeBorder(AppTheme.strongBorder, lineWidth: AppTheme.Stroke.hairline)
            }

            Button(action: action) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.background)
            .background(AppTheme.primaryText)
            .clipShape(Circle())
            .accessibilityLabel("Quick add \(template.foodName)")
        }
        .padding(12)
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
                        .foregroundStyle(selection == meal ? AppTheme.background : AppTheme.primaryText)
                        .background(selection == meal ? AppTheme.primaryText : AppTheme.surfaceRaised)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppTheme.Radius.control,
                                style: .continuous
                            )
                        )
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: AppTheme.Radius.control,
                                style: .continuous
                            )
                            .strokeBorder(AppTheme.strongBorder, lineWidth: AppTheme.Stroke.hairline)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == meal ? [.isSelected] : [])
            }
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
