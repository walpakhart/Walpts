import SwiftUI

struct CreateTaskView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @Binding var isPresented: Bool
    var date: Date?
    var isInbox: Bool = false
    
    @State private var title = ""
    @State private var taskType: TaskType = .work
    @State private var priority: Priority = .medium
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New task")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Type", selection: $taskType) {
                ForEach(TaskType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            TextField("Task title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            Picker("Priority", selection: $priority) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Text(priority.rawValue).tag(priority)
                }
            }
            
            HStack {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 0.8
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPresented = false
                    }
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create") {
                    if isInbox {
                        viewModel.addInboxTask(title: title, type: taskType, priority: priority)
                    } else if let date = date {
                        viewModel.addTask(title: title, type: taskType, date: date, priority: priority)
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 0.8
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 380, height: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
