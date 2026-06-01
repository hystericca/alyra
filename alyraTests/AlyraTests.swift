import Foundation
import Testing

@testable import Alyra

struct AlyraTests {
    @Test func dashboardSummaryTotalsEntries() {
        let summary = Nutrition.summary(from: Self.entries)

        #expect(summary.consumed.calories == 1_042)
        #expect(summary.consumed.protein == 103)
        #expect(summary.consumed.carbs == 93)
        #expect(summary.consumed.fat == 27)
    }

    @Test func calorieProgressClampsAtTarget() {
        let summary = NutritionSummary(
            consumed: NutritionFacts(
                calories: 2_640,
                protein: 0,
                carbs: 0,
                fat: 0,
                fiber: 0
            ),
            targets: DailyTargets.standard
        )

        #expect(summary.calorieProgress == 1)
    }

    @Test func dashboardSectionsKeepAllMealSlots() {
        let sections = Nutrition.sections(from: Self.entries)

        #expect(sections.map(\.mealTime) == MealTime.allCases)
        #expect(sections.first { $0.mealTime == .dinner }?.entries.isEmpty == true)
    }

    @Test func dashboardSnapshotPrecomputesRenderState() {
        let snapshot = DashboardSnapshot.from(
            entries: Self.entries,
            analytics: .empty
        )

        let protein = snapshot.macros.tiles.first { $0.id == .protein }

        #expect(snapshot.calories.consumedCaloriesText == "1,042")
        #expect(protein?.title == "Protein")
        #expect(protein?.valueText == "103 g")
        #expect(protein?.targetText == "140 g")
        #expect(protein?.symbolName == "dumbbell.fill")
        #expect(snapshot.macros.tiles.map(\.title) == ["Protein", "Carbs", "Fat"])
        #expect(snapshot.analytics.weightTrend.samples.isEmpty)
        #expect(snapshot.analytics.energyBalance.baseline == 0)
        #expect(snapshot.sections.first { $0.mealTime == .breakfast }?.totalCaloriesText == "192 kcal")
        let firstEntryTime = Self.entries[0].loggedAt.formatted(Date.FormatStyle.dateTime.hour().minute())
        #expect(snapshot.sections.first?.entries.first?.detailText == "\(firstEntryTime) - 170 g - Plain, 2%")
        #expect(snapshot.sections.first?.entries.first?.iconKind == .yogurt)
    }

    @Test func balanceGraphsUseZeroBaselineForAllNegativeValues() {
        let graph = HealthGraphViewState(
            id: "balance",
            title: "Energy balance",
            symbolName: "plus.forwardslash.minus",
            valueText: "-200",
            unitText: "kcal",
            detailText: "daily deficit",
            style: .bars,
            gradientKind: .balancePositive,
            negativeGradientKind: .balanceNegative,
            baselineRule: .zero,
            values: [-300, -200, -100]
        )

        #expect(graph.baseline == 0)
        #expect(graph.samples.allSatisfy { $0.normalizedValue < graph.baselineNormalized })
    }

    @Test func weightEntriesBuildWeightTrendAnalytics() {
        let analytics = DashboardAnalyticsViewState.from(
            foodEntries: [],
            targets: .standard,
            weightEntries: Self.weightEntries,
            unitSystem: .imperial,
            through: Self.referenceDate
        )

        #expect(analytics.weightTrend.valueText == "181.4")
        #expect(analytics.weightTrend.detailText == "-2.8 lb / 3d")
        #expect(analytics.weightTrend.samples.count == 3)
        #expect(analytics.expenditure.samples.isEmpty)
    }

    @Test func weightEntriesUseMetricUnitsWhenSelected() {
        let analytics = DashboardAnalyticsViewState.from(
            foodEntries: [],
            targets: .standard,
            weightEntries: Self.weightEntries,
            unitSystem: .metric,
            through: Self.referenceDate
        )

        #expect(analytics.weightTrend.unitText == "kg")
        #expect(analytics.weightTrend.valueText == "82.3")
    }

