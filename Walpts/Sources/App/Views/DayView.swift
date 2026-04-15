import SwiftUI
import AppKit
import EventKit
struct DayView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var showingCreateTask = false
    @State private var selectedTask: TaskItem?
    @State private var draggingTask: TaskItem?
    @State private var showingCalendar = false
    
    @State private var dragOffset: CGFloat = 0
    @State private var contentOpacity: Double = 1.0
    @State private var contentOffset: CGFloat = 0
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { animateTransition(direction: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.selectedDate = Date()
                    }
                }) {
                    Text(formattedDate(viewModel.selectedDate))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .disabled(Calendar.current.isDateInToday(viewModel.selectedDate))
                .help("Go to Today")
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedDate)
                
                Button(action: { animateTransition(direction: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                Button(action: {
                    showingDatePicker.toggle()
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Pick a date")
                .popover(isPresented: $showingDatePicker, arrowEdge: .bottom) {
                    DatePicker(
                        "Select date",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .hidesFocusRing()
                    .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            HStack(alignment: .center, spacing: 8) {
                Spacer()
                Button(action: {
                    withAnimation { showingCalendar.toggle() }
                }) {
                    Label(showingCalendar ? "Show Tasks" : "Show Calendar", systemImage: showingCalendar ? "checklist" : "calendar.badge.clock")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 8)
                
                Button(action: {
                    withAnimation { viewModel.sortTasksByStatusForDate(viewModel.selectedDate) }
                }) {
                    Label("Sort by status", systemImage: "arrow.up.arrow.down.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 8)
            }
            .padding(.top, 4)
            
            ScrollView {
                VStack(spacing: 8) {
                    if showingCalendar {
                        let events = calendarManager.fetchEvents(for: viewModel.selectedDate)
                        if events.isEmpty {
                            Text("No events for this day")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(events, id: \.eventIdentifier) { event in
                                EventRow(event: event)
                            }
                        }
                    } else {
                        let allTasks = viewModel.tasksForDate(viewModel.selectedDate)
                    let dayTasks = allTasks.filter { $0.status != .discussion }
                    let discussion = viewModel.discussionTasks()

                    if dayTasks.isEmpty && discussion.isEmpty {
                        Text("No tasks")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(dayTasks.enumerated()), id: \.element.id) { index, task in
                            let isDragging = draggingTask?.id == task.id
                            TaskRow(
                                task: task,
                                onNextStatus: { withAnimation { viewModel.updateStatus(for: task) } },
                                onRevertStatus: { withAnimation { viewModel.revertStatus(for: task) } },
                                projectName: viewModel.epics.first(where: { $0.id == task.epicId })?.name,
                                onTap: { selectedTask = task },
                                onGripDragChanged: { delta in
                                    if draggingTask == nil {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                            draggingTask = task
                                        }
                                    }
                                    dragOffset = delta
                                },
                                onGripDragEnded: { delta in
                                    let slotH: CGFloat = 68
                                    let fromIdx = dayTasks.firstIndex(where: { $0.id == task.id }) ?? index
                                    let targetIdx = max(0, min(dayTasks.count - 1, fromIdx + Int(round(delta / slotH))))
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if targetIdx != fromIdx {
                                            viewModel.moveTaskDay(from: IndexSet(integer: fromIdx), to: targetIdx > fromIdx ? targetIdx + 1 : targetIdx, date: viewModel.selectedDate)
                                        }
                                        draggingTask = nil
                                        dragOffset = 0
                                    }
                                }
                            )
                            .offset(y: dayTaskVisualOffset(taskId: task.id, index: index, tasks: dayTasks))
                            .scaleEffect(isDragging ? 1.02 : 1.0)
                            .shadow(color: isDragging ? .black.opacity(0.22) : .black.opacity(0.06),
                                    radius: isDragging ? 16 : 6,
                                    x: 0, y: isDragging ? 8 : 3)
                            .zIndex(isDragging ? 1 : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: draggingTask?.id)
                        }

                        if !discussion.isEmpty {
                            HStack {
                                Text("Discussion")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 4)

                            ForEach(discussion) { task in
                                TaskRow(
                                    task: task,
                                    onNextStatus: { withAnimation { viewModel.updateStatus(for: task) } },
                                    onRevertStatus: { withAnimation { viewModel.revertStatus(for: task) } },
                                    projectName: viewModel.epics.first(where: { $0.id == task.epicId })?.name,
                                    onTap: { selectedTask = task }
                                )
                            }
                        }
                    }
                    } // Close showingCalendar else
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .opacity(contentOpacity)
            .offset(x: contentOffset)
        }
        .onSwipe(left: {
            animateTransition(direction: 1)
        }, right: {
            animateTransition(direction: -1)
        })
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottomTrailing) {
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showingCreateTask = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                    .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .buttonStyle(PulseButtonStyle())
            .padding(24)
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView(isPresented: $showingCreateTask, date: viewModel.selectedDate)
                .presentationDetents([.height(300)])
        }
        .sheet(item: $selectedTask) { task in
            if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                TaskDetailView(task: $viewModel.tasks[index])
            } else {
                Text("Task not found")
            }
        }
    }

    private func dayTaskVisualOffset(taskId: UUID, index: Int, tasks: [TaskItem]) -> CGFloat {
        let slotH: CGFloat = 68
        guard let dragging = draggingTask,
              let fromIdx = tasks.firstIndex(where: { $0.id == dragging.id }) else { return 0 }
        if taskId == dragging.id { return dragOffset }
        let rawTarget = CGFloat(fromIdx) + dragOffset / slotH
        let targetIdx = Int(max(0, min(CGFloat(tasks.count - 1), rawTarget)).rounded())
        if fromIdx < targetIdx {
            if index > fromIdx && index <= targetIdx { return -slotH }
        } else if fromIdx > targetIdx {
            if index >= targetIdx && index < fromIdx { return slotH }
        }
        return 0
    }

    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: viewModel.selectedDate) {
            viewModel.selectedDate = newDate
        }
    }
    
    private func animateTransition(direction: Int) {
        withAnimation(.easeOut(duration: 0.15)) {
            contentOpacity = 0
            contentOffset = CGFloat(direction * -50)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            changeDate(by: direction)
            contentOffset = CGFloat(direction * 50)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
}

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(nsColor: event.calendar.color))
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(timeString(from: event.startDate, to: event.endDate, isAllDay: event.isAllDay))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func timeString(from start: Date, to end: Date, isAllDay: Bool) -> String {
        if isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PulseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct InboxView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var showingCreateTask = false
    @State private var selectedTask: TaskItem?
    @State private var draggingTask: TaskItem?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Inbox")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    withAnimation { viewModel.sortTasksByStatusInbox() }
                }) {
                    Label("Sort by status", systemImage: "arrow.up.arrow.down.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))

            ScrollView {
                VStack(spacing: 8) {
                    let tasks = viewModel.inboxTasks()
                    if tasks.isEmpty {
                        Text("No inbox tasks")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            let isDragging = draggingTask?.id == task.id
                            TaskRow(
                                task: task,
                                onNextStatus: { withAnimation { viewModel.updateStatus(for: task) } },
                                onRevertStatus: { withAnimation { viewModel.revertStatus(for: task) } },
                                projectName: viewModel.epics.first(where: { $0.id == task.epicId })?.name,
                                onTap: { selectedTask = task },
                                onGripDragChanged: { delta in
                                    if draggingTask == nil {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                            draggingTask = task
                                        }
                                    }
                                    dragOffset = delta
                                },
                                onGripDragEnded: { delta in
                                    let slotH: CGFloat = 68
                                    let fromIdx = tasks.firstIndex(where: { $0.id == task.id }) ?? index
                                    let targetIdx = max(0, min(tasks.count - 1, fromIdx + Int(round(delta / slotH))))
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if targetIdx != fromIdx {
                                            viewModel.moveTaskInbox(from: IndexSet(integer: fromIdx), to: targetIdx > fromIdx ? targetIdx + 1 : targetIdx)
                                        }
                                        draggingTask = nil
                                        dragOffset = 0
                                    }
                                }
                            )
                            .offset(y: inboxTaskVisualOffset(taskId: task.id, index: index, tasks: tasks))
                            .scaleEffect(isDragging ? 1.02 : 1.0)
                            .shadow(color: isDragging ? .black.opacity(0.22) : .black.opacity(0.06),
                                    radius: isDragging ? 16 : 6,
                                    x: 0, y: isDragging ? 8 : 3)
                            .zIndex(isDragging ? 1 : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: draggingTask?.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingCreateTask = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(24)
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView(isPresented: $showingCreateTask, date: nil, isInbox: true)
                .presentationDetents([.height(300)])
        }
        .sheet(item: $selectedTask) { task in
            if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                TaskDetailView(task: $viewModel.tasks[index])
            } else {
                Text("Task not found")
            }
        }
    }

    private func inboxTaskVisualOffset(taskId: UUID, index: Int, tasks: [TaskItem]) -> CGFloat {
        let slotH: CGFloat = 68
        guard let dragging = draggingTask,
              let fromIdx = tasks.firstIndex(where: { $0.id == dragging.id }) else { return 0 }
        if taskId == dragging.id { return dragOffset }
        let rawTarget = CGFloat(fromIdx) + dragOffset / slotH
        let targetIdx = Int(max(0, min(CGFloat(tasks.count - 1), rawTarget)).rounded())
        if fromIdx < targetIdx {
            if index > fromIdx && index <= targetIdx { return -slotH }
        } else if fromIdx > targetIdx {
            if index >= targetIdx && index < fromIdx { return slotH }
        }
        return 0
    }
}

struct ActionWrapper: Equatable {
    let id = UUID()
    let action: NotesDayView.EditorAction
}

struct NotesDayView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var noteText: String = ""
    @State private var editorActionWrapper: ActionWrapper?
    @State private var contentOpacity: Double = 0.0
    @State private var contentOffsetX: CGFloat = 0
    @State private var showingDatePicker = false
    
    @AppStorage("editorFontName") private var fontName: String = "System"
    @AppStorage("editorFontSize") private var fontSize: Double = 14.0
    
    enum EditorAction: Equatable {
        case toggleBold
        case toggleItalic
        case toggleUnderline
        case toggleStrikethrough
        case toggleList
        case insertLink
        case header(Int)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { animateTransition(direction: -1) }) {
                    Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.selectedDate = Date()
                    }
                    noteText = viewModel.noteText(for: Date())
                }) {
                    Text(formattedDate(viewModel.selectedDate))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Calendar.current.isDateInToday(viewModel.selectedDate) ? .primary : .primary)
                }
                .buttonStyle(.plain)
                .disabled(Calendar.current.isDateInToday(viewModel.selectedDate))
                .help("Go to Today")
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedDate)
                
                Button(action: { animateTransition(direction: 1) }) {
                    Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    showingDatePicker.toggle()
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Pick a date")
                .popover(isPresented: $showingDatePicker, arrowEdge: .bottom) {
                    DatePicker(
                        "Select date",
                        selection: Binding(
                            get: { viewModel.selectedDate },
                            set: { newDate in
                                viewModel.selectedDate = newDate
                                noteText = viewModel.noteText(for: newDate)
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .hidesFocusRing()
                    .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            HStack(spacing: 8) {
                Group {
                    Menu {
                        Picker("Font", selection: $fontName) {
                            Text("System").tag("System")
                            Text("Serif").tag("Serif")
                            Text("Monospaced").tag("Monospaced")
                        }
                    } label: {
                        Image(systemName: "textformat")
                    }
                    .help("Font Family")
                    
                    Menu {
                        Picker("Size", selection: $fontSize) {
                            Text("12").tag(12.0)
                            Text("14").tag(14.0)
                            Text("16").tag(16.0)
                            Text("18").tag(18.0)
                            Text("20").tag(20.0)
                            Text("24").tag(24.0)
                        }
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                    .help("Font Size")

                    Divider()
                        .frame(height: 16)
                    
                    Button(action: { editorActionWrapper = ActionWrapper(action: .header(1)) }) {
                        Text("H1")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .help("Heading 1")
                    
                    Button(action: { editorActionWrapper = ActionWrapper(action: .header(2)) }) {
                        Text("H2")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .help("Heading 2")
                    
                    Button(action: { editorActionWrapper = ActionWrapper(action: .header(3)) }) {
                        Text("H3")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .help("Heading 3")
                    
                    Divider()
                        .frame(height: 16)
                }

                Button(action: { editorActionWrapper = ActionWrapper(action: .toggleList) }) {
                    Image(systemName: "list.bullet")
                }
                .help("List")
                
                Button(action: { editorActionWrapper = ActionWrapper(action: .toggleBold) }) {
                    Image(systemName: "bold")
                }
                .help("Bold")
                
                Button(action: { editorActionWrapper = ActionWrapper(action: .toggleItalic) }) {
                    Image(systemName: "italic")
                }
                .help("Italic")
                
                Button(action: { editorActionWrapper = ActionWrapper(action: .toggleUnderline) }) {
                    Image(systemName: "underline")
                }
                .help("Underline")
                
                Button(action: { editorActionWrapper = ActionWrapper(action: .toggleStrikethrough) }) {
                    Image(systemName: "strikethrough")
                }
                .help("Strikethrough")
                
                Button(action: { editorActionWrapper = ActionWrapper(action: .insertLink) }) {
                    Image(systemName: "link")
                }
                .help("Link")
                
                Spacer()
            }
            .buttonStyle(.plain)
            .font(.system(size: 14))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            NotesRichTextEditor(text: $noteText, actionWrapper: $editorActionWrapper, fontName: fontName, fontSize: fontSize)
                .background(Color(nsColor: .textBackgroundColor))
                .opacity(contentOpacity)
                .offset(x: contentOffsetX)
                .onAppear {
                    noteText = viewModel.noteText(for: viewModel.selectedDate)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        contentOpacity = 1.0
                        contentOffsetX = 0
                    }
                }
                .onChange(of: noteText) { _, newText in
                    viewModel.setNoteText(newText, for: viewModel.selectedDate)
                }
        }
        .onSwipe(left: {
            animateTransition(direction: 1)
        }, right: {
            animateTransition(direction: -1)
        })
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: viewModel.selectedDate) {
            viewModel.selectedDate = newDate
        }
    }
    
    private func animateTransition(direction: Int) {
        withAnimation(.easeOut(duration: 0.15)) {
            contentOpacity = 0
            contentOffsetX = CGFloat(direction * -50)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            changeDate(by: direction)
            noteText = viewModel.noteText(for: viewModel.selectedDate)
            contentOffsetX = CGFloat(direction * 50)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                contentOpacity = 1.0
                contentOffsetX = 0
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
}

struct NotesWeekView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var anchorDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday Headers
            HStack(spacing: 1) {
                ForEach(0..<7) { index in
                    Text(calendarDays[index])
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary.opacity(0.5))
                }
            }
            .background(.regularMaterial)
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(-24...24, id: \.self) { offset in
                            NotesWeekMonthSection(monthOffset: offset, anchorDate: anchorDate, viewModel: viewModel)
                                .id(offset)
                        }
                    }
                }
                .onAppear {
                    scrollToSelectedDate(proxy: proxy)
                }
                .onChange(of: viewModel.selectedDate) { _, _ in
                    // Optional: scroll on external change
                }
            }
        }
        .background(Color.clear)
    }
    
    private func scrollToSelectedDate(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: viewModel.selectedDate)
        guard let weekStart = calendar.date(from: components) else { return }
        
        let anchorComponents = calendar.dateComponents([.year, .month], from: anchorDate)
        guard let anchorMonthStart = calendar.date(from: anchorComponents) else { return }
        
        let targetComponents = calendar.dateComponents([.year, .month], from: weekStart)
        guard let targetMonthStart = calendar.date(from: targetComponents) else { return }
        
        let diffComponents = calendar.dateComponents([.month], from: anchorMonthStart, to: targetMonthStart)
        
        if let monthDiff = diffComponents.month {
            proxy.scrollTo(monthDiff, anchor: .top)
        }
    }
    
    private var calendarDays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortStandaloneWeekdaySymbols
    }
}

