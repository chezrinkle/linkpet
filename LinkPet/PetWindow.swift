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

// MARK: - 主窗口
class PetWindowV3: NSWindow, WKNavigationDelegate, WKScriptMessageHandler {

    var webView: WKWebView!

    // 拖动状态
    var isDragging = false
    var dragStartWindowPos: CGPoint = .zero
    var dragStartMousePos:  CGPoint = .zero

    // 应用级鼠标事件 monitor（比视图层级更早拦截）
    private var mouseDownMonitor:    Any?
    private var mouseDraggedMonitor: Any?
    private var mouseUpMonitor:      Any?
    private var rightMouseMonitor:   Any?

    // 底部面板高度（px）——此区域内左键不触发拖动
    private let bottomPanelH: CGFloat = 72

    var karma: Int {
        get { UserDefaults.standard.integer(forKey: "linkpet_karma") }
        set { UserDefaults.standard.set(newValue, forKey: "linkpet_karma") }
    }
    var isAutoLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: "linkpet_autolaunch") }
        set { UserDefaults.standard.set(newValue, forKey: "linkpet_autolaunch") }
    }

    // MARK: - Init
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 300),
            styleMask:   [.borderless],
            backing:     .buffered,
            defer:       false
        )
        self.level            = .floating
        self.isOpaque         = false
        self.backgroundColor  = .clear
        self.hasShadow        = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces]

        setupWebView()
        setupMouseMonitors()
        placeOnScreen()
    }

    deinit {
        removeMouseMonitors()
    }

    // MARK: - 布局
    private func placeOnScreen() {
        guard let screen = NSScreen.main else { return }
        self.setFrameOrigin(NSPoint(
            x: screen.frame.width - 220,
            y: screen.frame.height * 0.3
        ))
    }

    // MARK: - WebView
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()

        let ucc = WKUserContentController()
        ucc.add(WeakScriptHandler(self), name: "petBridge")
        config.userContentController = ucc

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let frame = NSRect(x: 0, y: 0, width: 200, height: 300)
        webView = WKWebView(frame: frame, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        // 禁止 WKWebView 自带的右键菜单
        webView.configuration.preferences.setValue(false, forKey: "developerExtrasEnabled")

        self.contentView = webView

        webView.loadHTMLString(buildPetHTML(initialKarma: karma),
                               baseURL: URL(fileURLWithPath: NSHomeDirectory()))
    }

    // MARK: - 应用级鼠标 Monitor（绕过 WKWebView 视图层级）
    private func setupMouseMonitors() {
        // 判断事件是否落在本窗口内的辅助函数
        // 注意：eventWindow 可能是 WKWebView 内部私有窗口，所以用屏幕坐标判断
        func isInOurWindow(_ event: NSEvent) -> Bool {
            let pt = event.cgEvent?.location ?? CGPoint.zero   // CG坐标（左上原点）
            guard let screen = NSScreen.main else { return false }
            // 转换为 Cocoa 屏幕坐标（左下原点）
            let cocoaPt = NSPoint(x: pt.x, y: screen.frame.height - pt.y)
            return self.frame.contains(cocoaPt)
        }

        // 左键按下 → 拖动
        mouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self, isInOurWindow(event) else { return event }
            let cocoaPt = self.mouseLocationOutsideOfEventStream
            if cocoaPt.y > self.bottomPanelH {
                self.isDragging = true
                self.dragStartWindowPos = self.frame.origin
                self.dragStartMousePos  = NSEvent.mouseLocation
            }
            return event   // 继续传递，保证 WKWebView 也收到点击
        }

        // 左键拖动
        mouseDraggedMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self = self, self.isDragging else { return event }
            let cur = NSEvent.mouseLocation
            self.setFrameOrigin(NSPoint(
                x: self.dragStartWindowPos.x + cur.x - self.dragStartMousePos.x,
                y: self.dragStartWindowPos.y + cur.y - self.dragStartMousePos.y
            ))
            return event
        }

        // 左键抬起
        mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            self?.isDragging = false
            return event
        }

        // 右键按下 → 弹菜单，吞掉事件不传给 WKWebView
        rightMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self = self, isInOurWindow(event) else { return event }
            DispatchQueue.main.async { self.showContextMenu() }
            return nil   // nil = 吞掉，WKWebView 收不到，不会弹"重新载入"
        }
    }

    private func removeMouseMonitors() {
        [mouseDownMonitor, mouseDraggedMonitor, mouseUpMonitor, rightMouseMonitor]
            .compactMap { $0 }
            .forEach { NSEvent.removeMonitor($0) }
    }

    // MARK: - JS Bridge
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        switch body["action"] as? String ?? "" {
        case "saveKarma": if let k = body["karma"] as? Int { karma = k }
        case "dance":     startDanceWiggle()
        case "showMenu":  showContextMenu()   // JS 右键也转到同一个菜单
        default: break
        }
    }

    // MARK: - 公开接口
    func onKeystroke() {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("onKeystroke()", completionHandler: nil)
        }
    }

    func showChaosMessage(_ text: String) {
        let s = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'",  with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("showBubble('\(s)', 3500)", completionHandler: nil)
        }
    }

    // MARK: - 跳舞摇摆
    private func startDanceWiggle() {
        let offsets: [CGFloat] = [8, -8, 6, -6, 4, -4, 2, -2, 0]
        for (i, dx) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.11) { [weak self] in
                guard let self else { return }
                let cur = self.frame.origin
                self.setFrameOrigin(NSPoint(x: cur.x + dx, y: cur.y))
            }
        }
    }

    // MARK: - 右键菜单
    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(makeHeader("✨ 互动"))
        menu.addItem(item: "🐱 戳一戳",      action: #selector(doPoke))
        menu.addItem(item: "🤚 摸摸头",      action: #selector(doStroke))
        menu.addItem(item: "💃 跳舞",        action: #selector(doDance))
        menu.addItem(item: "😄 触发开心",    action: #selector(doHappy))

        menu.addItem(.separator())

        menu.addItem(makeHeader("🎒 道具"))
        menu.addItem(item: "🔮 求签（消耗50福气）", action: #selector(doFortune))
        menu.addItem(item: "🍬 喂零食（+20福气）",  action: #selector(doFeed))
        menu.addItem(item: "🎀 换装衣橱",            action: #selector(doWardrobe))
        menu.addItem(item: "📜 查看签文历史",        action: #selector(doHistory))

        menu.addItem(.separator())

        menu.addItem(makeHeader("😈 整蛊"))
        menu.addItem(item: "😈 随机整蛊",    action: #selector(doChaosRandom))
        menu.addItem(item: "🐾 留猫爪脚印",  action: #selector(doChaosFootprints))
        menu.addItem(item: "🖱️ 劫持鼠标",   action: #selector(doChaosHijack))
        menu.addItem(item: "📝 偷偷写字",    action: #selector(doChaosNotepad))
        menu.addItem(item: "💩 丢💩炸弹",    action: #selector(doChaosPoop))

        menu.addItem(.separator())

        menu.addItem(makeHeader("🪟 窗口层级"))
        let isTop    = self.level == .floating
        let isNormal = self.level == .normal
        let deskLv   = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        let isBottom = self.level.rawValue <= deskLv.rawValue
        menu.addItem(item: isTop    ? "✅ 置顶显示（当前）" : "⬆️ 置顶显示", action: #selector(setLevelTop))
        menu.addItem(item: isNormal ? "✅ 普通层级（当前）" : "↔️ 普通层级", action: #selector(setLevelNormal))
        menu.addItem(item: isBottom ? "✅ 置底显示（当前）" : "⬇️ 置底显示", action: #selector(setLevelBottom))

        menu.addItem(.separator())

        menu.addItem(makeHeader("⚙️ 设置"))
        menu.addItem(item: isAutoLaunch ? "✅ 开机自启（已开启）" : "🔲 开机自启（已关闭）",
                     action: #selector(toggleAutoLaunch))
        menu.addItem(item: "🔄 重置福气值", action: #selector(doResetKarma))
        menu.addItem(item: "❌ 退出 LinkPet", action: #selector(doQuit))

        for item in menu.items { item.target = self }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    private func makeHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - 互动
    @objc func doPoke()   { webView.evaluateJavaScript("onPoke(null)", completionHandler: nil) }
    @objc func doStroke() { webView.evaluateJavaScript("onStroke()", completionHandler: nil) }
    @objc func doDance()  { webView.evaluateJavaScript("doDance()", completionHandler: nil) }
    @objc func doHappy()  { webView.evaluateJavaScript("triggerHappy()", completionHandler: nil) }

    // MARK: - 道具
    @objc func doFortune()  { webView.evaluateJavaScript("doFortune()", completionHandler: nil) }
    @objc func doFeed()     { webView.evaluateJavaScript("doFeed()", completionHandler: nil) }
    @objc func doWardrobe() { webView.evaluateJavaScript("openWardrobe()", completionHandler: nil) }
    @objc func doHistory()  { webView.evaluateJavaScript("showFortuneHistory()", completionHandler: nil) }

    // MARK: - 整蛊
    @objc func doChaosRandom()      { engine?.triggerChaosNow() }
    @objc func doChaosFootprints()  { engine?.leaveFootprints() }
    @objc func doChaosHijack()      { engine?.hijackMouse() }
    @objc func doChaosNotepad()     { engine?.openNotePad() }
    @objc func doChaosPoop()        { engine?.leavePoop() }

    // MARK: - 层级
    @objc func setLevelTop()    { self.level = .floating; showBubble("已置顶显示 ⬆️") }
    @objc func setLevelNormal() { self.level = .normal;   showBubble("已切换普通层级 ↔️") }
    @objc func setLevelBottom() {
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        showBubble("已置底显示 ⬇️")
    }

    // MARK: - 设置
    @objc func toggleAutoLaunch() {
        isAutoLaunch = !isAutoLaunch
        if #available(macOS 13.0, *) {
            do {
                if isAutoLaunch { try SMAppService.mainApp.register() }
                else            { try SMAppService.mainApp.unregister() }
            } catch {}
        }
        showBubble(isAutoLaunch ? "开机自启已开启！🚀" : "开机自启已关闭")
    }

    @objc func doResetKarma() {
        karma = 0
        webView.evaluateJavaScript(
            "karma=0; updateKarmaDisplay(); saveAll(); showBubble('福气值已重置 🔄', 2500)",
            completionHandler: nil)
    }

    @objc func doQuit() { NSApplication.shared.terminate(nil) }

    // MARK: - 工具
    private func showBubble(_ text: String, duration: Int = 2500) {
        let s = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'",  with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        webView.evaluateJavaScript("showBubble('\(s)', \(duration))", completionHandler: nil)
    }

    private var engine: ChaosEngine? {
        (NSApplication.shared.delegate as? AppDelegate)?.chaosEngine
    }

    override var canBecomeKey:  Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - NSMenu 便捷扩展
private extension NSMenu {
    func addItem(item title: String, action: Selector) {
        addItem(withTitle: title, action: action, keyEquivalent: "")
    }
}
