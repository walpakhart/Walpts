import Foundation

enum TaskType: String, Codable, CaseIterable {
    case work = "Work"
    case discussion = "Discussion"
}

enum TaskStatus: String, Codable {
    case discussion = "Discussion"
    case pending = "Pending"
    case approved = "Approved"
    case inProgress = "In Progress"
    case completed = "Completed"
    case reported = "Reported"
}

enum Priority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct SubTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
}

struct TaskItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var type: TaskType
    var status: TaskStatus = .discussion
    var priority: Priority = .medium
    var date: Date
    var isInbox: Bool = false
    
    var startTime: Date?
    var endTime: Date?
    
    var subtasks: [SubTask] = []
}

struct NoteItem: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var text: String
}