struct NotesWeekMonthSection: View {
    let monthOffset: Int
    let anchorDate: Date
    @ObservedObject var viewModel: TaskViewModel
    
    private var currentMonth: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: anchorDate) ?? anchorDate
    }
    
    var body: some View {
        let weeks = weeksInMonth()
        
        if !weeks.isEmpty {
            Section(header: NotesWeekMonthHeader(title: monthString)) {
                VStack(spacing: 1) {
                    ForEach(weeks, id: \.self) { weekStart in
                        NotesWeekRow(weekStart: weekStart, viewModel: viewModel)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private func weeksInMonth() -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        var weeks: [Date] = []
        
        let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfMonth)
        var weekStart = calendar.date(from: weekComponents)!
        
        if weekStart < startOfMonth {
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }
        
        while calendar.isDate(weekStart, equalTo: startOfMonth, toGranularity: .month) {
            weeks.append(weekStart)
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }
        
        return weeks
    }
}

struct NotesWeekMonthHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.vertical, 8)
            Spacer()
        }
        .background(.ultraThinMaterial)
    }
}

struct NotesWeekRow: View {
    let weekStart: Date
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<7) { dayOffset in
                if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) {
                    NotesWeekDayCell(date: date, viewModel: viewModel)
                        .onTapGesture {
                            viewModel.selectedDate = date
                            viewModel.activeTab = .notesDay
                        }
                }
            }
        }
        .background(Color.clear)
    }
}

