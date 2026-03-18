import Foundation

func petHTML() -> String {
    return """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body {
    width: 280px; height: 340px;
    background: transparent;
    overflow: hidden;
    -webkit-user-select: none;
    user-select: none;
  }
  canvas {
    display: block;
    background: transparent;
  }
  #bubble {
    position: absolute;
    bottom: 85px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(255,250,235,0.96);
    border: 1.5px solid #e8c87a;
    border-radius: 16px;
    padding: 8px 14px;
    font-family: -apple-system, 'PingFang SC', sans-serif;
    font-size: 13px;
    color: #4a3520;
    white-space: nowrap;
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.3s ease;
    box-shadow: 0 3px 12px rgba(0,0,0,0.15);
    z-index: 100;
    max-width: 240px;
    white-space: normal;
    text-align: center;
  }
  #bubble.show { opacity: 1; }
  #bubble::after {
    content: '';
    position: absolute;
    bottom: -8px;
    left: 50%;
    transform: translateX(-50%);
    border: 7px solid transparent;
    border-top-color: #e8c87a;
    border-bottom: none;
  }
  #status-bar {
    position: absolute;
    bottom: 6px;
    left: 0; right: 0;
    display: flex;
    justify-content: center;
    gap: 8px;
    pointer-events: none;
    font-size: 11px;
    color: rgba(255,255,255,0.8);
    text-shadow: 0 1px 3px rgba(0,0,0,0.5);
  }
  #menu-btn {
    position: absolute;
    top: 6px; right: 6px;
    width: 22px; height: 22px;
    background: rgba(255,255,255,0.15);
    border-radius: 50%;
    cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    font-size: 14px;
    opacity: 0;
    transition: opacity 0.2s;
  }
  body:hover #menu-btn { opacity: 1; }
</style>
</head>
<body>

<canvas id="canvas" width="280" height="300"></canvas>
<div id="bubble" class="bubble"></div>
<div id="status-bar">
  <span id="stat-mood">💛💛💛</span>
  <span id="stat-food">🍯🍯🍯</span>
</div>

<script>
// ---- 配置 ----
const MODEL_URL = "https://cdn.jsdelivr.net/gh/guansss/pixi-live2d-display/test/assets/shizuku/shizuku.model.json";
const DIALOGUES = [
  "主人好呀～ヾ(≧▽≦*)",
  "摸摸我嘛 (o´ω`o)",
  "今天也要加油哦！",
  "🍬 想吃甜食了～",
  "嘿嘿～",
  "主人在忙嘛？",
  "呼噜呼噜...",
  "✨ 今天心情很好！",
  "来陪我玩嘛！(>ω<)",
  "嗯...有点困了",
];

let app, model;
let happiness = 70, hunger = 40;
let bubbleTimer = null;

// 动态加载脚本
function loadScript(src) {
  return new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = src;
    s.onload = resolve;
    s.onerror = reject;
    document.head.appendChild(s);
  });
}

async function init() {
  try {
    // 加载 PixiJS + pixi-live2d-display + Cubism4 core
    await loadScript('https://cdn.jsdelivr.net/npm/pixi.js@6/dist/browser/pixi.min.js');
    await loadScript('https://cdn.jsdelivr.net/gh/dylanNew/live2d/webgl/Live2D/lib/live2d.min.js');
    await loadScript('https://cubism.live2d.com/sdk-web/cubismcore/live2dcubismcore.min.js');
    await loadScript('https://cdn.jsdelivr.net/npm/pixi-live2d-display/dist/index.min.js');

    window.PIXI.live2d.config.logLevel = 0;

    app = new PIXI.Application({
      view: document.getElementById('canvas'),
      width: 280,
      height: 300,
      backgroundAlpha: 0,
      antialias: true,
      resolution: window.devicePixelRatio || 2,
      autoDensity: true,
    });

    model = await PIXI.live2d.Live2DModel.from(MODEL_URL, {
      autoInteract: false,
    });

    model.scale.set(0.18);
    model.anchor.set(0.5, 0);
    model.x = app.renderer.width / 2;
    model.y = 10;

    // 自动调整大小
    model.on('load', () => {
      fitModel();
    });
    fitModel();

    app.stage.addChild(model);

    // 交互
    model.interactive = true;

    // 单击 = 戳戳
    model.on('pointertap', (e) => {
      const local = model.toLocal(e.data.global);
      const hit = model.hitTest(local.x, local.y);
      if (hit && hit.length > 0) {
        onPoke(hit[0]);
      } else {
        onPoke('body');
      }
    });

    // 鼠标悬停 = 眼睛跟随
    document.addEventListener('mousemove', (e) => {
      if (!model || !model.internalModel) return;
      const rect = document.getElementById('canvas').getBoundingClientRect();
      const mx = (e.clientX - rect.left) / rect.width * 2 - 1;
      const my = -((e.clientY - rect.top) / rect.height * 2 - 1);
      model.focus(e.clientX - rect.left, e.clientY - rect.top);
    });

    startAutoBehavior();
    showBubble("你好～我是你的桌宠！(｡•̀ᴗ-)✧");

  } catch(e) {
    console.error('Live2D init failed:', e);
    showFallback();
  }
}

function fitModel() {
  if (!model) return;
  const canvasW = 280, canvasH = 300;
  const mw = model.internalModel?.originalWidth || 1200;
  const mh = model.internalModel?.originalHeight || 2400;
  const scale = Math.min(canvasW / mw, canvasH / mh) * 1.1;
  model.scale.set(scale);
  model.x = canvasW / 2;
  model.y = 0;
}

// ---- 互动 ----
function onPoke(area) {
  happiness = Math.max(0, happiness - 5);
  const msgs = {
    head: ["哎！别戳头！", "嗷～轻点！", "别弄乱我头发！"],
    body: ["嗯？做什么？", "痒痒的！(＞＜)", "戳什么戳！"],
    default: ["嘿！别乱戳！", "OAO 好痒！", "欸欸欸！"]
  };
  const pool = msgs[area] || msgs.default;
  showBubble(pool[Math.floor(Math.random() * pool.length)]);
  if (model && model.internalModel) {
    model.motion('tap_body');
  }
  updateStatus();
}

function onStroke() {
  happiness = Math.min(100, happiness + 20);
  showBubble(["好舒服～(*´▽`*)", "呼噜呼噜...", "最喜欢主人了！❤️", "再摸摸嘛～"].at(Math.random()*4|0));
  if (model) model.motion('flick_head');
  updateStatus();
}

function onFeed() {
  hunger = Math.max(0, hunger - 50);
  happiness = Math.min(100, happiness + 15);
  showBubble(["好好吃！(≧∇≦)/", "🍬 甜甜的～", "谢谢主人！"].at(Math.random()*3|0));
  updateStatus();
}

// ---- 自主行为 ----
function startAutoBehavior() {
  setInterval(() => {
    hunger = Math.min(100, hunger + 3);
    happiness = Math.max(0, happiness - 1);

    const r = Math.random();
    if (r < 0.3 && model) {
      // 随机动作
      const motions = ['idle', 'tap_body', 'pinch_in', 'shake'];
      model.motion(motions[Math.floor(Math.random() * motions.length)]);
    } else if (r < 0.5) {
      // 随机说话
      showBubble(DIALOGUES[Math.floor(Math.random() * DIALOGUES.length)]);
    }
    updateStatus();
  }, 5000);
}

// ---- UI ----
function showBubble(text) {
  const el = document.getElementById('bubble');
  el.textContent = text;
  el.classList.add('show');
  clearTimeout(bubbleTimer);
  bubbleTimer = setTimeout(() => el.classList.remove('show'), 3500);
}

function updateStatus() {
  const h = '💛'.repeat(Math.max(1, Math.round(happiness/25)));
  const f = '🍯'.repeat(Math.max(1, Math.round((100-hunger)/25)));
  document.getElementById('stat-mood').textContent = h;
  document.getElementById('stat-food').textContent = f;
}

// ---- 右键菜单 ----
document.addEventListener('contextmenu', (e) => {
  e.preventDefault();
  window.webkit?.messageHandlers?.contextMenu?.postMessage('show');
});

// ---- 降级显示 ----
function showFallback() {
  document.body.innerHTML = `
    <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;
                height:300px;background:transparent;">
      <div style="font-size:80px;animation:bounce 1s infinite alternate;">🧸</div>
      <div id="bubble2" style="margin-top:12px;padding:8px 14px;background:rgba(255,250,235,0.96);
           border:1.5px solid #e8c87a;border-radius:14px;font-size:13px;
           font-family:-apple-system,sans-serif;color:#4a3520;">
        你好！我是你的桌宠 (●'◡'●)
      </div>
    </div>
    <style>
      @keyframes bounce{from{transform:translateY(0)}to{transform:translateY(-12px)}}
    </style>`;
}

// 启动
init();
</script>
</body>
</html>
"""
}
