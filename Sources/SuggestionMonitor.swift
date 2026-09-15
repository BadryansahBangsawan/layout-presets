import AppKit
import CoreServices
import Foundation

/// Watches preset project paths. File changes never auto-restore.
final class SuggestionMonitor {
    private var stream: FSEventStreamRef?
    private let onEvent: () -> Void
    private var observer: NSObjectProtocol?

    init(onEvent: @escaping () -> Void) {
        self.onEvent = onEvent
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onEvent()
        }
    }

    deinit {
        stop()
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func update(paths: [String]) {
        stop()
        let existing = paths.filter { !$0.isEmpty && FileManager.default.fileExists(atPath: $0) }
        guard !existing.isEmpty else { return }

        var ctx = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let monitor = Unmanaged<SuggestionMonitor>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async {
                monitor.onEvent()
            }
        }
        guard let created = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &ctx,
            existing as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        ) else {
            return
        }
        stream = created
        FSEventStreamSetDispatchQueue(created, DispatchQueue.main)
        FSEventStreamStart(created)
    }

    private func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
}
