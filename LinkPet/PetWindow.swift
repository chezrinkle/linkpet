import AppKit
import WebKit

class PetWindowV3: NSWindow, WKNavigationDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    var isDragging = false
    var dragStartWindowPos: CGPoint = .zero
    var dragStartMousePos: CGPoint = .zero

    // 持久化 karma
    var karma: Int {
        get { UserDefaults.standard.integer(forKey: "linkpet_karma") }
        set { UserDefaults.standard.set(newValue, forKey: "linkpet_karma") }
    }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 260),
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
        centerOnScreen()
    }

    private func centerOnScreen() {
        if let screen = NSScreen.main {
            let sx = screen.frame.width - 220
            let sy = screen.frame.height / 2 - 130
            self.setFrameOrigin(NSPoint(x: sx, y: sy))
        }
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        // JS -> Swift 消息桥
        userContentController.add(self, name: "petBridge")
        config.userContentController = userContentController

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: self.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        self.contentView = webView

        // 传入初始 karma
        let html = buildPetHTML(initialKarma: karma)
        webView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - JS 消息处理
    func userContentController(_ userContentController: WKUserContentController,
                                didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        let action = body["action"] as? String ?? ""

        switch action {
        case "saveKarma":
            if let k = body["karma"] as? Int { karma = k }
        case "quit":
            NSApplication.shared.terminate(nil)
        case "showMenu":
            showContextMenu()
        default:
            break
        }
    }

    // MARK: - 键击 → JS
    func onKeystroke() {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript("onKeystroke()", completionHandler: nil)
        }
    }

    // MARK: - 右键菜单
    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "🔮 求签（消耗50福气）", action: #selector(doFortune), keyEquivalent: "")
        menu.addItem(withTitle: "🍬 喂零食（+20福气）", action: #selector(doFeed), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "❌ 退出 LinkPet", action: #selector(doQuit), keyEquivalent: "")
        for item in menu.items { item.target = self }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc func doFortune() {
        webView.evaluateJavaScript("doFortune()", completionHandler: nil)
    }
    @objc func doFeed() {
        webView.evaluateJavaScript("doFeed()", completionHandler: nil)
    }
    @objc func doQuit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 拖动
    override func mouseDown(with event: NSEvent) {
        let loc = event.locationInWindow
        if loc.y > 50 {
            isDragging = true
            dragStartWindowPos = self.frame.origin
            dragStartMousePos = NSEvent.mouseLocation
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let cur = NSEvent.mouseLocation
        let dx = cur.x - dragStartMousePos.x
        let dy = cur.y - dragStartMousePos.y
        self.setFrameOrigin(NSPoint(
            x: dragStartWindowPos.x + dx,
            y: dragStartWindowPos.y + dy
        ))
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
