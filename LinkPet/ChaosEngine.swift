import AppKit
import Foundation

// MARK: - 恶作剧引擎
class ChaosEngine {
    weak var petWindow: PetWindowV3?
    var timer: Timer?
    var footprintWindows: [NSWindow] = []
    var isChaosActive = false

    // 恶作剧冷却（秒）
    let minInterval: Double = 25
    let maxInterval: Double = 55

    init(petWindow: PetWindowV3) {
        self.petWindow = petWindow
    }

    func start() {
        scheduleNext()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleNext() {
        let delay = Double.random(in: minInterval...maxInterval)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.triggerRandomChaos()
            self?.scheduleNext()
        }
    }

    // MARK: - 随机选择一个恶作剧
    private func triggerRandomChaos() {
        guard !isChaosActive else { return }
        let roll = Int.random(in: 0...3)
        switch roll {
        case 0: leaveFootprints()
        case 1: hijackMouse()
        case 2: openNotePad()
        default: leavePoop()
        }
    }

    // MARK: - 恶作剧1：留下猫爪脚印（从猫咪位置走向随机方向）
    func leaveFootprints() {
        guard let screen = NSScreen.main,
              let pet = petWindow else { return }
        isChaosActive = true

        petWindow?.showChaosMessage("嘻嘻，我要去溜达了～")

        var startX = pet.frame.midX
        var startY = pet.frame.midY
        let targetX = CGFloat.random(in: 80...screen.frame.width - 80)
        let targetY = CGFloat.random(in: 80...screen.frame.height - 80)
        let steps = 12

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

        // 清除脚印
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.22 + 5.0) { [weak self] in
            self?.clearFootprints()
            self?.isChaosActive = false
        }
    }

    private func spawnFootprint(at point: CGPoint, isRight: Bool) {
        let size: CGFloat = 28
        let win = NSWindow(
            contentRect: NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .floating
        win.isOpaque = false
        win.backgroundColor = .clear
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let label = NSTextField(labelWithString: isRight ? "🐾" : "🐾")
        label.frame = NSRect(x: 0, y: 0, width: size, height: size)
        label.font = .systemFont(ofSize: 20)
        label.alignment = .center
        label.wantsLayer = true
        // 左右脚镜像
        if !isRight {
            label.layer?.transform = CATransform3DMakeScale(-1, 1, 1)
        }
        win.contentView?.addSubview(label)
        win.makeKeyAndOrderFront(nil)
        win.orderFront(nil)
        footprintWindows.append(win)

        // 淡入
        win.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            win.animator().alphaValue = 1
        }
    }

    private func clearFootprints() {
        let wins = footprintWindows
        footprintWindows.removeAll()
        for win in wins {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.6
                win.animator().alphaValue = 0
            }, completionHandler: {
                win.orderOut(nil)
            })
        }
    }

    // MARK: - 恶作剧2：叼走鼠标（把鼠标强制移到角落）
    func hijackMouse() {
        guard let screen = NSScreen.main else { return }
        isChaosActive = true
        petWindow?.showChaosMessage("哈哈！鼠标是我的！😈")

        let corners: [CGPoint] = [
            CGPoint(x: 10, y: 10),
            CGPoint(x: screen.frame.width - 10, y: 10),
            CGPoint(x: 10, y: screen.frame.height - 10),
            CGPoint(x: screen.frame.width - 10, y: screen.frame.height - 10),
        ]
        let target = corners.randomElement()!

        // 逐步移动鼠标（动画感）
        let steps = 20
        let startPos = NSEvent.mouseLocation
        for i in 1...steps {
            let delay = Double(i) * 0.035
            let t = CGFloat(i) / CGFloat(steps)
            let nx = startPos.x + (target.x - startPos.x) * t
            let ny = startPos.y + (target.y - startPos.y) * t
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // CGWarpMouseCursorPosition 坐标系：左上为原点
                let flippedY = screen.frame.height - ny
                CGWarpMouseCursorPosition(CGPoint(x: nx, y: flippedY))
            }
        }

        // 在角落停留2秒后放回
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps)*0.035 + 2.0) { [weak self] in
            self?.petWindow?.showChaosMessage("好啦好啦，还你！😏")
            // 移回中央
            let cx = screen.frame.width / 2
            let cy = screen.frame.height / 2
            CGWarpMouseCursorPosition(CGPoint(x: cx, y: cy))
            self?.isChaosActive = false
        }
    }

    // MARK: - 恶作剧3：自动打开记事本写字
    func openNotePad() {
        isChaosActive = true
        petWindow?.showChaosMessage("让我给主人写点东西～ 📝")

        let messages = [
            "主人你好呀！我是招财猫，记得多打字哦！🪙",
            "今日运势：大吉！继续努力！✨",
            "喵～ 我偷偷来这里留个爪印 🐾",
            "主人！你已经工作很久了，该摸摸我了！",
            "福气值还不够！快去打字！💪",
        ]
        let msg = messages.randomElement()!

        // 用 osascript 打开 TextEdit 并写字
        let script = """
            tell application "TextEdit"
                activate
                make new document
                set text of front document to "\(msg)"
            end tell
        """
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        try? task.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.isChaosActive = false
        }
    }

    // MARK: - 恶作剧4：在随机位置留下💩
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

        // 10秒后消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.clearFootprints() // 同一个数组
            self?.isChaosActive = false
        }
    }

    private func spawnPoop(at point: CGPoint) {
        let size: CGFloat = 36
        let win = NSWindow(
            contentRect: NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .floating
        win.isOpaque = false
        win.backgroundColor = .clear
        win.ignoresMouseEvents = false // 可以点击消除
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let btn = NSButton(frame: NSRect(x: 0, y: 0, width: size, height: size))
        btn.title = "💩"
        btn.font = .systemFont(ofSize: 24)
        btn.isBordered = false
        btn.bezelStyle = .inline
        // 点击消除
        btn.target = self
        btn.action = #selector(poopClicked(_:))
        win.contentView?.addSubview(btn)
        objc_setAssociatedObject(btn, &AssocKey.window, win, .OBJC_ASSOCIATION_RETAIN)

        win.makeKeyAndOrderFront(nil)
        win.orderFront(nil)
        footprintWindows.append(win)

        // 弹跳进入动画
        win.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            win.animator().alphaValue = 1
        }
    }

    @objc private func poopClicked(_ sender: NSButton) {
        if let win = objc_getAssociatedObject(sender, &AssocKey.window) as? NSWindow {
            footprintWindows.removeAll { $0 === win }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                win.animator().alphaValue = 0
            }, completionHandler: { win.orderOut(nil) })
            petWindow?.showChaosMessage("哈！被你发现了！😹")
        }
    }

    // 供外部调用：手动触发恶作剧
    func triggerChaosNow() {
        isChaosActive = false // 强制允许
        triggerRandomChaos()
    }
}

// MARK: - 关联对象 Key
private enum AssocKey {
    static var window = "window"
}
