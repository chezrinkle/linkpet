import Foundation
import Combine
import AppKit

// 宠物状态
enum PetState {
    case idle       // 待机
    case walk       // 行走
    case sit        // 坐下
    case happy      // 开心（被摸）
    case eating     // 吃东西
    case sleeping   // 睡觉
}

// 对话气泡内容
let petDialogues: [String] = [
    "喵~ 今天天气不错呢",
    "我饿了...能给我点好吃的吗？",
    "主人在忙吗？我来陪你！",
    "打个哈欠~🥱",
    "偷偷看了一眼你的屏幕👀",
    "我想出去旅行！",
    "今天心情很好，想到处跑跑",
    "主人，摸摸我嘛～",
    "听说外面有好吃的？",
    "Meow~ 我想睡觉了",
    "Nyaa~ 发现鼠标！",
    "要不要一起玩？",
]

class PetViewModel: ObservableObject {
    @Published var state: PetState = .idle
    @Published var position: CGPoint = CGPoint(x: 200, y: 100)
    @Published var facingRight: Bool = true
    @Published var showBubble: Bool = false
    @Published var bubbleText: String = ""
    @Published var frame: Int = 0  // 动画帧
    @Published var happiness: Int = 50  // 0-100
    @Published var hunger: Int = 50     // 0-100

    private var behaviorTimer: Timer?
    private var animTimer: Timer?
    private var bubbleTimer: Timer?
    private var walkTarget: CGPoint?
    private var screenBounds: CGRect = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)

    init() {
        // 随机初始位置
        let sx = CGFloat.random(in: 100...(screenBounds.width - 150))
        let sy = CGFloat.random(in: 100...(screenBounds.height - 150))
        position = CGPoint(x: sx, y: sy)
        startBehaviorLoop()
        startAnimLoop()
    }

    deinit {
        behaviorTimer?.invalidate()
        animTimer?.invalidate()
        bubbleTimer?.invalidate()
    }

    // 行为决策循环
    private func startBehaviorLoop() {
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.decideNextBehavior()
        }
    }

    private func decideNextBehavior() {
        // 如果正在执行特殊状态，不打断
        if state == .happy || state == .eating { return }

        let r = Int.random(in: 0...100)
        let isHungry = hunger > 70
        let isSleepy = happiness < 20

        if isSleepy {
            setState(.sleeping)
            return
        }
        if isHungry && r < 30 {
            showSpeech("肚子好饿...给我吃的！🐟")
        }

        switch r {
        case 0...30:
            // 随机走动
            let tx = CGFloat.random(in: 60...(screenBounds.width - 150))
            let ty = CGFloat.random(in: 60...(screenBounds.height - 150))
            walkTarget = CGPoint(x: tx, y: ty)
            setState(.walk)
        case 31...50:
            setState(.sit)
        case 51...65:
            setState(.idle)
        case 66...72:
            // 说话
            let text = petDialogues.randomElement() ?? "喵~"
            showSpeech(text)
            setState(.idle)
        case 73...80:
            setState(.sleeping)
        default:
            setState(.idle)
        }

        // 饥饿度随时间上升
        hunger = min(100, hunger + Int.random(in: 1...5))
        // 快乐度随时间下降
        happiness = max(0, happiness - Int.random(in: 0...3))
    }

    // 动画帧循环
    private func startAnimLoop() {
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.frame = (self.frame + 1) % 4

            // 移动逻辑
            if self.state == .walk, let target = self.walkTarget {
                let speed: CGFloat = 2.0
                let dx = target.x - self.position.x
                let dy = target.y - self.position.y
                let dist = sqrt(dx*dx + dy*dy)
                if dist < speed {
                    self.position = target
                    self.walkTarget = nil
                    self.setState(.idle)
                } else {
                    self.facingRight = dx > 0
                    self.position.x += (dx / dist) * speed
                    self.position.y += (dy / dist) * speed
                }
            }
        }
    }

    private func setState(_ newState: PetState) {
        DispatchQueue.main.async {
            self.state = newState
        }
    }

    // 被点击/摸头
    func onPetTapped() {
        happiness = min(100, happiness + 20)
        setState(.happy)
        showSpeech("喵喵！好舒服～ 🐾")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.setState(.idle)
        }
    }

    // 喂食
    func onFeed() {
        hunger = max(0, hunger - 40)
        happiness = min(100, happiness + 10)
        setState(.eating)
        showSpeech("哇！好好吃！🐟")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.setState(.idle)
        }
    }

    // 显示气泡
    func showSpeech(_ text: String) {
        DispatchQueue.main.async {
            self.bubbleText = text
            self.showBubble = true
        }
        bubbleTimer?.invalidate()
        bubbleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.showBubble = false
            }
        }
    }

    // 拖动
    func onDrag(to point: CGPoint) {
        position = point
        if state == .sleeping { setState(.idle) }
    }
}
