//
//  DashboardDemoData.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//
import Foundation

nonisolated enum DashboardDemoData {
    static let entries: [LogEntry] = [
        LogEntry(
            id: UUID(uuidString: "04E5E1DA-1DB8-4FA9-B043-FE93E333B301")!,
            foodName: "Greek yogurt",
            brand: "Plain, 2%",
            mealTime: .breakfast,
            loggedAt: .now,
            servingGrams: 170,
            nutrients: NutritionFacts(
                calories: 146,
                protein: 20,
                carbs: 7,
                fat: 4,
                fiber: 0
            )
        ),
        LogEntry(
            id: UUID(uuidString: "B210C5E6-7BE0-4D1B-85B6-8111FDE7AE55")!,
            foodName: "Blueberries",
            brand: "Fresh",
            mealTime: .breakfast,
            loggedAt: .now,
            servingGrams: 80,
            nutrients: NutritionFacts(
                calories: 46,
                protein: 1,
                carbs: 12,
                fat: 0,
                fiber: 2
            )
        ),
        LogEntry(
            id: UUID(uuidString: "EF03E589-956D-40B6-9864-A4A91164C4BC")!,
            foodName: "Chicken rice bowl",
            brand: "Homemade",
            mealTime: .lunch,
            loggedAt: .now,
            servingGrams: 410,
            nutrients: NutritionFacts(
                calories: 612,
                protein: 48,
                carbs: 62,
                fat: 18,
                fiber: 6
            )
        ),
        LogEntry(
            id: UUID(uuidString: "AB98B50F-6DDC-45DA-8EC6-A5C9F12EAF37")!,
            foodName: "Protein shake",
            brand: "Vanilla",
            mealTime: .snack,
            loggedAt: .now,
            servingGrams: 320,
            nutrients: NutritionFacts(
                calories: 238,
                protein: 34,
                carbs: 12,
                fat: 5,
                fiber: 1
            )
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
}
