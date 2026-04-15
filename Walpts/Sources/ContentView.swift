import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var calendarManager: CalendarManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("calendarNotificationsEnabled") private var calendarNotificationsEnabled = false
    
    enum ViewType: Hashable {
        case day, week, inbox
        case completed
        case allTasks
        case project(UUID)
        case notesDay, notesWeek
        case settings
    }
    
    @State private var contentOpacity: Double = 1.0
    @State private var contentScale: CGFloat = 1.0
    @State private var dayDropTargeted = false
    @State private var inboxDropTargeted = false
    @State private var allDropTargeted = false
    @State private var targetedProjectId: UUID?
    
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor, lineWidth: dayDropTargeted ? 2 : 0)
                            )
                            .onDrop(of: [UTType.plainText], isTargeted: $dayDropTargeted) { providers in
                                handleTaskDrop(providers) { taskId in
                                    viewModel.moveTaskToDay(taskId: taskId, date: viewModel.selectedDate)
                                }
                            }
                        Label("Week", systemImage: "calendar.badge.clock")
                            .tag(ViewType.week)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Label("Inbox", systemImage: "tray")
                            .tag(ViewType.inbox)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor, lineWidth: inboxDropTargeted ? 2 : 0)
                            )
                            .onDrop(of: [UTType.plainText], isTargeted: $inboxDropTargeted) { providers in
                                handleTaskDrop(providers) { taskId in
                                    viewModel.moveTaskToInbox(taskId: taskId)
                                }
                            }
                        Label("Completed", systemImage: "checkmark.circle")
                            .tag(ViewType.completed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Section("Projects") {
                        Label("All", systemImage: "tray.full")
                            .tag(ViewType.allTasks)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(0.5), lineWidth: allDropTargeted ? 2 : 0)
                            )
                            .onDrop(of: [UTType.plainText], isTargeted: $allDropTargeted) { providers in
                                handleTaskDrop(providers) { taskId in
                                    viewModel.assignTaskToProject(taskId: taskId, epicId: nil)
                                }
                            }
                        ForEach(viewModel.epics) { epic in
                            Label(epic.name, systemImage: "folder")
                                .tag(ViewType.project(epic.id))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accentColor, lineWidth: targetedProjectId == epic.id ? 2 : 0)
                                )
                                .onDrop(of: [UTType.plainText], isTargeted: Binding(
                                    get: { targetedProjectId == epic.id },
                                    set: { targeted in
                                        if targeted {
                                            targetedProjectId = epic.id
                                        } else if targetedProjectId == epic.id {
                                            targetedProjectId = nil
                                        }
                                    }
                                )) { providers in
                                    handleTaskDrop(providers) { taskId in
                                        viewModel.assignTaskToProject(taskId: taskId, epicId: epic.id)
                                    }
                                }
                        }
                        Button(action: {
                            viewModel.addEpic(name: "New project")
                            if let id = viewModel.epics.last?.id {
                                viewModel.activeTab = .project(id)
                            }
                        }) {
                            Label("Add project", systemImage: "plus.circle")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.borderless)
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
                        Label("Preferences", systemImage: "gear")
                            .tag(ViewType.settings)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    case .allTasks:
                        AllTasksView()
                    case .project(let id):
                        ProjectView(epicId: id, onDeleteProject: {
                            viewModel.activeTab = .day
                        })
                    case .notesDay:
                        NotesDayView()
                    case .notesWeek:
                        NotesWeekView()
                    case .settings:
                        SettingsView()
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
    
    private func handleTaskDrop(_ providers: [NSItemProvider], action: @escaping (UUID) -> Void) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { string, _ in
            if let uuidString = string as? String, let taskId = UUID(uuidString: uuidString) {
                DispatchQueue.main.async {
                    withAnimation {
                        action(taskId)
                    }
                }
            }
        }
        return true
    }
}
