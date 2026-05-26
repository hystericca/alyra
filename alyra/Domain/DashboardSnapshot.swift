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
    var analytics: DashboardAnalyticsViewState
    var sections: [MealSectionViewState]

    static func make(
        entries: [DiaryEntryRow],
        targets: DailyTargets = .standard,
        analytics: DashboardAnalyticsViewState
    ) -> DashboardSnapshot {
        let summary = DashboardDemoData.summary(from: entries, targets: targets)
        let sections = DashboardDemoData.sections(from: entries)

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

    var gradientKind: NutritionGradientKind {
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
    var gradientKind: NutritionGradientKind
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
    var gradientKind: NutritionGradientKind
    var negativeGradientKind: NutritionGradientKind?
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
        gradientKind: NutritionGradientKind,
        negativeGradientKind: NutritionGradientKind?,
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
    var id: MealKind { meal }

    var meal: MealKind
    var title: String
    var symbolName: String
    var totalCaloriesText: String
    var rows: [DiaryEntryViewState]

    init(section: MealSection) {
        meal = section.meal
        title = section.meal.rawValue
        symbolName = section.meal.symbolName
        totalCaloriesText = "\(DashboardNumberText.wholeNumber(section.total.calories)) kcal"
        rows = section.rows.map(DiaryEntryViewState.init(row:))
    }
}

nonisolated struct DiaryEntryViewState: Identifiable, Equatable, Sendable {
    var id: UUID
    var foodName: String
    var detailText: String
    var iconKind: FoodIconKind
    var caloriesText: String
    var deleteAccessibilityLabel: String

    init(row: DiaryEntryRow) {
        id = row.id
        foodName = row.foodName
        detailText = "\(DashboardNumberText.wholeNumber(row.servingGrams)) g - \(row.brand)"
        iconKind = row.iconKind
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
