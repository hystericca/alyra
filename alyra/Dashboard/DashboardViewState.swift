//
//  DashboardViewState.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import Foundation

nonisolated struct DashboardDateState: Equatable, Sendable {
    private static let weekdayStyle = Date.FormatStyle.dateTime.weekday(.wide)
    private static let dateStyle = Date.FormatStyle.dateTime.month(.wide).day().year()

    var weekdayText: String
    var dateText: String

    static func from(_ date: Date) -> DashboardDateState {
        DashboardDateState(
            weekdayText: date.formatted(weekdayStyle),
            dateText: date.formatted(dateStyle)
        )
    }
}

nonisolated struct DashboardSnapshot: Equatable, Sendable {
    var calories: CalorieSummaryViewState
    var macros: MacroStripViewState
    var analytics: DashboardAnalyticsViewState
    var sections: [MealSectionViewState]

    static func from(
        entries: [FoodLogEntry],
        targets: DailyTargets = .standard,
        analytics: DashboardAnalyticsViewState
    ) -> DashboardSnapshot {
        let summary = Nutrition.summary(from: entries, targets: targets)
        let sections = Nutrition.sections(from: entries)

        return DashboardSnapshot(
            calories: CalorieSummaryViewState(summary: summary),
            macros: MacroStripViewState(summary: summary),
            analytics: analytics,
            sections: sections.map(MealSectionViewState.init(section:))
        )
    }
}

nonisolated struct CalorieSummaryViewState: Equatable, Sendable {
    var progress: Double
    var consumedCaloriesText: String
    var remainingCaloriesText: String
    var targetCaloriesText: String

    init(summary: NutritionSummary) {
        progress = summary.calorieProgress
        consumedCaloriesText = DashboardNumberText.wholeNumber(summary.consumed.calories)
        remainingCaloriesText =
            "\(DashboardNumberText.wholeNumber(summary.remainingCalories)) remaining"
        targetCaloriesText =
            "\(DashboardNumberText.wholeNumber(summary.targets.calories)) kcal target"
    }
}

nonisolated struct MacroStripViewState: Equatable, Sendable {
    var tiles: [MacroTileViewState]

    init(summary: NutritionSummary) {
        tiles = [
            MacroTileViewState(
                kind: .protein,
                value: summary.consumed.protein,
                target: summary.targets.protein
            ),
            MacroTileViewState(
                kind: .carbs,
                value: summary.consumed.carbs,
                target: summary.targets.carbs
            ),
            MacroTileViewState(
                kind: .fat,
                value: summary.consumed.fat,
                target: summary.targets.fat
            ),
        ]
    }
}

nonisolated enum MacroKind: Hashable, Sendable {
    case protein
    case carbs
    case fat

    var title: String {
        switch self {
        case .protein: "Protein"
        case .carbs: "Carbs"
        case .fat: "Fat"
        }
    }

    var gradientKind: DataGradientKind {
        switch self {
        case .protein: .protein
        case .carbs: .carbs
        case .fat: .fat
        }
    }

    var symbolName: String {
        switch self {
        case .protein: "dumbbell.fill"
        case .carbs: "bolt.fill"
        case .fat: "drop.fill"
        }
    }
}

nonisolated struct MacroTileViewState: Identifiable, Equatable, Sendable {
    var id: MacroKind { kind }

    var kind: MacroKind
    var title: String
    var progress: Double
    var gradientKind: DataGradientKind
    var symbolName: String
    var valueText: String
    var targetText: String

    init(
        kind: MacroKind,
        value: Double,
        target: Double
    ) {
        self.kind = kind
        title = kind.title
        gradientKind = kind.gradientKind
        symbolName = kind.symbolName
        progress = DashboardNumberText.progress(value: value, target: target)
        valueText = "\(DashboardNumberText.wholeNumber(value))g"
        targetText = "\(DashboardNumberText.wholeNumber(target))g"
    }
}

nonisolated struct MealSectionViewState: Identifiable, Equatable, Sendable {
    var id: MealTime { mealTime }

    var mealTime: MealTime
    var title: String
    var symbolName: String
    var totalCaloriesText: String
    var entries: [LogEntryViewState]

    init(section: MealSection) {
        mealTime = section.mealTime
        title = section.mealTime.rawValue
        symbolName = section.mealTime.dashboardSymbolName
        totalCaloriesText = "\(DashboardNumberText.wholeNumber(section.total.calories)) kcal"
        entries = section.entries.map(LogEntryViewState.init(entry:))
    }
}

nonisolated struct LogEntryViewState: Identifiable, Equatable, Sendable {
    var id: UUID
    var foodName: String
    var detailText: String
    var iconKind: FoodIconKind
    var caloriesText: String
    var editAccessibilityLabel: String
    var deleteAccessibilityLabel: String

    init(entry: FoodLogEntry) {
        id = entry.id
        foodName = entry.foodName
        let timeText = entry.loggedAt.formatted(Date.FormatStyle.dateTime.hour().minute())
        let servingText = "\(DashboardNumberText.wholeNumber(entry.servingGrams))g"
        let foodDetailText = entry.brand.isEmpty ? servingText : "\(servingText) - \(entry.brand)"
        detailText = "\(timeText) - \(foodDetailText)"
        iconKind = entry.iconKind
        caloriesText = DashboardNumberText.wholeNumber(entry.nutrients.calories)
        editAccessibilityLabel = "Edit \(entry.foodName)"
        deleteAccessibilityLabel = "Delete \(entry.foodName)"
    }
}

nonisolated enum DashboardNumberText {
    private static let wholeNumberStyle = FloatingPointFormatStyle<Double>.number.precision(
        .fractionLength(0)
    )

    static func wholeNumber(_ value: Double) -> String {
        value.formatted(wholeNumberStyle)
    }

    static func signedWholeNumber(_ value: Double) -> String {
        let formattedValue = wholeNumber(value)
        return value > 0 ? "+\(formattedValue)" : formattedValue
    }

    static func oneDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    static func signedOneDecimal(_ value: Double) -> String {
        let formattedValue = oneDecimal(value)
        return value > 0 ? "+\(formattedValue)" : formattedValue
    }

    static func progress(value: Double, target: Double) -> Double {
        guard target > 0 else { return 0 }
        return min(max(value / target, 0), 1)
    }
}

nonisolated extension MealTime {
    var dashboardSymbolName: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "fork.knife"
        case .dinner: "moon"
        case .snack: "sparkle"
        }
    }
}

nonisolated enum DataGradientKind: Equatable, Sendable {
    case energy
    case protein
    case carbs
    case fat
    case weight
    case expenditure
    case balancePositive
    case balanceNegative
    case poultry
    case yogurt
    case berries
    case shake
    case generic
}

nonisolated extension FoodIconKind {
    var gradientKind: DataGradientKind {
        switch self {
        case .apple, .banana, .fruit:
            .berries
        case .avocado, .greens, .salad, .vegetables:
            .generic
        case .beans, .bread, .burger, .cheese, .coffee, .eggs, .grains, .milk,
             .noodles, .nuts, .rice, .sandwich, .soup, .sweets, .taco, .tofu:
            .generic
        case .fish, .seafood:
            .shake
        case .poultry: .poultry
        case .yogurt: .yogurt
        case .berries: .berries
        case .shake: .shake
        case .generic: .generic
        }
    }
}
