import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    enum ViewType {
        case day, week, inbox
        case notesDay, notesWeek
    }
    
    @State private var contentOpacity: Double = 1.0
    @State private var contentScale: CGFloat = 1.0
    
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
                        Label("Inbox", systemImage: "tray")
                            .tag(ViewType.inbox)
                    }
                    
                    Section("Notes") {
                        Label("Day", systemImage: "note.text")
                            .tag(ViewType.notesDay)
                        Label("Week", systemImage: "calendar.badge.clock")
                            .tag(ViewType.notesWeek)
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
                Group {
                    switch viewModel.activeTab {
                    case .day:
                        DayView()
                    case .week:
                        WeekView()
                    case .inbox:
                        InboxView()
                    case .notesDay:
                        NotesDayView()
                    case .notesWeek:
                        NotesWeekView()
                    }
                }
                .opacity(contentOpacity)
                .scaleEffect(contentScale)
                .onChange(of: viewModel.activeTab) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        contentOpacity = 0
                        contentScale = 0.95
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            contentOpacity = 1.0
                            contentScale = 1.0
                        }
                    }
                }
            }
        }
    }
}
