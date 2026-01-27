import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var task: TaskItem
    
    @State private var newSubtaskTitle = ""
    @State private var isEditingTitle = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if isEditingTitle {
                    TextField("Task title", text: $task.title)
                        .font(.title2)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            isEditingTitle = false
                        }
                    
                    Button(action: { isEditingTitle = false }) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(task.title)
                        .font(.title2)
                    
                    Button(action: { isEditingTitle = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit title")
                }
                
                Spacer()
                Button("Delete") {
                    viewModel.deleteTask(task)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                Button("Close") {
                    dismiss()
                }
            }
            
            HStack(alignment: .center, spacing: 16) {
                HStack {
                    Text("Status:")
                    Menu {
                        Button("Discussion") {
                            viewModel.updateStatus(for: task, to: .discussion)
                        }
                        Button("To do") {
                            viewModel.updateStatus(for: task, to: .pending)
                        }
                        Button("Approved") {
                            viewModel.updateStatus(for: task, to: .approved)
                        }
                        Button("In progress") {
                            viewModel.updateStatus(for: task, to: .inProgress)
                        }
                        Button("Done") {
                            viewModel.updateStatus(for: task, to: .completed)
                        }
                        Button("Reported") {
                            viewModel.updateStatus(for: task, to: .reported)
                        }
                    } label: {
                        Text(statusTitle(task.status))
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("Priority:")
                    Menu {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Button(p.rawValue) {
                                task.priority = p
                            }
                        }
                    } label: {
                        Text(task.priority.rawValue)
                    }
                }
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.headline)
                    DatePicker("", selection: $task.date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .frame(maxWidth: 260, maxHeight: 240)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Someday (Inbox)", isOn: $task.isInbox)
                        .toggleStyle(.switch)
                    
                    Button("Move to tomorrow") {
                        viewModel.moveTaskToNextDay(task)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            
            Divider()
            
            Text("Subtasks")
                .font(.headline)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($task.subtasks) { $subtask in
                        SubtaskRowView(subtask: $subtask, onDelete: {
                            if let index = task.subtasks.firstIndex(where: { $0.id == subtask.id }) {
                                task.subtasks.remove(at: index)
                            }
                        })
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 180)
            
            HStack {
                TextField("New subtask", text: $newSubtaskTitle)
                    .textFieldStyle(.roundedBorder)
                Button(action: addSubtask) {
                    Image(systemName: "plus")
                }
                .disabled(newSubtaskTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 520)
    }
    
    private func addSubtask() {
        let newSub = SubTask(title: newSubtaskTitle)
        task.subtasks.append(newSub)
        newSubtaskTitle = ""
    }
    
    private func statusTitle(_ status: TaskStatus) -> String {
        switch status {
        case .discussion:
            return "Discussion"
        case .pending:
            return "To do"
        case .approved:
            return "Approved"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Done"
        case .reported:
            return "Reported"
        }
    }
}

struct SubtaskRowView: View {
    @Binding var subtask: SubTask
    var onDelete: () -> Void
    
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            Image(systemName: subtask.isCompleted ? "checkmark.square" : "square")
                .onTapGesture {
                    subtask.isCompleted.toggle()
                }
            
            if isEditing {
                TextField("Subtask", text: $subtask.title)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        isEditing = false
                    }
                
                Button(action: { isEditing = false }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            } else {
                Text(subtask.title)
                    .strikethrough(subtask.isCompleted)
                    .onTapGesture(count: 2) { // Double tap to edit
                        isEditing = true
                    }
                
                if !subtask.isCompleted {
                    Button(action: { isEditing = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.03))
        .cornerRadius(8)
    }
}
