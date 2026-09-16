import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    private static let defaultsPrefix = "engineer.badry.layoutpresets."
    private static let lastRestoredKey = "engineer.badry.layoutpresets.lastRestoredId"

    @Published var presets: [LayoutPreset] = []
    @Published var loadError: String?
    @Published var actionError: String?
    @Published var missed: [MissedWindow] = []
    @Published var isRestoring = false
    @Published var suggested: LayoutPreset?
    @Published var axTrusted = false
    @Published var showSaveSheet = false
    @Published var saveName = ""
    @Published var saveProjectPath = ""

    private let store = PresetStore()
    private var monitor: SuggestionMonitor?
    private var loopTask: Task<Void, Never>?

    init() {
        let loaded = store.load()
        presets = loaded.presets
        loadError = loaded.error
        axTrusted = AXSupport.isTrusted(prompt: false)
        monitor = SuggestionMonitor { [weak self] in
            Task { @MainActor in
                self?.refreshSuggestion()
            }
        }
        monitor?.update(paths: presets.compactMap(\.projectPath))
        loopTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.axTrusted = AXSupport.isTrusted(prompt: false)
                self.refreshSuggestion()
                do {
                    try await Task.sleep(nanoseconds: 1_500_000_000)
                } catch {
                    return
                }
            }
        }
    }

    deinit {
        loopTask?.cancel()
    }

    func refreshTrust(prompt: Bool) {
        axTrusted = AXSupport.isTrusted(prompt: false)
        if !axTrusted {
            AXSupport.openAccessibilitySettings()
        }
    }

    func relaunch() {
        AXSupport.relaunch()
    }

    func beginSave() {
        actionError = nil
        saveName = ""
        saveProjectPath = ""
        showSaveSheet = true
    }

    func cancelSave() {
        showSaveSheet = false
    }

    func chooseProjectPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Optional project folder for suggestions"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        saveProjectPath = url.path
    }

    func confirmSave() {
        let name = saveName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            actionError = "Name is required."
            return
        }
        guard axTrusted || AXSupport.isTrusted(prompt: false) else {
            axTrusted = false
            actionError = LayoutError.accessibility.localizedDescription
            AXSupport.openAccessibilitySettings()
            return
        }
        axTrusted = true
        do {
            let captured = try LayoutEngine.capture()
            missed = captured.missed
            if captured.windows.isEmpty {
                actionError = "No capturable windows."
                return
            }
            let path = saveProjectPath.trimmingCharacters(in: .whitespacesAndNewlines)
            let preset = LayoutPreset(
                id: UUID(),
                name: name,
                projectPath: path.isEmpty ? nil : path,
                windows: captured.windows
            )
            presets.append(preset)
            try persist()
            showSaveSheet = false
            actionError = nil
        } catch {
            actionError = error.localizedDescription
        }
    }

    func restore(_ preset: LayoutPreset) {
        guard !isRestoring else { return }
        guard axTrusted || AXSupport.isTrusted(prompt: false) else {
            axTrusted = false
            actionError = LayoutError.accessibility.localizedDescription
            AXSupport.openAccessibilitySettings()
            return
        }
        axTrusted = true
        isRestoring = true
        actionError = nil
        missed = []
        Task { [weak self] in
            let missedWindows = await LayoutEngine.restore(preset)
            guard let self else { return }
            self.missed = missedWindows
            self.isRestoring = false
            UserDefaults.standard.set(preset.id.uuidString, forKey: Self.lastRestoredKey)
        }
    }

    func delete(_ preset: LayoutPreset) {
        presets.removeAll { $0.id == preset.id }
        if suggested?.id == preset.id {
            suggested = nil
        }
        do {
            try persist()
            actionError = nil
        } catch {
            actionError = error.localizedDescription
        }
    }

    func refreshSuggestion() {
        guard !isRestoring else { return }
        guard let doc = AXSupport.frontmostDocumentPath() else {
            if suggested != nil { suggested = nil }
            return
        }
        let match = presets.first { preset in
            guard let root = preset.projectPath, !root.isEmpty else { return false }
            return AXSupport.path(doc, isUnder: root)
        }
        if suggested?.id != match?.id {
            suggested = match
        }
    }

    private func persist() throws {
        try store.save(presets)
        monitor?.update(paths: presets.compactMap(\.projectPath))
    }
}
