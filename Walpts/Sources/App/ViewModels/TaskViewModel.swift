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
    }
    
    func addTask(title: String, type: TaskType, date: Date, priority: Priority = .medium) {
        let status: TaskStatus = type == .discussion ? .discussion : .pending
        let newTask = TaskItem(title: title, type: type, status: status, priority: priority, date: Calendar.current.startOfDay(for: date), isInbox: false)
        tasks.append(newTask)
    }
    
    func addInboxTask(title: String, type: TaskType, priority: Priority = .medium) {
        let today = Calendar.current.startOfDay(for: Date())
        let status: TaskStatus = type == .discussion ? .discussion : .pending
        let newTask = TaskItem(title: title, type: type, status: status, priority: priority, date: today, isInbox: true)
        tasks.append(newTask)
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func updateStatus(for task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updatedTask = tasks[index]
        
        switch updatedTask.status {
        case .discussion:
            updatedTask.status = .pending
            updatedTask.startTime = nil
            updatedTask.endTime = nil
            let day = Calendar.current.startOfDay(for: selectedDate)
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
        case .completed:
            updatedTask.status = .reported
        case .reported:
            break
        }
        
        tasks[index] = updatedTask
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
        tasks[index] = updatedTask
    }
    
    func tasksForDate(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        let filtered = tasks.filter { calendar.isDate($0.date, inSameDayAs: date) && !$0.isInbox }
        
        // Сортировка: Высокий -> Средний -> Низкий приоритет
        return filtered.sorted { t1, t2 in
            let p1 = priorityValue(t1.priority)
            let p2 = priorityValue(t2.priority)
            if p1 == p2 {
                return t1.title < t2.title
            }
            return p1 > p2
        }
    }

    func discussionTasks() -> [TaskItem] {
        let filtered = tasks.filter { $0.status == .discussion && !$0.isInbox }
        return filtered.sorted { t1, t2 in
            let p1 = priorityValue(t1.priority)
            let p2 = priorityValue(t2.priority)
            if p1 == p2 {
                return t1.title < t2.title
            }
            return p1 > p2
        }
    }
    
    private func priorityValue(_ p: Priority) -> Int {
        switch p {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
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
        tasks.filter { $0.isInbox }
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
            notes[index].text = text
        } else {
            let newNote = NoteItem(date: day, text: text)
            notes.append(newNote)
        }
    }
}
