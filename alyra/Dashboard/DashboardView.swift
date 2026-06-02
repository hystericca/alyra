//
//  DashboardView.swift
//  alyra
//
//  Created by Viktor Luna on 5/30/26.
//

import SwiftUI

enum DateNavigationDirection: Equatable {
    case backward
    case forward

    var insertionEdge: Edge {
        self == .forward ? .trailing : .leading
    }

    var removalEdge: Edge {
        self == .forward ? .leading : .trailing
    }
}

struct DashboardView: View {
    let date: DashboardDateState
    let dateNavigationDirection: DateNavigationDirection
    let snapshot: DashboardSnapshot
    let appTabPadding: CGFloat
    @Binding var trendPeriod: TrendPeriod
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void
    let onWeightTrendSelected: () -> Void

    var body: some View {
        ZStack {
            DashboardBackdrop()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.section) {
                    DateRail(
                        state: date,
                        direction: dateNavigationDirection,
                        onPreviousDay: onPreviousDay,
                        onNextDay: onNextDay
                    )

                    EnergyMeter(state: snapshot.calories)
                    MacroStrip(macros: snapshot.macros)
                    AnalyticsSection(
                        analytics: snapshot.analytics,
                        trendPeriod: $trendPeriod,
                        onWeightTrendSelected: onWeightTrendSelected
                    )

                    ForEach(snapshot.sections) { section in
                        MealSectionView(
                            section: section,
                            onEdit: onEdit,
                            onDelete: onDelete
                        )
                    }
                }
                .padding(AppTheme.Spacing.screen)
                .padding(.top, 2)
                .padding(.bottom, appTabPadding)
            }
        }
        .foregroundStyle(AppTheme.primaryText)
        .tint(AppTheme.accent)
    }
}

private struct DashboardBackdrop: View {
    var body: some View {
        ZStack {
            AppTheme.background

            LinearGradient(
                colors: [
                    AppTheme.surface.opacity(0.54),
                    AppTheme.background,
                    AppTheme.background,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Canvas { context, size in
                let spacing: CGFloat = 56
                var y: CGFloat = spacing

                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))

                    context.stroke(
                        path,
                        with: .color(AppTheme.separator),
                        lineWidth: AppTheme.Stroke.hairline
                    )

                    y += spacing
                }
            }
            .opacity(0.16)
        }
    }
}

private struct DateRail: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: DashboardDateState
    let direction: DateNavigationDirection
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.stack) {
                Button(action: onPreviousDay) {
                    Image(systemName: "chevron.left")
                }
                .alyraIconButtonStyle()
                .accessibilityLabel("Previous day")

                VStack(spacing: 1) {
                    Text(state.weekdayText)
                        .font(AppTheme.Typography.header)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(state.dateText)
                        .font(AppTheme.Typography.body)
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.88)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .id(state.dateText)
                .transition(
                    AppTheme.Motion.dateTransition(
                        insertionEdge: direction.insertionEdge,
                        removalEdge: direction.removalEdge,
                        reduceMotion: reduceMotion
                    )
                )

                Button(action: onNextDay) {
                    Image(systemName: "chevron.right")
                }
                .alyraIconButtonStyle()
                .accessibilityLabel("Next day")
            }

            AlyraSeparator()
        }
        .frame(minHeight: 60)
    }
}

private struct EnergyMeter: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var gaugeSize: CGFloat = 254
    @ScaledMetric(relativeTo: .largeTitle) private var gaugeHeight: CGFloat = 258
    @ScaledMetric(relativeTo: .largeTitle) private var valueOffsetY: CGFloat = 14

    let state: CalorieSummaryViewState

    var body: some View {
        ZStack {
            EnergyArcGauge(progress: state.progress)
                .frame(width: gaugeSize, height: gaugeSize)

            VStack(spacing: 2) {
                Text(state.consumedCaloriesText)
                    .font(AppTheme.Typography.gaugeNumber)
                    .foregroundStyle(AppTheme.primaryText)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Text("kcal")
                    .font(AppTheme.Typography.gaugeUnit)
                    .foregroundStyle(AppTheme.mutedText)
            }
            .offset(y: valueOffsetY)
        }
        .frame(maxWidth: .infinity)
        .frame(height: gaugeHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Energy")
        .accessibilityValue(
            "\(state.consumedCaloriesText) calories of \(state.targetCaloriesText), \(state.remainingCaloriesText)"
        )
        .animation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion), value: state)
    }
}

