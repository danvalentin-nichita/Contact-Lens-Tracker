import SwiftUI

enum AppTheme: String, CaseIterable {
    case defaultBlue = "Default Blue"
    case green = "Green"
    case red = "Red"
    case pink = "Pink"
    case orange = "Orange"
    case yellow = "Yellow"
    case teal = "Teal"
    case ocean = "Ocean"
    case purple = "Purple"
    case midnight = "Midnight"
    case sunset = "Sunset"
    case rainbow = "Rainbow"
    
    var gradient: AnyShapeStyle {
        switch self {
        case .defaultBlue:
            return AnyShapeStyle(.linearGradient(colors: [.cyan, .blue, .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .green:
            return AnyShapeStyle(.linearGradient(colors: [.green.opacity(0.6), .green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .red:
            return AnyShapeStyle(.linearGradient(colors: [.red.opacity(0.6), .red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .pink:
            return AnyShapeStyle(.linearGradient(colors: [.pink.opacity(0.5), .pink, Color(red: 1.0, green: 0.2, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .orange:
            return AnyShapeStyle(.linearGradient(colors: [.orange.opacity(0.8), .orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .yellow:
            return AnyShapeStyle(.linearGradient(colors: [.yellow.opacity(0.8), .yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .teal:
            return AnyShapeStyle(.linearGradient(colors: [.teal.opacity(0.6), .teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .ocean:
            return AnyShapeStyle(.linearGradient(colors: [.cyan.opacity(0.6), .blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .purple:
            return AnyShapeStyle(.linearGradient(colors: [.purple.opacity(0.6), .purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .midnight:
            return AnyShapeStyle(.linearGradient(colors: [.indigo, Color(red: 0.1, green: 0.1, blue: 0.3), .black], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .sunset:
            return AnyShapeStyle(.linearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .rainbow:
            return AnyShapeStyle(.linearGradient(colors: [.red, .orange, .yellow, .green, .blue, .indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .defaultBlue: return .cyan.opacity(0.6)
        case .green: return .green.opacity(0.6)
        case .red: return .red.opacity(0.6)
        case .pink: return .pink.opacity(0.6)
        case .orange: return .orange.opacity(0.6)
        case .yellow: return .yellow.opacity(0.6)
        case .teal: return .teal.opacity(0.6)
        case .ocean: return .blue.opacity(0.6)
        case .purple: return .purple.opacity(0.6)
        case .midnight: return .indigo.opacity(0.6)
        case .sunset: return .pink.opacity(0.6)
        case .rainbow: return .yellow.opacity(0.6)
        }
    }
}
