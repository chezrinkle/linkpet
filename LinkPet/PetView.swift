import SwiftUI

// MARK: - 主视图
struct PetView: View {
    @ObservedObject var viewModel: PetViewModel

    var body: some View {
        ZStack {
            // 对话气泡
            if viewModel.showBubble {
                VStack(spacing: 0) {
                    BubbleView(text: viewModel.bubbleText)
                    BubbleTail()
                        .fill(Color.white)
                        .frame(width: 14, height: 9)
                        .shadow(color: .black.opacity(0.1), radius: 1)
                }
                .offset(x: 10, y: -105)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.6, anchor: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.showBubble)
            }

            // 宠物本体：黄油小熊
            ButterBearView(
                state: viewModel.state,
                frame: viewModel.animFrame,
                eyeOffset: viewModel.eyeOffset
            )
            .scaleEffect(x: viewModel.facingRight ? 1 : -1, y: 1)
            .frame(width: 90, height: 90)
            .onTapGesture(count: 2) {
                // 双击 = 摸摸
                viewModel.onPetStroked()
            }
            .onTapGesture(count: 1) {
                // 单击 = 戳戳
                viewModel.onPetTapped()
            }
            .contextMenu {
                Button("🍯 喂蜂蜜") { viewModel.onFeed() }
                Button("🤚 摸摸头") { viewModel.onPetStroked() }
                Button("💃 跳个舞") { viewModel.startDancing() }
                Button("📊 查看状态") { viewModel.showSpeech(viewModel.statusText) }
                Divider()
                Button("退出 LinkPet") { NSApplication.shared.terminate(nil) }
            }
        }
    }
}

// MARK: - 黄油小熊视图
struct ButterBearView: View {
    let state: PetState
    let frame: Int
    let eyeOffset: CGSize

    var body: some View {
        ZStack {
            // 身体层（根据状态切换）
            Text(bodyEmoji)
                .font(.system(size: 62))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .scaleEffect(bodyScale)
                .rotationEffect(bodyRotation)
                .animation(.spring(response: 0.2), value: frame)

            // 眼睛跟随层（叠加在熊脸上）
            if state != .sleeping {
                HStack(spacing: 8) {
                    Eye(offset: eyeOffset)
                    Eye(offset: eyeOffset)
                }
                .offset(x: 2, y: -8)
            }

            // 动作特效
            if state == .dancing {
                DanceEffectView(frame: frame)
                    .offset(x: 0, y: -50)
            }
            if state == .chasing {
                Text("💨")
                    .font(.system(size: 20))
                    .offset(x: -40, y: 10)
                    .opacity(Double(frame % 2))
            }
        }
    }

    var bodyEmoji: String {
        switch state {
        case .idle:
            return frame % 4 < 2 ? "🧸" : "🐻"
        case .walk:
            let frames = ["🧸", "🐾", "🧸", "🐾"]
            return frames[frame % 4]
        case .sit:
            return "🧸"
        case .happy:
            let frames = ["🥰", "🧸", "😊", "🧸"]
            return frames[frame % 4]
        case .eating:
            let frames = ["🧸", "🍯", "😋", "🍯"]
            return frames[frame % 4]
        case .sleeping:
            return frame % 4 < 2 ? "😴" : "💤"
        case .dancing:
            let frames = ["🕺", "🧸", "💃", "🧸"]
            return frames[frame % 4]
        case .chasing:
            let frames = ["🧸", "🏃", "🧸", "🏃"]
            return frames[frame % 4]
        case .poked:
            let frames = ["😤", "🧸", "😤", "🧸"]
            return frames[frame % 4]
        }
    }

    var bodyScale: CGFloat {
        switch state {
        case .dancing: return frame % 2 == 0 ? 1.1 : 0.95
        case .happy: return frame % 2 == 0 ? 1.08 : 1.0
        case .poked: return frame % 2 == 0 ? 0.9 : 1.05
        default: return 1.0
        }
    }

    var bodyRotation: Angle {
        switch state {
        case .dancing: return .degrees(frame % 4 < 2 ? -12 : 12)
        case .chasing: return .degrees(-5)
        case .poked: return .degrees(frame % 2 == 0 ? -8 : 8)
        default: return .degrees(0)
        }
    }
}

// MARK: - 眼睛跟随组件
struct Eye: View {
    let offset: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.0001)) // 透明底，占位用
                .frame(width: 10, height: 10)

            Circle()
                .fill(Color.black)
                .frame(width: 4, height: 4)
                .offset(x: offset.width * 0.6, y: -offset.height * 0.6)
        }
    }
}

// MARK: - 跳舞特效
struct DanceEffectView: View {
    let frame: Int
    let notes = ["🎵", "🎶", "✨", "⭐️"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<2) { i in
                Text(notes[(frame + i * 2) % notes.count])
                    .font(.system(size: 14))
                    .offset(y: CGFloat((frame + i) % 3) * -5)
                    .opacity(0.8)
            }
        }
    }
}

// MARK: - 气泡
struct BubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 1.0, green: 0.97, blue: 0.88))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.95, green: 0.85, blue: 0.65), lineWidth: 1.5)
                    )
            )
            .frame(maxWidth: 190)
            .multilineTextAlignment(.center)
    }
}

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + 2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - 脚印视图
struct FootprintView: View {
    var body: some View {
        Text("🐾")
            .font(.system(size: 22))
            .opacity(0.75)
    }
}

// MARK: - ViewModel 公开方法补充
extension PetViewModel {
    func startDancing() {
        state = .dancing
        showSpeech("🎵 跳个舞～")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            if self?.state == .dancing { self?.state = .idle }
        }
    }
}
