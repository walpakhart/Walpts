import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("calendarNotificationsEnabled") private var calendarNotificationsEnabled = false
    @AppStorage("notify15Min") private var notify15Min = true
    @AppStorage("notify5Min") private var notify5Min = true
    
    @AppStorage("showAllDayEvents") private var showAllDayEvents = false
    @AppStorage("calendarFilterExclude") private var calendarFilterExclude = ""
    @AppStorage("calendarFilterInclude") private var calendarFilterInclude = ""
    
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                Text("Preferences")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.bottom, 8)
                
                // Appearance Section
                SettingsSection(title: "Appearance", icon: "paintpalette.fill") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .toggleStyle(.switch)
                }
                
                // Calendar View Section
                SettingsSection(title: "Calendar View", icon: "calendar") {
                    Toggle("Show All-Day Events (e.g. Vacations)", isOn: $showAllDayEvents)
                        .toggleStyle(.switch)
                    
                    Divider().padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Exclude Words")
                            .font(.system(size: 13, weight: .medium))
                        Text("Hide events containing these words (comma separated)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        TextField("e.g. Lunch, Gym", text: $calendarFilterExclude)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Include Words")
                            .font(.system(size: 13, weight: .medium))
                        Text("If not empty, only events with these words are shown")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        TextField("e.g. Sync, Meeting", text: $calendarFilterInclude)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Notifications Section
                SettingsSection(title: "Calendar Notifications", icon: "bell.fill") {
                    Toggle("Enable Event Alerts", isOn: $calendarNotificationsEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: calendarNotificationsEnabled) { _, _ in
                            calendarManager.syncNotifications()
                        }
                    
                    if calendarNotificationsEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Remind 15 minutes before", isOn: $notify15Min)
                                .toggleStyle(.switch)
                                .onChange(of: notify15Min) { _, _ in
                                    calendarManager.syncNotifications()
                                }
                            Toggle("Remind 5 minutes before", isOn: $notify5Min)
                                .toggleStyle(.switch)
                                .onChange(of: notify5Min) { _, _ in
                                    calendarManager.syncNotifications()
                                }
                        }
                        .padding(.leading, 12)
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
            }
            .padding(40)
            .frame(maxWidth: 700, alignment: .leading)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
    }
}
