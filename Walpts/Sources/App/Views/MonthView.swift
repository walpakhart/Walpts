import SwiftUI

struct MonthView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    
    private var currentMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: viewModel.selectedDate)
        return calendar.date(from: components) ?? viewModel.selectedDate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            HStack(spacing: 1) {
                ForEach(0..<7) { index in
                    Text(calendarDays[index])
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary.opacity(0.5))
                }
            }
            .background(.clear)
            
            let days = daysInMonth()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
            
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(0..<firstWeekdayOffset(), id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fill)
                }
                
                ForEach(days, id: \.self) { date in
                    MonthDayCell(date: date, viewModel: viewModel)
                        .aspectRatio(1, contentMode: .fill)
                        .onTapGesture {
                            viewModel.selectedDate = date
                            viewModel.activeTab = .day
                        }
                }
            }
            .background(Color.clear)
            .padding(.top, 1)
            
            Spacer()
        }
        .background(Color.clear)
        .onSwipe(left: {
            withAnimation { changeMonth(by: 1) }
        }, right: {
            withAnimation { changeMonth(by: -1) }
        })
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: viewModel.selectedDate) {
            viewModel.selectedDate = newDate
        }
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private var calendarDays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortStandaloneWeekdaySymbols
    }
    
    private func daysInMonth() -> [Date] {
        let range = Calendar.current.range(of: .day, in: .month, for: currentMonth)!
        return range.compactMap { day -> Date? in
            Calendar.current.date(byAdding: .day, value: day - 1, to: currentMonth)
        }
    }
    
    private func firstWeekdayOffset() -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        let firstDayOfMonth = Calendar.current.date(from: components)!
        // 1 = Sunday, 2 = Monday...
        // We want 0 for Monday (if week starts on Monday)
        let weekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        // Assuming Monday start for RU locale
        return (weekday + 5) % 7
    }
}

struct MonthDayCell: View {
    let date: Date
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 12))
                .foregroundColor(Calendar.current.isDateInToday(date) ? .primary : .primary.opacity(0.8))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Calendar.current.isDateInToday(date) ? Color.blue.opacity(0.08) : Color.clear)
                )
            
            // Dots for tasks
            let tasks = viewModel.tasksForDate(date).filter { $0.status != .discussion }
            if !tasks.isEmpty {
                HStack(spacing: 2) {
                    ForEach(tasks.prefix(3)) { task in
                        Circle()
                            .fill(colorForTask(task))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(4)
        .background(.ultraThinMaterial)
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

extension Array {
    func rotated(shiftingToStart index: Int) -> Array {
        var array = self
        if index > 0 && index < count {
            let slice = array[0..<index]
            array.removeFirst(index)
            array.append(contentsOf: slice)
        }
        return array
    }
}
