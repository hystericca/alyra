import SwiftUI

struct DashboardView: View {
    let date: DashboardDateState
    let snapshot: DashboardSnapshot
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    DateRail(
                        state: date,
                        onPreviousDay: onPreviousDay,
                        onNextDay: onNextDay
                    )

                    CalorieSummaryCard(state: snapshot.calories)
                    MacroStrip(tiles: snapshot.macros)

                    ForEach(snapshot.sections) { section in
                        MealSectionView(section: section, onDelete: onDelete)
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Mela")
            .melaInlineNavigationTitle()
        }
    }
}

private struct DateRail: View {
    let state: DashboardDateState
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPreviousDay) {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous day")

            VStack(spacing: 2) {
                Text(state.weekdayText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
                Text(state.dateText)
                    .font(.headline)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            Button(action: onNextDay) {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next day")
        }
        .padding(8)
        .melaCard()
    }
}

private struct CalorieSummaryCard: View {
    let state: CalorieSummaryViewState

    var body: some View {
        HStack(spacing: 18) {
            CalorieRing(progress: state.progress)
                .frame(width: 112, height: 112)
                .overlay {
                    VStack(spacing: 2) {
                        Text(state.consumedCaloriesText)
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("kcal")
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedText)
                    }
                }

            VStack(alignment: .leading, spacing: 12) {
                Text("Today")
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(AppTheme.mutedText)

                Text(state.remainingCaloriesText)
                    .font(.title2.weight(.semibold))
                    .contentTransition(.numericText())

                ProgressView(value: min(state.progress, 1))
                    .tint(.primary)

                Text(state.targetCaloriesText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .melaCard()
        .animation(.smooth(duration: 0.24), value: state)
    }
}

private struct CalorieRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.08), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct MacroStrip: View {
    let tiles: MacroStripViewState

    var body: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                MacroTile(tile: tiles.protein)
                MacroTile(tile: tiles.carbs)
            }
            GridRow {
                MacroTile(tile: tiles.fat)
                MacroTile(tile: tiles.fiber)
            }
        }
        .animation(.smooth(duration: 0.24), value: tiles)
    }
}

private struct MacroTile: View {
    let tile: MacroTileViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: tile.symbolName)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(tile.valueText)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Text(tile.title)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedText)

            ProgressView(value: tile.progress)
                .tint(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .melaCard()
    }
}

private struct MealSectionView: View {
    let section: MealSectionViewState
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(section.title, systemImage: section.symbolName)
                    .font(.headline)
                Spacer()
                Text(section.totalCaloriesText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedText)
                    .monospacedDigit()
            }

            if section.rows.isEmpty {
                EmptyMealRow()
            } else {
                ForEach(section.rows) { row in
                    HStack(spacing: 12) {
                        DiaryFoodRowContent(row: row)

                        Spacer(minLength: 12)

                        Text(row.caloriesText)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()

                        Button(action: { onDelete(row.id) }) {
                            Image(systemName: "trash")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.mutedText)
                        .accessibilityLabel(row.deleteAccessibilityLabel)
                    }
                    .padding(14)
                    .melaCard()
                }
            }
        }
    }
}

private struct EmptyMealRow: View {
    var body: some View {
        HStack {
            Image(systemName: "plus")
                .font(.caption.weight(.semibold))
            Text("No entries")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(AppTheme.border, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
    }
}

private struct DiaryFoodRowContent: View {
    let row: DiaryEntryViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.foodName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(row.detailText)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedText)
                .lineLimit(1)
        }
    }
}
