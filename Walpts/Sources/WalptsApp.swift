import SwiftUI
import AppKit

final class WalptsAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let app = NSApplication.shared
        print("[Walpts] applicationDidFinishLaunching, isActive=\(app.isActive)")
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("[Walpts] after activate, isActive=\(app.isActive)")
            if let window = app.windows.first {
                print("[Walpts] making window key and front: \(window)")
                window.level = .normal
                window.makeKeyAndOrderFront(nil)
            } else {
                print("[Walpts] no window to make key")
            }
            for window in app.windows {
                print("[Walpts] window=\(window), isKey=\(window.isKeyWindow), isMain=\(window.isMainWindow)")
            }
        }
    }
}

@main
struct WalptsApp: App {
    @NSApplicationDelegateAdaptor(WalptsAppDelegate.self) var appDelegate
    @StateObject private var viewModel = TaskViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
