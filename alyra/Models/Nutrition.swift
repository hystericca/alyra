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

    static func defaultFor(date: Date, calendar: Calendar = .current) -> MealTime {
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }
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

    func scaled(by multiplier: Double) -> NutritionFacts {
        NutritionFacts(
            calories: calories * multiplier,
            protein: protein * multiplier,
            carbs: carbs * multiplier,
            fat: fat * multiplier,
            fiber: fiber * multiplier
        )
    }

    func normalizedPer100Grams(servingGrams: Double) -> NutritionFacts {
        guard servingGrams > 0 else { return .zero }
        return scaled(by: 100 / servingGrams)
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

nonisolated enum FoodDataSource: String, Codable, Sendable {
    case manual
    case foodDatabase
}

nonisolated struct FoodReference: Codable, Equatable, Sendable {
    var source: FoodDataSource
    var externalID: String?
    var canonicalName: String

    static func manual(name: String) -> FoodReference {
        FoodReference(
            source: .manual,
            externalID: nil,
            canonicalName: name
        )
    }
}

nonisolated enum FoodIconKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case apple
    case avocado
    case banana
    case beans
    case bread
    case burger
    case cheese
    case coffee
    case eggs
    case fish
    case fruit
    case grains
    case greens
    case milk
    case noodles
    case nuts
    case poultry
    case rice
    case salad
    case sandwich
    case seafood
    case soup
    case sweets
    case taco
    case tofu
    case vegetables
    case yogurt
    case berries
    case shake
    case generic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple: "Apple"
        case .avocado: "Avocado"
        case .banana: "Banana"
        case .beans: "Beans"
        case .bread: "Bread"
        case .burger: "Burger"
        case .cheese: "Cheese"
        case .coffee: "Coffee"
        case .eggs: "Eggs"
        case .fish: "Fish"
        case .fruit: "Fruit"
        case .grains: "Grains"
        case .greens: "Greens"
        case .milk: "Milk"
        case .noodles: "Noodles"
        case .nuts: "Nuts"
        case .poultry: "Poultry"
        case .rice: "Rice"
        case .salad: "Salad"
        case .sandwich: "Sandwich"
        case .seafood: "Seafood"
        case .soup: "Soup"
        case .sweets: "Sweets"
        case .taco: "Taco"
        case .tofu: "Tofu"
        case .vegetables: "Vegetables"
        case .yogurt: "Yogurt"
        case .berries: "Berries"
        case .shake: "Shake"
        case .generic: "Food"
        }
    }

    var symbolName: String {
        switch self {
        case .apple: "apple.logo"
        case .avocado: "oval.fill"
        case .banana: "moon.fill"
        case .beans: "circle.grid.3x3.fill"
        case .bread: "birthday.cake.fill"
        case .burger: "takeoutbag.and.cup.and.straw.fill"
        case .cheese: "triangle.fill"
        case .coffee: "cup.and.saucer.fill"
        case .eggs: "oval.portrait.fill"
        case .fish: "fish.fill"
        case .fruit: "leaf.circle.fill"
        case .grains: "circle.hexagongrid.fill"
        case .greens: "leaf.fill"
        case .milk: "waterbottle.fill"
        case .noodles: "takeoutbag.and.cup.and.straw.fill"
        case .nuts: "circle.grid.cross.fill"
        case .poultry: "bird.fill"
        case .rice: "circle.grid.2x2.fill"
        case .salad: "leaf"
        case .sandwich: "rectangle.fill"
        case .seafood: "fish"
        case .soup: "cup.and.saucer.fill"
        case .sweets: "birthday.cake.fill"
        case .taco: "seal.fill"
        case .tofu: "cube.fill"
        case .vegetables: "carrot.fill"
        case .yogurt: "cup.and.saucer.fill"
        case .berries: "circle.grid.2x2.fill"
        case .shake: "takeoutbag.and.cup.and.straw.fill"
        case .generic: "fork.knife"
        }
    }

    static func guess(foodName: String) -> FoodIconKind {
        let name = foodName.lowercased()

        if name.contains("apple") { return .apple }
        if name.contains("avocado") { return .avocado }
        if name.contains("banana") { return .banana }
        if name.contains("bean") { return .beans }
        if name.contains("bread") || name.contains("toast") { return .bread }
        if name.contains("burger") { return .burger }
        if name.contains("cheese") { return .cheese }
        if name.contains("coffee") { return .coffee }
        if name.contains("egg") { return .eggs }
        if name.contains("fish") || name.contains("salmon") || name.contains("tuna") { return .fish }
        if name.contains("oat") || name.contains("grain") { return .grains }
        if name.contains("spinach") || name.contains("lettuce") { return .greens }
        if name.contains("milk") { return .milk }
        if name.contains("noodle") || name.contains("pasta") { return .noodles }
        if name.contains("almond") || name.contains("nut") { return .nuts }
        if name.contains("chicken") { return .poultry }
        if name.contains("rice") { return .rice }
        if name.contains("salad") { return .salad }
        if name.contains("sandwich") { return .sandwich }
        if name.contains("shrimp") || name.contains("seafood") { return .seafood }
        if name.contains("soup") { return .soup }
        if name.contains("cake") || name.contains("cookie") || name.contains("candy") { return .sweets }
        if name.contains("taco") { return .taco }
        if name.contains("tofu") { return .tofu }
        if name.contains("carrot") || name.contains("vegetable") { return .vegetables }
        if name.contains("yogurt") { return .yogurt }
        if name.contains("blueberr") || name.contains("berr") { return .berries }
        if name.contains("shake") { return .shake }

        return .generic
    }
}

