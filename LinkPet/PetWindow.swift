import AppKit
import WebKit
import ServiceManagement

class PetWindowV3: NSWindow, WKNavigationDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
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
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        setupWebView()
        placeOnScreen()
    }

    private func placeOnScreen() {
        guard let screen = NSScreen.main else { return }
        // 右侧 1/4 位置
        let x = screen.frame.width - 220
        let y = screen.frame.height * 0.3
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let ucc = WKUserContentController()
        ucc.add(self, name: "petBridge")
        config.userContentController = ucc

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: self.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        self.contentView = webView

        let html = buildPetHTML(initialKarma: karma)
        webView.loadHTMLString(html, baseURL: nil)
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
            // 跳舞时窗口轻微移动
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

    // MARK: - 跳舞摇摆窗口
    private func startDanceWiggle() {
        let origin = self.frame.origin
        let offsets: [CGFloat] = [8, -8, 6, -6, 4, -4, 0]
        for (i, dx) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) { [weak self] in
                guard let self = self else { return }
                self.setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y))
            }
        }
    }

    // MARK: - 右键菜单
    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "🔮 求签（消耗50福气）", action: #selector(doFortune), keyEquivalent: "")
        menu.addItem(withTitle: "🍬 喂零食（+20福气）", action: #selector(doFeed), keyEquivalent: "")
        menu.addItem(withTitle: "💃 跳舞", action: #selector(doDance), keyEquivalent: "")
        menu.addItem(withTitle: "🎀 换装衣橱", action: #selector(doWardrobe), keyEquivalent: "")
        menu.addItem(withTitle: "📜 查看签文历史", action: #selector(doHistory), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        let autoTitle = isAutoLaunch ? "✅ 开机自启（已开启）" : "🔲 开机自启（已关闭）"
        menu.addItem(withTitle: autoTitle, action: #selector(toggleAutoLaunch), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "❌ 退出 LinkPet", action: #selector(doQuit), keyEquivalent: "")
        for item in menu.items { item.target = self }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc func doFortune()  { webView.evaluateJavaScript("doFortune()", completionHandler: nil) }
    @objc func doFeed()     { webView.evaluateJavaScript("doFeed()", completionHandler: nil) }
    @objc func doDance()    { webView.evaluateJavaScript("doDance()", completionHandler: nil) }
    @objc func doWardrobe() { webView.evaluateJavaScript("openWardrobe()", completionHandler: nil) }
    @objc func doHistory()  { webView.evaluateJavaScript("showFortuneHistory()", completionHandler: nil) }

    @objc func toggleAutoLaunch() {
        isAutoLaunch = !isAutoLaunch
        // macOS 13+ SMAppService
        if #available(macOS 13.0, *) {
            do {
                if isAutoLaunch {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // 静默失败（沙盒限制时）
            }
        }
        let msg = isAutoLaunch ? "开机自启已开启！" : "开机自启已关闭"
        webView.evaluateJavaScript("showBubble('\(msg)', 2500)", completionHandler: nil)
    }

    @objc func doQuit() { NSApplication.shared.terminate(nil) }

    // MARK: - 拖动
    override func mouseDown(with event: NSEvent) {
        let loc = event.locationInWindow
        if loc.y > 60 {
            isDragging = true
            dragStartWindowPos = self.frame.origin
            dragStartMousePos = NSEvent.mouseLocation
        }
    }
    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let cur = NSEvent.mouseLocation
        self.setFrameOrigin(NSPoint(
            x: dragStartWindowPos.x + cur.x - dragStartMousePos.x,
            y: dragStartWindowPos.y + cur.y - dragStartMousePos.y
        ))
    }
    override func mouseUp(with event: NSEvent) { isDragging = false }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
