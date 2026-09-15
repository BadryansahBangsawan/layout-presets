import AppKit
import ApplicationServices

enum AXSupport {
    static let skipBundleIds: Set<String> = [
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.dock",
        "engineer.badry.layoutpresets"
    ]

    static func isTrusted(prompt: Bool) -> Bool {
        if prompt {
            return AXIsProcessTrustedWithOptions(
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            )
        }
        return AXIsProcessTrusted()
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    static func copy(_ element: AXUIElement, _ attribute: CFString) -> CFTypeRef? {
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute, &ref)
        guard err == .success else { return nil }
        return ref
    }

    static func stringValue(_ element: AXUIElement, _ attribute: CFString) -> String? {
        copy(element, attribute) as? String
    }

    static func asElement(_ value: Any) -> AXUIElement? {
        let ref = value as CFTypeRef
        guard CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(ref, to: AXUIElement.self)
    }

    static func windowElements(pid: pid_t) -> [AXUIElement] {
        let app = AXUIElementCreateApplication(pid)
        guard let ref = copy(app, kAXWindowsAttribute as CFString) else { return [] }
        guard let ns = ref as? NSArray else { return [] }
        return ns.compactMap { asElement($0) }
    }

    static func title(of window: AXUIElement) -> String {
        stringValue(window, kAXTitleAttribute as CFString) ?? ""
    }

    static func point(_ element: AXUIElement, _ attribute: CFString) -> CGPoint? {
        guard let ref = copy(element, attribute) else { return nil }
        guard CFGetTypeID(ref) == AXValueGetTypeID() else { return nil }
        let ax = unsafeBitCast(ref, to: AXValue.self)
        var value = CGPoint.zero
        guard AXValueGetValue(ax, .cgPoint, &value) else { return nil }
        return value
    }

    static func size(_ element: AXUIElement, _ attribute: CFString) -> CGSize? {
        guard let ref = copy(element, attribute) else { return nil }
        guard CFGetTypeID(ref) == AXValueGetTypeID() else { return nil }
        let ax = unsafeBitCast(ref, to: AXValue.self)
        var value = CGSize.zero
        guard AXValueGetValue(ax, .cgSize, &value) else { return nil }
        return value
    }

    static func frame(of window: AXUIElement) -> CGRect? {
        guard let origin = point(window, kAXPositionAttribute as CFString),
              let dim = size(window, kAXSizeAttribute as CFString) else { return nil }
        return CGRect(origin: origin, size: dim)
    }

    static func findWindow(pid: pid_t, titleContains: String) -> AXUIElement? {
        let needle = titleContains.lowercased()
        for window in windowElements(pid: pid) {
            let t = title(of: window)
            if !t.isEmpty, t.lowercased().contains(needle) {
                return window
            }
        }
        return nil
    }

    static func setFrame(_ window: AXUIElement, x: Double, y: Double, w: Double, h: Double) -> Bool {
        var pos = CGPoint(x: x, y: y)
        var dim = CGSize(width: w, height: h)
        guard let posVal = AXValueCreate(.cgPoint, &pos),
              let sizeVal = AXValueCreate(.cgSize, &dim) else { return false }
        let r1 = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
        let r2 = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
        _ = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
        return r1 == .success && r2 == .success
    }

    static func documentPath(of window: AXUIElement) -> String? {
        guard let raw = stringValue(window, kAXDocumentAttribute as CFString), !raw.isEmpty else {
            return nil
        }
        if let url = URL(string: raw), url.isFileURL {
            return url.path
        }
        if raw.hasPrefix("file://"), let url = URL(string: raw) {
            return url.path
        }
        if raw.hasPrefix("/") {
            return raw
        }
        return raw
    }

    static func frontmostDocumentPath() -> String? {
        guard let front = NSWorkspace.shared.frontmostApplication else { return nil }
        if let bid = front.bundleIdentifier, skipBundleIds.contains(bid) { return nil }
        let pid = front.processIdentifier
        let app = AXUIElementCreateApplication(pid)
        if let focused = copy(app, kAXFocusedWindowAttribute as CFString),
           let win = asElement(focused),
           let path = documentPath(of: win) {
            return path
        }
        for window in windowElements(pid: pid) {
            if let path = documentPath(of: window) {
                return path
            }
        }
        return nil
    }

    static func path(_ path: String, isUnder root: String) -> Bool {
        let p = URL(fileURLWithPath: path).standardizedFileURL.path
        var r = URL(fileURLWithPath: root).standardizedFileURL.path
        if p == r { return true }
        if !r.hasSuffix("/") { r += "/" }
        return p.hasPrefix(r)
    }
}
