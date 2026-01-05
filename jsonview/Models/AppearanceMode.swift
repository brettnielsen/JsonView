import SwiftUI

enum AppearanceMode: String {
    case system
    case light
    case dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var icon: String {
        switch self {
        case .system, .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var isLight: Bool {
        self == .light || self == .system
    }
    
    func toggled() -> AppearanceMode {
        switch self {
        case .system, .light: return .dark
        case .dark: return .light
        }
    }
}
