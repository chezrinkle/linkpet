import Cocoa
import SwiftUI
import WebKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindowLive2D!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        petWindow = PetWindowLive2D()
        petWindow.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
