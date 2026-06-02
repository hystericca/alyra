import SwiftUI

struct WeightHistoryView: View {
    let entries: [WeightLogEntry]
    let unitSystem: UnitSystem
    @Binding var trendPeriod: TrendPeriod
    let through: Date
    let onSave: (WeightLogEntry) -> Void
    let onDelete: (UUID) -> Void

    @State private var editingDraft: WeightLogDraft?

    private var state: WeightHistoryViewState {
        WeightHistoryViewState(
            entries: entries,
            unitSystem: unitSystem,
            trendPeriod: trendPeriod,
            through: through
        )
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    header

                    WeightHistoryGraphPanel(
                        title: "Trend",
                        subtitle: "Moving average",
                        graph: state.trendGraph
                    )

                    WeightHistoryGraphPanel(
                        title: "Logs",
                        subtitle: "Actual entries",
                        graph: state.logGraph
                    )

                    logHistory
                }
                .padding(AppTheme.Spacing.screen)
                .padding(.bottom, AppTheme.Spacing.section)
            }
        }
        .foregroundStyle(AppTheme.primaryText)
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(AppTheme.preferredColorScheme, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Weight History")
                    .font(AppTheme.Typography.header)
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Text(state.summaryText)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.mutedText)
                    .monospacedDigit()
            }

            Picker("Weight period", selection: $trendPeriod) {
                ForEach(TrendPeriod.allCases) { period in
                    Text(period.title)
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var logHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logs")
                .font(AppTheme.Typography.mealHeader)
                .foregroundStyle(AppTheme.primaryText)

            if state.rows.isEmpty {
                Text("No weight entries in this period")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
            } else {
                VStack(spacing: 0) {
                    ForEach(state.rows) { row in
                        if row.id != state.rows.first?.id {
                            Divider()
                                .overlay(AppTheme.separator)
                        }

                        WeightLogHistoryRow(
                            row: row,
                            onEdit: { editingDraft = WeightLogDraft(entry: row.entry, unitSystem: unitSystem) },
                            onDelete: { onDelete(row.id) }
                        )
                    }
                }
            }
        }
        .sheet(item: $editingDraft) { draft in
            WeightLogEditorView(
                draft: draft,
                unitSystem: unitSystem,
                onCancel: { editingDraft = nil },
                onSave: { updatedEntry in
                    onSave(updatedEntry)
                    editingDraft = nil
                }
            )
        }
    }
}

private struct WeightHistoryGraphPanel: View {
    let title: String
    let subtitle: String
    let graph: HealthGraphViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(AppTheme.Typography.sectionTitle)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text(graph.valueText)
                        .font(AppTheme.Typography.metric)
                        .foregroundStyle(AppTheme.primaryText)
                        .monospacedDigit()

                    Text(graph.detailText)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            HealthGraphCanvas(graph: graph)
                .frame(height: 142)
        }
        .alyraPanel(border: .strong)
    }
}

private struct WeightLogHistoryRow: View {
    let row: WeightHistoryRowViewState
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "scalemass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(row.dateText)
                    .font(AppTheme.Typography.bodyStrong)
                    .foregroundStyle(AppTheme.primaryText)

                if !row.note.isEmpty {
                    Text(row.note)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(row.weightText)
                .font(AppTheme.Typography.bodyStrong)
                .foregroundStyle(AppTheme.primaryText)
                .monospacedDigit()

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(WeightLogActionButtonStyle())
            .accessibilityLabel("Edit \(row.weightText)")

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(WeightLogActionButtonStyle())
            .accessibilityLabel("Delete \(row.weightText)")
        }
        .padding(.vertical, 12)
    }
}

private struct WeightLogActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(AppTheme.primaryText)
            .frame(width: AppTheme.Control.minimumHitSize, height: AppTheme.Control.minimumHitSize)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.62 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .animation(AppTheme.Motion.press(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

private struct WeightLogEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: WeightLogEditorField?

    @State private var draft: WeightLogDraft
    let unitSystem: UnitSystem
    let onCancel: () -> Void
    let onSave: (WeightLogEntry) -> Void

    init(
        draft: WeightLogDraft,
        unitSystem: UnitSystem,
        onCancel: @escaping () -> Void,
        onSave: @escaping (WeightLogEntry) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.unitSystem = unitSystem
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Logged at")
                                .font(AppTheme.Typography.eyebrow)
                                .foregroundStyle(AppTheme.mutedText)
                                .textCase(.uppercase)
                                .tracking(0.8)

                            DatePicker(selection: $draft.loggedAt, displayedComponents: .date) {
                                Label("Date", systemImage: "calendar")
                            }

                            DatePicker(selection: $draft.loggedAt, displayedComponents: .hourAndMinute) {
                                Label("Time", systemImage: "clock")
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            WeightEditorTextField(
                                title: "Weight",
                                symbolName: "scalemass",
                                text: $draft.weightValue,
                                suffix: unitSystem.weightUnitName,
                                focusedField: $focusedField,
                                field: .weight
                            )

                            WeightEditorTextField(
                                title: "Note",
                                symbolName: "note.text",
                                text: $draft.note,
                                suffix: nil,
                                focusedField: $focusedField,
                                field: .note
                            )
                        }
                    }
                    .padding(AppTheme.Spacing.screen)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .foregroundStyle(AppTheme.primaryText)
            .navigationTitle("Edit Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let entry = draft.entry(unitSystem: unitSystem) else { return }
                        onSave(entry)
                        dismiss()
                    }
                    .font(AppTheme.Typography.bodyStrong)
                    .disabled(!draft.isValid)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        focusedField = nil
                    }
                    .font(AppTheme.Typography.bodyStrong)
                }
            }
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(AppTheme.preferredColorScheme, for: .navigationBar)
        }
        .preferredColorScheme(AppTheme.preferredColorScheme)
    }
}

