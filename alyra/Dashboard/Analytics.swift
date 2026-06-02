//
//  Analytics.swift
//  alyra
//
//  Created by Viktor Luna on 6/1/26.
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
        let days = Self.days(endingAt: date, count: trendPeriod.rawValue, calendar: calendar)
        let calories = Self.calories(from: foodEntries, days: days, calendar: calendar)
        let balance = calories.map { $0 - targets.calories }

        if let latest = calories.last, calories.contains(where: { $0 > 0 }) {
            let average = calories.reduce(0, +) / Double(calories.count)
            analytics.expenditure = HealthGraphViewState(
                id: "intake",
                title: "Energy intake",
                symbolName: "fork.knife",
                valueText: DashboardNumberText.wholeNumber(latest),
                unitText: "kcal",
                detailText: "\(DashboardNumberText.wholeNumber(average)) kcal \(trendPeriod.averageText)",
                style: .bars,
                gradientKind: .expenditure,
                negativeGradientKind: nil,
                baselineRule: .zero,
                values: calories
            )
        }

        if let latest = balance.last, calories.contains(where: { $0 > 0 }) {
            let average = balance.reduce(0, +) / Double(balance.count)
            analytics.energyBalance = HealthGraphViewState(
                id: "balance",
                title: "Energy balance",
                symbolName: "plus.forwardslash.minus",
                valueText: DashboardNumberText.signedWholeNumber(latest),
                unitText: "kcal",
                detailText: "\(DashboardNumberText.signedWholeNumber(average)) kcal \(trendPeriod.averageText)",
                style: .bars,
                gradientKind: .balancePositive,
                negativeGradientKind: .balanceNegative,
                baselineRule: .zero,
                values: balance
            )
        }

        let start = calendar.date(
            byAdding: .day,
            value: -trendPeriod.rawValue + 1,
            to: calendar.startOfDay(for: date)
        ) ?? date
        let recent = weightEntries
            .sorted { $0.loggedAt < $1.loggedAt }
            .filter { entry in
                entry.loggedAt >= start &&
                (entry.loggedAt <= date || calendar.isDate(entry.loggedAt, inSameDayAs: date))
            }
        let weights = recent.map { $0.displayWeight(for: unitSystem) }

        if let latest = weights.last {
            let first = weights.first ?? latest
            let delta = latest - first

            analytics.weightTrend = HealthGraphViewState(
                id: "weight",
                title: "Weight",
                symbolName: "scalemass",
                valueText: DashboardNumberText.oneDecimal(latest),
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

    private static func days(
        endingAt date: Date,
        count: Int,
        calendar: Calendar
    ) -> [Date] {
        let end = calendar.startOfDay(for: date)

        return (0..<count).compactMap { offset in
            calendar.date(
                byAdding: .day,
                value: offset - count + 1,
                to: end
            )
        }
    }

    private static func calories(
        from entries: [FoodLogEntry],
        days: [Date],
        calendar: Calendar
    ) -> [Double] {
        days.map { day in
            entries
                .filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.nutrients.calories }
        }
    }

    static func movingAverage(values: [Double], window: Int = 3) -> [Double] {
        values.indices.map { index in
            let lower = max(0, index - window + 1)
            let slice = values[lower...index]
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

        let range = HealthGraphRange(values: values, baseline: baseline)

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
        baselineNormalized = range.normalize(baseline)
        samples = values.enumerated().map { index, value in
            HealthGraphSampleViewState(
                index: index,
                value: value,
                normalizedValue: range.normalize(value)
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
