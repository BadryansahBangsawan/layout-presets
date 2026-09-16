import AppKit
import CoreGraphics
import ApplicationServices

enum LayoutEngine {
    static func capture() throws -> (windows: [PresetWindow], missed: [MissedWindow]) {
        guard AXSupport.isTrusted(prompt: false) else {
            throw LayoutError.accessibility
        }
        var result: [PresetWindow] = []
        var missed: [MissedWindow] = []
        var seen = Set<String>()

        if let raw = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) {
            for item in raw as NSArray {
                guard let dict = item as? [String: Any] else { continue }
                let layer = (dict[kCGWindowLayer as String] as? NSNumber)?.intValue ?? -1
                guard layer == 0 else { continue }
                let name = (dict[kCGWindowName as String] as? String) ?? ""
                guard !name.isEmpty else { continue }
                let pid = pid_t((dict[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value ?? 0)
                guard pid != 0 else { continue }
                guard let app = NSRunningApplication(processIdentifier: pid),
                      let bundleId = app.bundleIdentifier,
                      !AXSupport.skipBundleIds.contains(bundleId) else { continue }

                let key = bundleId + "\u{1e}" + name
                if seen.contains(key) { continue }
                seen.insert(key)

                if let frame = AXSupport.findWindow(pid: pid, titleContains: name).flatMap(AXSupport.frame(of:)) {
                    result.append(
                        PresetWindow(
                            bundleId: bundleId,
                            titleContains: name,
                            x: frame.origin.x,
                            y: frame.origin.y,
                            w: frame.size.width,
                            h: frame.size.height
                        )
                    )
                } else if let bounds = dict[kCGWindowBounds as String] as? NSDictionary,
                          let rect = CGRect(dictionaryRepresentation: bounds) {
                    result.append(
                        PresetWindow(
                            bundleId: bundleId,
                            titleContains: name,
                            x: rect.origin.x,
                            y: rect.origin.y,
                            w: rect.size.width,
                            h: rect.size.height
                        )
                    )
                } else {
                    missed.append(
                        MissedWindow(
                            bundleId: bundleId,
                            titleContains: name,
                            reason: "Could not read frame"
                        )
                    )
                }
            }
        }

        if result.isEmpty {
            let viaAX = captureViaAX()
            result = viaAX.windows
            missed.append(contentsOf: viaAX.missed)
        }
        return (result, missed)
    }

    private static func captureViaAX() -> (windows: [PresetWindow], missed: [MissedWindow]) {
        var result: [PresetWindow] = []
        var missed: [MissedWindow] = []
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        for app in apps {
            guard let bundleId = app.bundleIdentifier, !AXSupport.skipBundleIds.contains(bundleId) else { continue }
            let pid = app.processIdentifier
            for window in AXSupport.windowElements(pid: pid) {
                let name = AXSupport.title(of: window)
                guard !name.isEmpty else { continue }
                guard let frame = AXSupport.frame(of: window) else {
                    missed.append(
                        MissedWindow(
                            bundleId: bundleId,
                            titleContains: name,
                            reason: "Could not read frame"
                        )
                    )
                    continue
                }
                result.append(
                    PresetWindow(
                        bundleId: bundleId,
                        titleContains: name,
                        x: frame.origin.x,
                        y: frame.origin.y,
                        w: frame.size.width,
                        h: frame.size.height
                    )
                )
            }
        }
        return (result, missed)
    }

    static func restore(_ preset: LayoutPreset) async -> [MissedWindow] {
        var missed: [MissedWindow] = []
        var windowCache: [pid_t: [AXWin]] = [:]
        var waited = Set<String>()

        for window in preset.windows {
            let bundleId = window.bundleId
            var app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first
            if app == nil || app?.isTerminated == true {
                if let err = await launch(bundleId: bundleId) {
                    missed.append(
                        MissedWindow(
                            bundleId: bundleId,
                            titleContains: window.titleContains,
                            reason: err
                        )
                    )
                    continue
                }
                if !waited.contains(bundleId) {
                    waited.insert(bundleId)
                    _ = await waitForWindows(bundleId: bundleId, timeout: 8)
                }
                app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first
            }
            guard let running = app, !running.isTerminated else {
                missed.append(
                    MissedWindow(
                        bundleId: bundleId,
                        titleContains: window.titleContains,
                        reason: "App did not show windows in time"
                    )
                )
                continue
            }
            let pid = running.processIdentifier
            if windowCache[pid] == nil {
                windowCache[pid] = AXSupport.windowElements(pid: pid).map {
                    AXWin(element: $0, title: AXSupport.title(of: $0), used: false)
                }
            }
            guard var list = windowCache[pid] else { continue }
            if let match = takeMatch(from: &list, titleContains: window.titleContains) {
                windowCache[pid] = list
                if !AXSupport.setFrame(match, x: window.x, y: window.y, w: window.w, h: window.h) {
                    missed.append(
                        MissedWindow(
                            bundleId: bundleId,
                            titleContains: window.titleContains,
                            reason: "Could not set position/size"
                        )
                    )
                }
            } else {
                windowCache[pid] = list
                missed.append(
                    MissedWindow(
                        bundleId: bundleId,
                        titleContains: window.titleContains,
                        reason: "Window not found"
                    )
                )
            }
        }
        return missed
    }

    private struct AXWin {
        let element: AXUIElement
        let title: String
        var used: Bool
    }

    private static func takeMatch(from windows: inout [AXWin], titleContains: String) -> AXUIElement? {
        let needle = titleContains.lowercased()
        if let idx = windows.firstIndex(where: { !$0.used && !$0.title.isEmpty && $0.title.lowercased().contains(needle) }) {
            windows[idx].used = true
            return windows[idx].element
        }
        return nil
    }

    private static func launch(bundleId: String) async -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return "No application for \(bundleId)"
        }
        do {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = false
            cfg.addsToRecentItems = false
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: cfg)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private static func waitForWindows(bundleId: String, timeout: TimeInterval) async -> pid_t? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if Task.isCancelled { return nil }
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
                let pid = app.processIdentifier
                if !AXSupport.windowElements(pid: pid).isEmpty {
                    return pid
                }
            }
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
            } catch {
                return nil
            }
        }
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first?.processIdentifier
    }
}