    @Test func emptyWeightAnalyticsUseSelectedUnits() {
        let analytics = DashboardAnalyticsViewState.from(
            foodEntries: [],
            targets: .standard,
            weightEntries: [],
            unitSystem: .metric,
            through: Self.referenceDate
        )

        #expect(analytics.weightTrend.unitText == "kg")
        #expect(analytics.weightTrend.samples.isEmpty)
    }

    @Test func foodEntriesBuildIntakeAndBalanceTrends() {
        let analytics = DashboardAnalyticsViewState.from(
            foodEntries: Self.entries,
            targets: DailyTargets.standard,
            weightEntries: [],
            unitSystem: .imperial,
            through: Date(timeIntervalSinceReferenceDate: 7_200)
        )

        #expect(analytics.expenditure.title == "Energy intake")
        #expect(analytics.expenditure.valueText == "1,042")
        #expect(analytics.expenditure.samples.count == 14)
        #expect(analytics.energyBalance.valueText == "-1,158")
        #expect(analytics.energyBalance.samples.last?.value == -1_158)
    }

    @Test func logEntryViewStateIncludesLoggedTime() {
        let entry = LogEntryViewState(entry: Self.entries[1])
        let loggedTime = Self.entries[1].loggedAt.formatted(Date.FormatStyle.dateTime.hour().minute())

        #expect(entry.detailText == "\(loggedTime) - 420 g - Homemade")
    }

    private static let referenceDate = Date(timeIntervalSinceReferenceDate: 172_800)

    private static let entries = [
        FoodLogEntry(
            id: UUID(uuidString: "86F8EB82-4327-4D87-897D-1382A020F210")!,
            foodName: "Greek Yogurt",
            brand: "Plain, 2%",
            mealTime: .breakfast,
            loggedAt: Date(timeIntervalSinceReferenceDate: 0),
            servingGrams: 170,
            nutrients: NutritionFacts(
                calories: 192,
                protein: 20,
                carbs: 9,
                fat: 8,
                fiber: 0
            )
        ),
        FoodLogEntry(
            id: UUID(uuidString: "1F11E3CB-B5C8-489D-B12A-749278E53A6B")!,
            foodName: "Chicken Bowl",
            brand: "Homemade",
            mealTime: .lunch,
            loggedAt: Date(timeIntervalSinceReferenceDate: 3_600),
            servingGrams: 420,
            nutrients: NutritionFacts(
                calories: 640,
                protein: 62,
                carbs: 68,
                fat: 16,
                fiber: 9
            )
        ),
        FoodLogEntry(
            id: UUID(uuidString: "952A0DA8-3485-4D8B-856D-F905195551BA")!,
            foodName: "Protein Shake",
            brand: "Whey",
            mealTime: .snack,
            loggedAt: Date(timeIntervalSinceReferenceDate: 7_200),
            servingGrams: 330,
            nutrients: NutritionFacts(
                calories: 210,
                protein: 21,
                carbs: 16,
                fat: 3,
                fiber: 2
            )
        ),
    ]

    private static let weightEntries = [
        WeightLogEntry(
            id: UUID(uuidString: "DDE9A2A0-3B8A-4862-A40C-4FDC90EC41C1")!,
            loggedAt: Date(timeIntervalSinceReferenceDate: 0),
            displayWeight: 184.2,
            unitSystem: .imperial,
            note: ""
        ),
        WeightLogEntry(
            id: UUID(uuidString: "586E7E93-2D2C-42DD-86D2-5DC3EBD4DB3D")!,
            loggedAt: Date(timeIntervalSinceReferenceDate: 86_400),
            displayWeight: 182.6,
            unitSystem: .imperial,
            note: ""
        ),
        WeightLogEntry(
            id: UUID(uuidString: "17C7BF17-1C91-40C6-80A6-962525B3E9F4")!,
            loggedAt: Date(timeIntervalSinceReferenceDate: 172_800),
            displayWeight: 181.4,
            unitSystem: .imperial,
            note: ""
        ),
    ]
}
