import SwiftUI

struct AllTasksView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var selectedTask: TaskItem?
    
    private var allTasks: [TaskItem] {
        viewModel.allTasksSorted()
    }
    
    private func epicName(for epicId: UUID?) -> String? {
        guard let id = epicId else { return nil }
        return viewModel.epics.first { $0.id == id }?.name
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("All tasks")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    withAnimation { viewModel.sortAllTasksByStatus() }
                }) {
                    Label("Sort by status", systemImage: "arrow.up.arrow.down.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                Text("\(allTasks.count)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            List {
                if allTasks.isEmpty {
                    Section {
                        Text("No tasks yet")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(allTasks) { task in
                            VStack(alignment: .leading, spacing: 2) {
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
                                if let name = epicName(for: task.epicId) {
                                    Text(name)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 28)
                                }
                            }
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
