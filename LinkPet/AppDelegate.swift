import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var petWindow: PetWindow!
    var petViewModel: PetViewModel!
    var footprintWindows: [FootprintWindow] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        petViewModel = PetViewModel()
        petViewModel.onSpawnFootprint = { [weak self] pos in
            self?.spawnFootprint(at: pos)
        }
        petWindow = PetWindow(viewModel: petViewModel)
        petWindow.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func spawnFootprint(at pos: CGPoint) {
        DispatchQueue.main.async {
            let fw = FootprintWindow(position: pos)
            self.footprintWindows.append(fw)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                fw.fadeOut {
                    self?.footprintWindows.removeAll { $0 === fw }
                }
            }
        }
    }
}
