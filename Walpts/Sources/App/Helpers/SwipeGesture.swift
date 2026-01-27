import SwiftUI
import AppKit

struct SwipeGestureModifier: ViewModifier {
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    
    func body(content: Content) -> some View {
        content
            .background(SwipeEventMonitor(onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight))
    }
}

struct SwipeEventMonitor: NSViewRepresentable {
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.setupMonitor(view: view)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onSwipeLeft = onSwipeLeft
        context.coordinator.onSwipeRight = onSwipeRight
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var onSwipeLeft: (() -> Void)?
        var onSwipeRight: (() -> Void)?
        private var monitor: Any?
        private var lastSwipeTime: Date = .distantPast
        
        func setupMonitor(view: NSView) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handleEvent(event, view: view)
                return event
            }
        }
        
        private func handleEvent(_ event: NSEvent, view: NSView) {
            // Debounce
            guard Date().timeIntervalSince(lastSwipeTime) > 0.4 else { return }
            
            // Only handle if mouse is over the view or its window is key
            guard let window = view.window, window.isKeyWindow else { return }
            
            // Check for horizontal swipe
            // Phase .began is for trackpad gestures
            // Also check for raw delta for other devices if needed, but trackpad swipe usually has phase
            if event.phase == .began || event.momentumPhase == .began {
                if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) && abs(event.scrollingDeltaX) > 2 {
                    if event.scrollingDeltaX < 0 {
                        // Swipe Left (content moves left, fingers move right) -> Next Day
                        // Note: scrollingDeltaX sign depends on "Natural Scrolling" setting. 
                        // Usually negative X means content moves left (scroll right).
                        // Let's assume standard behavior: swipe left (fingers right) -> next page
                        onSwipeLeft?()
                        lastSwipeTime = Date()
                    } else {
                        // Swipe Right (content moves right, fingers move left) -> Prev Day
                        onSwipeRight?()
                        lastSwipeTime = Date()
                    }
                }
            }
        }
        
        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}

extension View {
    func onSwipe(left: @escaping () -> Void, right: @escaping () -> Void) -> some View {
        self.modifier(SwipeGestureModifier(onSwipeLeft: left, onSwipeRight: right))
    }
}
