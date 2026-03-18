import AppKit
import SwiftUI

class PetWindow: NSWindow {
    private var viewModel: PetViewModel
    private var isDragging = false
    private var dragStartWindowPos: CGPoint = .zero
    private var dragStartMousePos: CGPoint = .zero

    init(viewModel: PetViewModel) {
        self.viewModel = viewModel

        super.init(
            contentRect: NSRect(x: 200, y: 200, width: 200, height: 160),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // 关键属性：悬浮在所有窗口之上
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // SwiftUI 内容
        let hostingView = NSHostingView(rootView: PetView(viewModel: viewModel))
        hostingView.frame = self.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        self.contentView = hostingView

        // 监听位置变化，同步窗口
        viewModel.$position
            .receive(on: RunLoop.main)
            .sink { [weak self] pos in
                self?.updateWindowPosition(to: pos)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable?>()

    private func updateWindowPosition(to pos: CGPoint) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        // SwiftUI 坐标（左上角原点）→ Cocoa 坐标（左下角原点）
        let windowX = pos.x - self.frame.width / 2
        let windowY = screenFrame.height - pos.y - self.frame.height / 2
        self.setFrameOrigin(NSPoint(x: windowX, y: windowY))
    }

    // 拖动支持
    override func mouseDown(with event: NSEvent) {
        isDragging = true
        dragStartWindowPos = self.frame.origin
        dragStartMousePos = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let currentMouse = NSEvent.mouseLocation
        let dx = currentMouse.x - dragStartMousePos.x
        let dy = currentMouse.y - dragStartMousePos.y
        let newOrigin = NSPoint(x: dragStartWindowPos.x + dx, y: dragStartWindowPos.y + dy)
        self.setFrameOrigin(newOrigin)

        // 同步 viewModel 位置（Cocoa → SwiftUI 坐标）
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let centerX = newOrigin.x + self.frame.width / 2
        let centerY = screenFrame.height - newOrigin.y - self.frame.height / 2
        viewModel.onDrag(to: CGPoint(x: centerX, y: centerY))
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }

    // 点击穿透逻辑：只捕获宠物区域
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// Combine 导入补充
import Combine
