import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = [] {
        didSet {
            TaskStorage.shared.save(tasks)
        }
    }
    
    @Published var notes: [NoteItem] = [] {
        didSet {
            NoteStorage.shared.save(notes)
        }
    }
    
    @Published var epics: [Epic] = [] {
        didSet {
            EpicStorage.shared.save(epics)
        }
    }
    
    @Published var selectedDate: Date = Date()
    @Published var activeTab: ContentView.ViewType = .day
    
    init() {
        let loaded = TaskStorage.shared.load()
        if loaded.isEmpty {
            let today = Calendar.current.startOfDay(for: Date())
            tasks = [
                TaskItem(title: "Implement UI", type: .discussion, status: .pending, priority: .medium, date: today),
                TaskItem(title: "Discuss design", type: .discussion, status: .pending, priority: .medium, date: today),
                TaskItem(title: "Login bugfix", type: .discussion, status: .inProgress, priority: .medium, date: today, startTime: Date().addingTimeInterval(-3600))
            ]
        } else {
            tasks = loaded
        }
        
        notes = NoteStorage.shared.load()
        epics = EpicStorage.shared.load()
    }
    
    func statusSeverity(_ status: TaskStatus) -> Int {
        switch status {
        case .discussion: return 0
        case .pending: return 1
        case .approved: return 2
        case .inProgress: return 3
        case .completed: return 4
        case .reported: return 5
        }
    }
    
    private func isCompletedOrReported(_ task: TaskItem) -> Bool {
        task.status == .completed || task.status == .reported
    }
    
    private func orderValue(_ task: TaskItem) -> Int {
        task.orderIndex ?? Int.max
    }
    
    func addTask(title: String, type: TaskType, date: Date, priority: Priority = .medium, epicId: UUID? = nil) {
        let status: TaskStatus = type == .discussion ? .discussion : .pending
        let day = Calendar.current.startOfDay(for: date)
        let dayTasks = tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: day) && !$0.isInbox }
        let maxOrder = dayTasks.compactMap(\.orderIndex).max() ?? -1
        var newTask = TaskItem(title: title, type: type, status: status, priority: priority, date: day, isInbox: false, orderIndex: maxOrder + 1, epicId: epicId)
        tasks.append(newTask)
    }
    
    func addInboxTask(title: String, type: TaskType, priority: Priority = .medium, epicId: UUID? = nil) {
        let today = Calendar.current.startOfDay(for: Date())
        let status: TaskStatus = type == .discussion ? .discussion : .pending
        let inbox = tasks.filter(\.isInbox)
        let maxOrder = inbox.compactMap(\.orderIndex).max() ?? -1
        var newTask = TaskItem(title: title, type: type, status: status, priority: priority, date: today, isInbox: true, orderIndex: maxOrder + 1, epicId: epicId)
        tasks.append(newTask)
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func revertStatus(for task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updatedTask = tasks[index]
        
        switch updatedTask.status {
        case .pending:
            updatedTask.status = .discussion
        case .inProgress:
            updatedTask.status = .pending
            updatedTask.startTime = nil
            updatedTask.endTime = nil
        case .completed:
            updatedTask.status = .inProgress
            updatedTask.endTime = nil
        case .reported:
            updatedTask.status = .completed
        case .approved:
            updatedTask.status = .pending
        case .discussion:
            break
        }
        
        tasks[index] = updatedTask
    }
    
    // Прямое изменение статуса (например, Completed -> InProgress)
    func updateStatus(for task: TaskItem, to newStatus: TaskStatus) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updatedTask = tasks[index]
        let oldStatus = updatedTask.status
        let calendar = Calendar.current
        
        // Если переводим в InProgress -> сбрасываем endTime, ставим startTime если нет
        if newStatus == .inProgress {
            updatedTask.endTime = nil
            if updatedTask.startTime == nil {
                updatedTask.startTime = Date()
            }
        }
        
        // Если переводим в Pending -> сбрасываем время
        if newStatus == .pending {
            updatedTask.startTime = nil
            updatedTask.endTime = nil
            if oldStatus == .discussion {
                let day = Calendar.current.startOfDay(for: selectedDate)
                updatedTask.date = day
                updatedTask.isInbox = false
            }
        }
        
        updatedTask.status = newStatus
        if newStatus == .completed || newStatus == .reported {
            let dayTasks = tasks.filter { calendar.isDate(updatedTask.date, inSameDayAs: $0.date) && !$0.isInbox }
            let maxOrder = dayTasks.compactMap(\.orderIndex).max() ?? 0
            updatedTask.orderIndex = maxOrder + 1
        }
        tasks[index] = updatedTask
    }
    
    func updateStatus(for task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updatedTask = tasks[index]
        let calendar = Calendar.current
        
        switch updatedTask.status {
        case .discussion:
            updatedTask.status = .pending
            updatedTask.startTime = nil
            updatedTask.endTime = nil
            let day = calendar.startOfDay(for: selectedDate)
            updatedTask.date = day
        case .pending:
            updatedTask.status = .inProgress
            updatedTask.startTime = Date()
            updatedTask.endTime = nil
        case .approved:
            updatedTask.status = .inProgress
            if updatedTask.startTime == nil {
                updatedTask.startTime = Date()
            }
            updatedTask.endTime = nil
        case .inProgress:
            updatedTask.status = .completed
            updatedTask.endTime = Date()
            let dayTasks = tasks.filter { calendar.isDate(updatedTask.date, inSameDayAs: $0.date) && !$0.isInbox }
            let maxOrder = dayTasks.compactMap(\.orderIndex).max() ?? 0
            updatedTask.orderIndex = maxOrder + 1
        case .completed:
            updatedTask.status = .reported
            let dayTasks = tasks.filter { calendar.isDate(updatedTask.date, inSameDayAs: $0.date) && !$0.isInbox }
            let maxOrder = dayTasks.compactMap(\.orderIndex).max() ?? 0
            updatedTask.orderIndex = maxOrder + 1
        case .reported:
            break
        }
        
        tasks[index] = updatedTask
    }
    
    func tasksForDate(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks
            .filter { calendar.isDate($0.date, inSameDayAs: date) && !$0.isInbox }
            .sorted { orderValue($0) < orderValue($1) }
    }

    func discussionTasks() -> [TaskItem] {
        tasks
            .filter { $0.status == .discussion && !$0.isInbox }
            .sorted { orderValue($0) < orderValue($1) }
    }
    
    func moveTaskDay(from source: IndexSet, to destination: Int, date: Date) {
        var sorted = tasksForDate(date)
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, task) in sorted.enumerated() {
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx].orderIndex = i
            }
        }
    }
    
    func moveTaskInbox(from source: IndexSet, to destination: Int) {
        var sorted = inboxTasks()
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, task) in sorted.enumerated() {
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx].orderIndex = i
            }
        }
    }
    
    func moveTaskDayUp(_ task: TaskItem, date: Date) {
        var sorted = tasksForDate(date)
        guard let idx = sorted.firstIndex(where: { $0.id == task.id }), idx > 0 else { return }
        sorted.swapAt(idx, idx - 1)
        for (i, t) in sorted.enumerated() {
            if let j = tasks.firstIndex(where: { $0.id == t.id }) {
                tasks[j].orderIndex = i
            }
        }
    }
    
    func moveTaskDayDown(_ task: TaskItem, date: Date) {
        var sorted = tasksForDate(date)
        guard let idx = sorted.firstIndex(where: { $0.id == task.id }), idx < sorted.count - 1 else { return }
        sorted.swapAt(idx, idx + 1)
        for (i, t) in sorted.enumerated() {
            if let j = tasks.firstIndex(where: { $0.id == t.id }) {
                tasks[j].orderIndex = i
            }
        }
    }
    
    func moveTaskInboxUp(_ task: TaskItem) {
        var sorted = inboxTasks()
        guard let idx = sorted.firstIndex(where: { $0.id == task.id }), idx > 0 else { return }
        sorted.swapAt(idx, idx - 1)
        for (i, t) in sorted.enumerated() {
            if let j = tasks.firstIndex(where: { $0.id == t.id }) {
                tasks[j].orderIndex = i
            }
        }
    }
    
    func moveTaskInboxDown(_ task: TaskItem) {
        var sorted = inboxTasks()
        guard let idx = sorted.firstIndex(where: { $0.id == task.id }), idx < sorted.count - 1 else { return }
        sorted.swapAt(idx, idx + 1)
        for (i, t) in sorted.enumerated() {
            if let j = tasks.firstIndex(where: { $0.id == t.id }) {
                tasks[j].orderIndex = i
            }
        }
    }

    func sortTasksByStatusForDate(_ date: Date) {
        let calendar = Calendar.current
        var dayTasks = tasks.filter { calendar.isDate($0.date, inSameDayAs: date) && !$0.isInbox }
        dayTasks.sort { t1, t2 in
            let c1 = isCompletedOrReported(t1), c2 = isCompletedOrReported(t2)
            if c1 != c2 { return !c1 }
            let ip1 = t1.status == .inProgress, ip2 = t2.status == .inProgress
            if ip1 != ip2 { return ip1 }
            let p1 = priorityValue(t1.priority), p2 = priorityValue(t2.priority)
            if p1 != p2 { return p1 > p2 }
            if statusSeverity(t1.status) != statusSeverity(t2.status) { return statusSeverity(t1.status) < statusSeverity(t2.status) }
            return t1.title < t2.title
        }
        for (i, task) in dayTasks.enumerated() {
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx].orderIndex = i
            }
        }
    }
    
    func sortTasksByStatusInbox() {
        var inbox = tasks.filter(\.isInbox)
        inbox.sort { t1, t2 in
            let c1 = isCompletedOrReported(t1), c2 = isCompletedOrReported(t2)
            if c1 != c2 { return !c1 }
            let ip1 = t1.status == .inProgress, ip2 = t2.status == .inProgress
            if ip1 != ip2 { return ip1 }
            let p1 = priorityValue(t1.priority), p2 = priorityValue(t2.priority)
            if p1 != p2 { return p1 > p2 }
            if statusSeverity(t1.status) != statusSeverity(t2.status) { return statusSeverity(t1.status) < statusSeverity(t2.status) }
            return t1.title < t2.title
        }
        for (i, task) in inbox.enumerated() {
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx].orderIndex = i
            }
        }
    }
    
    func allTasksSorted() -> [TaskItem] {
        tasks.sorted { orderValue($0) < orderValue($1) }
    }
    
    func sortAllTasksByStatus() {
        var sorted = tasks
        sorted.sort { t1, t2 in
            let c1 = isCompletedOrReported(t1), c2 = isCompletedOrReported(t2)
            if c1 != c2 { return !c1 }
            let ip1 = t1.status == .inProgress, ip2 = t2.status == .inProgress
            if ip1 != ip2 { return ip1 }
            let p1 = priorityValue(t1.priority), p2 = priorityValue(t2.priority)
            if p1 != p2 { return p1 > p2 }
            if statusSeverity(t1.status) != statusSeverity(t2.status) { return statusSeverity(t1.status) < statusSeverity(t2.status) }
            return t1.title < t2.title
        }
        for (i, task) in sorted.enumerated() {
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx].orderIndex = i
            }
        }
    }
    
    func tasksForEpic(_ epicId: UUID) -> [TaskItem] {
        tasks.filter { $0.epicId == epicId }.sorted { orderValue($0) < orderValue($1) }
    }
    
    func sortTasksByStatusForEpic(_ epicId: UUID) {
        var epicTasks = tasks.filter { $0.epicId == epicId }
        epicTasks.sort { t1, t2 in
            let c1 = isCompletedOrReported(t1), c2 = isCompletedOrReported(t2)
            if c1 != c2 { return !c1 }
            let ip1 = t1.status == .inProgress, ip2 = t2.status == .inProgress
            if ip1 != ip2 { return ip1 }
            let p1 = priorityValue(t1.priority), p2 = priorityValue(t2.priority)
            if p1 != p2 { return p1 > p2 }
            if statusSeverity(t1.status) != statusSeverity(t2.status) { return statusSeverity(t1.status) < statusSeverity(t2.status) }
            return t1.title < t2.title
        }
        for (i, task) in epicTasks.enumerated() {
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx].orderIndex = i
            }
        }
    }
    
    func addEpic(name: String) {
        epics.append(Epic(name: name))
    }
    
    func updateEpic(id: UUID, name: String) {
        guard let idx = epics.firstIndex(where: { $0.id == id }) else { return }
        epics[idx].name = name
    }
    
    func deleteEpic(_ epic: Epic) {
        epics.removeAll { $0.id == epic.id }
        for i in tasks.indices where tasks[i].epicId == epic.id {
            tasks[i].epicId = nil
        }
    }
    
    func updateTaskEpic(_ task: TaskItem, epicId: UUID?) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].epicId = epicId
    }
    
    private func priorityValue(_ p: Priority) -> Int {
        switch p {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    func moveTaskToInbox(taskId: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        guard !tasks[index].isInbox else { return }
        let inbox = tasks.filter(\.isInbox)
        let maxOrder = inbox.compactMap(\.orderIndex).max() ?? -1
        tasks[index].isInbox = true
        tasks[index].orderIndex = maxOrder + 1
    }
    
    func moveTaskToDay(taskId: UUID, date: Date) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let day = Calendar.current.startOfDay(for: date)
        let dayTasks = tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: day) && !$0.isInbox }
        let maxOrder = dayTasks.compactMap(\.orderIndex).max() ?? -1
        tasks[index].date = day
        tasks[index].isInbox = false
        tasks[index].orderIndex = maxOrder + 1
    }
    
    func assignTaskToProject(taskId: UUID, epicId: UUID?) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].epicId = epicId
    }
    
    func moveTaskToNextDay(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: tasks[index].date) {
            tasks[index].date = nextDay
            tasks[index].isInbox = false
        }
    }
    
    func updatePriority(_ task: TaskItem, priority: Priority) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].priority = priority
    }
    
    func inboxTasks() -> [TaskItem] {
        tasks.filter(\.isInbox).sorted { orderValue($0) < orderValue($1) }
    }
    
    /// Выполненные задачи (completed или reported) за указанный день
    func completedTasks(for date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter {
            ($0.status == .completed || $0.status == .reported) &&
            calendar.isDate($0.date, inSameDayAs: date)
        }.sorted { t1, t2 in
            let p1 = priorityValue(t1.priority)
            let p2 = priorityValue(t2.priority)
            if p1 == p2 { return (t1.endTime ?? t1.date) > (t2.endTime ?? t2.date) }
            return p1 > p2
        }
    }
    
    /// Выполненные задачи за неделю: все 7 дней (день -> задачи, пустые дни тоже в списке)
    func completedTasksByDay(weekStart: Date) -> [(day: Date, tasks: [TaskItem])] {
        let calendar = Calendar.current
        return (0..<7).compactMap { dayOffset -> (day: Date, tasks: [TaskItem])? in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }
            return (day: day, tasks: completedTasks(for: day))
        }
    }
    
    /// Выполненные задачи за месяц: все дни месяца (день -> задачи, пустые дни тоже в списке)
    func completedTasksByDay(monthStart: Date) -> [(day: Date, tasks: [TaskItem])] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: monthStart),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart)) else {
            return []
        }
        return (0..<range.count).compactMap { dayOffset -> (day: Date, tasks: [TaskItem])? in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: firstDay) else { return nil }
            return (day: day, tasks: completedTasks(for: day))
        }
    }
    
    func noteText(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        return notes.first(where: { calendar.isDate($0.date, inSameDayAs: day) })?.text ?? ""
    }
    
    func setNoteText(_ text: String, for date: Date) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        if let index = notes.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            guard notes[index].text != text else { return }
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notes.remove(at: index)
            } else {
                notes[index].text = text
            }
        } else {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            let newNote = NoteItem(date: day, text: text)
            notes.append(newNote)
        }
    }
}
