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
    var isDragging           = false
    var dragStartWindowPos:  CGPoint = .zero
    var dragStartMousePos:   CGPoint = .zero
    private let bottomPanelH: CGFloat = 72

    // 事件监听器（应用级 + 全局）
    private var localDragDownMonitor:    Any?
    private var localDragMovedMonitor:   Any?
    private var localDragUpMonitor:      Any?
    private var globalRightMouseMonitor: Any?   // Global：能捕获 WKWebView 子进程产生的右键

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
        self.level              = .floating
        self.isOpaque           = false
        self.backgroundColor    = .clear
        self.hasShadow          = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces]

        setupWebView()
        setupMouseMonitors()
        placeOnScreen()
    }

    deinit { removeMonitors() }

    private func placeOnScreen() {
        guard let screen = NSScreen.main else { return }
        setFrameOrigin(NSPoint(x: screen.frame.width - 220, y: screen.frame.height * 0.3))
    }

    // MARK: - WebView 初始化
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()

        // JS 注入：第1层防护——在 HTML/JS 层禁掉 contextmenu 事件冒泡
        let noCtxMenu = WKUserScript(
            source: "document.addEventListener('contextmenu', function(e){ e.preventDefault(); e.stopPropagation(); }, true);",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        let ucc = WKUserContentController()
        ucc.addUserScript(noCtxMenu)
        ucc.add(WeakScriptHandler(self), name: "petBridge")
        config.userContentController = ucc

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        // developerExtras 关掉（"检查元素"等系统菜单项）
        config.preferences.setValue(false, forKey: "developerExtrasEnabled")

        let frame = NSRect(x: 0, y: 0, width: 200, height: 300)
        webView = WKWebView(frame: frame, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")

        self.contentView = webView
        webView.loadHTMLString(buildPetHTML(initialKarma: karma),
                               baseURL: URL(fileURLWithPath: NSHomeDirectory()))
    }

    // MARK: - 事件监听：第3层防护——Global Monitor 弹我们的菜单
    private func setupMouseMonitors() {
        // ── 拖动：Local Monitor（只需本 App 窗口内的左键）──
        localDragDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self else { return event }
            // 用 mouseLocationOutsideOfEventStream 获取窗口内坐标（无视 WKWebView 子视图）
            let loc = self.mouseLocationOutsideOfEventStream
            if self.frame.width > 0,    // 确保窗口存在
               loc.x >= 0, loc.x <= self.frame.width,
               loc.y >= 0, loc.y <= self.frame.height,
               loc.y > self.bottomPanelH {
                self.isDragging          = true
                self.dragStartWindowPos  = self.frame.origin
                self.dragStartMousePos   = NSEvent.mouseLocation
            }
            return event
        }

        localDragMovedMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self, self.isDragging else { return event }
            let cur = NSEvent.mouseLocation
            self.setFrameOrigin(NSPoint(
                x: self.dragStartWindowPos.x + cur.x - self.dragStartMousePos.x,
                y: self.dragStartWindowPos.y + cur.y - self.dragStartMousePos.y
            ))
            return event
        }

        localDragUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            self?.isDragging = false
            return event
        }

        // ── 右键：Global Monitor（能捕获 WKWebView 子进程产生的事件）──
        // Global Monitor 无法 return nil 吞事件，所以配合第1/2层防护确保系统菜单不弹
        globalRightMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self else { return }
            // 判断右键是否落在本窗口范围内（Cocoa 坐标，左下原点）
            let pt = NSEvent.mouseLocation
            guard self.frame.contains(pt) else { return }
            DispatchQueue.main.async { self.showContextMenu() }
        }
    }

    private func removeMonitors() {
        [localDragDownMonitor, localDragMovedMonitor, localDragUpMonitor, globalRightMouseMonitor]
            .compactMap { $0 }.forEach { NSEvent.removeMonitor($0) }
    }

    // MARK: - JS Bridge
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        switch body["action"] as? String ?? "" {
        case "saveKarma": if let k = body["karma"] as? Int { karma = k }
        case "dance":     startDanceWiggle()
        case "showMenu":  DispatchQueue.main.async { self.showContextMenu() }
        default:          break
        }
    }

    // MARK: - 公开接口
    func onKeystroke() {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("onKeystroke()", completionHandler: nil)
        }
    }

    func showChaosMessage(_ text: String) {
        let s = escape(text)
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("showBubble('\(s)', 3500)", completionHandler: nil)
        }
    }

    // MARK: - 舞蹈摇摆
    private func startDanceWiggle() {
        let offsets: [CGFloat] = [8, -8, 6, -6, 4, -4, 2, -2, 0]
        for (i, dx) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.11) { [weak self] in
                guard let self else { return }
                let o = self.frame.origin
                self.setFrameOrigin(NSPoint(x: o.x + dx, y: o.y))
            }
        }
    }

    // MARK: - 右键菜单
    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(makeHeader("✨ 互动"))
        menu.addItem(mk("🐱 戳一戳",      #selector(doPoke)))
        menu.addItem(mk("🤚 摸摸头",      #selector(doStroke)))
        menu.addItem(mk("💃 跳舞",        #selector(doDance)))
        menu.addItem(mk("😄 触发开心",    #selector(doHappy)))
        menu.addItem(.separator())

        menu.addItem(makeHeader("🎒 道具"))
        menu.addItem(mk("🔮 求签（消耗50福气）", #selector(doFortune)))
        menu.addItem(mk("🍬 喂零食（+20福气）",  #selector(doFeed)))
        menu.addItem(mk("🎀 换装衣橱",           #selector(doWardrobe)))
        menu.addItem(mk("📜 查看签文历史",       #selector(doHistory)))
        menu.addItem(.separator())

        menu.addItem(makeHeader("😈 整蛊"))
        menu.addItem(mk("😈 随机整蛊",   #selector(doChaosRandom)))
        menu.addItem(mk("🐾 留猫爪脚印", #selector(doChaosFootprints)))
        menu.addItem(mk("🖱️ 劫持鼠标",  #selector(doChaosHijack)))
        menu.addItem(mk("📝 偷偷写字",   #selector(doChaosNotepad)))
        menu.addItem(mk("💩 丢💩炸弹",   #selector(doChaosPoop)))
        menu.addItem(.separator())

        menu.addItem(makeHeader("🪟 窗口层级"))
        let deskLv = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        menu.addItem(mk(level == .floating            ? "✅ 置顶显示（当前）" : "⬆️ 置顶显示", #selector(setLevelTop)))
        menu.addItem(mk(level == .normal              ? "✅ 普通层级（当前）" : "↔️ 普通层级", #selector(setLevelNormal)))
        menu.addItem(mk(level.rawValue <= deskLv.rawValue ? "✅ 置底显示（当前）" : "⬇️ 置底显示", #selector(setLevelBottom)))
        menu.addItem(.separator())

        menu.addItem(makeHeader("⚙️ 设置"))
        menu.addItem(mk(isAutoLaunch ? "✅ 开机自启（已开启）" : "🔲 开机自启（已关闭）", #selector(toggleAutoLaunch)))
        menu.addItem(mk("🔄 重置福气值",  #selector(doResetKarma)))
        menu.addItem(mk("❌ 退出 LinkPet", #selector(doQuit)))

        for item in menu.items { item.target = self }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    private func makeHeader(_ t: String) -> NSMenuItem {
        let i = NSMenuItem(title: t, action: nil, keyEquivalent: ""); i.isEnabled = false; return i
    }
    private func mk(_ title: String, _ sel: Selector) -> NSMenuItem {
        NSMenuItem(title: title, action: sel, keyEquivalent: "")
    }

    // MARK: - Actions
    @objc func doPoke()              { webView.evaluateJavaScript("onPoke(null)", completionHandler: nil) }
    @objc func doStroke()            { webView.evaluateJavaScript("onStroke()", completionHandler: nil) }
    @objc func doDance()             { webView.evaluateJavaScript("doDance()", completionHandler: nil) }
    @objc func doHappy()             { webView.evaluateJavaScript("triggerHappy()", completionHandler: nil) }
    @objc func doFortune()           { webView.evaluateJavaScript("doFortune()", completionHandler: nil) }
    @objc func doFeed()              { webView.evaluateJavaScript("doFeed()", completionHandler: nil) }
    @objc func doWardrobe()          { webView.evaluateJavaScript("openWardrobe()", completionHandler: nil) }
    @objc func doHistory()           { webView.evaluateJavaScript("showFortuneHistory()", completionHandler: nil) }
    @objc func doChaosRandom()       { engine?.triggerChaosNow() }
    @objc func doChaosFootprints()   { engine?.leaveFootprints() }
    @objc func doChaosHijack()       { engine?.hijackMouse() }
    @objc func doChaosNotepad()      { engine?.openNotePad() }
    @objc func doChaosPoop()         { engine?.leavePoop() }
    @objc func setLevelTop()         { level = .floating; showBubble("已置顶显示 ⬆️") }
    @objc func setLevelNormal()      { level = .normal;   showBubble("已切换普通层级 ↔️") }
    @objc func setLevelBottom()      { level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow))); showBubble("已置底显示 ⬇️") }
    @objc func toggleAutoLaunch() {
        isAutoLaunch = !isAutoLaunch
        if #available(macOS 13.0, *) {
            do { if isAutoLaunch { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } } catch {}
        }
        showBubble(isAutoLaunch ? "开机自启已开启！🚀" : "开机自启已关闭")
    }
    @objc func doResetKarma() {
        karma = 0
        webView.evaluateJavaScript("karma=0; updateKarmaDisplay(); saveAll(); showBubble('福气值已重置 🔄', 2500)", completionHandler: nil)
    }
    @objc func doQuit() { NSApplication.shared.terminate(nil) }

    // MARK: - 工具
    private func showBubble(_ text: String, duration: Int = 2500) {
        webView.evaluateJavaScript("showBubble('\(escape(text))', \(duration))", completionHandler: nil)
    }
    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "'",  with: "\\'")
         .replacingOccurrences(of: "\n", with: "\\n")
    }
    private var engine: ChaosEngine? {
        (NSApplication.shared.delegate as? AppDelegate)?.chaosEngine
    }

    override var canBecomeKey:  Bool { true }
    override var canBecomeMain: Bool { false }
}
