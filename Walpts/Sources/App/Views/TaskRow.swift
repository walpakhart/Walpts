import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    var onNextStatus: (() -> Void)?
    var onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Rectangle()
                .fill(priorityColor.opacity(0.9))
                .frame(width: 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .strikethrough(task.status == .reported)
                    .foregroundColor(textColor)
                
                HStack(spacing: 8) {
                    Text(task.priority.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(priorityTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.12))
                        .cornerRadius(4)
                    
                    Text(statusTitle(task.status))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    if let duration = durationText {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(duration)
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let onNextStatus = onNextStatus {
                Button(action: onNextStatus) {
                    Text(statusTitle(task.status))
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
    
    private var priorityTextColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .black
        }
    }
    
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .completed, .reported:
            return .green
        case .inProgress:
            return .blue
        case .pending, .approved, .discussion:
            return .gray
        }
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
    
    private var textColor: Color {
        if task.status == .reported {
            return .gray
        }
        return .primary
    }
    
    private var durationText: String? {
        guard let start = task.startTime, let end = task.endTime else {
            return nil
        }
        let interval = max(end.timeIntervalSince(start), 0)
        let minutes = Int(interval / 60)
        if minutes < 1 {
            return "less than a minute"
        } else if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        if hours < 24 {
            let remMinutes = minutes % 60
            if remMinutes == 0 {
                return "\(hours) h"
            } else {
                return "\(hours) h \(remMinutes) min"
            }
        }
        let days = hours / 24
        let remHours = hours % 24
        if remHours == 0 {
            return "\(days) d"
        } else {
            return "\(days) d \(remHours) h"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
