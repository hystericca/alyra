//
//  Nutrition.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import Foundation

nonisolated enum MealTime: String, CaseIterable, Identifiable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }
}

nonisolated struct NutritionFacts: Equatable, Sendable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double

    static let zero = NutritionFacts(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0
    )

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

    static let standard = DailyTargets(
        calories: 2_200,
        protein: 140,
        carbs: 250,
        fat: 70
    )
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

nonisolated struct LogEntry: Identifiable, Equatable, Sendable {
    var id: UUID
    var foodName: String
    var brand: String
    var mealTime: MealTime
    var loggedAt: Date
    var servingGrams: Double
    var nutrients: NutritionFacts
}

nonisolated struct MealSection: Identifiable, Equatable, Sendable {
    var id: MealTime { mealTime }

    var mealTime: MealTime
    var entries: [LogEntry]
    var total: NutritionFacts
}

nonisolated enum Nutrition {
    static func sections(from entries: [LogEntry]) -> [MealSection] {
        let entriesByMealTime = Dictionary(grouping: entries, by: \.mealTime)

        return MealTime.allCases.map { mealTime in
            let entries = entriesByMealTime[mealTime] ?? []

            return MealSection(
                mealTime: mealTime,
                entries: entries,
                total: entries.reduce(.zero) { $0 + $1.nutrients }
            )
        }
    }

    static func summary(
        from entries: [LogEntry],
        targets: DailyTargets = .standard
    ) -> NutritionSummary {
        NutritionSummary(
            consumed: entries.reduce(.zero) { $0 + $1.nutrients },
            targets: targets
        )
    }
}