nonisolated struct FoodProfileIdentity: Codable, Hashable, Sendable {
    var source: FoodDataSource
    var value: String

    static func manual(foodName: String, brand: String) -> FoodProfileIdentity {
        FoodProfileIdentity(
            source: .manual,
            value: [
                normalizedFoodKey(foodName),
                normalizedFoodKey(brand),
            ].joined(separator: "|")
        )
    }

    static func database(id: String) -> FoodProfileIdentity {
        FoodProfileIdentity(source: .foodDatabase, value: id)
    }

    private static func normalizedFoodKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

nonisolated struct FoodProfileSnapshot: Codable, Equatable, Sendable {
    var identity: FoodProfileIdentity
    var foodName: String
    var brand: String
    var iconKind: FoodIconKind
    var foodReference: FoodReference
    var nutrientsPer100Grams: NutritionFacts

    static func manual(
        foodName: String,
        brand: String,
        iconKind: FoodIconKind,
        nutrients: NutritionFacts,
        servingGrams: Double
    ) -> FoodProfileSnapshot {
        FoodProfileSnapshot(
            identity: .manual(foodName: foodName, brand: brand),
            foodName: foodName,
            brand: brand,
            iconKind: iconKind,
            foodReference: .manual(name: foodName),
            nutrientsPer100Grams: nutrients.normalizedPer100Grams(servingGrams: servingGrams)
        )
    }

    func renamedIfNeeded(
        foodName: String,
        brand: String,
        iconKind: FoodIconKind,
        nutrients: NutritionFacts,
        servingGrams: Double
    ) -> FoodProfileSnapshot {
        let nextIdentity = FoodProfileIdentity.manual(foodName: foodName, brand: brand)
        guard identity == nextIdentity else {
            return .manual(
                foodName: foodName,
                brand: brand,
                iconKind: iconKind,
                nutrients: nutrients,
                servingGrams: servingGrams
            )
        }

        var snapshot = self
        snapshot.foodName = foodName
        snapshot.brand = brand
        snapshot.iconKind = iconKind
        snapshot.nutrientsPer100Grams = nutrients.normalizedPer100Grams(servingGrams: servingGrams)
        return snapshot
    }
}

nonisolated struct FoodLogEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var foodName: String
    var brand: String
    var iconKind: FoodIconKind
    var foodReference: FoodReference
    var foodProfile: FoodProfileSnapshot
    var mealTime: MealTime
    var loggedAt: Date
    var servingGrams: Double
    var nutrients: NutritionFacts

    private enum CodingKeys: String, CodingKey {
        case id
        case foodName
        case brand
        case iconKind
        case foodReference
        case foodProfile
        case mealTime
        case loggedAt
        case servingGrams
        case nutrients
    }

    init(
        id: UUID,
        foodName: String,
        brand: String,
        iconKind: FoodIconKind = .generic,
        foodReference: FoodReference? = nil,
        foodProfile: FoodProfileSnapshot? = nil,
        mealTime: MealTime,
        loggedAt: Date,
        servingGrams: Double,
        nutrients: NutritionFacts
    ) {
        self.id = id
        self.foodName = foodName
        self.brand = brand
        self.iconKind = iconKind
        self.foodReference = foodReference ?? .manual(name: foodName)
        self.foodProfile = foodProfile ?? .manual(
            foodName: foodName,
            brand: brand,
            iconKind: iconKind,
            nutrients: nutrients,
            servingGrams: servingGrams
        )
        self.mealTime = mealTime
        self.loggedAt = loggedAt
        self.servingGrams = servingGrams
        self.nutrients = nutrients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        foodName = try container.decode(String.self, forKey: .foodName)
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        mealTime = try container.decode(MealTime.self, forKey: .mealTime)
        loggedAt = try container.decode(Date.self, forKey: .loggedAt)
        servingGrams = try container.decode(Double.self, forKey: .servingGrams)
        nutrients = try container.decode(NutritionFacts.self, forKey: .nutrients)
        iconKind = try container.decodeIfPresent(FoodIconKind.self, forKey: .iconKind) ?? .guess(foodName: foodName)
        foodReference = try container.decodeIfPresent(FoodReference.self, forKey: .foodReference) ?? .manual(name: foodName)
        foodProfile = try container.decodeIfPresent(FoodProfileSnapshot.self, forKey: .foodProfile) ?? .manual(
            foodName: foodName,
            brand: brand,
            iconKind: iconKind,
            nutrients: nutrients,
            servingGrams: servingGrams
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(foodName, forKey: .foodName)
        try container.encode(brand, forKey: .brand)
        try container.encode(iconKind, forKey: .iconKind)
        try container.encode(foodReference, forKey: .foodReference)
        try container.encode(foodProfile, forKey: .foodProfile)
        try container.encode(mealTime, forKey: .mealTime)
        try container.encode(loggedAt, forKey: .loggedAt)
        try container.encode(servingGrams, forKey: .servingGrams)
        try container.encode(nutrients, forKey: .nutrients)
    }
}

nonisolated struct FoodQuickAddTemplate: Identifiable, Equatable, Sendable {
    var id: String
    var foodName: String
    var brand: String
    var iconKind: FoodIconKind
    var foodReference: FoodReference
    var foodProfile: FoodProfileSnapshot
    var mealTime: MealTime
    var lastLoggedAt: Date
    var defaultServingGrams: Double
    var nutrientsPer100Grams: NutritionFacts

    var displayDetail: String {
        brand.isEmpty ? "Recently logged" : brand
    }

    func nutrients(for servingGrams: Double) -> NutritionFacts {
        nutrientsPer100Grams.scaled(by: servingGrams / 100)
    }

    func entry(servingGrams: Double, loggedAt: Date, mealTime: MealTime) -> FoodLogEntry {
        FoodLogEntry(
            id: UUID(),
            foodName: foodName,
            brand: brand,
            iconKind: iconKind,
            foodReference: foodReference,
            foodProfile: foodProfile,
            mealTime: mealTime,
            loggedAt: loggedAt,
            servingGrams: servingGrams,
            nutrients: nutrients(for: servingGrams)
        )
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

    static func quickAddTemplates(
        from entries: [FoodLogEntry],
        mealTime: MealTime,
        limit: Int = 6
    ) -> [FoodQuickAddTemplate] {
        let templatesByFood = Dictionary(grouping: entries.filter { $0.mealTime == mealTime }) { entry in
            foodIdentity(for: entry)
        }

        return templatesByFood.values.compactMap { groupedEntries in
            guard
                let latestEntry = groupedEntries.sorted(by: { $0.loggedAt > $1.loggedAt }).first,
                latestEntry.servingGrams > 0
            else {
                return nil
            }

            return FoodQuickAddTemplate(
                id: foodIdentity(for: latestEntry),
                foodName: latestEntry.foodName,
                brand: latestEntry.brand,
                iconKind: latestEntry.iconKind,
                foodReference: latestEntry.foodReference,
                foodProfile: latestEntry.foodProfile,
                mealTime: latestEntry.mealTime,
                lastLoggedAt: latestEntry.loggedAt,
                defaultServingGrams: latestEntry.servingGrams,
                nutrientsPer100Grams: latestEntry.foodProfile.nutrientsPer100Grams
            )
        }
        .sorted { $0.lastLoggedAt > $1.lastLoggedAt }
        .prefix(limit)
        .map { $0 }
    }

    private static func foodIdentity(for entry: FoodLogEntry) -> String {
        "\(entry.foodProfile.identity.source.rawValue):\(entry.foodProfile.identity.value)"
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
