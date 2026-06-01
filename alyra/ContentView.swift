//
//  ContentView.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedTab = AppTab.dashboard
    @State private var selectedDate = Date.now
    @State private var dateNavigationDirection = DateNavigationDirection.forward
    @State private var entries = FoodLogStore.load()
    @State private var weightEntries = WeightLogStore.load()
    @State private var isKeyboardVisible = false
    @AppStorage(AppSettingsKeys.dailyCalories) private var dailyCalories = 2_200.0
    @AppStorage(AppSettingsKeys.proteinTarget) private var proteinTarget = 140.0
    @AppStorage(AppSettingsKeys.carbsTarget) private var carbsTarget = 250.0
    @AppStorage(AppSettingsKeys.fatTarget) private var fatTarget = 70.0
    @AppStorage(AppSettingsKeys.unitSystem) private var unitSystem = UnitSystem.imperial.rawValue

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom
            let appTabPadding = AppTheme.Navigation.contentInset(bottomInset: bottomInset)

            ZStack(alignment: .bottom) {
                selectedContent(appTabPadding: appTabPadding)

                AppTabBar(
                    selectedTab: $selectedTab,
                    bottomInset: bottomInset
                )
                .opacity(isKeyboardVisible ? 0 : 1)
                .allowsHitTesting(!isKeyboardVisible)
                .accessibilityHidden(isKeyboardVisible)
                .zIndex(1)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(AppTheme.background)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            setKeyboardVisible(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            setKeyboardVisible(false)
        }
    }

    @ViewBuilder
    private func selectedContent(appTabPadding: CGFloat) -> some View {
        switch selectedTab {
        case .dashboard:
            DashboardView(
                date: dateState,
                dateNavigationDirection: dateNavigationDirection,
                snapshot: dashboard,
                appTabPadding: appTabPadding,
                onPreviousDay: { moveDate(by: -1) },
                onNextDay: { moveDate(by: 1) },
                onDelete: deleteEntry
            )

        case .add:
            LogEntryView(
                date: selectedDate,
                appTabPadding: appTabPadding,
                unitSystem: selectedUnitSystem,
                onSaveFood: addEntry,
                onSaveWeight: addWeightEntry
            )

        case .settings:
            SettingsView(appTabPadding: appTabPadding)
        }
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
        withAnimation(AppTheme.Motion.delete(reduceMotion: reduceMotion)) {
            entries.removeAll { $0.id == id }
            FoodLogStore.save(entries)
        }
    }

    private func addEntry(_ entry: FoodLogEntry) {
        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            entries.append(entry)
            FoodLogStore.save(entries)
            selectedTab = .dashboard
        }
    }

    private func addWeightEntry(_ entry: WeightLogEntry) {
        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            weightEntries.append(entry)
            WeightLogStore.save(weightEntries)
            selectedTab = .dashboard
        }
    }

    private func setKeyboardVisible(_ isVisible: Bool) {
        guard isKeyboardVisible != isVisible else { return }

        isKeyboardVisible = isVisible
    }

    private var dateState: DashboardDateState {
        DashboardDateState.from(selectedDate)
    }

    private var dashboard: DashboardSnapshot {
        DashboardSnapshot.from(
            entries: entriesForSelectedDate,
            targets: targets,
            analytics: DashboardAnalyticsViewState.from(
                weightEntries: weightEntriesForTrend,
                unitSystem: selectedUnitSystem
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

private struct AppTabBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selectedTab: AppTab
    let bottomInset: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                AppTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    select(tab)
                }
            }
        }
        .padding(AppTheme.Navigation.railInnerPadding)
        .background(tabBarBackground)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .padding(.horizontal, AppTheme.Navigation.railHorizontalPadding)
        .padding(.bottom, AppTheme.Navigation.railBottomPadding + bottomInset)
        .frame(maxWidth: .infinity)
        .frame(
            height: AppTheme.Navigation.railHeight(bottomInset: bottomInset),
            alignment: .bottom
        )
        .accessibilityElement(children: .contain)
    }

    private func select(_ tab: AppTab) {
        guard selectedTab != tab else { return }

        withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
            selectedTab = tab
        }
    }

    private var tabBarBackground: some View {
        RoundedRectangle(
            cornerRadius: AppTheme.Navigation.railCornerRadius,
            style: .continuous
        )
        .fill(AppTheme.surfaceRaised.opacity(0.96))
        .overlay {
            RoundedRectangle(
                cornerRadius: AppTheme.Navigation.railCornerRadius,
                style: .continuous
            )
            .strokeBorder(AppTheme.border, lineWidth: AppTheme.Stroke.hairline)
        }
    }
}

private struct AppTabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: tab == .add ? 15 : 14, weight: .medium))
                    .frame(width: 18, height: 17)

                Text(tab.title)
                    .font(AppTheme.Typography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? AppTheme.primaryText : AppTheme.mutedText)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Navigation.itemHeight)
            .background {
                RoundedRectangle(
                    cornerRadius: AppTheme.Navigation.itemCornerRadius,
                    style: .continuous
                )
                .fill(isSelected ? AppTheme.controlFill : .clear)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppTheme.Navigation.itemCornerRadius,
                        style: .continuous
                    )
                    .strokeBorder(
                        isSelected ? AppTheme.border : .clear,
                        lineWidth: AppTheme.Stroke.hairline
                    )
                }
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.Navigation.itemCornerRadius,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
