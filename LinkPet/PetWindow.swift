import AppKit
import WebKit
import ServiceManagement

// MARK: - WeakScriptHandler（防 retain cycle）
private class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(ucc, didReceive: message)
    }
}

// MARK: - 核心修复：拖动+事件容器视图
// WKWebView 作为 contentView 会完全消费鼠标事件。
// DragContainerView 作为 contentView，在 NSView 层拦截所有鼠标事件。
class DragContainerView: NSView {
    weak var petWindow: PetWindowV3?
    private let dragThresholdY: CGFloat = 72   // 底部面板高度

    // MARK: 左键：猫身区域拖动
    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        if loc.y > dragThresholdY {
            petWindow?.beginDrag(event)
        } else {
            super.mouseDown(with: event)
        }
    }
    override func mouseDragged(with event: NSEvent) {
        if petWindow?.isDragging == true {
            petWindow?.continueDrag(event)
        } else {
            super.mouseDragged(with: event)
        }
    }
    override func mouseUp(with event: NSEvent) {
        petWindow?.endDrag()
        super.mouseUp(with: event)
    }

    // MARK: 右键：完全拦截，交给 PetWindow 弹菜单（绕开 WKWebView 的"重新载入"菜单）
    override func rightMouseDown(with event: NSEvent) {
        petWindow?.showContextMenuFromEvent(event)
    }
    override func rightMouseUp(with event: NSEvent) { /* 吞掉，防止 WKWebView 再处理 */ }

    // MARK: 基础设置
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // 返回 nil 让 WKWebView 不显示系统右键菜单
    override func menu(for event: NSEvent) -> NSMenu? { nil }
}

