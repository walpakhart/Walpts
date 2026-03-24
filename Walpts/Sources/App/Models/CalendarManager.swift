import Foundation
import EventKit
import Combine
import SwiftUI
import UserNotifications

class CalendarManager: ObservableObject {
    @Published var events: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    let eventStore = EKEventStore()
    
    init() {
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if self.authorizationStatus == .authorized || self.authorizationStatus == .fullAccess {
            // Already authorized
        } else if self.authorizationStatus == .notDetermined {
            requestAccess()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(eventStoreChanged), name: .EKEventStoreChanged, object: eventStore)
        syncNotifications()
    }
    
    @objc private func eventStoreChanged() {
        DispatchQueue.main.async {
            self.syncNotifications()
        }
    }
    
    func requestAccess() {
        print("[CalendarManager] Requesting calendar access...")
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    print("[CalendarManager] requestFullAccessToEvents granted: \(granted), error: \(String(describing: error))")
                    self?.authorizationStatus = granted ? .fullAccess : .denied
                    self?.syncNotifications()
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    print("[CalendarManager] requestAccess granted: \(granted), error: \(String(describing: error))")
                    self?.authorizationStatus = granted ? .authorized : .denied
                    self?.syncNotifications()
                }
            }
        }
    }
    
    func fetchEvents(for date: Date) -> [EKEvent] {
        guard authorizationStatus == .authorized || authorizationStatus == .fullAccess else {
            print("[CalendarManager] Fetch aborted. Status is: \(authorizationStatus.rawValue)")
            return []
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else { return [] }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let foundEvents = eventStore.events(matching: predicate)
        let filtered = filterEvents(foundEvents)
        print("[CalendarManager] Fetched \(filtered.count) events (excluded/included via filters) for \(date)")
        
        return filtered.sorted { $0.startDate < $1.startDate }
    }
    
    private func filterEvents(_ events: [EKEvent]) -> [EKEvent] {
        let showAllDay = UserDefaults.standard.bool(forKey: "showAllDayEvents")
        let excludeStr = UserDefaults.standard.string(forKey: "calendarFilterExclude") ?? ""
        let includeStr = UserDefaults.standard.string(forKey: "calendarFilterInclude") ?? ""
        
        let excludeList = excludeStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
        let includeList = includeStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
        
        return events.filter { event in
            if !showAllDay && event.isAllDay { return false }
            
            let title = (event.title ?? "").lowercased()
            
            for ex in excludeList {
                if title.contains(ex) { return false }
            }
            
            if !includeList.isEmpty {
                var matchesInclude = false
                for inc in includeList {
                    if title.contains(inc) {
                        matchesInclude = true
                        break
                    }
                }
                if !matchesInclude { return false }
            }
            
            return true
        }
    }
    
    func syncNotifications() {
        let isEnabled = UserDefaults.standard.bool(forKey: "calendarNotificationsEnabled")
        let center = UNUserNotificationCenter.current()
        
        if isEnabled {
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                if granted {
                    self.scheduleNotifications()
                }
            }
        } else {
            center.removeAllPendingNotificationRequests()
        }
    }
    
    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        guard authorizationStatus == .authorized || authorizationStatus == .fullAccess else { return }
        
        let now = Date()
        guard let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return }
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: nil)
        let foundEvents = eventStore.events(matching: predicate)
        let events = filterEvents(foundEvents)
        
        // Settings defaults to true if not set
        let notify15 = UserDefaults.standard.object(forKey: "notify15Min") as? Bool ?? true
        let notify5 = UserDefaults.standard.object(forKey: "notify5Min") as? Bool ?? true
        
        for event in events {
            if notify15 {
                scheduleNotification(for: event, offset: -15 * 60, identifierSuffix: "15m")
            }
            if notify5 {
                scheduleNotification(for: event, offset: -5 * 60, identifierSuffix: "5m")
            }
        }
    }
    
    private func scheduleNotification(for event: EKEvent, offset: TimeInterval, identifierSuffix: String) {
        let triggerDate = event.startDate.addingTimeInterval(offset)
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = event.title ?? "Event"
        let minutes = Int(abs(offset) / 60)
        content.body = "Starts in \(minutes) minutes"
        content.sound = .default
        
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        guard let eventId = event.eventIdentifier else { return }
        let request = UNNotificationRequest(identifier: "\(eventId)-\(identifierSuffix)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
