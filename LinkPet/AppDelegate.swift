import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindowV3!
    var keyMonitor: Any?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        petWindow = PetWindowV3()
        petWindow.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)

        // 全局键盘监听（需要辅助功能权限）
        setupKeyboardMonitor()
    }

    func setupKeyboardMonitor() {
        // 先尝试无需权限的 local monitor，再尝试 global
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            self?.petWindow.onKeystroke()
        }
        // 也监听本地（当 app 在前台时）
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.petWindow.onKeystroke()
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
