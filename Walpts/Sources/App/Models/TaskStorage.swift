import Foundation

final class TaskStorage {
    static let shared = TaskStorage()
    
    private let fileURL: URL
    private let queue = DispatchQueue(label: "TaskStorageQueue", qos: .background)
    
    private init() {
        let fileManager = FileManager.default
        let baseDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let appDir = baseDir.appendingPathComponent("Walpts", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        fileURL = appDir.appendingPathComponent("tasks.json")
    }
    
    func load() -> [TaskItem] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([TaskItem].self, from: data)
        } catch {
            return []
        }
    }
    
    func save(_ tasks: [TaskItem]) {
        queue.async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(tasks)
                try data.write(to: self.fileURL, options: .atomic)
            } catch {
            }
        }
    }
}

final class NoteStorage {
    static let shared = NoteStorage()
    
    private let fileURL: URL
    private let queue = DispatchQueue(label: "NoteStorageQueue", qos: .background)
    
    private init() {
        let fileManager = FileManager.default
        let baseDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let appDir = baseDir.appendingPathComponent("Walpts", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        fileURL = appDir.appendingPathComponent("notes.json")
    }
    
    func load() -> [NoteItem] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([NoteItem].self, from: data)
        } catch {
            return []
        }
    }
    
    func save(_ notes: [NoteItem]) {
        queue.async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(notes)
                try data.write(to: self.fileURL, options: .atomic)
            } catch {
            }
        }
    }
}
