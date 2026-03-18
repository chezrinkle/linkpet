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
            contentRect: NSRect(x: 200, y: 200, width: 220, height: 180),
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
        self.acceptsMouseMovedEvents = true

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

    // MARK: - 拖动（关键修复）
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
        let newOrigin = NSPoint(
            x: dragStartWindowPos.x + dx,
            y: dragStartWindowPos.y + dy
        )
        self.setFrameOrigin(newOrigin)

        // 同步 ViewModel 坐标
        guard let screen = NSScreen.main else { return }
        let sf = screen.frame
        let cx = newOrigin.x + self.frame.width / 2
        let cy = sf.height - newOrigin.y - self.frame.height / 2
        DispatchQueue.main.async {
            self.viewModel.position = CGPoint(x: cx, y: cy)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            isDragging = false
            viewModel.showSpeech("呀！飞起来了！")
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}


// MARK: - 脚印窗口
class FootprintWindow: NSWindow {
    init(position: CGPoint) {
        let size = CGFloat(28)
        guard let screen = NSScreen.main else {
            super.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
            return
        }
        let sf = screen.frame
        let wx = position.x - size / 2
        let wy = sf.height - position.y - size / 2

        super.init(
            contentRect: NSRect(x: wx, y: wy, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let hosting = NSHostingView(rootView: FootprintView())
        hosting.frame = self.contentView!.bounds
        self.contentView = hosting
        self.makeKeyAndOrderFront(nil)
    }

    func fadeOut(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 1.0
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            completion()
        })
    }
}
