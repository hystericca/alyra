import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedTab = AppTab.dashboard
    @State private var selectedDate = Date.now
    @State private var dateNavigationDirection = DateNavigationDirection.forward
    @State private var entries = DashboardDemoData.entries

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom

            ZStack(alignment: .bottom) {
                DashboardView(
                    date: dateState,
                    dateNavigationDirection: dateNavigationDirection,
                    snapshot: dashboard,
                    bottomContentInset: AppTheme.Navigation.contentInset(bottomInset: bottomInset),
                    onPreviousDay: { moveDate(by: -1) },
                    onNextDay: { moveDate(by: 1) },
                    onDelete: deleteEntry
                )

                AppBottomNavigation(
                    selectedTab: $selectedTab,
                    bottomInset: bottomInset
                )
                .zIndex(1)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(AppTheme.background)
    }

    private func moveDate(by days: Int) {
        withAnimation(AppTheme.Motion.dateChange(reduceMotion: reduceMotion)) {
            dateNavigationDirection = days < 0 ? .backward : .forward
            let nextDate =
                Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
            selectedDate = nextDate
        }
    }

    private func deleteEntry(id: UUID) {
        withAnimation(AppTheme.Motion.delete(reduceMotion: reduceMotion)) {
            entries.removeAll { $0.id == id }
        }
    }

    private var dateState: DashboardDateState {
        DashboardDateState.make(for: selectedDate)
    }

    private var dashboard: DashboardSnapshot {
        DashboardSnapshot.make(
            entries: entries,
            analytics: DashboardDemoData.analytics
        )
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

private struct AppBottomNavigation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selectedTab: AppTab
    let bottomInset: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                AppBottomNavigationButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    guard selectedTab != tab else { return }

                    withAnimation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(AppTheme.Navigation.railInnerPadding)
        .frame(height: AppTheme.Navigation.itemHeight + AppTheme.Navigation.railInnerPadding * 2)
        .background {
            RoundedRectangle(
                cornerRadius: AppTheme.Navigation.railCornerRadius,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.surface.opacity(0.98),
                        AppTheme.surfaceRaised.opacity(0.92),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppTheme.Navigation.railCornerRadius,
                    style: .continuous
                )
                .strokeBorder(AppTheme.border, lineWidth: AppTheme.Stroke.hairline)
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        .padding(.horizontal, AppTheme.Navigation.railHorizontalPadding)
        .padding(.bottom, AppTheme.Navigation.railBottomPadding + bottomInset)
        .frame(maxWidth: .infinity)
        .frame(height: AppTheme.Navigation.railHeight(bottomInset: bottomInset), alignment: .bottom)
        .accessibilityElement(children: .contain)
    }
}

private struct AppBottomNavigationButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: tab == .add ? 14 : 13, weight: .medium))
                    .frame(width: 16, height: 16)

                Text(tab.title)
                    .font(AppTheme.Typography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? AppTheme.primaryText : AppTheme.mutedText)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Navigation.itemHeight)
            .background {
                if isSelected {
                    RoundedRectangle(
                        cornerRadius: AppTheme.Navigation.itemCornerRadius,
                        style: .continuous
                    )
                    .fill(AppTheme.surfaceRaised)
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: AppTheme.Navigation.itemCornerRadius,
                            style: .continuous
                        )
                        .strokeBorder(AppTheme.border, lineWidth: AppTheme.Stroke.hairline)
                    }
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
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
