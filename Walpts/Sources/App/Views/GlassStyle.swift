import SwiftUI

struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: CGFloat = 0.2
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Материал размытия (основа стекла)
                    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                        .opacity(0.6)
                    
                    // Белый полупрозрачный слой для "молочного" эффекта
                    Color.white.opacity(opacity)
                    
                    // Градиентный блик сверху слева
                    LinearGradient(
                        gradient: Gradient(colors: [.white.opacity(0.4), .clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .cornerRadius(cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.1),
                                .black.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Обертка для NSVisualEffectView для использования в SwiftUI
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

extension View {
    func glass(cornerRadius: CGFloat = 20, opacity: CGFloat = 0.1) -> some View {
        self.modifier(GlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// Компонент фона для всего приложения
struct LiquidBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color("BackgroundColor") // Нужно добавить в Assets или использовать системный
                .ignoresSafeArea()
            
            // Плавающие "пузыри"
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 400, height: 400)
                        .blur(radius: 60)
                        .offset(x: animate ? -100 : 100, y: animate ? -100 : 100)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.4))
                        .frame(width: 300, height: 300)
                        .blur(radius: 50)
                        .offset(x: animate ? 200 : -200, y: animate ? 200 : -200)
                    
                    Circle()
                        .fill(Color.cyan.opacity(0.3))
                        .frame(width: 350, height: 350)
                        .blur(radius: 40)
                        .offset(x: animate ? -200 : 200, y: animate ? 300 : -100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black.opacity(0.05)) // Легкая подложка
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
