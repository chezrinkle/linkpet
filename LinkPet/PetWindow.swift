import AppKit
import SwiftUI
import Combine

class PetWindow: NSWindow {
    private var viewModel: PetViewModel
    private var isDragging = false
    private var dragStartWindowPos: CGPoint = .zero
    private var dragStartMousePos: CGPoint = .zero
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: PetViewModel) {
        self.viewModel = viewModel

        super.init(
            contentRect: NSRect(x: 200, y: 200, width: 200, height: 160),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let hostingView = NSHostingView(rootView: PetView(viewModel: viewModel))
        hostingView.frame = self.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        self.contentView = hostingView

        viewModel.$position
            .receive(on: RunLoop.main)
            .sink { [weak self] pos in self?.updateWindowPosition(to: pos) }
            .store(in: &cancellables)
    }

    private func updateWindowPosition(to pos: CGPoint) {
        guard let screen = NSScreen.main else { return }
        let sf = screen.frame
        let wx = pos.x - self.frame.width / 2
        let wy = sf.height - pos.y - self.frame.height / 2
        self.setFrameOrigin(NSPoint(x: wx, y: wy))
    }

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        dragStartWindowPos = self.frame.origin
        dragStartMousePos = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let cur = NSEvent.mouseLocation
        let dx = cur.x - dragStartMousePos.x
        let dy = cur.y - dragStartMousePos.y
        let newOrigin = NSPoint(x: dragStartWindowPos.x + dx, y: dragStartWindowPos.y + dy)
        self.setFrameOrigin(newOrigin)

        guard let screen = NSScreen.main else { return }
        let sf = screen.frame
        let cx = newOrigin.x + self.frame.width / 2
        let cy = sf.height - newOrigin.y - self.frame.height / 2
        viewModel.onDrag(to: CGPoint(x: cx, y: cy))
    }

    override func mouseUp(with event: NSEvent) { isDragging = false }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
