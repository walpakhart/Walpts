import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var task: TaskItem
    
    @State private var newSubtaskTitle = ""
    @State private var isEditingTitle = false
    @State private var showCalendar = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "en_US")
        return f
    }
    
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 0.8
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.deleteTask(task)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                Button("Close") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 0.8
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismiss()
                    }
                }
            }
            
            HStack(alignment: .center, spacing: 16) {
                HStack {
                    Text("Status:")
                    Menu {
                        Button("Discussion") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.updateStatus(for: task, to: .discussion)
                            }
                        }
                        Button("To do") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.updateStatus(for: task, to: .pending)
                            }
                        }
                        Button("Approved") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.updateStatus(for: task, to: .approved)
                            }
                        }
                        Button("In progress") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.updateStatus(for: task, to: .inProgress)
                            }
                        }
                        Button("Done") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.updateStatus(for: task, to: .completed)
                            }
                        }
                        Button("Reported") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.updateStatus(for: task, to: .reported)
                            }
                        }
                    } label: {
                        Text(statusTitle(task.status))
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.status)
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
            
            HStack(alignment: .center, spacing: 20) {
                HStack(alignment: .center, spacing: 12) {
                    Text("Date")
                        .font(.headline)
                        .frame(width: 44, alignment: .leading)
                    Button(action: { showCalendar = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                            Text(dateFormatter.string(from: task.date))
                                .font(.system(size: 14))
                        }
                        .frame(minWidth: 140, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showCalendar, arrowEdge: .bottom) {
                        DatePicker("", selection: $task.date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .frame(width: 280, height: 260)
                            .padding(8)
                    }
                }
                
                Toggle(isOn: $task.isInbox) {
                    Text("Inbox")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .toggleStyle(.switch)
                .help("Someday (Inbox)")
                
                Button("Move to tomorrow") {
                    viewModel.moveTaskToNextDay(task)
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes / Description")
                    .font(.headline)
                TextEditor(text: Binding(
                    get: { task.notes ?? "" },
                    set: { newValue in
                        var copy = task
                        copy.notes = newValue.isEmpty ? nil : newValue
                        task = copy
                    }
                ))
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60, maxHeight: 120)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
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
        .frame(width: 500, height: 620)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
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
