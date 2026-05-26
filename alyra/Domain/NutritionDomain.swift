import Foundation

nonisolated enum MealKind: String, CaseIterable, Identifiable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "fork.knife"
        case .dinner: "moon"
        case .snack: "sparkle"
        }
    }
}

nonisolated struct NutritionFacts: Equatable, Sendable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double

    static let zero = NutritionFacts(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0)

    static func + (lhs: NutritionFacts, rhs: NutritionFacts) -> NutritionFacts {
        NutritionFacts(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber
        )
    }
}

nonisolated struct DailyTargets: Equatable, Sendable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let standard = DailyTargets(calories: 2_200, protein: 140, carbs: 250, fat: 70)
}

nonisolated struct NutritionSummary: Equatable, Sendable {
    var consumed: NutritionFacts
    var targets: DailyTargets

    var remainingCalories: Double {
        max(0, targets.calories - consumed.calories)
    }

    var calorieProgress: Double {
        guard targets.calories > 0 else { return 0 }
        return min(max(consumed.calories / targets.calories, 0), 1)
    }
}

nonisolated struct DiaryEntryRow: Identifiable, Equatable, Sendable {
    var id: UUID
    var foodName: String
    var brand: String
    var iconKind: FoodIconKind
    var meal: MealKind
    var loggedAt: Date
    var servingGrams: Double
    var nutrients: NutritionFacts
}

nonisolated enum NutritionGradientKind: Equatable, Sendable {
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

nonisolated enum FoodIconKind: Equatable, Sendable {
    case poultry
    case yogurt
    case berries
    case shake
    case generic

    var symbolName: String {
        switch self {
        case .poultry: "bird.fill"
        case .yogurt: "cup.and.saucer.fill"
        case .berries: "circle.grid.2x2.fill"
        case .shake: "takeoutbag.and.cup.and.straw.fill"
        case .generic: "fork.knife"
        }
    }

    var gradientKind: NutritionGradientKind {
        switch self {
        case .poultry: .poultry
        case .yogurt: .yogurt
        case .berries: .berries
        case .shake: .shake
        case .generic: .generic
        }
    }
}

nonisolated struct MealSection: Identifiable, Equatable, Sendable {
    var id: MealKind { meal }
    var meal: MealKind
    var rows: [DiaryEntryRow]
    var total: NutritionFacts
}

nonisolated enum DashboardDemoData {
    static let entries: [DiaryEntryRow] = [
        DiaryEntryRow(
            id: UUID(uuidString: "04E5E1DA-1DB8-4FA9-B043-FE93E333B301")!,
            foodName: "Greek yogurt",
            brand: "Plain, 2%",
            iconKind: .yogurt,
            meal: .breakfast,
            loggedAt: .now,
            servingGrams: 170,
            nutrients: NutritionFacts(calories: 146, protein: 20, carbs: 7, fat: 4, fiber: 0)
        ),
        DiaryEntryRow(
            id: UUID(uuidString: "B210C5E6-7BE0-4D1B-85B6-8111FDE7AE55")!,
            foodName: "Blueberries",
            brand: "Fresh",
            iconKind: .berries,
            meal: .breakfast,
            loggedAt: .now,
            servingGrams: 80,
            nutrients: NutritionFacts(calories: 46, protein: 1, carbs: 12, fat: 0, fiber: 2)
        ),
        DiaryEntryRow(
            id: UUID(uuidString: "EF03E589-956D-40B6-9864-A4A91164C4BC")!,
            foodName: "Chicken rice bowl",
            brand: "Homemade",
            iconKind: .poultry,
            meal: .lunch,
            loggedAt: .now,
            servingGrams: 410,
            nutrients: NutritionFacts(calories: 612, protein: 48, carbs: 62, fat: 18, fiber: 6)
        ),
        DiaryEntryRow(
            id: UUID(uuidString: "AB98B50F-6DDC-45DA-8EC6-A5C9F12EAF37")!,
            foodName: "Protein shake",
            brand: "Vanilla",
            iconKind: .shake,
            meal: .snack,
            loggedAt: .now,
            servingGrams: 320,
            nutrients: NutritionFacts(calories: 238, protein: 34, carbs: 12, fat: 5, fiber: 1)
        ),
    ]

    static let analytics = DashboardAnalyticsViewState(
        weightTrend: HealthGraphViewState(
            id: "weight",
            title: "Weight trend",
            symbolName: "scalemass",
            valueText: "181.4",
            unitText: "lb",
            detailText: "-2.8 lb / 14 days",
            style: .lineArea,
            gradientKind: .weight,
            negativeGradientKind: nil,
            values: [
                184.2, 183.9, 183.7, 183.8, 183.1, 182.9, 182.6,
                182.8, 182.3, 182.0, 181.8, 181.9, 181.5, 181.4,
            ]
        ),
        expenditure: HealthGraphViewState(
            id: "expenditure",
            title: "Expenditure",
            symbolName: "flame.fill",
            valueText: "2,640",
            unitText: "kcal",
            detailText: "14 day burn average",
            style: .bars,
            gradientKind: .expenditure,
            negativeGradientKind: nil,
            values: [
                2_420, 2_510, 2_640, 2_580, 2_760, 2_900, 2_680,
                2_590, 2_730, 2_810, 2_620, 2_700, 2_540, 2_690,
            ]
        ),
        energyBalance: HealthGraphViewState(
            id: "balance",
            title: "Energy balance",
            symbolName: "plus.forwardslash.minus",
            valueText: "-284",
            unitText: "kcal",
            detailText: "average daily deficit",
            style: .bars,
            gradientKind: .balancePositive,
            negativeGradientKind: .balanceNegative,
            baselineRule: .zero,
            values: [
                -380, -260, -140, 90, -420, -530, -310,
                -180, 120, -260, -340, -110, -510, -440,
            ]
        ),
    )

    static func sections(from entries: [DiaryEntryRow]) -> [MealSection] {
        let rowsByMeal = Dictionary(grouping: entries, by: \.meal)
        return MealKind.allCases.map { meal in
            let rows = rowsByMeal[meal] ?? []
            return MealSection(
                meal: meal,
                rows: rows,
                total: rows.reduce(.zero) { $0 + $1.nutrients }
            )
        }
    }

    static func summary(
        from entries: [DiaryEntryRow],
        targets: DailyTargets = .standard
    ) -> NutritionSummary {
        NutritionSummary(
            consumed: entries.reduce(.zero) { $0 + $1.nutrients },
            targets: targets
        )
    }
}
