import SwiftUI

struct WeekView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    
    @State private var contentOpacity: Double = 1.0
    @State private var contentOffset: CGFloat = 0
    
    private var currentWeekStart: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: viewModel.selectedDate)
        return calendar.date(from: components) ?? viewModel.selectedDate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { animateTransition(direction: 1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                Text(weekIntervalString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedDate)
                
                Spacer()
                
                Button(action: { animateTransition(direction: -1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            HStack(spacing: 1) {
                ForEach(0..<7) { dayOffset in
                    if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                        WeekDayCell(date: date, viewModel: viewModel)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    viewModel.selectedDate = date
                                    viewModel.activeTab = .day
                                }
                            }
                    }
                }
            }
            .background(Color.clear)
            .padding(.top, 1)
            .opacity(contentOpacity)
            .offset(x: contentOffset)
            
            Spacer()
        }
        .background(Color.clear)
        .onSwipe(left: {
            animateTransition(direction: 1)
        }, right: {
            animateTransition(direction: -1)
        })
    }
    
    private func changeWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: viewModel.selectedDate) {
            viewModel.selectedDate = newDate
        }
    }
    
    private func animateTransition(direction: Int) {
        withAnimation(.easeOut(duration: 0.15)) {
            contentOpacity = 0
            contentOffset = CGFloat(direction * -50)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            changeWeek(by: direction)
            contentOffset = CGFloat(direction * 50)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
    }
    
    private var weekIntervalString: String {
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endOfWeek))"
    }
}

struct WeekDayCell: View {
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
            
            // Task list preview
            VStack(alignment: .leading, spacing: 4) {
                let tasks = viewModel.tasksForDate(date).filter { $0.status != .discussion }
                ForEach(tasks.prefix(5)) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForTask(task))
                            .frame(width: 4, height: 4)
                        Text(task.title)
                            .font(.system(size: 10))
                            .lineLimit(1)
                                .foregroundColor(.primary.opacity(0.7))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                    .cornerRadius(2)
                }
                if tasks.count > 5 {
                    Text("+ \(tasks.count - 5) more")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            Spacer()
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
    
    private func colorForStatus(_ status: TaskStatus) -> Color {
        switch status {
        case .completed, .reported: return .green
        case .inProgress: return .blue
        case .pending, .approved, .discussion: return .gray
        }
    }
    
    private func colorForTask(_ task: TaskItem) -> Color {
        if task.status == .reported {
            return Color(red: 0.85, green: 0.65, blue: 0.13)
        }
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}
