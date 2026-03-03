import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    enum ViewType {
        case day, week, inbox
        case completed
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
                        Label("Day", systemImage: "sun.max.fill")
                            .tag(ViewType.day)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Label("Week", systemImage: "calendar.badge.clock")
                            .tag(ViewType.week)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Label("Inbox", systemImage: "tray")
                            .tag(ViewType.inbox)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Label("Completed", systemImage: "checkmark.circle")
                            .tag(ViewType.completed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Section("Notes") {
                        Label("Day", systemImage: "note.text")
                            .tag(ViewType.notesDay)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Label("Week", systemImage: "calendar.badge.clock")
                            .tag(ViewType.notesWeek)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    case .completed:
                        CompletedView()
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
