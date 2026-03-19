import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindowV3!
    var keyMonitor: Any?
    var localKeyMonitor: Any?
    var chaosEngine: ChaosEngine!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        petWindow = PetWindowV3()
        petWindow.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)
        setupKeyboardMonitor()
        chaosEngine = ChaosEngine(petWindow: petWindow)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.chaosEngine.start()
        }
    }

    func setupKeyboardMonitor() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            self?.petWindow.onKeystroke()
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.petWindow.onKeystroke()
            return event
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // 退出时移除 monitor，防止内存泄漏
        if let m = keyMonitor      { NSEvent.removeMonitor(m); keyMonitor = nil }
        if let m = localKeyMonitor { NSEvent.removeMonitor(m); localKeyMonitor = nil }
        chaosEngine.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
