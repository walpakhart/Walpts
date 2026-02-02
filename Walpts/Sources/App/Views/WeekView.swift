import SwiftUI

struct WeekView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var anchorDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday Headers
            HStack(spacing: 1) {
                ForEach(0..<7) { index in
                    Text(calendarDays[index])
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary.opacity(0.5))
                }
            }
            .background(.regularMaterial)
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(-24...24, id: \.self) { offset in
                            WeekMonthSection(monthOffset: offset, anchorDate: anchorDate, viewModel: viewModel)
                                .id(offset)
                        }
                    }
                }
                .onAppear {
                    scrollToSelectedDate(proxy: proxy)
                }
                .onChange(of: viewModel.selectedDate) { _, _ in
                    // Optional: scroll on external change
                }
            }
        }
        .background(Color.clear)
    }
    
    private func scrollToSelectedDate(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        // Find week start for selected date
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: viewModel.selectedDate)
        guard let weekStart = calendar.date(from: components) else { return }
        
        // Find month difference based on weekStart's month
        let anchorComponents = calendar.dateComponents([.year, .month], from: anchorDate)
        guard let anchorMonthStart = calendar.date(from: anchorComponents) else { return }
        
        let targetComponents = calendar.dateComponents([.year, .month], from: weekStart)
        guard let targetMonthStart = calendar.date(from: targetComponents) else { return }
        
        let diffComponents = calendar.dateComponents([.month], from: anchorMonthStart, to: targetMonthStart)
        
        if let monthDiff = diffComponents.month {
            proxy.scrollTo(monthDiff, anchor: .top)
        }
    }
    
    private var calendarDays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortStandaloneWeekdaySymbols
    }
}

struct WeekMonthSection: View {
    let monthOffset: Int
    let anchorDate: Date
    @ObservedObject var viewModel: TaskViewModel
    
    private var currentMonth: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: anchorDate) ?? anchorDate
    }
    
    var body: some View {
        // Only show section if there are weeks in it?
        // Yes, but let's calculate first.
        let weeks = weeksInMonth()
        
        if !weeks.isEmpty {
            Section(header: WeekMonthHeader(title: monthString)) {
                VStack(spacing: 1) {
                    ForEach(weeks, id: \.self) { weekStart in
                        WeekRow(weekStart: weekStart, viewModel: viewModel)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private func weeksInMonth() -> [Date] {
        let calendar = Calendar.current
        
        // Start of month
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        var weeks: [Date] = []
        
        // If startOfMonth is not start of week (Monday), we need to find the first Monday >= startOfMonth
        // But wait, "Week belongs to month of its start date".
        // So we look for weeks where weekStart.month == currentMonth.
        
        // Find the start of the week for startOfMonth
        let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfMonth)
        var weekStart = calendar.date(from: weekComponents)!
        
        // If this weekStart is in previous month, skip it
        // Check if weekStart < startOfMonth
        if weekStart < startOfMonth {
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }
        
        // Now iterate adding weeks while weekStart is in currentMonth
        while calendar.isDate(weekStart, equalTo: startOfMonth, toGranularity: .month) {
            weeks.append(weekStart)
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }
        
        return weeks
    }
}

struct WeekMonthHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.vertical, 8)
            Spacer()
        }
        .background(.ultraThinMaterial)
    }
}

struct WeekRow: View {
    let weekStart: Date
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<7) { dayOffset in
                if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart) {
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
                            .strikethrough(task.status == .reported)
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
            return .purple
        }
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}
