import Foundation

func buildPetHTML(initialKarma: Int) -> String {
return """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
* { margin:0; padding:0; box-sizing:border-box; }
html, body {
  width:200px; height:260px;
  background: transparent;
  overflow: hidden;
  -webkit-user-select: none;
  font-family: -apple-system, 'PingFang SC', sans-serif;
}

/* ===== 招财猫容器 ===== */
#pet-container {
  position: relative;
  width: 200px;
  height: 210px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

/* ===== SVG 招财猫 ===== */
#cat-svg {
  width: 150px;
  height: 180px;
  cursor: pointer;
  filter: drop-shadow(0 6px 12px rgba(0,0,0,0.2));
  transition: transform 0.1s;
}
#cat-svg:active { transform: scale(0.95); }

/* ===== 招手动画 ===== */
#arm-right {
  transform-origin: 10px 5px;
  animation: wave 1.2s ease-in-out infinite;
}
@keyframes wave {
  0%,100% { transform: rotate(-20deg); }
  50%      { transform: rotate(25deg); }
}

/* ===== 眼睛跟随（通过JS控制）===== */
#eye-left-pupil, #eye-right-pupil {
  transition: transform 0.1s ease-out;
}

/* ===== 气泡 ===== */
#bubble {
  position: absolute;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255,250,235,0.97);
  border: 1.5px solid #e8c46a;
  border-radius: 14px;
  padding: 7px 12px;
  font-size: 12px;
  color: #3a2800;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s;
  box-shadow: 0 3px 10px rgba(0,0,0,0.15);
  z-index: 50;
  max-width: 180px;
  white-space: normal;
  text-align: center;
}
#bubble.show { opacity: 1; }
#bubble::after {
  content:'';
  position:absolute;
  bottom:-8px; left:50%;
  transform:translateX(-50%);
  border:7px solid transparent;
  border-top-color:#e8c46a;
  border-bottom:none;
}

/* ===== Karma 栏 ===== */
#karma-bar {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 50px;
  background: linear-gradient(135deg, rgba(255,215,0,0.15), rgba(255,165,0,0.1));
  border-top: 1px solid rgba(255,200,50,0.3);
  border-radius: 0 0 12px 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}
#karma-icon { font-size: 20px; }
#karma-count {
  font-size: 18px;
  font-weight: 700;
  color: #c8860a;
  text-shadow: 0 1px 2px rgba(0,0,0,0.1);
  min-width: 50px;
}
#karma-label {
  font-size: 11px;
  color: #a06010;
}

/* ===== 金币飞出动画 ===== */
.coin-popup {
  position: absolute;
  font-size: 16px;
  pointer-events: none;
  animation: coinFly 0.9s ease-out forwards;
  z-index: 100;
}
@keyframes coinFly {
  0%   { opacity:1; transform: translateY(0) scale(1); }
  100% { opacity:0; transform: translateY(-60px) scale(0.5); }
}

/* ===== 戳戳特效 ===== */
.poke-effect {
  position: absolute;
  font-size: 22px;
  pointer-events: none;
  animation: pokePop 0.6s ease-out forwards;
  z-index: 100;
}
@keyframes pokePop {
  0%   { opacity:1; transform:scale(0.5); }
  40%  { opacity:1; transform:scale(1.3); }
  100% { opacity:0; transform:scale(0.8); }
}
</style>
</head>
<body>

<div id="pet-container">
  <!-- 气泡 -->
  <div id="bubble">你好呀！</div>

  <!-- 招财猫 SVG -->
  <svg id="cat-svg" viewBox="0 0 120 150" xmlns="http://www.w3.org/2000/svg"
       onclick="onCatClick(event)">

    <!-- 身体 -->
    <ellipse cx="60" cy="110" rx="38" ry="32" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>

    <!-- 肚子花纹 -->
    <ellipse cx="60" cy="112" rx="22" ry="18" fill="#FFE4C4" opacity="0.6"/>

    <!-- 头部 -->
    <circle cx="60" cy="68" r="36" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>

    <!-- 头部橘色斑纹 -->
    <path d="M35 50 Q40 42 50 48" stroke="#F4A460" stroke-width="4" fill="none" stroke-linecap="round" opacity="0.7"/>
    <path d="M85 50 Q80 42 70 48" stroke="#F4A460" stroke-width="4" fill="none" stroke-linecap="round" opacity="0.7"/>
    <ellipse cx="60" cy="62" rx="14" ry="8" fill="#F4A460" opacity="0.25"/>

    <!-- 耳朵 -->
    <polygon points="28,45 18,22 42,38" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
    <polygon points="28,45 22,28 38,40" fill="#FFB6C1" opacity="0.8"/>
    <polygon points="92,45 102,22 78,38" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
    <polygon points="92,45 98,28 82,40" fill="#FFB6C1" opacity="0.8"/>

    <!-- 眼睛 -->
    <g id="eye-left">
      <circle cx="47" cy="66" r="9" fill="white" stroke="#333" stroke-width="1.2"/>
      <circle cx="47" cy="66" r="5.5" fill="#1a1a2e"/>
      <circle id="eye-left-pupil" cx="47" cy="66" r="5.5" fill="#1a1a2e"/>
      <circle cx="49" cy="63" r="1.8" fill="white" opacity="0.9"/>
    </g>
    <g id="eye-right">
      <circle cx="73" cy="66" r="9" fill="white" stroke="#333" stroke-width="1.2"/>
      <circle cx="73" cy="66" r="5.5" fill="#1a1a2e"/>
      <circle id="eye-right-pupil" cx="73" cy="66" r="5.5" fill="#1a1a2e"/>
      <circle cx="75" cy="63" r="1.8" fill="white" opacity="0.9"/>
    </g>

    <!-- 鼻子 -->
    <ellipse cx="60" cy="78" rx="4" ry="2.5" fill="#FF9999"/>
    <!-- 嘴 -->
    <path d="M56 81 Q60 85 64 81" stroke="#FF9999" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <!-- 舌头 -->
    <ellipse cx="60" cy="85" rx="4" ry="2.5" fill="#FF8080" opacity="0"/>
    <!-- 胡须 -->
    <line x1="20" y1="77" x2="45" y2="78" stroke="#AAA" stroke-width="1" opacity="0.7"/>
    <line x1="20" y1="82" x2="45" y2="80" stroke="#AAA" stroke-width="1" opacity="0.7"/>
    <line x1="75" y1="78" x2="100" y2="77" stroke="#AAA" stroke-width="1" opacity="0.7"/>
    <line x1="75" y1="80" x2="100" y2="82" stroke="#AAA" stroke-width="1" opacity="0.7"/>
    <!-- 腮红 -->
    <ellipse cx="36" cy="76" rx="7" ry="4" fill="#FFB6C1" opacity="0.5"/>
    <ellipse cx="84" cy="76" rx="7" ry="4" fill="#FFB6C1" opacity="0.5"/>

    <!-- 左爪（静止） -->
    <g id="arm-left">
      <ellipse cx="25" cy="118" rx="12" ry="10" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
      <line x1="20" y1="122" x2="22" y2="126" stroke="#E8C8A0" stroke-width="1.2"/>
      <line x1="25" y1="124" x2="25" y2="128" stroke="#E8C8A0" stroke-width="1.2"/>
      <line x1="30" y1="122" x2="28" y2="126" stroke="#E8C8A0" stroke-width="1.2"/>
    </g>

    <!-- 右爪（招手） -->
    <g id="arm-right">
      <ellipse cx="95" cy="88" rx="10" ry="12" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
      <line x1="90" y1="85" x2="88" y2="81" stroke="#E8C8A0" stroke-width="1.2"/>
      <line x1="95" y1="83" x2="95" y2="79" stroke="#E8C8A0" stroke-width="1.2"/>
      <line x1="100" y1="85" x2="102" y2="81" stroke="#E8C8A0" stroke-width="1.2"/>
    </g>

    <!-- 金币 -->
    <circle cx="25" cy="128" r="11" fill="#FFD700" stroke="#DAA520" stroke-width="1.5"/>
    <text x="25" y="132" text-anchor="middle" font-size="10" font-weight="bold" fill="#8B6914">福</text>

    <!-- 红色装饰项圈 -->
    <path d="M30 95 Q60 102 90 95" stroke="#CC2200" stroke-width="4" fill="none" stroke-linecap="round"/>
    <circle cx="60" cy="100" r="4" fill="#FFD700" stroke="#DAA520" stroke-width="1"/>

    <!-- 尾巴 -->
    <path d="M88 130 Q105 125 108 110 Q112 95 100 92" stroke="#E8C8A0" stroke-width="6" fill="none" stroke-linecap="round"/>
    <path d="M88 130 Q105 125 108 110 Q112 95 100 92" stroke="#FFF8F0" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.6"/>
  </svg>
</div>

<!-- Karma 栏 -->
<div id="karma-bar">
  <span id="karma-icon">🪙</span>
  <div>
    <div id="karma-count">0</div>
  </div>
  <div id="karma-label">福气值</div>
</div>

<script>
// ====== 状态 ======
var karma = \(initialKarma);
var bubbleTimer = null;
var isHappy = false;

const FORTUNES = [
  "🌸 上上签：今日诸事皆宜，好运连连！",
  "🌟 大吉：贵人相助，财运亨通～",
  "✨ 中签：平稳前行，稳中有升",
  "🍀 吉签：坚持就是胜利，加油！",
  "🌙 平签：今日宜静，静待花开",
  "🎋 小吉：小有收获，知足常乐",
  "🔮 上签：机遇将至，把握时机！",
  "💫 吉：今日与贵人相遇，留意身边人",
  "🌺 大吉大利：今晚吃鸡！",
  "⭐ 吉签：心想事成，梦想成真～",
];

const POKE_MSGS = ["哎！别戳我！(＞﹏＜)", "嗷～轻点嘛！", "好痒！OwO", "戳什么戳！(｀へ´)"];
const STROKE_MSGS = ["呼噜呼噜～♪", "好舒服呀！(o´▽`o)", "再摸摸～", "最喜欢主人了！❤️"];
const IDLE_MSGS = ["今天也要带来好运哦！✨", "嘿嘿～(≧▽≦)", "主人辛苦啦！", "🪙 福气满满～", "喵～有什么需要吗？"];

// ====== 初始化 ======
document.addEventListener('DOMContentLoaded', function() {
  updateKarmaDisplay();
  showBubble("你好呀！我是招财猫～ 🪙");
  startIdleChatter();
  startMouseTracking();
});

// ====== 键击事件（Swift 调用）======
function onKeystroke() {
  karma += 1;
  saveKarma();
  updateKarmaDisplay();
  spawnCoin();
  // 每100次特别庆祝
  if (karma % 100 === 0) {
    showBubble("🎉 已积累 " + karma + " 福气！超厉害！");
    triggerHappy();
  }
}

// ====== 金币飞出 ======
function spawnCoin() {
  const container = document.getElementById('pet-container');
  const coin = document.createElement('div');
  coin.className = 'coin-popup';
  coin.textContent = '🪙';
  coin.style.left = (60 + Math.random() * 60) + 'px';
  coin.style.top = (100 + Math.random() * 40) + 'px';
  container.appendChild(coin);
  setTimeout(() => coin.remove(), 900);
}

// ====== 点击猫咪 ======
var clickCount = 0;
var clickTimer = null;
function onCatClick(e) {
  clickCount++;
  clearTimeout(clickTimer);
  clickTimer = setTimeout(function() {
    if (clickCount >= 2) {
      // 双击 = 摸摸
      onStroke();
    } else {
      // 单击 = 戳戳
      onPoke(e);
    }
    clickCount = 0;
  }, 280);
}

function onPoke(e) {
  const msg = POKE_MSGS[Math.floor(Math.random() * POKE_MSGS.length)];
  showBubble(msg);
  // 特效
  const container = document.getElementById('pet-container');
  const fx = document.createElement('div');
  fx.className = 'poke-effect';
  fx.textContent = '💢';
  fx.style.left = (e ? e.offsetX - 10 : 80) + 'px';
  fx.style.top = (e ? e.offsetY - 20 : 60) + 'px';
  container.appendChild(fx);
  setTimeout(() => fx.remove(), 600);
}

function onStroke() {
  karma += 5;
  saveKarma();
  updateKarmaDisplay();
  const msg = STROKE_MSGS[Math.floor(Math.random() * STROKE_MSGS.length)];
  showBubble(msg);
  triggerHappy();
}

function triggerHappy() {
  const svg = document.getElementById('cat-svg');
  svg.style.transform = 'scale(1.08)';
  setTimeout(() => svg.style.transform = '', 400);
}

// ====== 求签 ======
function doFortune() {
  if (karma < 50) {
    showBubble("福气不足！需要50福气才能求签 🪙");
    return;
  }
  karma -= 50;
  saveKarma();
  updateKarmaDisplay();
  const fortune = FORTUNES[Math.floor(Math.random() * FORTUNES.length)];
  showBubble(fortune, 5000);
}

// ====== 喂零食 ======
function doFeed() {
  karma += 20;
  saveKarma();
  updateKarmaDisplay();
  showBubble("好好吃！谢谢主人！(≧∇≦)/ 🍬");
  triggerHappy();
}

// ====== 眼睛跟随 ======
function startMouseTracking() {
  document.addEventListener('mousemove', function(e) {
    const rect = document.getElementById('cat-svg').getBoundingClientRect();
    const catCX = rect.left + rect.width/2;
    const catCY = rect.top + rect.height * 0.45;
    const dx = e.clientX - catCX;
    const dy = e.clientY - catCY;
    const dist = Math.sqrt(dx*dx + dy*dy) || 1;
    const maxOffset = 2.5;
    const ox = (dx/dist) * maxOffset;
    const oy = (dy/dist) * maxOffset;

    document.getElementById('eye-left-pupil').setAttribute('transform',
      'translate(' + ox + ',' + oy + ')');
    document.getElementById('eye-right-pupil').setAttribute('transform',
      'translate(' + ox + ',' + oy + ')');
  });
}

// ====== 随机闲话 ======
function startIdleChatter() {
  setInterval(function() {
    if (Math.random() < 0.4) {
      showBubble(IDLE_MSGS[Math.floor(Math.random() * IDLE_MSGS.length)]);
    }
  }, 8000);
}

// ====== UI ======
function showBubble(text, duration) {
  const el = document.getElementById('bubble');
  el.textContent = text;
  el.classList.add('show');
  clearTimeout(bubbleTimer);
  bubbleTimer = setTimeout(function() {
    el.classList.remove('show');
  }, duration || 3500);
}

function updateKarmaDisplay() {
  document.getElementById('karma-count').textContent = karma;
}

// ====== 持久化（调用 Swift）======
function saveKarma() {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.petBridge) {
    window.webkit.messageHandlers.petBridge.postMessage({action:'saveKarma', karma: karma});
  }
}

// ====== 右键菜单 ======
document.addEventListener('contextmenu', function(e) {
  e.preventDefault();
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.petBridge) {
    window.webkit.messageHandlers.petBridge.postMessage({action:'showMenu'});
  }
});
</script>
</body>
</html>
"""
}
