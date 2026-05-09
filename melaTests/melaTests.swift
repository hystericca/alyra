import Testing

@testable import mela

struct melaTests {
    @Test func dashboardSummaryTotalsDemoEntries() {
        let summary = DashboardDemoData.summary(from: DashboardDemoData.entries)

        #expect(summary.consumed.calories == 1_042)
        #expect(summary.consumed.protein == 103)
        #expect(summary.consumed.carbs == 93)
        #expect(summary.consumed.fat == 27)
    }

    @Test func dashboardSectionsKeepAllMealSlots() {
        let sections = DashboardDemoData.sections(from: DashboardDemoData.entries)

        #expect(sections.map(\.meal) == MealKind.allCases)
        #expect(sections.first { $0.meal == .dinner }?.rows.isEmpty == true)
    }

    @Test func dashboardSnapshotPrecomputesRenderState() {
        let snapshot = DashboardSnapshot.make(entries: DashboardDemoData.entries)

        #expect(snapshot.calories.consumedCalories == 1_042)
        #expect(snapshot.macros.protein.title == "Protein")
        #expect(snapshot.macros.carbs.title == "Carbs")
        #expect(snapshot.macros.fat.title == "Fat")
        #expect(snapshot.macros.fiber.title == "Fiber")
        #expect(snapshot.sections.first { $0.meal == .breakfast }?.totalCalories == 192)
        #expect(snapshot.sections.first?.rows.first?.detailText == "170 g - Plain, 2%")
    }
}
