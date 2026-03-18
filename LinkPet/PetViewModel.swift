import Foundation
import Combine
import AppKit

enum PetState {
    case idle, walk, sit, happy, eating, sleeping
}

let petDialogues: [String] = [
    "喵~ 今天天气不错呢",
    "我饿了...能给我点好吃的吗？",
    "主人在忙吗？我来陪你！",
    "打个哈欠~",
    "偷偷看了一眼你的屏幕",
    "我想出去旅行！",
    "今天心情很好，想到处跑跑",
    "主人，摸摸我嘛～",
    "Meow~ 我想睡觉了",
    "发现鼠标！",
    "要不要一起玩？",
]

class PetViewModel: ObservableObject {
    @Published var state: PetState = .idle
    @Published var position: CGPoint = CGPoint(x: 200, y: 100)
    @Published var facingRight: Bool = true
    @Published var showBubble: Bool = false
    @Published var bubbleText: String = ""
    @Published var frame: Int = 0
    @Published var happiness: Int = 50
    @Published var hunger: Int = 50

    private var behaviorTimer: Timer?
    private var animTimer: Timer?
    private var bubbleTimer: Timer?
    private var walkTarget: CGPoint?
    private var screenBounds: CGRect

    private var cancellables = Set<AnyCancellable>()

    init() {
        screenBounds = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
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

    private func startBehaviorLoop() {
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.decideNextBehavior()
        }
    }

    private func decideNextBehavior() {
        if state == .happy || state == .eating { return }

        let r = Int.random(in: 0...100)
        let isSleepy = happiness < 20

        if isSleepy { setState(.sleeping); return }

        if hunger > 70 && r < 30 {
            showSpeech("肚子好饿...给我吃的！")
        }

        switch r {
        case 0...30:
            let tx = CGFloat.random(in: 60...(screenBounds.width - 150))
            let ty = CGFloat.random(in: 60...(screenBounds.height - 150))
            walkTarget = CGPoint(x: tx, y: ty)
            setState(.walk)
        case 31...50:
            setState(.sit)
        case 51...65:
            setState(.idle)
        case 66...72:
            let text = petDialogues.randomElement() ?? "喵~"
            showSpeech(text)
            setState(.idle)
        case 73...80:
            setState(.sleeping)
        default:
            setState(.idle)
        }

        hunger = min(100, hunger + Int.random(in: 1...5))
        happiness = max(0, happiness - Int.random(in: 0...3))
    }

    private func startAnimLoop() {
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.frame = (self.frame + 1) % 4

            if self.state == .walk, let target = self.walkTarget {
                let speed: CGFloat = 2.0
                let dx = target.x - self.position.x
                let dy = target.y - self.position.y
                let dist = sqrt(dx * dx + dy * dy)
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
        DispatchQueue.main.async { self.state = newState }
    }

    func onPetTapped() {
        happiness = min(100, happiness + 20)
        setState(.happy)
        showSpeech("喵喵！好舒服～")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.setState(.idle) }
    }

    func onFeed() {
        hunger = max(0, hunger - 40)
        happiness = min(100, happiness + 10)
        setState(.eating)
        showSpeech("哇！好好吃！")
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
        if state == .sleeping { setState(.idle) }
    }

    var statusText: String {
        let h = String(repeating: "❤️", count: max(1, happiness / 20))
        let f = String(repeating: "🐟", count: max(1, (100 - hunger) / 20))
        return "快乐: \(h)\n饥饿: \(f)"
    }
}
