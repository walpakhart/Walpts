import SwiftUI

struct CompletedView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var period: CompletedPeriod = .week
    @State private var selectedTask: TaskItem?
    
    enum CompletedPeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    private var calendar: Calendar { Calendar.current }
    
    private var todayStart: Date {
        calendar.startOfDay(for: Date())
    }
    
    private var weekStart: Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: comps) ?? Date()
    }
    
    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps) ?? Date()
    }
    
    private var sections: [(day: Date, tasks: [TaskItem])] {
        switch period {
        case .day:
            let tasks = viewModel.completedTasks(for: todayStart)
            return [(day: todayStart, tasks: tasks)]
        case .week:
            return viewModel.completedTasksByDay(weekStart: weekStart)
        case .month:
            return viewModel.completedTasksByDay(monthStart: monthStart)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMMM"
        return f
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text("Completed")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 8) {
                    Text("Period")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Picker("", selection: $period) {
                        Label("Day", systemImage: "calendar.day")
                            .tag(CompletedPeriod.day)
                        Label("Week", systemImage: "calendar")
                            .tag(CompletedPeriod.week)
                        Label("Month", systemImage: "calendar.badge.clock")
                            .tag(CompletedPeriod.month)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .labelsHidden()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if sections.isEmpty {
                        Text("No completed tasks")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(sections, id: \.day) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dateFormatter.string(from: section.day))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                if section.tasks.isEmpty {
                                    Text("No completed tasks")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .padding(.vertical, 4)
                                } else {
                                    ForEach(section.tasks) { task in
                                        TaskRow(
                                            task: task,
                                            onNextStatus: nil,
                                            onTap: { selectedTask = task }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
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
