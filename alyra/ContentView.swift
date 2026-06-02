//
//  ContentView.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedTab = AppTab.dashboard
    @State private var selectedDate = Date.now
    @State private var dateNavigationDirection = DateNavigationDirection.forward
    @State private var entries = FoodLogStore.load()
    @State private var weightEntries = WeightLogStore.load()
    @State private var trendPeriod = TrendPeriod.twoWeeks
    @State private var isWeightHistoryPresented = false
    @State private var editingFoodEntry: FoodLogEntry?
    @AppStorage(AppSettingsKeys.dailyCalories) private var dailyCalories = 2_200.0
    @AppStorage(AppSettingsKeys.proteinTarget) private var proteinTarget = 140.0
    @AppStorage(AppSettingsKeys.carbsTarget) private var carbsTarget = 250.0
    @AppStorage(AppSettingsKeys.fatTarget) private var fatTarget = 70.0
    @AppStorage(AppSettingsKeys.unitSystem) private var unitSystem = UnitSystem.imperial.rawValue
    @AppStorage(AppSettingsKeys.healthKitNutritionWrite) private var healthKitNutritionWrite = false
    @AppStorage(AppSettingsKeys.healthKitWeightWrite) private var healthKitWeightWrite = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.dashboard.title, systemImage: AppTab.dashboard.symbolName, value: AppTab.dashboard) {
                dashboardTab
            }

            Tab(AppTab.add.title, systemImage: AppTab.add.symbolName, value: AppTab.add) {
                addTab
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.symbolName, value: AppTab.settings) {
                settingsTab
            }
        }
        .tabViewStyle(.tabBarOnly)
        .tint(AppTheme.primaryText)
        .toolbarBackground(AppTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(AppTheme.preferredColorScheme, for: .tabBar)
        .background(AppTheme.background)
        .preferredColorScheme(AppTheme.preferredColorScheme)
        .onChange(of: selectedTab) { _, tab in
            if tab != .add {
                editingFoodEntry = nil
            }
        }
    }

    private var dashboardTab: some View {
        NavigationStack {
            DashboardView(
                date: dateState,
                dateNavigationDirection: dateNavigationDirection,
                snapshot: dashboard,
                appTabPadding: tabContentPadding,
                trendPeriod: $trendPeriod,
                onPreviousDay: { moveDate(by: -1) },
                onNextDay: { moveDate(by: 1) },
                onEdit: editEntry,
                onDelete: deleteEntry,
                onWeightTrendSelected: { isWeightHistoryPresented = true }
            )
            .navigationDestination(isPresented: $isWeightHistoryPresented) {
                WeightHistoryView(
                    entries: weightEntriesForTrend,
                    unitSystem: selectedUnitSystem,
                    trendPeriod: $trendPeriod,
                    through: selectedDate,
                    onSave: saveWeightEntry,
                    onDelete: deleteWeightEntry
                )
            }
        }
        .toolbarBackground(AppTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(AppTheme.preferredColorScheme, for: .tabBar)
    }

    private var addTab: some View {
        LogEntryView(
            date: selectedDate,
            editingFoodEntry: editingFoodEntry,
            appTabPadding: tabContentPadding,
            unitSystem: selectedUnitSystem,
            foodHistory: entries,
            onSaveFood: addEntry,
            onSaveWeight: addWeightEntry
        )
        .toolbarBackground(AppTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(AppTheme.preferredColorScheme, for: .tabBar)
    }

    private var settingsTab: some View {
        SettingsView(
            appTabPadding: tabContentPadding,
            onImportAppleHealthWeights: importWeightsFromHealth
        )
            .toolbarBackground(AppTheme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(AppTheme.preferredColorScheme, for: .tabBar)
    }

    private func moveDate(by days: Int) {
        withAnimation(AppTheme.Motion.dateChange(reduceMotion: reduceMotion)) {
            dateNavigationDirection = days < 0 ? .backward : .forward

            let nextDate =
                Calendar.current.date(
                    byAdding: .day,
                    value: days,
                    to: selectedDate
                ) ?? selectedDate

            selectedDate = nextDate
        }
    }

    private func deleteEntry(id: UUID) {
        let deletedEntry = entries.first { $0.id == id }

        withAnimation(AppTheme.Motion.delete(reduceMotion: reduceMotion)) {
            entries.removeAll { $0.id == id }
            FoodLogStore.save(entries)
        }

        if let deletedEntry {
            deleteFoodFromHealthIfNeeded(deletedEntry)
        }
    }

    private func editEntry(id: UUID) {
        guard let entry = entries.first(where: { $0.id == id }) else { return }

        editingFoodEntry = entry
        selectedDate = entry.loggedAt

        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            selectedTab = .add
        }
    }

    private func addEntry(_ entry: FoodLogEntry) {
        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = entry
            } else {
                entries.append(entry)
            }

            FoodLogStore.save(entries)
            syncFoodToHealthIfNeeded(entry)
            selectedDate = entry.loggedAt
            editingFoodEntry = nil
            selectedTab = .dashboard
        }
    }

    private func addWeightEntry(_ entry: WeightLogEntry) {
        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            weightEntries.append(entry)
            WeightLogStore.save(weightEntries)
            syncWeightToHealthIfNeeded(entry)
            selectedDate = entry.loggedAt
            selectedTab = .dashboard
        }
    }

    private func saveWeightEntry(_ entry: WeightLogEntry) {
        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            if let index = weightEntries.firstIndex(where: { $0.id == entry.id }) {
                weightEntries[index] = entry
            } else {
                weightEntries.append(entry)
            }

            WeightLogStore.save(weightEntries)
            syncWeightToHealthIfNeeded(entry)
            selectedDate = entry.loggedAt
        }
    }

    private func deleteWeightEntry(id: UUID) {
        let deletedEntry = weightEntries.first { $0.id == id }

        withAnimation(AppTheme.Motion.delete(reduceMotion: reduceMotion)) {
            weightEntries.removeAll { $0.id == id }
            WeightLogStore.save(weightEntries)
        }

        if let deletedEntry {
            deleteWeightFromHealthIfNeeded(deletedEntry)
        }
    }

    private func syncFoodToHealthIfNeeded(_ entry: FoodLogEntry) {
        guard healthKitNutritionWrite else { return }

        Task {
            await HealthKitSyncService.saveFood(entry)
        }
    }

    private func syncWeightToHealthIfNeeded(_ entry: WeightLogEntry) {
        guard healthKitWeightWrite, entry.reference.source == .manual else { return }

        Task {
            await HealthKitSyncService.saveWeight(entry)
        }
    }

    private func deleteFoodFromHealthIfNeeded(_ entry: FoodLogEntry) {
        guard healthKitNutritionWrite else { return }

        Task {
            await HealthKitSyncService.deleteFood(entry)
        }
    }

    private func deleteWeightFromHealthIfNeeded(_ entry: WeightLogEntry) {
        guard healthKitWeightWrite, entry.reference.source == .manual else { return }

        Task {
            await HealthKitSyncService.deleteWeight(entry)
        }
    }

    private func importWeightsFromHealth() async throws -> HealthKitWeightImportResult {
        let endDate = Date.now
        let startDate = Calendar.current.date(
            byAdding: .year,
            value: -5,
            to: endDate
        ) ?? .distantPast

        let importedEntries = try await HealthKitSyncService.importWeights(
            startDate: startDate,
            endDate: endDate
        )

        var inserted = 0
        var updated = 0

        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            for importedEntry in importedEntries {
                if let index = weightEntries.firstIndex(where: { existingEntry in
                    existingEntry.reference.source == .appleHealth &&
                    existingEntry.reference.externalID == importedEntry.reference.externalID
                }) {
                    weightEntries[index] = importedEntry
                    updated += 1
                } else {
                    weightEntries.append(importedEntry)
                    inserted += 1
                }
            }

            if inserted > 0 || updated > 0 {
                WeightLogStore.save(weightEntries)
            }
        }

        return HealthKitWeightImportResult(
            scanned: importedEntries.count,
            inserted: inserted,
            updated: updated
        )
    }

    private var dateState: DashboardDateState {
        DashboardDateState.from(selectedDate)
    }

    private var tabContentPadding: CGFloat {
        AppTheme.Spacing.section
    }

    private var dashboard: DashboardSnapshot {
        DashboardSnapshot.from(
            entries: entriesForSelectedDate,
            targets: targets,
            analytics: DashboardAnalyticsViewState.from(
                foodEntries: entriesForTrend,
                targets: targets,
                weightEntries: weightEntriesForTrend,
                unitSystem: selectedUnitSystem,
                trendPeriod: trendPeriod,
                through: selectedDate
            )
        )
    }

    private var targets: DailyTargets {
        DailyTargets(
            calories: dailyCalories,
            protein: proteinTarget,
            carbs: carbsTarget,
            fat: fatTarget
        )
    }

    private var selectedUnitSystem: UnitSystem {
        UnitSystem(rawValue: unitSystem) ?? .imperial
    }

    private var entriesForSelectedDate: [FoodLogEntry] {
        entries
            .filter { Calendar.current.isDate($0.loggedAt, inSameDayAs: selectedDate) }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    private var entriesForTrend: [FoodLogEntry] {
        entries
            .filter { $0.loggedAt <= selectedDate || Calendar.current.isDate($0.loggedAt, inSameDayAs: selectedDate) }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    private var weightEntriesForTrend: [WeightLogEntry] {
        weightEntries
            .filter { $0.loggedAt <= selectedDate || Calendar.current.isDate($0.loggedAt, inSameDayAs: selectedDate) }
            .sorted { $0.loggedAt < $1.loggedAt }
    }
}

private enum AppTab: CaseIterable, Hashable, Identifiable {
    case dashboard
    case add
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .add:
            return "Add"
        case .settings:
            return "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard:
            return "square.grid.2x2"
        case .add:
            return "plus"
        case .settings:
            return "slider.horizontal.3"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
