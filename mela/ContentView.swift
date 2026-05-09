import SwiftUI

struct ContentView: View {
    @State private var selectedDate: Date
    @State private var dateState: DashboardDateState
    @State private var entries: [DiaryEntryRow]
    @State private var dashboard: DashboardSnapshot

    init(entries: [DiaryEntryRow] = DashboardDemoData.entries) {
        let selectedDate = Date.now
        _selectedDate = State(initialValue: selectedDate)
        _dateState = State(initialValue: DashboardDateState.make(for: selectedDate))
        _entries = State(initialValue: entries)
        _dashboard = State(initialValue: DashboardSnapshot.make(entries: entries))
    }

    var body: some View {
        DashboardView(
            date: dateState,
            snapshot: dashboard,
            onPreviousDay: { moveDate(by: -1) },
            onNextDay: { moveDate(by: 1) },
            onDelete: deleteEntry
        )
    }

    private func moveDate(by days: Int) {
        let nextDate =
            Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        selectedDate = nextDate
        dateState = DashboardDateState.make(for: nextDate)
    }

    private func deleteEntry(id: UUID) {
        withAnimation(.smooth(duration: 0.22)) {
            var nextEntries = entries
            nextEntries.removeAll { $0.id == id }
            replaceEntries(nextEntries)
        }
    }

    private func replaceEntries(_ nextEntries: [DiaryEntryRow]) {
        entries = nextEntries
        dashboard = DashboardSnapshot.make(entries: nextEntries)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
