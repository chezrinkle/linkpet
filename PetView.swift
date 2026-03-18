import SwiftUI

struct PetView: View {
    @ObservedObject var viewModel: PetViewModel

    var body: some View {
        ZStack {
            // 对话气泡
            if viewModel.showBubble {
                VStack(spacing: 0) {
                    BubbleView(text: viewModel.bubbleText)
                    // 气泡小尾巴
                    Triangle()
                        .fill(Color.white)
                        .frame(width: 12, height: 8)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                }
                .offset(x: 0, y: -90)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3), value: viewModel.showBubble)
            }

            // 宠物本体
            CatSpriteView(state: viewModel.state, frame: viewModel.frame, facingRight: viewModel.facingRight)
                .scaleEffect(x: viewModel.facingRight ? 1 : -1, y: 1)
                .frame(width: 80, height: 80)
                .onTapGesture {
                    viewModel.onPetTapped()
                }
                .contextMenu {
                    Button("喂食 🐟") { viewModel.onFeed() }
                    Button("摸摸 🤝") { viewModel.onPetTapped() }
                    Button("查看状态") { viewModel.showSpeech(viewModel.statusText) }
                    Divider()
                    Button("退出 LinkPet") { NSApplication.shared.terminate(nil) }
                }
        }
    }
}

// 猫咪 Sprite（纯 Emoji 实现，可替换为真实图片资源）
struct CatSpriteView: View {
    let state: PetState
    let frame: Int
    let facingRight: Bool

    var body: some View {
        Text(currentEmoji)
            .font(.system(size: 56))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.1), value: currentEmoji)
    }

    var currentEmoji: String {
        switch state {
        case .idle:
            return frame % 2 == 0 ? "🐱" : "😺"
        case .walk:
            let walkFrames = ["🐈", "🐱", "🐈", "😺"]
            return walkFrames[frame % 4]
        case .sit:
            return "🐈‍⬛"
        case .happy:
            let happyFrames = ["😻", "🥰", "😻", "🎉"]
            return happyFrames[frame % 4]
        case .eating:
            let eatFrames = ["😺", "🐟", "😸", "🐟"]
            return eatFrames[frame % 4]
        case .sleeping:
            return frame % 2 == 0 ? "😴" : "💤"
        }
    }
}

// 气泡
struct BubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.black.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 180)
            .multilineTextAlignment(.center)
    }
}

// 气泡小尖角
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// 状态文本扩展
extension PetViewModel {
    var statusText: String {
        let happinessBar = String(repeating: "❤️", count: happiness / 20)
        let hungerBar = String(repeating: "🐟", count: (100 - hunger) / 20)
        return "快乐: \(happinessBar)\n饥饿: \(hungerBar)"
    }
}
