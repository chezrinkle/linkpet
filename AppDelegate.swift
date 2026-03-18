import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindow!
    var petViewModel: PetViewModel!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        petViewModel = PetViewModel()
        petWindow = PetWindow(viewModel: petViewModel)
        petWindow.makeKeyAndOrderFront(nil)
        
        // 隐藏 Dock 图标，做成纯桌面宠物
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
