import Testing

@testable import Alyra

struct AlyraTests {
    @Test func dashboardSummaryTotalsDemoEntries() {
        let summary = Nutrition.summary(from: DashboardDemoData.entries)

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
        let sections = Nutrition.sections(from: DashboardDemoData.entries)

        #expect(sections.map(\.mealTime) == MealTime.allCases)
        #expect(sections.first { $0.mealTime == .dinner }?.entries.isEmpty == true)
    }

    @Test func dashboardSnapshotPrecomputesRenderState() {
        let snapshot = DashboardSnapshot.from(
            entries: DashboardDemoData.entries,
            analytics: DashboardDemoData.analytics
        )

        let protein = snapshot.macros.tiles.first { $0.id == .protein }

        #expect(snapshot.calories.consumedCaloriesText == "1,042")
        #expect(protein?.title == "Protein")
        #expect(protein?.valueText == "103 g")
        #expect(protein?.targetText == "140 g")
        #expect(protein?.symbolName == "dumbbell.fill")
        #expect(snapshot.macros.tiles.map(\.title) == ["Protein", "Carbs", "Fat"])
        #expect(snapshot.analytics.weightTrend.samples.count == 14)
        #expect(snapshot.analytics.energyBalance.baseline == 0)
        #expect(snapshot.sections.first { $0.mealTime == .breakfast }?.totalCaloriesText == "192 kcal")
        #expect(snapshot.sections.first?.entries.first?.detailText == "170 g - Plain, 2%")
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
}
