import Foundation

struct PresetWindow: Codable, Equatable, Hashable {
    var bundleId: String
    var titleContains: String
    var x: Double
    var y: Double
    var w: Double
    var h: Double
}

struct LayoutPreset: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var projectPath: String?
    var windows: [PresetWindow]
}

struct MissedWindow: Identifiable, Equatable {
    let id = UUID()
    var bundleId: String
    var titleContains: String
    var reason: String
}

enum LayoutError: LocalizedError {
    case accessibility
    case message(String)

    var errorDescription: String? {
        switch self {
        case .accessibility:
            return "Accessibility access is required to capture and restore windows."
        case .message(let text):
            return text
        }
    }
}