private struct EnergyArcGauge: View {
    @ScaledMetric(relativeTo: .largeTitle) private var lineWidth: CGFloat = 12

    private static let startAngle = Angle.degrees(150)
    private static let sweepDegrees = 240.0

    let progress: Double

    var body: some View {
        let clampedProgress = min(max(progress, 0), 1)
        let endAngle = Angle.degrees(Self.startAngle.degrees + Self.sweepDegrees)

        let style = StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round
        )

        ZStack {
            EnergyArcShape(
                progress: 1,
                startDegrees: Self.startAngle.degrees,
                sweepDegrees: Self.sweepDegrees,
                lineWidth: lineWidth
            )
            .stroke(AppTheme.tickTrack, style: style)

            EnergyArcShape(
                progress: clampedProgress,
                startDegrees: Self.startAngle.degrees,
                sweepDegrees: Self.sweepDegrees,
                lineWidth: lineWidth
            )
            .stroke(
                AppTheme.dataAngularGradient(
                    .energy,
                    startAngle: Self.startAngle,
                    endAngle: endAngle
                ),
                style: style
            )
        }
        .allowsHitTesting(false)
    }
}

private struct EnergyArcShape: Shape {
    var progress: Double
    let startDegrees: Double
    let sweepDegrees: Double
    let lineWidth: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        let radius = max(min(rect.width, rect.height) / 2 - lineWidth / 2, 0)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = Angle.degrees(startDegrees)
        let endAngle = Angle.degrees(startDegrees + sweepDegrees * clampedProgress)

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

private struct MacroStrip: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let macros: MacroStripViewState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(macros.tiles) { tile in
                MacroTile(tile: tile)
            }
        }
        .padding(.vertical, 2)
        .animation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion), value: macros)
    }
}

private struct MacroTile: View {
    let tile: MacroTileViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: tile.symbolName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.dataAccent(tile.gradientKind))
                        .frame(width: 14, alignment: .leading)

                    Text(tile.title)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 4)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(tile.valueText)
                    .foregroundStyle(AppTheme.primaryText)

                Text("/")
                    .foregroundStyle(AppTheme.primaryText)

                Text(tile.targetText)
                    .foregroundStyle(AppTheme.mutedText)
            }
            .font(AppTheme.Typography.metric)
            .monospacedDigit()
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.58)

            MacroGradientBar(
                progress: tile.progress,
                gradientKind: tile.gradientKind
            )
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tile.title), \(tile.valueText) of \(tile.targetText)")
    }
}

private struct MacroGradientBar: View {
    let progress: Double
    let gradientKind: DataGradientKind

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)
            let fillWidth = max(proxy.size.width * clampedProgress, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.tickTrack)

                Capsule()
                    .fill(AppTheme.dataProgressGradient(gradientKind))
                    .frame(width: fillWidth)
            }
        }
        .frame(height: 4.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent")
    }
}

private struct AnalyticsSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let analytics: DashboardAnalyticsViewState
    @Binding var trendPeriod: TrendPeriod
    let onWeightTrendSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trends")
                    .font(AppTheme.Typography.mealHeader)
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Picker("Trend period", selection: $trendPeriod) {
                    ForEach(TrendPeriod.allCases) { period in
                        Text(period.title)
                            .tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 154)
            }

            Button(action: onWeightTrendSelected) {
                HealthGraphPanel(graph: analytics.weightTrend, density: .wide)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open weight history")
            .accessibilityHint("Shows weight logs and trend charts")

            HStack(alignment: .top, spacing: 10) {
                HealthGraphPanel(graph: analytics.expenditure, density: .compact)
                HealthGraphPanel(graph: analytics.energyBalance, density: .compact)
            }
        }
        .animation(AppTheme.Motion.contentChange(reduceMotion: reduceMotion), value: analytics)
    }
}

private enum HealthGraphPanelDensity {
    case wide
    case compact

    var spacing: CGFloat {
        switch self {
        case .wide: 12
        case .compact: 10
        }
    }

    var padding: CGFloat {
        switch self {
        case .wide: 13
        case .compact: 11
        }
    }

    var chartHeight: CGFloat {
        switch self {
        case .wide: 86
        case .compact: 62
        }
    }

