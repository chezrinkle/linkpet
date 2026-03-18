import Foundation
import Combine
import AppKit

enum PetState {
    case idle         // 待机
    case walk         // 溜达
    case sit          // 坐着
    case happy        // 被摸开心
    case eating       // 吃东西
    case sleeping     // 睡觉
    case dancing      // 跳舞
    case chasing      // 追鼠标
    case poked        // 被戳
}

let petDialogues: [String] = [
    "🍯 蜂蜜好吃！",
    "🐾 我来啦～",
    "主人在忙吗？陪我玩嘛",
    "困了...打个盹儿",
    "嘿！别动！让我追上你！",
    "今天心情超好！",
    "🎵 哼哼哼～",
    "发现好东西了？",
    "嘻嘻，抓到你啦",
    "摸摸头好舒服～",
    "想出去溜达溜达",
    "🍯 有没有蜂蜜？",
    "哼！才不怕你呢",
    "嘿嘿嘿...",
]

class PetViewModel: ObservableObject {
    @Published var state: PetState = .idle
    @Published var position: CGPoint = CGPoint(x: 300, y: 300)
    @Published var facingRight: Bool = true
    @Published var showBubble: Bool = false
    @Published var bubbleText: String = ""
    @Published var animFrame: Int = 0
    @Published var happiness: Int = 60
    @Published var hunger: Int = 30
    @Published var mousePos: CGPoint = .zero   // 鼠标位置（屏幕坐标）
    @Published var eyeOffset: CGSize = .zero   // 眼睛跟随偏移

    var onSpawnFootprint: ((CGPoint) -> Void)?

    private var behaviorTimer: Timer?
    private var animTimer: Timer?
    private var bubbleTimer: Timer?
    private var mouseTrackTimer: Timer?
    private var walkTarget: CGPoint?
    private var chaseTimer: Timer?
    private var footprintCounter: Int = 0
    private var screenBounds: CGRect

    init() {
        screenBounds = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let sx = CGFloat.random(in: 150...(screenBounds.width - 200))
        let sy = CGFloat.random(in: 150...(screenBounds.height - 200))
        position = CGPoint(x: sx, y: sy)
        startAnimLoop()
        startBehaviorLoop()
        startMouseTracking()
    }

    deinit {
        behaviorTimer?.invalidate()
        animTimer?.invalidate()
        bubbleTimer?.invalidate()
        mouseTrackTimer?.invalidate()
        chaseTimer?.invalidate()
    }

    // MARK: - 鼠标追踪
    private func startMouseTracking() {
        mouseTrackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let mp = NSEvent.mouseLocation
            self.mousePos = mp

            // 眼睛跟随（相对宠物位置偏移，最大4pt）
            let dx = mp.x - self.position.x
            let dy = mp.y - self.position.y
            let dist = max(1, sqrt(dx*dx + dy*dy))
            let maxEye: CGFloat = 4
            self.eyeOffset = CGSize(
                width: min(maxEye, max(-maxEye, dx / dist * maxEye)),
                height: min(maxEye, max(-maxEye, dy / dist * maxEye))
            )
        }
    }

    // MARK: - 动画帧
    private func startAnimLoop() {
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.animFrame = (self.animFrame + 1) % 8

            // 行走移动
            if self.state == .walk || self.state == .chasing {
                self.updateMovement()
            }

            // 行走留脚印
            if self.state == .walk {
                self.footprintCounter += 1
                if self.footprintCounter % 16 == 0 {
                    self.onSpawnFootprint?(self.position)
                }
            }
        }
    }

    private func updateMovement() {
        let target: CGPoint
        if state == .chasing {
            // 追鼠标：目标是鼠标位置（转换坐标）
            guard let screen = NSScreen.main else { return }
            let sf = screen.frame
            target = CGPoint(x: mousePos.x, y: sf.height - mousePos.y)
        } else if let wt = walkTarget {
            target = wt
        } else {
            return
        }

        let speed: CGFloat = state == .chasing ? 4.0 : 2.5
        let dx = target.x - position.x
        let dy = target.y - position.y
        let dist = sqrt(dx*dx + dy*dy)

        if dist < speed + 5 {
            if state == .walk {
                position = target
                walkTarget = nil
                setState(.idle)
            }
            // chasing 状态到达鼠标旁边
        } else {
            facingRight = dx > 0
            position.x += (dx / dist) * speed
            position.y += (dy / dist) * speed
        }
    }

    // MARK: - 行为决策
    private func startBehaviorLoop() {
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.decideNextBehavior()
        }
    }

    private func decideNextBehavior() {
        guard state != .happy && state != .eating && state != .poked && state != .dancing else { return }

        hunger = min(100, hunger + Int.random(in: 1...4))
        happiness = max(0, happiness - Int.random(in: 0...2))

        if happiness < 15 { setState(.sleeping); return }

        let r = Int.random(in: 0...100)
        switch r {
        case 0...25:  // 溜达
            randomWalk()
        case 26...38: // 坐着发呆
            setState(.sit)
        case 39...50: // 追鼠标
            startChasing()
        case 51...60: // 跳舞
            startDancing()
        case 61...70: // 说话
            showSpeech(petDialogues.randomElement() ?? "喵～")
            setState(.idle)
        case 71...78: // 睡觉
            setState(.sleeping)
        default:
            setState(.idle)
        }
    }

    private func randomWalk() {
        let tx = CGFloat.random(in: 80...(screenBounds.width - 180))
        let ty = CGFloat.random(in: 80...(screenBounds.height - 180))
        walkTarget = CGPoint(x: tx, y: ty)
        setState(.walk)
    }

    private func startChasing() {
        setState(.chasing)
        showSpeech("嘿！抓住你！")
        // 追3秒后放弃
        chaseTimer?.invalidate()
        chaseTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            if self?.state == .chasing {
                self?.setState(.idle)
                self?.showSpeech("哼！跑那么快！")
            }
        }
    }

    private func startDancing() {
        setState(.dancing)
        showSpeech("🎵 跳个舞～")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            if self?.state == .dancing { self?.setState(.idle) }
        }
    }

    // MARK: - 交互
    func onPetTapped() {
        // 戳戳
        setState(.poked)
        showSpeech(["哎呀！别戳！", "嘿！干嘛呢！", "OwO 好痒！", "戳什么戳！"].randomElement()!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.setState(.idle) }
    }

    func onPetStroked() {
        // 摸摸
        happiness = min(100, happiness + 25)
        setState(.happy)
        showSpeech(["好舒服～", "再摸摸～", "最喜欢主人了 🍯", "呼噜呼噜..."].randomElement()!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.setState(.idle) }
    }

    func onFeed() {
        hunger = max(0, hunger - 50)
        happiness = min(100, happiness + 15)
        setState(.eating)
        showSpeech("🍯 蜂蜜！太好吃了！")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in self?.setState(.idle) }
    }

    func showSpeech(_ text: String) {
        DispatchQueue.main.async {
            self.bubbleText = text
            self.showBubble = true
        }
        bubbleTimer?.invalidate()
        bubbleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.showBubble = false }
        }
    }

    func onDrag(to point: CGPoint) {
        position = point
        if state == .sleeping || state == .sit { setState(.idle) }
        showSpeech("呀！飞起来了！")
    }

    private func setState(_ s: PetState) {
        DispatchQueue.main.async { self.state = s }
    }

    var statusText: String {
        let h = String(repeating: "💛", count: max(1, happiness / 20))
        let f = String(repeating: "🍯", count: max(1, (100 - hunger) / 20))
        return "开心: \(h)\n饱腹: \(f)"
    }
}
