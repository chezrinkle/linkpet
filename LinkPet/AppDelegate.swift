import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindow!
    var petViewModel: PetViewModel!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        petViewModel = PetViewModel()
        petWindow = PetWindow(viewModel: petViewModel)
        petWindow.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
