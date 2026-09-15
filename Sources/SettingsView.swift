import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var loginError: String?
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Toggle("Open at Login", isOn: Binding(
                    get: { openAtLogin },
                    set: { newValue in
                        do {
                            loginError = nil
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            openAtLogin = SMAppService.mainApp.status == .enabled
                        } catch {
                            loginError = error.localizedDescription
                            openAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                ))
                if let loginError {
                    Label(loginError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section {
                if model.axTrusted {
                    Label("Accessibility allowed", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Accessibility is required to read and set window frames.")
                    Button("Enable Accessibility") {
                        model.refreshTrust(prompt: true)
                    }
                }
            }

            Section {
                Button("Quit Layout Presets") {
                    NSApp.terminate(nil)
                }
            }
        }
        .frame(width: FunTheme.panelWidth)
        .padding(12)
        .onAppear {
            openAtLogin = SMAppService.mainApp.status == .enabled
            model.axTrusted = AXSupport.isTrusted(prompt: false)
        }
    }
}