// MARK: - 主窗口
class PetWindowV3: NSWindow, WKNavigationDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    var containerView: DragContainerView!
    var isDragging = false
    var dragStartWindowPos: CGPoint = .zero
    var dragStartMousePos: CGPoint = .zero

    var karma: Int {
        get { UserDefaults.standard.integer(forKey: "linkpet_karma") }
        set { UserDefaults.standard.set(newValue, forKey: "linkpet_karma") }
    }
    var isAutoLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: "linkpet_autolaunch") }
        set { UserDefaults.standard.set(newValue, forKey: "linkpet_autolaunch") }
    }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces]
        setupViews()
        placeOnScreen()
    }

    private func placeOnScreen() {
        guard let screen = NSScreen.main else { return }
        let x = screen.frame.width - 220
        let y = screen.frame.height * 0.3
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func setupViews() {
        let winFrame = NSRect(x: 0, y: 0, width: 200, height: 300)

        // 1. 容器视图作为 contentView
        containerView = DragContainerView(frame: winFrame)
        containerView.petWindow = self
        containerView.autoresizingMask = [.width, .height]
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        self.contentView = containerView

        // 2. WKWebView 作为子视图（不再是 contentView）
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let ucc = WKUserContentController()
        ucc.add(WeakScriptHandler(self), name: "petBridge")
        config.userContentController = ucc
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: winFrame, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        // 禁用 WKWebView 内建右键菜单（"重新载入"等），改由 DragContainerView 接管
        webView.configuration.preferences.setValue(false, forKey: "developerExtrasEnabled")

        containerView.addSubview(webView)

        let html = buildPetHTML(initialKarma: karma)
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    // MARK: - 拖动（由 DragContainerView 调用）
    func beginDrag(_ event: NSEvent) {
        isDragging = true
        dragStartWindowPos = self.frame.origin
        dragStartMousePos = NSEvent.mouseLocation
    }

    func continueDrag(_ event: NSEvent) {
        let cur = NSEvent.mouseLocation
        self.setFrameOrigin(NSPoint(
            x: dragStartWindowPos.x + cur.x - dragStartMousePos.x,
            y: dragStartWindowPos.y + cur.y - dragStartMousePos.y
        ))
    }

    func endDrag() {
        isDragging = false
    }

    // MARK: - JS Bridge
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        let action = body["action"] as? String ?? ""
        switch action {
        case "saveKarma":
            if let k = body["karma"] as? Int { karma = k }
        case "showMenu":
            showContextMenu()
        case "dance":
            startDanceWiggle()
        default:
            break
        }
    }

    // MARK: - 键击
    func onKeystroke() {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("onKeystroke()", completionHandler: nil)
        }
    }

    // MARK: - 恶作剧消息
    func showChaosMessage(_ text: String) {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("showBubble('\(escaped)', 3500)", completionHandler: nil)
        }
    }

    // MARK: - 跳舞摇摆
    private func startDanceWiggle() {
        let offsets: [CGFloat] = [8, -8, 6, -6, 4, -4, 2, -2, 0]
        for (i, dx) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.11) { [weak self] in
                guard let self = self else { return }
                let cur = self.frame.origin
                self.setFrameOrigin(NSPoint(x: cur.x + dx, y: cur.y))
            }
        }
    }

    // MARK: - 右键菜单入口（由 DragContainerView 调用）
    func showContextMenuFromEvent(_ event: NSEvent) {
        showContextMenu()
    }

    // MARK: - 右键菜单（完整功能版）
    private func showContextMenu() {
        let menu = NSMenu()

        // —— 互动 ——
        menu.addItem(makeHeader("✨ 互动"))
        menu.addItem(withTitle: "🐱 戳一戳", action: #selector(doPoke), keyEquivalent: "")
        menu.addItem(withTitle: "🤚 摸摸头", action: #selector(doStroke), keyEquivalent: "")
        menu.addItem(withTitle: "💃 跳舞", action: #selector(doDance), keyEquivalent: "")
        menu.addItem(withTitle: "😄 触发开心", action: #selector(doHappy), keyEquivalent: "")

        menu.addItem(NSMenuItem.separator())

        // —— 道具 ——
        menu.addItem(makeHeader("🎒 道具"))
        menu.addItem(withTitle: "🔮 求签（消耗50福气）", action: #selector(doFortune), keyEquivalent: "")
        menu.addItem(withTitle: "🍬 喂零食（+20福气）", action: #selector(doFeed), keyEquivalent: "")
        menu.addItem(withTitle: "🎀 换装衣橱", action: #selector(doWardrobe), keyEquivalent: "")
        menu.addItem(withTitle: "📜 查看签文历史", action: #selector(doHistory), keyEquivalent: "")

        menu.addItem(NSMenuItem.separator())

        // —— 整蛊 ——
        menu.addItem(makeHeader("😈 整蛊"))
        menu.addItem(withTitle: "😈 随机整蛊", action: #selector(doChaosRandom), keyEquivalent: "")
        menu.addItem(withTitle: "🐾 留猫爪脚印", action: #selector(doChaosFootprints), keyEquivalent: "")
        menu.addItem(withTitle: "🖱️ 劫持鼠标", action: #selector(doChaosHijack), keyEquivalent: "")
        menu.addItem(withTitle: "📝 偷偷写字", action: #selector(doChaosNotepad), keyEquivalent: "")
        menu.addItem(withTitle: "💩 丢💩炸弹", action: #selector(doChaosPoop), keyEquivalent: "")

        menu.addItem(NSMenuItem.separator())

        // —— 窗口层级 ——
        menu.addItem(makeHeader("🪟 窗口层级"))
        let topTitle = (self.level == .floating) ? "✅ 置顶显示（当前）" : "⬆️ 置顶显示"
        let normalTitle = (self.level == .normal) ? "✅ 普通层级（当前）" : "↔️ 普通层级"
        let bottomTitle = (self.level.rawValue <= NSWindow.Level.desktopIcon.rawValue) ? "✅ 置底显示（当前）" : "⬇️ 置底显示"
        menu.addItem(withTitle: topTitle,    action: #selector(setLevelTop),    keyEquivalent: "")
        menu.addItem(withTitle: normalTitle, action: #selector(setLevelNormal), keyEquivalent: "")
        menu.addItem(withTitle: bottomTitle, action: #selector(setLevelBottom), keyEquivalent: "")

        menu.addItem(NSMenuItem.separator())

        // —— 设置 ——
        menu.addItem(makeHeader("⚙️ 设置"))
        let autoTitle = isAutoLaunch ? "✅ 开机自启（已开启）" : "🔲 开机自启（已关闭）"
        menu.addItem(withTitle: autoTitle, action: #selector(toggleAutoLaunch), keyEquivalent: "")
        menu.addItem(withTitle: "🔄 重置福气值", action: #selector(doResetKarma), keyEquivalent: "")
        menu.addItem(withTitle: "❌ 退出 LinkPet", action: #selector(doQuit), keyEquivalent: "")

        for item in menu.items { item.target = self }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    /// 创建不可点击的分组标题
    private func makeHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - 互动 Actions
    @objc func doPoke()   { webView.evaluateJavaScript("onPoke(null)", completionHandler: nil) }
    @objc func doStroke() { webView.evaluateJavaScript("onStroke()", completionHandler: nil) }
    @objc func doDance()  { webView.evaluateJavaScript("doDance()", completionHandler: nil) }
    @objc func doHappy()  { webView.evaluateJavaScript("triggerHappy()", completionHandler: nil) }

    // MARK: - 道具 Actions
    @objc func doFortune()  { webView.evaluateJavaScript("doFortune()", completionHandler: nil) }
    @objc func doFeed()     { webView.evaluateJavaScript("doFeed()", completionHandler: nil) }
    @objc func doWardrobe() { webView.evaluateJavaScript("openWardrobe()", completionHandler: nil) }
    @objc func doHistory()  { webView.evaluateJavaScript("showFortuneHistory()", completionHandler: nil) }

    // MARK: - 整蛊 Actions
    @objc func doChaosRandom() {
        engine?.triggerChaosNow()
    }
    @objc func doChaosFootprints() {
        engine?.leaveFootprints()
    }
    @objc func doChaosHijack() {
        engine?.hijackMouse()
    }
    @objc func doChaosNotepad() {
        engine?.openNotePad()
    }
    @objc func doChaosPoop() {
        engine?.leavePoop()
    }

    // MARK: - 窗口层级 Actions
    @objc func setLevelTop() {
        self.level = .floating
        showBubble("已置顶显示 ⬆️")
    }
    @objc func setLevelNormal() {
        self.level = .normal
        showBubble("已切换普通层级 ↔️")
    }
    @objc func setLevelBottom() {
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        showBubble("已置底显示 ⬇️")
    }

    // MARK: - 设置 Actions
    @objc func toggleAutoLaunch() {
        isAutoLaunch = !isAutoLaunch
        if #available(macOS 13.0, *) {
            do {
                if isAutoLaunch { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {}
        }
        let msg = isAutoLaunch ? "开机自启已开启！🚀" : "开机自启已关闭"
        showBubble(msg)
    }

    @objc func doResetKarma() {
        karma = 0
        webView.evaluateJavaScript("karma=0; updateKarmaDisplay(); saveAll(); showBubble('福气值已重置 🔄', 2500)", completionHandler: nil)
    }

    @objc func doQuit() { NSApplication.shared.terminate(nil) }

    // MARK: - 便捷：Swift 侧弹气泡
    private func showBubble(_ text: String, duration: Int = 2500) {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        webView.evaluateJavaScript("showBubble('\(escaped)', \(duration))", completionHandler: nil)
    }

    // MARK: - engine 快捷访问
    private var engine: ChaosEngine? {
        (NSApplication.shared.delegate as? AppDelegate)?.chaosEngine
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
