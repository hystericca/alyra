//
//  DashboardViewState.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import Foundation

nonisolated enum TrendPeriod: Int, CaseIterable, Identifiable, Sendable {
    case twoWeeks = 14
    case month = 30
    case quarter = 90

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .twoWeeks: "14d"
        case .month: "30d"
        case .quarter: "90d"
        }
    }

    var averageText: String {
        "\(title) avg"
    }
}

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
        valueText = "\(DashboardNumberText.wholeNumber(value)) g"
        targetText = "\(DashboardNumberText.wholeNumber(target)) g"
    }
}

nonisolated struct DashboardAnalyticsViewState: Equatable, Sendable {
    var weightTrend: HealthGraphViewState
    var expenditure: HealthGraphViewState
    var energyBalance: HealthGraphViewState

    static let empty = DashboardAnalyticsViewState(
        weightTrend: HealthGraphViewState(
            id: "weight",
            title: "Weight",
            symbolName: "scalemass",
            valueText: "--",
            unitText: "lb",
            detailText: "No entries yet",
            style: .lineArea,
            gradientKind: .weight,
            negativeGradientKind: nil,
            values: []
        ),
        expenditure: HealthGraphViewState(
            id: "expenditure",
            title: "Energy intake",
            symbolName: "fork.knife",
            valueText: "--",
            unitText: "kcal",
            detailText: "No entries yet",
            style: .bars,
            gradientKind: .expenditure,
            negativeGradientKind: nil,
            baselineRule: .zero,
            values: []
        ),
        energyBalance: HealthGraphViewState(
            id: "balance",
            title: "Energy balance",
            symbolName: "plus.forwardslash.minus",
            valueText: "--",
            unitText: "kcal",
            detailText: "No data",
            style: .bars,
            gradientKind: .balancePositive,
            negativeGradientKind: .balanceNegative,
            baselineRule: .zero,
            values: []
        )
    )

    static func empty(unitSystem: UnitSystem) -> DashboardAnalyticsViewState {
        var analytics = DashboardAnalyticsViewState.empty
        analytics.weightTrend.unitText = unitSystem.weightUnitName
        return analytics
    }

    static func from(
        foodEntries: [FoodLogEntry],
        targets: DailyTargets,
        weightEntries: [WeightLogEntry],
        unitSystem: UnitSystem,
        trendPeriod: TrendPeriod,
        through date: Date,
        calendar: Calendar = .current
    ) -> DashboardAnalyticsViewState {
        var analytics = DashboardAnalyticsViewState.empty(unitSystem: unitSystem)
        let dayStarts = Self.dayStarts(endingAt: date, count: trendPeriod.rawValue, calendar: calendar)
        let dailyCalories = Self.dailyCalories(
            from: foodEntries,
            dayStarts: dayStarts,
            calendar: calendar
        )
        let energyBalance = dailyCalories.map { $0 - targets.calories }

        if let latestCalories = dailyCalories.last, dailyCalories.contains(where: { $0 > 0 }) {
            let averageCalories = dailyCalories.reduce(0, +) / Double(dailyCalories.count)
            analytics.expenditure = HealthGraphViewState(
                id: "intake",
                title: "Energy intake",
                symbolName: "fork.knife",
                valueText: DashboardNumberText.wholeNumber(latestCalories),
                unitText: "kcal",
                detailText: "\(DashboardNumberText.wholeNumber(averageCalories)) kcal \(trendPeriod.averageText)",
                style: .bars,
                gradientKind: .expenditure,
                negativeGradientKind: nil,
                baselineRule: .zero,
                values: dailyCalories
            )
        }

        if let latestBalance = energyBalance.last, dailyCalories.contains(where: { $0 > 0 }) {
            let averageBalance = energyBalance.reduce(0, +) / Double(energyBalance.count)
            analytics.energyBalance = HealthGraphViewState(
                id: "balance",
                title: "Energy balance",
                symbolName: "plus.forwardslash.minus",
                valueText: DashboardNumberText.signedWholeNumber(latestBalance),
                unitText: "kcal",
                detailText: "\(DashboardNumberText.signedWholeNumber(averageBalance)) kcal \(trendPeriod.averageText)",
                style: .bars,
                gradientKind: .balancePositive,
                negativeGradientKind: .balanceNegative,
                baselineRule: .zero,
                values: energyBalance
            )
        }

        let sortedWeightEntries = weightEntries.sorted { $0.loggedAt < $1.loggedAt }
        let startDate = calendar.date(
            byAdding: .day,
            value: -trendPeriod.rawValue + 1,
            to: calendar.startOfDay(for: date)
        ) ?? date
        let recentWeightEntries = sortedWeightEntries.filter { entry in
            entry.loggedAt >= startDate
                && (entry.loggedAt <= date || calendar.isDate(entry.loggedAt, inSameDayAs: date))
        }
        let weights = recentWeightEntries.map { $0.displayWeight(for: unitSystem) }

        if let latestWeight = weights.last {
            let firstWeight = weights.first ?? latestWeight
            let delta = latestWeight - firstWeight

            analytics.weightTrend = HealthGraphViewState(
                id: "weight",
                title: "Weight",
                symbolName: "scalemass",
                valueText: DashboardNumberText.oneDecimal(latestWeight),
                unitText: unitSystem.weightUnitName,
                detailText: "\(DashboardNumberText.signedOneDecimal(delta)) \(unitSystem.weightUnitName) / \(weights.count)d",
                style: .lineArea,
                gradientKind: .weight,
                negativeGradientKind: nil,
                values: Self.movingAverage(values: weights)
            )
        }

        return analytics
    }

    private static func dayStarts(
        endingAt date: Date,
        count: Int,
        calendar: Calendar
    ) -> [Date] {
        let endOfRange = calendar.startOfDay(for: date)

        return (0..<count).compactMap { offset in
            calendar.date(
                byAdding: .day,
                value: offset - count + 1,
                to: endOfRange
            )
        }
    }

    private static func dailyCalories(
        from entries: [FoodLogEntry],
        dayStarts: [Date],
        calendar: Calendar
    ) -> [Double] {
        dayStarts.map { dayStart in
            entries
                .filter { calendar.isDate($0.loggedAt, inSameDayAs: dayStart) }
                .reduce(0) { $0 + $1.nutrients.calories }
        }
    }

    static func movingAverage(values: [Double], window: Int = 3) -> [Double] {
        values.indices.map { index in
            let lowerBound = max(0, index - window + 1)
            let slice = values[lowerBound...index]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }
}

nonisolated enum HealthGraphStyle: Equatable, Sendable {
    case lineArea
    case bars
}

nonisolated enum HealthGraphBaselineRule: Equatable, Sendable {
    case minimum
    case zero
}

nonisolated struct HealthGraphViewState: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var symbolName: String
    var valueText: String
    var unitText: String
    var detailText: String
    var style: HealthGraphStyle
    var gradientKind: DataGradientKind
    var negativeGradientKind: DataGradientKind?
    var baseline: Double
    var baselineNormalized: Double
    var samples: [HealthGraphSampleViewState]

    init(
        id: String,
        title: String,
        symbolName: String,
        valueText: String,
        unitText: String,
        detailText: String,
        style: HealthGraphStyle,
        gradientKind: DataGradientKind,
        negativeGradientKind: DataGradientKind?,
        baselineRule: HealthGraphBaselineRule = .minimum,
        values: [Double]
    ) {
        let minValue = values.min() ?? 0
        let baseline: Double

        switch baselineRule {
        case .minimum:
            baseline = minValue
        case .zero:
            baseline = 0
        }

        let paddedRange = HealthGraphRange(values: values, baseline: baseline)

        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.valueText = valueText
        self.unitText = unitText
        self.detailText = detailText
        self.style = style
        self.gradientKind = gradientKind
        self.negativeGradientKind = negativeGradientKind
        self.baseline = baseline
        baselineNormalized = paddedRange.normalize(baseline)
        samples = values.enumerated().map { index, value in
            HealthGraphSampleViewState(
                index: index,
                value: value,
                normalizedValue: paddedRange.normalize(value)
            )
        }
    }
}

nonisolated struct HealthGraphSampleViewState: Equatable, Sendable {
    var index: Int
    var value: Double
    var normalizedValue: Double
}

nonisolated struct HealthGraphRange: Equatable, Sendable {
    private let lowerBound: Double
    private let span: Double

    init(values: [Double], baseline: Double) {
        let minValue = min(values.min() ?? 0, baseline)
        let maxValue = max(values.max() ?? 1, baseline)
        let rawSpan = max(maxValue - minValue, 1)
        let padding = rawSpan * 0.12

        lowerBound = minValue - padding
        span = rawSpan + padding * 2
    }

    func normalize(_ value: Double) -> Double {
        min(max((value - lowerBound) / span, 0), 1)
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
        let servingText = "\(DashboardNumberText.wholeNumber(entry.servingGrams)) g"
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
