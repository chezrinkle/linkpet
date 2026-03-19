import AppKit
import Foundation

// MARK: - 恶作剧引擎
class ChaosEngine {
    weak var petWindow: PetWindowV3?
    var timer: Timer?
    var footprintWindows: [NSWindow] = []
    var poopWindows: [NSWindow] = []
    var isChaosActive = false

    let minInterval: Double = 25
    let maxInterval: Double = 55

    init(petWindow: PetWindowV3) {
        self.petWindow = petWindow
    }

    // Fix-B: Timer 必须在主线程 RunLoop 上调度
    func start() {
        DispatchQueue.main.async { self.scheduleNext() }
    }
    func stop() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = nil
        }
    }

    private func scheduleNext() {
        // 已在主线程，直接用 RunLoop.main
        let delay = Double.random(in: minInterval...maxInterval)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.triggerRandomChaos()
            self?.scheduleNext()
        }
        // 安全解包，避免 timer! 强解包崩溃
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
    }

    private func triggerRandomChaos() {
        guard !isChaosActive else { return }
        switch Int.random(in: 0...3) {
        case 0: leaveFootprints()
        case 1: hijackMouse()
        case 2: openNotePad()
        default: leavePoop()
        }
    }

    // MARK: - 恶作剧1：猫爪脚印
    func leaveFootprints() {
        guard let screen = NSScreen.main,
              let pet = petWindow else { return }
        isChaosActive = true
        petWindow?.showChaosMessage("嘻嘻，我要去溜达了～")

        let startX = pet.frame.midX
        let startY = pet.frame.midY
        let targetX = CGFloat.random(in: 80...screen.frame.width - 80)
        let targetY = CGFloat.random(in: 80...screen.frame.height - 80)
        // Fix-C: steps >= 2 才能安全做除法
        let steps = 12
        guard steps >= 2 else { isChaosActive = false; return }

        for i in 0..<steps {
            let delay = Double(i) * 0.22
            let progress = CGFloat(i) / CGFloat(steps - 1)
            let x = startX + (targetX - startX) * progress + CGFloat.random(in: -15...15)
            let y = startY + (targetY - startY) * progress + CGFloat.random(in: -15...15)
            let isRight = (i % 2 == 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.spawnFootprint(at: CGPoint(x: x, y: y), isRight: isRight)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.22 + 5.0) { [weak self] in
            self?.clearFootprints()
            self?.isChaosActive = false
        }
    }

    private func spawnFootprint(at point: CGPoint, isRight: Bool) {
        let size: CGFloat = 28
        let win = makeOverlayWindow(
            rect: NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size),
            ignoresMouse: true)

        let label = NSTextField(labelWithString: "🐾")
        label.frame = NSRect(x: 0, y: 0, width: size, height: size)
        label.font = .systemFont(ofSize: 20)
        label.alignment = .center
        win.contentView?.addSubview(label)
        label.wantsLayer = true
        if !isRight, let layer = label.layer {
            layer.transform = CATransform3DMakeScale(-1, 1, 1)
        }

        win.orderFront(nil)
        footprintWindows.append(win)
        win.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            win.animator().alphaValue = 1
        }
    }

    private func clearFootprints() {
        let wins = footprintWindows
        footprintWindows.removeAll()
        fadeOutAndClose(wins)
    }

    // MARK: - 恶作剧2：劫持鼠标
    func hijackMouse() {
        guard let screen = NSScreen.main else { return }
        isChaosActive = true
        petWindow?.showChaosMessage("哈哈！鼠标是我的！😈")

        let corners: [CGPoint] = [
            CGPoint(x: 10,                      y: 10),
            CGPoint(x: screen.frame.width - 10, y: 10),
            CGPoint(x: 10,                      y: screen.frame.height - 10),
            CGPoint(x: screen.frame.width - 10, y: screen.frame.height - 10),
        ]
        let target = corners.randomElement()!
        let steps = 20
        let startPos = NSEvent.mouseLocation  // Cocoa 坐标（左下原点）
        for i in 1...steps {
            let delay = Double(i) * 0.035
            let t = CGFloat(i) / CGFloat(steps)
            let nx = startPos.x + (target.x - startPos.x) * t
            let ny = startPos.y + (target.y - startPos.y) * t
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                ChaosEngine.warpTo(x: nx, y: ny, screenH: screen.frame.height)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.035 + 2.0) { [weak self] in
            self?.petWindow?.showChaosMessage("好啦好啦，还你！😏")
            ChaosEngine.warpTo(x: screen.frame.width / 2,
                               y: screen.frame.height / 2,
                               screenH: screen.frame.height)
            self?.isChaosActive = false
        }
    }

    /// Cocoa(左下原点) → CGWarpMouseCursorPosition(左上原点)
    private static func warpTo(x: CGFloat, y: CGFloat, screenH: CGFloat) {
        CGWarpMouseCursorPosition(CGPoint(x: x, y: screenH - y))
    }

    // MARK: - 恶作剧3：自动写字
    func openNotePad() {
        isChaosActive = true
        petWindow?.showChaosMessage("让我给主人写点东西～ 📝")

        let messages = [
            "主人你好呀！我是招财猫，记得多打字哦！",
            "今日运势：大吉！继续努力！",
            "喵～ 我偷偷来这里留个爪印",
            "主人！你已经工作很久了，该摸摸我了！",
            "福气值还不够！快去打字！",
        ]
        let raw  = messages.randomElement()!
        let safe = raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
            tell application "TextEdit"
                activate
                make new document
                set text of front document to "\(safe)"
            end tell
        """
        // Fix-D: 子线程跑 Process，避免卡主线程
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            try? task.run()
            task.waitUntilExit()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.isChaosActive = false
        }
    }

    // MARK: - 恶作剧4：随机💩
    func leavePoop() {
        guard let screen = NSScreen.main else { return }
        isChaosActive = true
        petWindow?.showChaosMessage("嘿嘿，给你个惊喜！💩")

        let poopCount = Int.random(in: 2...5)
        for i in 0..<poopCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) { [weak self] in
                let x = CGFloat.random(in: 60...screen.frame.width - 60)
                let y = CGFloat.random(in: 60...screen.frame.height - 80)
                self?.spawnPoop(at: CGPoint(x: x, y: y))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.clearPoops()
            self?.isChaosActive = false
        }
    }

    private func spawnPoop(at point: CGPoint) {
        let size: CGFloat = 36
        let win = makeOverlayWindow(
            rect: NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size),
            ignoresMouse: false)

        let btn = NSButton(frame: NSRect(x: 0, y: 0, width: size, height: size))
        btn.title = "💩"
        btn.font = .systemFont(ofSize: 24)
        btn.isBordered = false
        btn.bezelStyle = .shadowlessSquare
        btn.target = self
        btn.action = #selector(poopClicked(_:))
        win.contentView?.addSubview(btn)
        objc_setAssociatedObject(btn, &AssocKey.window, win, .OBJC_ASSOCIATION_RETAIN)

        win.orderFront(nil)
        poopWindows.append(win)
        win.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            win.animator().alphaValue = 1
        }
    }

    private func clearPoops() {
        let wins = poopWindows
        poopWindows.removeAll()
        fadeOutAndClose(wins)
    }

    @objc private func poopClicked(_ sender: NSButton) {
        if let win = objc_getAssociatedObject(sender, &AssocKey.window) as? NSWindow {
            poopWindows.removeAll { $0 === win }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                win.animator().alphaValue = 0
            }, completionHandler: { win.orderOut(nil) })
            petWindow?.showChaosMessage("哈！被你发现了！😹")
        }
    }

    // MARK: - 公开：立刻整蛊
    func triggerChaosNow() {
        isChaosActive = false
        triggerRandomChaos()
    }

    // MARK: - 工具
    private func makeOverlayWindow(rect: NSRect, ignoresMouse: Bool) -> NSWindow {
        let win = NSWindow(contentRect: rect, styleMask: [.borderless],
                           backing: .buffered, defer: false)
        win.level = .floating
        win.isOpaque = false
        win.backgroundColor = .clear
        win.ignoresMouseEvents = ignoresMouse
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        return win
    }

    private func fadeOutAndClose(_ wins: [NSWindow]) {
        for win in wins {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.5
                win.animator().alphaValue = 0
            }, completionHandler: { win.orderOut(nil) })
        }
    }
}

private enum AssocKey {
    static var window = "window"
}
