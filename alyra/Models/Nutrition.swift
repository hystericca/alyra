//
//  Nutrition.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import Foundation

nonisolated enum MealTime: String, CaseIterable, Codable, Identifiable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }
}

nonisolated enum LogEntryType: String, CaseIterable, Codable, Identifiable, Sendable {
    case food = "Food"
    case weight = "Weight"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .food: "fork.knife"
        case .weight: "scalemass"
        }
    }
}

nonisolated enum UnitSystem: String, CaseIterable, Identifiable, Sendable {
    case imperial = "Imperial"
    case metric = "Metric"

    var id: String { rawValue }

    var weightUnitName: String {
        switch self {
        case .imperial: "lb"
        case .metric: "kg"
        }
    }

    var weightUnit: UnitMass {
        switch self {
        case .imperial: .pounds
        case .metric: .kilograms
        }
    }
}

nonisolated struct NutritionFacts: Codable, Equatable, Sendable {
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

nonisolated struct DailyTargets: Codable, Equatable, Sendable {
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

nonisolated struct NutritionSummary: Codable, Equatable, Sendable {
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

nonisolated struct FoodLogEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var foodName: String
    var brand: String
    var mealTime: MealTime
    var loggedAt: Date
    var servingGrams: Double
    var nutrients: NutritionFacts
}

nonisolated struct WeightLogEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var loggedAt: Date
    var weightKilograms: Double
    var note: String

    private enum CodingKeys: String, CodingKey {
        case id
        case loggedAt
        case weightKilograms
        case weightPounds
        case note
    }

    init(
        id: UUID,
        loggedAt: Date,
        weightKilograms: Double,
        note: String
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.weightKilograms = weightKilograms
        self.note = note
    }

    init(
        id: UUID,
        loggedAt: Date,
        displayWeight: Double,
        unitSystem: UnitSystem,
        note: String
    ) {
        let measurement = Measurement(
            value: displayWeight,
            unit: unitSystem.weightUnit
        ).converted(to: .kilograms)

        self.init(
            id: id,
            loggedAt: loggedAt,
            weightKilograms: measurement.value,
            note: note
        )
    }

    func displayWeight(for unitSystem: UnitSystem) -> Double {
        Measurement(
            value: weightKilograms,
            unit: UnitMass.kilograms
        )
        .converted(to: unitSystem.weightUnit)
        .value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        loggedAt = try container.decode(Date.self, forKey: .loggedAt)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""

        if let weightKilograms = try container.decodeIfPresent(
            Double.self,
            forKey: .weightKilograms
        ) {
            self.weightKilograms = weightKilograms
        } else {
            let weightPounds = try container.decode(Double.self, forKey: .weightPounds)
            self.weightKilograms = Measurement(
                value: weightPounds,
                unit: UnitMass.pounds
            )
            .converted(to: .kilograms)
            .value
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(loggedAt, forKey: .loggedAt)
        try container.encode(weightKilograms, forKey: .weightKilograms)
        try container.encode(note, forKey: .note)
    }
}

nonisolated struct MealSection: Identifiable, Equatable, Sendable {
    var id: MealTime { mealTime }

    var mealTime: MealTime
    var entries: [FoodLogEntry]
    var total: NutritionFacts
}

nonisolated enum Nutrition {
    static func sections(from entries: [FoodLogEntry]) -> [MealSection] {
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
        from entries: [FoodLogEntry],
        targets: DailyTargets = .standard
    ) -> NutritionSummary {
        NutritionSummary(
            consumed: entries.reduce(.zero) { $0 + $1.nutrients },
            targets: targets
        )
    }
}

enum FoodLogStore {
    private static let storageKey = "alyra.nutrition.logEntries"

    static func load() -> [FoodLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([FoodLogEntry].self, from: data)
        } catch {
            return []
        }
    }

    static func save(_ entries: [FoodLogEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save nutrition log entries: \(error)")
        }
    }
}

enum WeightLogStore {
    private static let storageKey = "alyra.weight.logEntries"

    static func load() -> [WeightLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WeightLogEntry].self, from: data)
        } catch {
            return []
        }
    }

    static func save(_ entries: [WeightLogEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save weight log entries: \(error)")
        }
    }
}
