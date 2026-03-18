import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindowV3!
    var keyMonitor: Any?
    var chaosEngine: ChaosEngine!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        petWindow = PetWindowV3()
        petWindow.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)

        setupKeyboardMonitor()

        // 启动恶作剧引擎（30秒后开始）
        chaosEngine = ChaosEngine(petWindow: petWindow)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.chaosEngine.start()
        }
    }

    func setupKeyboardMonitor() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            self?.petWindow.onKeystroke()
        }
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.petWindow.onKeystroke()
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