    var valueFont: Font {
        switch self {
        case .wide: AppTheme.Typography.header
        case .compact: AppTheme.Typography.metric
        }
    }

    var detailMaxWidth: CGFloat {
        switch self {
        case .wide: 118
        case .compact: .infinity
        }
    }
}

private struct HealthGraphPanel: View {
    let graph: HealthGraphViewState
    let density: HealthGraphPanelDensity

    var body: some View {
        VStack(alignment: .leading, spacing: density.spacing) {
            header

            HealthGraphCanvas(graph: graph)
                .frame(height: density.chartHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(density.padding)
        .background(AppTheme.surfaceRaised)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppTheme.Radius.card,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppTheme.Radius.card,
                style: .continuous
            )
            .strokeBorder(AppTheme.border, lineWidth: AppTheme.Stroke.hairline)
        }
    }

    @ViewBuilder
    private var header: some View {
        switch density {
        case .wide:
            HStack(alignment: .top, spacing: 14) {
                metricBlock

                Spacer(minLength: 12)

                detailText
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: density.detailMaxWidth, alignment: .trailing)
            }

        case .compact:
            VStack(alignment: .leading, spacing: 7) {
                metricBlock

                detailText
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var metricBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: graph.symbolName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.dataAccent(graph.gradientKind))
                    .frame(width: 16)

                Text(graph.title)
                    .font(AppTheme.Typography.eyebrow)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(graph.valueText)
                    .font(density.valueFont)
                    .foregroundStyle(AppTheme.primaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(graph.unitText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
            }
        }
    }

    private var detailText: some View {
        Text(graph.detailText)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .lineLimit(2)
    }
}

struct HealthGraphCanvas: View {
    let graph: HealthGraphViewState

    var body: some View {
        Canvas { context, size in
            let plotRect = CGRect(
                x: 1,
                y: 4,
                width: max(size.width - 2, 1),
                height: max(size.height - 8, 1)
            )

            drawGrid(in: plotRect, context: &context)

            switch graph.style {
            case .lineArea:
                drawLineArea(in: plotRect, context: &context)

            case .bars:
                drawBars(in: plotRect, context: &context)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(graph.title)
        .accessibilityValue("\(graph.valueText) \(graph.unitText), \(graph.detailText)")
    }

    private func drawGrid(in rect: CGRect, context: inout GraphicsContext) {
        for fraction in [0.25, 0.5, 0.75] {
            let y = rect.minY + rect.height * fraction

            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))

            context.stroke(
                path,
                with: .color(AppTheme.separator),
                lineWidth: 1
            )
        }
    }

    private func drawLineArea(in rect: CGRect, context: inout GraphicsContext) {
        let points = graph.samples.map { point(for: $0, in: rect) }
        guard let first = points.first else { return }

        var linePath = Path()
        linePath.move(to: first)

        for point in points.dropFirst() {
            linePath.addLine(to: point)
        }

        var areaPath = linePath
        areaPath.addLine(to: CGPoint(x: points.last?.x ?? rect.maxX, y: rect.maxY))
        areaPath.addLine(to: CGPoint(x: first.x, y: rect.maxY))
        areaPath.closeSubpath()

        context.fill(
            areaPath,
            with: .linearGradient(
                Gradient(colors: AppTheme.dataAreaGradientColors(graph.gradientKind)),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)
            )
        )

