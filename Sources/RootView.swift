import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
                if let loadError = model.loadError {
                    Label(loadError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let actionError = model.actionError {
                    Label(actionError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !model.axTrusted {
                    VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                        Text("Accessibility is required to capture and restore window frames.")
                            .fixedSize(horizontal: false, vertical: true)
                        Text("If the switch is already on, turn it off and on, then Relaunch.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Button("Enable Accessibility") {
                                model.refreshTrust(prompt: false)
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Relaunch") {
                                model.relaunch()
                            }
                        }
                    }
                }

                if let suggested = model.suggested, !model.isRestoring {
                    Button {
                        model.restore(suggested)
                    } label: {
                        Label("Suggested: \(suggested.name)", systemImage: "sparkle")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if model.showSaveSheet {
                    saveForm
                } else if model.presets.isEmpty {
                    VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                        Text("No presets")
                            .font(.headline)
                        if !model.axTrusted {
                            Text("Accessibility is required to capture frames.")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Name a layout, then restore it later.")
                                .foregroundStyle(.secondary)
                        }
                        Button("Save current as…") {
                            model.beginSave()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.axTrusted)
                    }
                } else {
                    Text("Presets")
                        .font(.headline)
                    ForEach(model.presets) { preset in
                        presetRow(preset)
                    }
                }

                if model.isRestoring {
                    ProgressView("Restoring…")
                }

                if !model.missed.isEmpty {
                    Text("Missed")
                        .font(.headline)
                    ForEach(model.missed) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.titleContains)
                                .lineLimit(1)
                            Text("\(item.bundleId) — \(item.reason)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !model.showSaveSheet && !model.presets.isEmpty {
                    Button("Save current as…") {
                        model.beginSave()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!model.axTrusted || model.isRestoring)
                }

                ExtraSettingsFooter()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 480)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.presets.count)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.missed.count)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.suggested?.id)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.showSaveSheet)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.isRestoring)
        .funPanel()
    }

    private var saveForm: some View {
        VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
            Text("Save current as…")
                .font(.headline)
            TextField("Name", text: $model.saveName)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("Project path (optional)", text: $model.saveProjectPath)
                    .textFieldStyle(.roundedBorder)
                Button("Choose…") {
                    model.chooseProjectPath()
                }
            }
            HStack {
                Button("Cancel") {
                    model.cancelSave()
                }
                Button("Save") {
                    model.confirmSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.saveName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func presetRow(_ preset: LayoutPreset) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(preset.name)
                .fontWeight(.medium)
            if let path = preset.projectPath, !path.isEmpty {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Text("\(preset.windows.count) windows")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack {
                Button("Restore") {
                    model.restore(preset)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isRestoring || !model.axTrusted)
                Button("Delete", role: .destructive) {
                    model.delete(preset)
                }
                .buttonStyle(.bordered)
                .disabled(model.isRestoring)
            }
        }
        .extraRowSurface()
    }
}