struct NotesWeekDayCell: View {
    let date: Date
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dateFormatter.string(from: date).uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary.opacity(0.5))
            
            Text(dayNumberFormatter.string(from: date))
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Calendar.current.isDateInToday(date) ? .primary : .primary.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Calendar.current.isDateInToday(date) ? Color.blue.opacity(0.08) : Color.clear)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                let raw = viewModel.noteText(for: date)
                let preview = Self.plainTextPreview(from: raw)
                if preview.isEmpty {
                    Text("No note")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    Text(preview)
                        .font(.system(size: 10))
                        .foregroundColor(.primary.opacity(0.7))
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.ultraThinMaterial)
            .cornerRadius(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "E"
        return formatter
    }()
    
    private let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    static func plainTextPreview(from stored: String) -> String {
        if stored.hasPrefix(NotesRichTextEditor.rtfPrefix) {
            let base64 = String(stored.dropFirst(NotesRichTextEditor.rtfPrefix.count))
            if let data = Data(base64Encoded: base64),
               let attributed = NSAttributedString(rtf: data, documentAttributes: nil) {
                return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return ""
        }
        return stored.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}



struct NotesRichTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var actionWrapper: ActionWrapper?
    var fontName: String
    var fontSize: Double
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isRichText = true
        textView.importsGraphics = false
        textView.isEditable = true
        textView.allowsUndo = true
        textView.font = getFont(size: fontSize, bold: false, italic: false)
        textView.textColor = .textColor
        textView.drawsBackground = false
        
        context.coordinator.textView = textView
        
        let attributed = Self.deserialize(text, fontSize: fontSize, fontName: fontName, getFont: getFont)
        textView.textStorage?.setAttributedString(attributed)
        context.coordinator.lastSerializedText = text
        
        // Ensure typing attributes also have the correct color initially
        var attributes = textView.typingAttributes
        attributes[.foregroundColor] = NSColor.textColor
        attributes[.font] = getFont(size: fontSize, bold: false, italic: false)
        textView.typingAttributes = attributes
        
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        
        textView.delegate = context.coordinator
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if context.coordinator.lastFontName != fontName || context.coordinator.lastFontSize != fontSize {
            textView.delegate = nil
            
            var attributes = textView.typingAttributes
            if let currentFont = attributes[.font] as? NSFont {
                 let traits = NSFontManager.shared.traits(of: currentFont)
                 let isBold = traits.contains(.boldFontMask)
                 let isItalic = traits.contains(.italicFontMask)
                 attributes[.font] = getFont(size: fontSize, bold: isBold, italic: isItalic)
            } else {
                attributes[.font] = getFont(size: fontSize, bold: false, italic: false)
            }
            textView.typingAttributes = attributes
            
            if let storage = textView.textStorage {
                 let selectedRange = textView.selectedRange()
                 let styled = applyCustomAttributes(to: storage)
                 storage.setAttributedString(styled)
                 textView.setSelectedRange(selectedRange)
            }
            
            context.coordinator.lastFontName = fontName
            context.coordinator.lastFontSize = fontSize
            textView.delegate = context.coordinator
        }
        
        // Handle actions
        if let wrapper = actionWrapper {
            if wrapper != context.coordinator.lastActionWrapper {
                switch wrapper.action {
                case .toggleBold:
                    toggleTrait(.boldFontMask, in: textView)
                case .toggleItalic:
                    toggleTrait(.italicFontMask, in: textView)
                case .toggleUnderline:
                    toggleUnderline(in: textView)
                case .toggleStrikethrough:
                    toggleStrikethrough(in: textView)
                case .toggleList:
                    toggleList(in: textView)
                case .insertLink:
                    insertLink(in: textView)
                case .header(let level):
                    toggleHeader(level, in: textView)
                }
                context.coordinator.lastActionWrapper = wrapper
            }
        }
        
        if context.coordinator.lastSerializedText != text {
            textView.delegate = nil
            let attributed = Self.deserialize(text, fontSize: fontSize, fontName: fontName, getFont: getFont)
            textView.textStorage?.setAttributedString(attributed)
            context.coordinator.lastSerializedText = text
            textView.delegate = context.coordinator
        }
    }
    
    static let rtfPrefix = "rtf:"
    
    static func serialize(_ attributedString: NSAttributedString) -> String {
        let range = NSRange(location: 0, length: attributedString.length)
        if let rtfData = try? attributedString.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) {
            return rtfPrefix + rtfData.base64EncodedString()
        }
        return attributedString.string
    }
    
    static func deserialize(_ text: String, fontSize: Double, fontName: String, getFont: (CGFloat, Bool, Bool) -> NSFont) -> NSAttributedString {
        if text.hasPrefix(rtfPrefix) {
            let base64 = String(text.dropFirst(rtfPrefix.count))
            if let data = Data(base64Encoded: base64),
               let attributed = NSAttributedString(rtf: data, documentAttributes: nil) {
                let mutable = NSMutableAttributedString(attributedString: attributed)
                let fullRange = NSRange(location: 0, length: mutable.length)
                mutable.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
                return mutable
            }
        }
        
        if text.isEmpty {
            return NSAttributedString(string: "", attributes: [
                .font: getFont(fontSize, false, false),
                .foregroundColor: NSColor.textColor
            ])
        }
        
        if let attributed = try? NSAttributedString(markdown: text) {
            let mutable = NSMutableAttributedString(attributedString: attributed)
            let fullRange = NSRange(location: 0, length: mutable.length)
            mutable.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
            return mutable
        }
        
        return NSAttributedString(string: text, attributes: [
            .font: getFont(fontSize, false, false),
            .foregroundColor: NSColor.textColor
        ])
    }
    
    func applyCustomAttributes(to attributed: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        let fullRange = NSRange(location: 0, length: mutable.length)
        
        // 1. Set base color
        mutable.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        
        // 2. Fix fonts (preserve traits and header sizes)
        mutable.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if let font = value as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits
                let size = font.pointSize
                
                var newSize: CGFloat = fontSize
                var isBold = traits.contains(.bold)
                
                // Heuristic to detect headers from standard Markdown parsing
                if size >= 23 { newSize = fontSize * 1.7; isBold = true }      // H1
                else if size >= 19 { newSize = fontSize * 1.4; isBold = true } // H2
                else if size >= 15 { newSize = fontSize * 1.15; isBold = true } // H3
                else { newSize = fontSize }                                     // Body
                
                let isItalic = traits.contains(.italic)
                let newFont = getFont(size: newSize, bold: isBold, italic: isItalic)
                
                mutable.addAttribute(.font, value: newFont, range: range)
            } else {
                // No font? Set default
                let newFont = getFont(size: fontSize, bold: false, italic: false)
                mutable.addAttribute(.font, value: newFont, range: range)
            }
        }
        
        return mutable
    }
    
    private func getFont(size: CGFloat, bold: Bool, italic: Bool) -> NSFont {
        let manager = NSFontManager.shared
        var font: NSFont
        
        switch fontName {
        case "Serif":
            font = NSFont(name: "New York", size: size) ?? NSFont(name: "Times New Roman", size: size) ?? NSFont.systemFont(ofSize: size, weight: .regular)
        case "Monospaced":
            font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        default:
            font = NSFont.systemFont(ofSize: size)
        }
        
        if bold { font = manager.convert(font, toHaveTrait: .boldFontMask) }
        if italic { font = manager.convert(font, toHaveTrait: .italicFontMask) }
        
        return font
    }
    
    private func toggleHeader(_ level: Int, in textView: NSTextView) {
        let range = textView.selectedRange()
        let paragraphRange = (textView.string as NSString).paragraphRange(for: range)
        let storage = textView.textStorage
        
        // Determine size
        let size: CGFloat
        switch level {
        case 1: size = fontSize * 1.7
        case 2: size = fontSize * 1.4
        case 3: size = fontSize * 1.15
        default: size = fontSize
        }
        
        // Create font
        let font = getFont(size: size, bold: true, italic: false)
        
        // Apply to paragraph
        storage?.beginEditing()
        // Remove list style if applying header
        let style = NSMutableParagraphStyle()
        style.textLists = []
        style.firstLineHeadIndent = 0
        style.headIndent = 0
        storage?.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
        
        // Apply font
        storage?.addAttribute(.font, value: font, range: paragraphRange)
        
        // Ensure color
        storage?.addAttribute(.foregroundColor, value: NSColor.textColor, range: paragraphRange)
        
        storage?.endEditing()
        textView.didChangeText()
    }
    
    private func toggleUnderline(in textView: NSTextView) {
        let range = textView.selectedRange()
        if range.length > 0 {
            if let storage = textView.textStorage {
                storage.beginEditing()
                storage.enumerateAttribute(.underlineStyle, in: range, options: []) { value, subRange, _ in
                    let currentStyle = (value as? Int) ?? 0
                    let newStyle = (currentStyle == 0) ? NSUnderlineStyle.single.rawValue : 0
                    storage.addAttribute(.underlineStyle, value: newStyle, range: subRange)
                    // Ensure color persists
                    storage.addAttribute(.foregroundColor, value: NSColor.textColor, range: subRange)
                }
                storage.endEditing()
            }
        } else {
            var attributes = textView.typingAttributes
            let currentStyle = (attributes[.underlineStyle] as? Int) ?? 0
            let newStyle = (currentStyle == 0) ? NSUnderlineStyle.single.rawValue : 0
            attributes[.underlineStyle] = newStyle
            attributes[.foregroundColor] = NSColor.textColor
            textView.typingAttributes = attributes
        }
        textView.didChangeText()
    }
    
    private func toggleStrikethrough(in textView: NSTextView) {
        let range = textView.selectedRange()
        if range.length > 0 {
            if let storage = textView.textStorage {
                storage.beginEditing()
                storage.enumerateAttribute(.strikethroughStyle, in: range, options: []) { value, subRange, _ in
                    let currentStyle = (value as? Int) ?? 0
                    let newStyle = (currentStyle == 0) ? NSUnderlineStyle.single.rawValue : 0
                    storage.addAttribute(.strikethroughStyle, value: newStyle, range: subRange)
                    // Ensure color persists
                    storage.addAttribute(.foregroundColor, value: NSColor.textColor, range: subRange)
                }
                storage.endEditing()
            }
        } else {
            var attributes = textView.typingAttributes
            let currentStyle = (attributes[.strikethroughStyle] as? Int) ?? 0
            let newStyle = (currentStyle == 0) ? NSUnderlineStyle.single.rawValue : 0
            attributes[.strikethroughStyle] = newStyle
            attributes[.foregroundColor] = NSColor.textColor
            textView.typingAttributes = attributes
        }
        textView.didChangeText()
    }

    private func toggleTrait(_ trait: NSFontTraitMask, in textView: NSTextView) {
        let range = textView.selectedRange()
        let fontManager = NSFontManager.shared
        
        if range.length > 0 {
            if let storage = textView.textStorage {
                storage.beginEditing()
                storage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                    if let font = value as? NSFont {
                        let currentTraits = fontManager.traits(of: font)
                        let hasTrait = currentTraits.contains(trait)
                        var newFont: NSFont
                        if hasTrait {
                            newFont = fontManager.convert(font, toNotHaveTrait: trait)
                        } else {
                            newFont = fontManager.convert(font, toHaveTrait: trait)
                        }
                        storage.addAttribute(.font, value: newFont, range: subRange)
                        // Ensure color persists
                        storage.addAttribute(.foregroundColor, value: NSColor.textColor, range: subRange)
                    }
                }
                storage.endEditing()
            }
        } else {
            // Typing attributes
            var attributes = textView.typingAttributes
            if let font = attributes[.font] as? NSFont {
                let currentTraits = fontManager.traits(of: font)
                let hasTrait = currentTraits.contains(trait)
                var newFont: NSFont
                if hasTrait {
                    newFont = fontManager.convert(font, toNotHaveTrait: trait)
                } else {
                    newFont = fontManager.convert(font, toHaveTrait: trait)
                }
                attributes[.font] = newFont
                attributes[.foregroundColor] = NSColor.textColor
                textView.typingAttributes = attributes
            }
        }
        textView.didChangeText()
    }
    
    private func toggleList(in textView: NSTextView) {
        let range = textView.selectedRange()
        let paragraphRange = (textView.string as NSString).paragraphRange(for: range)
        
        let storage = textView.textStorage
        var isList = false
        
        storage?.enumerateAttribute(.paragraphStyle, in: paragraphRange, options: []) { value, range, stop in
            if let style = value as? NSParagraphStyle, !style.textLists.isEmpty {
                isList = true
                stop.pointee = true
            }
        }
        
        let style = NSMutableParagraphStyle()
        if isList {
            // Remove list
            style.textLists = []
            style.firstLineHeadIndent = 0
            style.headIndent = 0
        } else {
            // Add list
            // Use a custom bullet string to ensure it looks like a dot, as .disc might be rendered differently
            let list = NSTextList(markerFormat: .init("•"), options: 0)
            style.textLists = [list]
            style.firstLineHeadIndent = 0
            style.headIndent = 15
        }
        
        if paragraphRange.length > 0 {
            storage?.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
        }
        
        // Update typing attributes
        var newAttributes = textView.typingAttributes
        newAttributes[.paragraphStyle] = style
        textView.typingAttributes = newAttributes
        
        // Force bullet appearance if empty line
        if !isList {
            let length = paragraphRange.length
            let content = (textView.string as NSString).substring(with: paragraphRange)
            let isEmptyLine = length == 0 || content == "\n"
            
            if isEmptyLine {
                 // Use Zero Width Space to force bullet rendering without visible space
                 let zeroWidthSpace = "\u{200B}"
                 let currentFont = textView.typingAttributes[.font] as? NSFont ?? getFont(size: fontSize, bold: false, italic: false)
                 let attrStr = NSAttributedString(string: zeroWidthSpace, attributes: [
                    .paragraphStyle: style,
                    .font: currentFont,
                    .foregroundColor: NSColor.textColor
                 ])
                 
                 if textView.shouldChangeText(in: NSRange(location: range.location, length: 0), replacementString: zeroWidthSpace) {
                     storage?.insert(attrStr, at: range.location)
                     textView.setSelectedRange(NSRange(location: range.location + 1, length: 0))
                 }
            }
        }
        
        textView.didChangeText()
    }
    
    private func insertLink(in textView: NSTextView) {
        let range = textView.selectedRange()
        if range.length > 0 {
            textView.orderFrontLinkPanel(nil)
        } else {
            let linkText = "link"
            let url = URL(string: "https://")!
            let attrString = NSMutableAttributedString(string: linkText)
            attrString.addAttribute(.link, value: url, range: NSRange(location: 0, length: linkText.count))
            textView.textStorage?.insert(attrString, at: range.location)
            textView.setSelectedRange(NSRange(location: range.location, length: linkText.count))
            textView.orderFrontLinkPanel(nil)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NotesRichTextEditor
        var lastSerializedText: String = ""
        var lastActionWrapper: ActionWrapper?
        var lastFontName: String = ""
        var lastFontSize: Double = 0
        weak var textView: NSTextView?
        
        init(_ parent: NotesRichTextEditor) {
            self.parent = parent
        }
        
        func applyCustomAttributes(to attributed: NSAttributedString) -> NSAttributedString {
            return parent.applyCustomAttributes(to: attributed)
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard let storage = textView.textStorage else { return }
            
            let serialized = NotesRichTextEditor.serialize(storage)
            parent.text = serialized
            lastSerializedText = serialized
        }
    }
}


