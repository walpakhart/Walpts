import SwiftUI

struct ProjectView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    let epicId: UUID
    var onDeleteProject: (() -> Void)?
    @State private var selectedTask: TaskItem?
    @State private var isEditingName = false
    @State private var editedName = ""
    
    private var epic: Epic? {
        viewModel.epics.first { $0.id == epicId }
    }
    
    private var projectTasks: [TaskItem] {
        viewModel.tasksForEpic(epicId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let epic = epic {
                    if isEditingName {
                        TextField("Project name", text: $editedName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .onSubmit {
                                viewModel.updateEpic(id: epicId, name: editedName)
                                isEditingName = false
                            }
                        Button(action: {
                            viewModel.updateEpic(id: epicId, name: editedName)
                            isEditingName = false
                        }) {
                            Image(systemName: "checkmark")
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Text(epic.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Button(action: {
                            editedName = epic.name
                            isEditingName = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                } else {
                    Text("Project")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                Spacer()
                if onDeleteProject != nil, epic != nil {
                    Button(role: .destructive, action: {
                        if let e = epic {
                            viewModel.deleteEpic(e)
                            onDeleteProject?()
                        }
                    }) {
                        Label("Delete project", systemImage: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            List {
                if projectTasks.isEmpty {
                    Section {
                        Text("No tasks in this project")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(projectTasks) { task in
                            TaskRow(
                                task: task,
                                onNextStatus: {
                                    withAnimation {
                                        viewModel.updateStatus(for: task)
                                    }
                                },
                                onRevertStatus: {
                                    withAnimation {
                                        viewModel.revertStatus(for: task)
                                    }
                                },
                                onTap: {
                                    selectedTask = task
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color(nsColor: .textBackgroundColor))
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .sheet(item: $selectedTask) { task in
            if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                TaskDetailView(task: $viewModel.tasks[index])
            } else {
                Text("Task not found")
            }
        }
    }
}