private struct WeightEditorTextField: View {
    let title: String
    let symbolName: String
    @Binding var text: String
    let suffix: String?
    let focusedField: FocusState<WeightLogEditorField?>.Binding
    let field: WeightLogEditorField

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbolName)
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.primaryText)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 8) {
                TextField("Optional", text: $text)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.primaryText)
                    .textFieldStyle(.plain)
                    .keyboardType(field == .weight ? .decimalPad : .default)
                    .focused(focusedField, equals: field)
                    .textInputAutocapitalization(field == .note ? .sentences : .never)
                    .autocorrectionDisabled(field == .weight)

                if let suffix {
                    Text(suffix)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(AppTheme.surfaceRaised)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
                .strokeBorder(AppTheme.strongBorder, lineWidth: AppTheme.Stroke.hairline)
            }
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var doubleValue: Double? {
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else {
            return nil
        }

        return value
    }
}

private enum WeightLogEditorField: Hashable {
    case weight
    case note
}

private struct WeightLogDraft: Identifiable, Equatable {
    var id: UUID
    var loggedAt: Date
    var weightValue: String
    var note: String
    var reference: WeightLogReference

    var isValid: Bool {
        weightValue.doubleValue != nil
    }

    init(entry: WeightLogEntry, unitSystem: UnitSystem) {
        id = entry.id
        loggedAt = entry.loggedAt
        weightValue = DashboardNumberText.oneDecimal(entry.displayWeight(for: unitSystem))
        note = entry.note
        reference = entry.reference
    }

    func entry(unitSystem: UnitSystem) -> WeightLogEntry? {
        guard let displayWeight = weightValue.doubleValue else { return nil }

        return WeightLogEntry(
            id: id,
            loggedAt: loggedAt,
            displayWeight: displayWeight,
            unitSystem: unitSystem,
            note: note.trimmed,
            reference: reference
        )
    }
}

private struct WeightHistoryViewState: Equatable {
    var trendGraph: HealthGraphViewState
    var logGraph: HealthGraphViewState
    var rows: [WeightHistoryRowViewState]
    var summaryText: String

    init(
        entries: [WeightLogEntry],
        unitSystem: UnitSystem,
        trendPeriod: TrendPeriod,
        through date: Date,
        calendar: Calendar = .current
    ) {
        let startDate = calendar.date(
            byAdding: .day,
            value: -trendPeriod.rawValue + 1,
            to: calendar.startOfDay(for: date)
        ) ?? date
        let filteredEntries = entries
            .filter { entry in
                entry.loggedAt >= startDate
                    && (entry.loggedAt <= date || calendar.isDate(entry.loggedAt, inSameDayAs: date))
            }
            .sorted { $0.loggedAt < $1.loggedAt }
        let weights = filteredEntries.map { $0.displayWeight(for: unitSystem) }
        let latestWeight = weights.last
        let firstWeight = weights.first ?? latestWeight ?? 0
        let delta = (latestWeight ?? firstWeight) - firstWeight
        let latestText = latestWeight.map(DashboardNumberText.oneDecimal) ?? "--"
        let detailText = weights.isEmpty
            ? "No entries yet"
            : "\(DashboardNumberText.signedOneDecimal(delta)) \(unitSystem.weightUnitName) / \(weights.count) logs"

        trendGraph = HealthGraphViewState(
            id: "weight-trend-detail",
            title: "Trend",
            symbolName: "scalemass",
            valueText: latestText,
            unitText: unitSystem.weightUnitName,
            detailText: detailText,
            style: .lineArea,
            gradientKind: .weight,
            negativeGradientKind: nil,
            values: DashboardAnalyticsViewState.movingAverage(values: weights)
        )

        logGraph = HealthGraphViewState(
            id: "weight-log-detail",
            title: "Logs",
            symbolName: "point.3.connected.trianglepath.dotted",
            valueText: latestText,
            unitText: unitSystem.weightUnitName,
            detailText: "Raw entries",
            style: .lineArea,
            gradientKind: .weight,
            negativeGradientKind: nil,
            values: weights
        )

        rows = filteredEntries.reversed().map { entry in
            WeightHistoryRowViewState(entry: entry, unitSystem: unitSystem)
        }
        summaryText = trendPeriod.title
    }
}

private struct WeightHistoryRowViewState: Identifiable, Equatable {
    var id: UUID
    var entry: WeightLogEntry
    var dateText: String
    var weightText: String
    var note: String

    init(entry: WeightLogEntry, unitSystem: UnitSystem) {
        id = entry.id
        self.entry = entry
        dateText = entry.loggedAt.formatted(
            Date.FormatStyle.dateTime.month(.abbreviated).day().hour().minute()
        )
        weightText = "\(DashboardNumberText.oneDecimal(entry.displayWeight(for: unitSystem))) \(unitSystem.weightUnitName)"
        note = entry.note
    }
}