        context.stroke(
            linePath,
            with: .linearGradient(
                Gradient(colors: AppTheme.dataGradientColors(graph.gradientKind)),
                startPoint: CGPoint(x: rect.minX, y: rect.midY),
                endPoint: CGPoint(x: rect.maxX, y: rect.midY)
            ),
            style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawBars(in rect: CGRect, context: inout GraphicsContext) {
        guard !graph.samples.isEmpty else { return }

        let sampleCount = CGFloat(graph.samples.count)
        let gap: CGFloat = 6
        let barWidth = max((rect.width - gap * (sampleCount - 1)) / sampleCount, 2)
        let baselineY = yPosition(for: graph.baselineNormalized, in: rect)

        for sample in graph.samples {
            let x = rect.minX + CGFloat(sample.index) * (barWidth + gap)
            let valueY = yPosition(for: sample.normalizedValue, in: rect)
            let top = min(valueY, baselineY)
            let height = max(abs(valueY - baselineY), 2)

            let barRect = CGRect(
                x: x,
                y: top,
                width: barWidth,
                height: height
            )

            let gradientKind =
                sample.value >= graph.baseline
                ? graph.gradientKind
                : graph.negativeGradientKind ?? graph.gradientKind

            context.fill(
                Path(roundedRect: barRect, cornerRadius: 1.5),
                with: .linearGradient(
                    Gradient(colors: AppTheme.dataGradientColors(gradientKind)),
                    startPoint: CGPoint(x: barRect.midX, y: barRect.minY),
                    endPoint: CGPoint(x: barRect.midX, y: barRect.maxY)
                )
            )
        }

        if graph.negativeGradientKind != nil {
            var baseline = Path()
            baseline.move(to: CGPoint(x: rect.minX, y: baselineY))
            baseline.addLine(to: CGPoint(x: rect.maxX, y: baselineY))

            context.stroke(
                baseline,
                with: .color(AppTheme.strongBorder),
                lineWidth: AppTheme.Stroke.hairline
            )
        }
    }

    private func point(
        for sample: HealthGraphSampleViewState,
        in rect: CGRect
    ) -> CGPoint {
        let lastIndex = max(graph.samples.count - 1, 1)
        let x = rect.minX + rect.width * CGFloat(sample.index) / CGFloat(lastIndex)

        return CGPoint(
            x: x,
            y: yPosition(for: sample.normalizedValue, in: rect)
        )
    }

    private func yPosition(
        for normalizedValue: Double,
        in rect: CGRect
    ) -> CGFloat {
        rect.maxY - rect.height * CGFloat(normalizedValue)
    }
}

private struct MealSectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let section: MealSectionViewState
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
                    .frame(width: 31, alignment: .leading)

                Text(section.title)
                    .font(AppTheme.Typography.mealHeader)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer()

                Text(section.totalCaloriesText)
                    .font(AppTheme.Typography.mealHeader)
                    .foregroundStyle(AppTheme.mutedText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.top, 6)
            .padding(.bottom, 16)

            AlyraSeparator()

            if section.entries.isEmpty {
                EmptyMealRow()
            } else {
                ForEach(section.entries) { entry in
                    if entry.id != section.entries.first?.id {
                        AlyraSeparator()
                            .padding(.leading, 14)
                    }

                    LogFoodRow(
                        entry: entry,
                        onEdit: onEdit,
                        onDelete: onDelete
                    )
                        .transition(AppTheme.Motion.rowTransition(reduceMotion: reduceMotion))
                }
            }
        }
    }
}

private struct EmptyMealRow: View {
    var body: some View {
        HStack {
            Text("No entries")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.mutedText)

            Spacer()
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }
}

private struct LogFoodRow: View {
    let entry: LogEntryViewState
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        HStack(spacing: 12) {
            FoodIcon(kind: entry.iconKind)

            LogFoodRowContent(entry: entry)

            Spacer(minLength: 12)

            Text(entry.caloriesText)
                .font(AppTheme.Typography.bodyStrong)
                .foregroundStyle(AppTheme.primaryText)
                .monospacedDigit()

            Button(action: { onEdit(entry.id) }) {
                Image(systemName: "pencil")
            }
            .buttonStyle(LogRowActionButtonStyle())
            .accessibilityLabel(entry.editAccessibilityLabel)

            Button(action: { onDelete(entry.id) }) {
                Image(systemName: "trash")
            }
            .buttonStyle(LogRowActionButtonStyle())
            .accessibilityLabel(entry.deleteAccessibilityLabel)
        }
        .padding(.vertical, 12)
    }
}

private struct LogRowActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(AppTheme.primaryText)
            .frame(width: AppTheme.Control.minimumHitSize, height: AppTheme.Control.minimumHitSize)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.62 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .animation(AppTheme.Motion.press(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

private struct LogFoodRowContent: View {
    let entry: LogEntryViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.foodName)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)

            Text(entry.detailText)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.mutedText)
                .lineLimit(1)
        }
    }
}

private struct FoodIcon: View {
    let kind: FoodIconKind

    var body: some View {
        Image(systemName: kind.symbolName)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AppTheme.dataAccent(kind.gradientKind))
            .frame(width: 22)
    }
}

private struct AlyraSeparator: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, AppTheme.separator, AppTheme.separator, .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: AppTheme.Stroke.hairline)
    }
}
