import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    enum ViewType {
        case day, week, month, inbox
        case notesDay, notesWeek, notesMonth
    }
    
    var body: some View {
        let appBackground = Color(nsColor: .windowBackgroundColor)
        let sidebarBackground = Color(nsColor: .controlBackgroundColor)
        
        return ZStack {
            appBackground.ignoresSafeArea()
            
            NavigationSplitView {
                List(selection: $viewModel.activeTab) {
                    Section("Tasks") {
                        Label("Day", systemImage: "calendar.day")
                            .tag(ViewType.day)
                        Label("Week", systemImage: "calendar.badge.clock")
                            .tag(ViewType.week)
                        Label("Month", systemImage: "calendar")
                            .tag(ViewType.month)
                        Label("Inbox", systemImage: "tray")
                            .tag(ViewType.inbox)
                    }
                    
                    Section("Notes") {
                        Label("Day", systemImage: "note.text")
                            .tag(ViewType.notesDay)
                        Label("Week", systemImage: "calendar.badge.clock")
                            .tag(ViewType.notesWeek)
                        Label("Month", systemImage: "calendar")
                            .tag(ViewType.notesMonth)
                    }

                    Section("Settings") {
                        Toggle(isOn: $isDarkMode) {
                            Label("Dark Mode", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                        }
                        .toggleStyle(.switch)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(sidebarBackground)
                .navigationTitle("Walpts")
            } detail: {
                switch viewModel.activeTab {
                case .day:
                    DayView()
                case .week:
                    WeekView()
                case .month:
                    MonthView()
                case .inbox:
                    InboxView()
                case .notesDay:
                    NotesDayView()
                case .notesWeek:
                    NotesWeekView()
                case .notesMonth:
                    NotesMonthView()
                }
            }
        }
    }
}
