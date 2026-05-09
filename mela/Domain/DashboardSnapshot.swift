import Foundation

nonisolated struct DashboardDateState: Equatable, Sendable {
    private static let weekdayStyle = Date.FormatStyle.dateTime.weekday(.wide)
    private static let dateStyle = Date.FormatStyle.dateTime.month(.wide).day().year()

    var weekdayText: String
    var dateText: String

    static func make(for date: Date) -> DashboardDateState {
        DashboardDateState(
            weekdayText: date.formatted(weekdayStyle),
            dateText: date.formatted(dateStyle)
        )
    }
}

nonisolated struct DashboardSnapshot: Equatable, Sendable {
    var calories: CalorieSummaryViewState
    var macros: MacroStripViewState
    var sections: [MealSectionViewState]

    static func make(
        entries: [DiaryEntryRow],
        targets: DailyTargets = .standard
    ) -> DashboardSnapshot {
        let summary = DashboardDemoData.summary(from: entries, targets: targets)
        let sections = DashboardDemoData.sections(from: entries)

        return DashboardSnapshot(
            calories: CalorieSummaryViewState(summary: summary),
            macros: MacroStripViewState(summary: summary),
            sections: sections.map(MealSectionViewState.init(section:))
        )
    }
}

nonisolated struct CalorieSummaryViewState: Equatable, Sendable {
    var consumedCalories: Double
    var remainingCalories: Double
    var progress: Double
    var consumedCaloriesText: String
    var remainingCaloriesText: String
    var targetCaloriesText: String

    init(summary: NutritionSummary) {
        consumedCalories = summary.consumed.calories
        remainingCalories = summary.remainingCalories
        progress = summary.calorieProgress
        consumedCaloriesText = DashboardNumberText.wholeNumber(summary.consumed.calories)
        remainingCaloriesText =
            "\(DashboardNumberText.wholeNumber(summary.remainingCalories)) remaining"
        targetCaloriesText =
            "\(DashboardNumberText.wholeNumber(summary.targets.calories)) kcal target"
    }
}

nonisolated struct MacroStripViewState: Equatable, Sendable {
    var protein: MacroTileViewState
    var carbs: MacroTileViewState
    var fat: MacroTileViewState
    var fiber: MacroTileViewState

    init(summary: NutritionSummary) {
        protein = MacroTileViewState(
            title: "Protein",
            value: summary.consumed.protein,
            target: summary.targets.protein,
            symbolName: "bolt"
        )
        carbs = MacroTileViewState(
            title: "Carbs",
            value: summary.consumed.carbs,
            target: summary.targets.carbs,
            symbolName: "leaf"
        )
        fat = MacroTileViewState(
            title: "Fat",
            value: summary.consumed.fat,
            target: summary.targets.fat,
            symbolName: "drop"
        )
        fiber = MacroTileViewState(
            title: "Fiber",
            value: summary.consumed.fiber,
            target: 30,
            symbolName: "line.3.horizontal.decrease"
        )
    }
}

nonisolated struct MacroTileViewState: Identifiable, Equatable, Sendable {
    var id: String { title }

    var title: String
    var value: Double
    var target: Double
    var progress: Double
    var symbolName: String
    var valueText: String

    init(title: String, value: Double, target: Double, symbolName: String) {
        self.title = title
        self.value = value
        self.target = target
        self.symbolName = symbolName
        progress = DashboardNumberText.progress(value: value, target: target)
        valueText = "\(DashboardNumberText.wholeNumber(value)) g"
    }
}

nonisolated struct MealSectionViewState: Identifiable, Equatable, Sendable {
    var id: MealKind { meal }

    var meal: MealKind
    var title: String
    var symbolName: String
    var totalCalories: Double
    var totalCaloriesText: String
    var rows: [DiaryEntryViewState]

    init(section: MealSection) {
        meal = section.meal
        title = section.meal.rawValue
        symbolName = section.meal.symbolName
        totalCalories = section.total.calories
        totalCaloriesText = "\(DashboardNumberText.wholeNumber(section.total.calories)) kcal"
        rows = section.rows.map(DiaryEntryViewState.init(row:))
    }
}

nonisolated struct DiaryEntryViewState: Identifiable, Equatable, Sendable {
    var id: UUID
    var foodName: String
    var detailText: String
    var calories: Double
    var caloriesText: String
    var deleteAccessibilityLabel: String

    init(row: DiaryEntryRow) {
        id = row.id
        foodName = row.foodName
        detailText = "\(DashboardNumberText.wholeNumber(row.servingGrams)) g - \(row.brand)"
        calories = row.nutrients.calories
        caloriesText = DashboardNumberText.wholeNumber(row.nutrients.calories)
        deleteAccessibilityLabel = "Delete \(row.foodName)"
    }
}

nonisolated enum DashboardNumberText {
    private static let wholeNumberStyle = FloatingPointFormatStyle<Double>.number.precision(
        .fractionLength(0)
    )

    static func wholeNumber(_ value: Double) -> String {
        value.formatted(wholeNumberStyle)
    }

    static func progress(value: Double, target: Double) -> Double {
        guard target > 0 else { return 0 }
        return min(max(value / target, 0), 1)
    }
}
