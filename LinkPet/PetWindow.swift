import AppKit
import WebKit

class PetWindowLive2D: NSWindow, WKNavigationDelegate, WKUIDelegate {
    var webView: WKWebView!
    var isDragging = false
    var dragStartWindowPos: CGPoint = .zero
    var dragStartMousePos: CGPoint = .zero

    init() {
        let size = NSRect(x: 0, y: 0, width: 280, height: 340)
        super.init(
            contentRect: size,
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

        // 居中显示
        if let screen = NSScreen.main {
            let sx = screen.frame.width / 2 - 140
            let sy = screen.frame.height / 2 - 170
            self.setFrameOrigin(NSPoint(x: sx, y: sy))
        }
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // 允许本地资源
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: self.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.setValue(false, forKey: "drawsBackground")  // 透明背景

        self.contentView = webView

        // 加载 HTML
        if let htmlURL = Bundle.main.url(forResource: "pet", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        } else {
            // fallback: load from string
            webView.loadHTMLString(buildHTML(), baseURL: nil)
        }
    }

    // MARK: - 拖动
    override func mouseDown(with event: NSEvent) {
        // 如果点击在 webview 的上半部分（宠物身体），开始拖动
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

    // MARK: - 内联 HTML (fallback)
    func buildHTML() -> String {
        return petHTML()
    }
}
