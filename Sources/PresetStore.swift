import Foundation

struct PresetStore {
    let directory: URL
    let fileURL: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        directory = home
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Layout Presets")
        fileURL = directory.appendingPathComponent("presets.json")
    }

    func load() -> (presets: [LayoutPreset], error: String?) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: fileURL.path) {
            return ([], nil)
        }
        do {
            let data = try Data(contentsOf: fileURL)
            do {
                let presets = try JSONDecoder().decode([LayoutPreset].self, from: data)
                return (presets, nil)
            } catch {
                return ([], error.localizedDescription)
            }
        } catch {
            return ([], error.localizedDescription)
        }
    }

    func save(_ presets: [LayoutPreset]) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(presets)
        try data.write(to: fileURL, options: .atomic)
    }
}
