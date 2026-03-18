# LinkPet - macOS 桌面宠物 Demo

一个参考 LinkPet 设计文档的 macOS 桌面宠物 Demo，使用 Swift + SwiftUI + AppKit 实现。

## 功能特性

- 🐱 悬浮在所有窗口最顶层，永远可见
- 🖱️ 可拖动到桌面任意位置
- 🚶 自主在桌面随机漫步
- 💬 随机弹出对话气泡
- 😴 会睡觉（快乐值低时）
- 🐟 喂食互动（右键菜单）
- 😻 摸头互动（点击或右键）
- 📊 查看宠物状态（快乐/饥饿）

## 项目结构

```
LinkPet/
├── AppDelegate.swift     # 应用入口，隐藏 Dock 图标
├── PetViewModel.swift    # 宠物状态机、行为逻辑
├── PetView.swift         # SwiftUI 视图（猫咪 + 气泡）
├── PetWindow.swift       # 透明悬浮窗口、拖动支持
├── Info.plist            # 应用配置
└── README.md
```

## 运行方法

### 方式一：Xcode（推荐）

1. 打开 Xcode，新建 macOS App 项目（App Delegate 模式，不用 SwiftUI lifecycle）
2. 将以上所有 `.swift` 文件复制到项目中
3. 将 `Info.plist` 内容合并到项目的 Info.plist
4. 设置 Deployment Target: macOS 12.0+
5. 删除默认生成的 `MainMenu.xib` 或 `Main.storyboard` 引用
6. Command+R 运行

### 方式二：Swift Package (命令行)

> 注意：需要 Xcode 环境，纯命令行编译 AppKit 应用需要额外配置。

## 交互说明

| 操作 | 效果 |
|------|------|
| 点击宠物 | 摸头，快乐度+20 |
| 右键菜单 → 喂食 | 饥饿度-40，快乐度+10 |
| 右键菜单 → 摸摸 | 同点击 |
| 右键菜单 → 查看状态 | 显示快乐/饥饿状态气泡 |
| 拖动 | 移动宠物到桌面任意位置 |

## 宠物状态

- **idle** 😺 待机，轻微帧动画
- **walk** 🐈 随机漫步到目标位置
- **sit** 🐈‍⬛ 坐下休息
- **happy** 😻 被摸后开心状态
- **eating** 🐟 进食动画
- **sleeping** 😴 快乐度低时自动入睡

## 后续可扩展

- [ ] 替换为自绘精灵图（Sprite Sheet）动画
- [ ] 接入 AI 对话（调用本地 LLM 或 API）
- [ ] 双人共养模式（WebSocket 同步状态）
- [ ] 旅行系统（地图打卡、纪念品收集）
- [ ] 恶作剧功能（跟随鼠标、留下脚印）
- [ ] 代币养成系统
