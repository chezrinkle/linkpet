import AppKit
import WebKit
import ServiceManagement

// Fix-E: 用 WeakScriptHandler 打破 WKUserContentController → self 的 retain cycle
private class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(ucc, didReceive: message)
    }
}

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
        // Fix-Bug9: 移除 .stationary，保留拖动能力
        self.collectionBehavior = [.canJoinAllSpaces]
        setupWebView()
        placeOnScreen()
    }

    private func placeOnScreen() {
        guard let screen = NSScreen.main else { return }
        let x = screen.frame.width - 220
        let y = screen.frame.height * 0.3
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let ucc = WKUserContentController()
        // Fix-E: 用 WeakScriptHandler 避免 retain cycle
        ucc.add(WeakScriptHandler(self), name: "petBridge")
        config.userContentController = ucc

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // 安全解包 contentView，避免强解包崩溃
        let frame = self.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 200, height: 300)
        webView = WKWebView(frame: frame, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        self.contentView = webView

        let html = buildPetHTML(initialKarma: karma)
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        webView.loadHTMLString(html, baseURL: baseURL)
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

    // MARK: - 跳舞摇摆窗口
    // Fix-F: 每步重新读当前 origin，避免拖动期间 origin 已变导致窗口跳回
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

    // MARK: - 右键菜单
    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "🔮 求签（消耗50福气）", action: #selector(doFortune), keyEquivalent: "")
        menu.addItem(withTitle: "🍬 喂零食（+20福气）", action: #selector(doFeed), keyEquivalent: "")
        menu.addItem(withTitle: "💃 跳舞", action: #selector(doDance), keyEquivalent: "")
        menu.addItem(withTitle: "🎀 换装衣橱", action: #selector(doWardrobe), keyEquivalent: "")
        menu.addItem(withTitle: "📜 查看签文历史", action: #selector(doHistory), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "😈 立刻整蛊！", action: #selector(doChaosNow), keyEquivalent: "")
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

    @objc func doChaosNow() {
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
            delegate.chaosEngine.triggerChaosNow()
        }
    }

    @objc func toggleAutoLaunch() {
        isAutoLaunch = !isAutoLaunch
        if #available(macOS 13.0, *) {
            do {
                if isAutoLaunch { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {}
        }
        let msg = isAutoLaunch ? "开机自启已开启！" : "开机自启已关闭"
        let escaped = msg.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("showBubble('\(escaped)', 2500)", completionHandler: nil)
    }

    @objc func doQuit() { NSApplication.shared.terminate(nil) }

    // MARK: - 拖动
    override func mouseDown(with event: NSEvent) {
        let loc = event.locationInWindow
        // Fix-Bug10: 底部面板72px，拖动区域在 y > 72
        if loc.y > 72 {
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
