import Foundation

func buildPetHTML(initialKarma: Int) -> String {
let karmaJS = initialKarma
return """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
* { margin:0; padding:0; box-sizing:border-box; }
html, body {
  width:200px; height:280px;
  background: transparent;
  overflow: hidden;
  -webkit-user-select: none;
  font-family: -apple-system, 'PingFang SC', sans-serif;
}

#pet-container {
  position: relative;
  width: 200px;
  height: 220px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

#cat-svg {
  width: 160px;
  height: 200px;
  cursor: pointer;
  filter: drop-shadow(0 8px 16px rgba(0,0,0,0.18));
}

/* 招手动画 */
#arm-right {
  transform-origin: 108px 92px;
  animation: wave 1.1s ease-in-out infinite;
}
@keyframes wave {
  0%,100% { transform: rotate(-18deg); }
  50%      { transform: rotate(22deg); }
}

/* 尾巴摇摆 */
#tail {
  transform-origin: 88px 130px;
  animation: tailWag 2s ease-in-out infinite;
}
@keyframes tailWag {
  0%,100% { transform: rotate(-5deg); }
  50%      { transform: rotate(8deg); }
}

/* 身体呼吸 */
#body-group {
  transform-origin: 60px 110px;
  animation: breathe 3s ease-in-out infinite;
}
@keyframes breathe {
  0%,100% { transform: scaleY(1); }
  50%      { transform: scaleY(1.025); }
}

/* 眨眼（JS控制class） */
.blink #eye-left-white, .blink #eye-right-white {
  transform: scaleY(0.05);
}
#eye-left-white, #eye-right-white {
  transition: transform 0.08s;
  transform-origin: center;
}

/* 状态指示 */
#state-icon {
  position: absolute;
  top: 8px;
  right: 8px;
  font-size: 16px;
  opacity: 0;
  transition: opacity 0.4s;
  pointer-events: none;
}
#state-icon.show { opacity: 1; }

/* 帽子叠加层 */
#hat-overlay {
  position: absolute;
  top: 12px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 32px;
  pointer-events: none;
  transition: opacity 0.3s;
}

/* 气泡 */
#bubble {
  position: absolute;
  top: 6px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255,250,235,0.97);
  border: 1.5px solid #e8c46a;
  border-radius: 14px;
  padding: 7px 12px;
  font-size: 12px;
  color: #3a2800;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s;
  box-shadow: 0 3px 10px rgba(0,0,0,0.15);
  z-index: 50;
  max-width: 175px;
  white-space: normal;
  text-align: center;
  line-height: 1.4;
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

/* Karma 栏 */
#karma-bar {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 60px;
  background: linear-gradient(135deg, rgba(255,220,50,0.18), rgba(255,160,30,0.12));
  border-top: 1px solid rgba(255,200,50,0.35);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
}
#karma-row {
  display: flex;
  align-items: center;
  gap: 5px;
}
#karma-count {
  font-size: 20px;
  font-weight: 800;
  color: #c8760a;
  min-width: 52px;
  text-align: center;
}
#karma-label { font-size: 11px; color: #a06010; }
#state-text { font-size: 11px; color: #888; height: 14px; }

/* 金币飞出 */
.coin-popup {
  position: absolute;
  font-size: 15px;
  pointer-events: none;
  animation: coinFly 0.85s ease-out forwards;
  z-index: 100;
}
@keyframes coinFly {
  0%   { opacity:1; transform:translateY(0) scale(1) rotate(0deg); }
  100% { opacity:0; transform:translateY(-65px) scale(0.4) rotate(180deg); }
}

/* 戳戳特效 */
.poke-effect {
  position:absolute; font-size:20px; pointer-events:none;
  animation:pokePop 0.55s ease-out forwards; z-index:100;
}
@keyframes pokePop {
  0%  {opacity:1;transform:scale(0.4);}
  40% {opacity:1;transform:scale(1.4);}
  100%{opacity:0;transform:scale(0.7);}
}

/* 换装面板 */
#wardrobe {
  display:none;
  position:fixed; top:0;left:0;right:0;bottom:0;
  background:rgba(0,0,0,0.5);
  z-index:200;
  align-items:center;
  justify-content:center;
}
#wardrobe.open { display:flex; }
#wardrobe-box {
  background:#fffbf0;
  border-radius:18px;
  padding:16px;
  width:180px;
  box-shadow:0 8px 30px rgba(0,0,0,0.25);
}
#wardrobe-box h3 {
  font-size:13px; color:#5a3800; text-align:center;
  margin-bottom:10px;
}
.hat-item {
  display:flex; align-items:center; justify-content:space-between;
  padding:6px 8px; border-radius:10px; margin-bottom:6px;
  cursor:pointer;
  border:1.5px solid transparent;
  transition:all 0.2s;
}
.hat-item:hover { background:#fff3d0; border-color:#e8c46a; }
.hat-item.equipped { background:#fff0b0; border-color:#d4a00a; }
.hat-item .hat-emoji { font-size:20px; }
.hat-item .hat-info { flex:1; margin-left:6px; }
.hat-item .hat-name { font-size:11px; font-weight:600; color:#3a2800; }
.hat-item .hat-cost { font-size:10px; color:#a06010; }
.hat-item .hat-btn {
  font-size:10px; padding:3px 7px;
  background:#e8c46a; color:#5a3000;
  border:none; border-radius:8px; cursor:pointer;
  font-weight:600;
}
.hat-item .hat-btn.owned { background:#c8e88a; color:#2a5000; }
#wardrobe-close {
  width:100%; margin-top:8px;
  padding:7px; border:none; border-radius:10px;
  background:#f0d888; color:#5a3000; font-size:12px; font-weight:600;
  cursor:pointer;
}
</style>
</head>
<body>

<div id="pet-container">
  <div id="state-icon">💤</div>
  <div id="hat-overlay"></div>
  <div id="bubble"></div>

  <svg id="cat-svg" viewBox="0 0 120 160" xmlns="http://www.w3.org/2000/svg"
       onclick="onCatClick(event)" onmouseover="onHover()">

    <!-- 尾巴（最底层） -->
    <g id="tail">
      <path d="M85 132 Q108 122 112 105 Q116 90 102 87"
            stroke="#E8C8A0" stroke-width="7" fill="none" stroke-linecap="round"/>
      <path d="M85 132 Q108 122 112 105 Q116 90 102 87"
            stroke="#FFF8F0" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.7"/>
    </g>

    <!-- 身体组 -->
    <g id="body-group">
      <ellipse cx="60" cy="116" rx="37" ry="30" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
      <ellipse cx="60" cy="118" rx="22" ry="17" fill="#FFE4C4" opacity="0.55"/>
      <!-- 项圈 -->
      <path d="M30 98 Q60 106 90 98" stroke="#CC2200" stroke-width="4.5" fill="none" stroke-linecap="round"/>
      <circle cx="60" cy="103" r="4.5" fill="#FFD700" stroke="#DAA520" stroke-width="1.2"/>
      <!-- 左爪 -->
      <g id="arm-left">
        <ellipse cx="24" cy="122" rx="11" ry="9" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.3"/>
        <line x1="19" y1="126" x2="21" y2="130" stroke="#D8B890" stroke-width="1.2"/>
        <line x1="24" y1="128" x2="24" y2="132" stroke="#D8B890" stroke-width="1.2"/>
        <line x1="29" y1="126" x2="27" y2="130" stroke="#D8B890" stroke-width="1.2"/>
      </g>
    </g>

    <!-- 头部 -->
    <circle cx="60" cy="70" r="36" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
    <!-- 头部斑纹 -->
    <ellipse cx="60" cy="63" rx="13" ry="7" fill="#F4A460" opacity="0.22"/>
    <path d="M36 52 Q41 44 51 50" stroke="#F4A460" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.65"/>
    <path d="M84 52 Q79 44 69 50" stroke="#F4A460" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.65"/>

    <!-- 耳朵 -->
    <polygon points="29,47 19,24 43,40" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
    <polygon points="29,47 23,30 39,42" fill="#FFB6C1" opacity="0.75"/>
    <polygon points="91,47 101,24 77,40" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
    <polygon points="91,47 97,30 81,42" fill="#FFB6C1" opacity="0.75"/>

    <!-- 眼睛（可眨眼） -->
    <g id="eye-left-group">
      <ellipse id="eye-left-white" cx="47" cy="68" rx="9" ry="9" fill="white" stroke="#333" stroke-width="1.2"/>
      <circle id="eye-left-pupil" cx="47" cy="68" r="5.5" fill="#1a1a2e"/>
      <circle cx="49.5" cy="65" r="1.8" fill="white" opacity="0.9"/>
    </g>
    <g id="eye-right-group">
      <ellipse id="eye-right-white" cx="73" cy="68" rx="9" ry="9" fill="white" stroke="#333" stroke-width="1.2"/>
      <circle id="eye-right-pupil" cx="73" cy="68" r="5.5" fill="#1a1a2e"/>
      <circle cx="75.5" cy="65" r="1.8" fill="white" opacity="0.9"/>
    </g>

    <!-- 鼻子+嘴 -->
    <ellipse cx="60" cy="80" rx="3.5" ry="2.2" fill="#FF9999"/>
    <path d="M57 83 Q60 87 63 83" stroke="#FF9999" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <!-- 胡须 -->
    <line x1="18" y1="79" x2="44" y2="80" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <line x1="18" y1="84" x2="44" y2="82" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <line x1="76" y1="80" x2="102" y2="79" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <line x1="76" y1="82" x2="102" y2="84" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <!-- 腮红 -->
    <ellipse cx="36" cy="78" rx="7" ry="4" fill="#FFB6C1" opacity="0.45"/>
    <ellipse cx="84" cy="78" rx="7" ry="4" fill="#FFB6C1" opacity="0.45"/>

    <!-- 右爪（招手） -->
    <g id="arm-right">
      <ellipse cx="97" cy="90" rx="10" ry="12" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
      <line x1="92" y1="87" x2="90" y2="83" stroke="#D8B890" stroke-width="1.2"/>
      <line x1="97" y1="85" x2="97" y2="81" stroke="#D8B890" stroke-width="1.2"/>
      <line x1="102" y1="87" x2="104" y2="83" stroke="#D8B890" stroke-width="1.2"/>
    </g>

    <!-- 金币 -->
    <circle cx="24" cy="133" r="12" fill="#FFD700" stroke="#DAA520" stroke-width="1.8"/>
    <text x="24" y="138" text-anchor="middle" font-size="11" font-weight="bold" fill="#7a5a00">福</text>
  </svg>
</div>

<!-- Karma 栏 -->
<div id="karma-bar">
  <div id="karma-row">
    <span style="font-size:18px">🪙</span>
    <div id="karma-count">0</div>
    <span id="karma-label">福气值</span>
  </div>
  <div id="state-text">😊 状态良好</div>
</div>

<!-- 换装面板 -->
<div id="wardrobe">
  <div id="wardrobe-box">
    <h3>🎀 换装衣橱</h3>
    <div id="hat-list"></div>
    <button id="wardrobe-close" onclick="closeWardrobe()">关闭</button>
  </div>
</div>

<script>
// ======= 数据 =======
var karma = \(karmaJS);
var equippedHat = getLS('lp_hat') || 'none';
var ownedHats = JSON.parse(getLS('lp_owned') || '["none"]');
var petState = 'happy'; // happy / sleepy / hungry
var bubbleTimer = null;
var blinkTimer = null;
var idleTimer = 0;

const HATS = [
  {id:'none',    name:'无帽子',  emoji:'❌', cost:0},
  {id:'crown',   name:'金皇冠',  emoji:'👑', cost:100},
  {id:'santa',   name:'圣诞帽',  emoji:'🎅', cost:80},
  {id:'witch',   name:'魔女帽',  emoji:'🧙', cost:120},
  {id:'tophat',  name:'绅士帽',  emoji:'🎩', cost:150},
  {id:'flower',  name:'花朵发饰',emoji:'🌸', cost:60},
  {id:'bow',     name:'蝴蝶结',  emoji:'🎀', cost:50},
  {id:'halo',    name:'天使光环',emoji:'😇', cost:200},
];

const FORTUNES = [
  "🌸 上上签：今日诸事皆宜，出门必遇贵人！",
  "🌟 大吉：财运亨通，有意外之财降临～",
  "✨ 上签：坚持努力，好事将近！",
  "🍀 吉签：平稳前行，步步为赢",
  "🌙 中签：静待时机，蓄势待发",
  "🎋 小吉：知足常乐，心态平和万事顺",
  "🔮 吉：机遇将至，保持警觉！",
  "💫 大吉：今日与贵人有缘，注意结交",
  "🌺 上上签：大吉大利！诸事皆成！",
  "⭐ 吉签：梦想正在变为现实，继续！",
  "🎯 上签：目标明确，全力以赴必有收获",
  "🌈 大吉：彩虹之后是晴天，好运已在路上",
  "🦋 中上签：蜕变时刻来临，迎接新的自己",
  "🌊 吉：随波逐流未必坏，顺势而为",
  "🌻 上签：阳光总在风雨后，坚持就是胜利",
  "🎪 中签：生活多姿多彩，好好享受当下",
  "🍯 吉：甜蜜时刻将来临，期待惊喜",
  "🐉 上上签：龙马精神，大展宏图！",
  "🎵 吉签：心情愉快，好事自然来",
  "💎 大吉：珍贵机遇即将到来，把握住！",
];

const POKE_MSGS = [
  "哎！别戳我！(＞﹏＜)",
  "嗷～轻点嘛！",
  "好痒！OwO",
  "戳什么戳！(｀へ´)",
  "再戳我就生气了哦！",
  "欸欸欸！手拿开！",
];
const STROKE_MSGS = [
  "呼噜呼噜～♪",
  "好舒服呀！(o´▽`o)",
  "再摸摸嘛～",
  "最喜欢主人了！❤️",
  "摸摸头好幸福～",
];
const IDLE_MSGS = [
  "今天也要带来好运哦！✨",
  "嘿嘿～(≧▽≦)",
  "主人辛苦啦！加油！",
  "🪙 福气越来越多了！",
  "喵～有什么需要吗？",
  "打字打字！快积福气！",
  "我在这里陪着你哦 ♡",
  "今日运势：大吉大利！",
  "困了...打个盹儿好嘛",
  "🍬 好想吃零食...",
];

// ======= 初始化 =======
document.addEventListener('DOMContentLoaded', function() {
  updateKarmaDisplay();
  updateHatOverlay();
  renderWardrobe();
  startBlink();
  startMouseTracking();
  startIdleChatter();
  startStateCheck();
  setTimeout(function(){
    showBubble("你好呀！我是招财猫～ 🪙\\n打字就能积累福气！");
  }, 500);
});

// ======= 键击（Swift调用）=======
function onKeystroke() {
  karma += 1;
  idleTimer = 0;
  saveAll();
  updateKarmaDisplay();
  spawnCoin();
  if (karma % 50 === 0) showBubble("🎉 已积 " + karma + " 福气！", 3000);
  if (karma % 100 === 0) triggerHappy();
}

// ======= 金币飞出 =======
function spawnCoin() {
  if (Math.random() > 0.35) return; // 35%概率显示，避免太乱
  const c = document.getElementById('pet-container');
  const el = document.createElement('div');
  el.className = 'coin-popup';
  el.textContent = '🪙';
  el.style.left = (40 + Math.random() * 100) + 'px';
  el.style.top = (80 + Math.random() * 50) + 'px';
  c.appendChild(el);
  setTimeout(() => el.remove(), 900);
}

// ======= 点击 =======
var clickCount = 0, clickTimer = null;
function onCatClick(e) {
  clickCount++;
  clearTimeout(clickTimer);
  clickTimer = setTimeout(function(){
    if (clickCount >= 2) onStroke();
    else onPoke(e);
    clickCount = 0;
  }, 260);
}

function onHover() {
  // 轻微抖动
  const svg = document.getElementById('cat-svg');
  svg.style.filter = 'drop-shadow(0 8px 20px rgba(255,180,0,0.4))';
  setTimeout(() => svg.style.filter = 'drop-shadow(0 8px 16px rgba(0,0,0,0.18))', 300);
}

function onPoke(e) {
  idleTimer = 0;
  const msg = POKE_MSGS[Math.floor(Math.random()*POKE_MSGS.length)];
  showBubble(msg);
  const c = document.getElementById('pet-container');
  const fx = document.createElement('div');
  fx.className = 'poke-effect';
  fx.textContent = '💢';
  fx.style.left = ((e ? e.offsetX : 80) - 12) + 'px';
  fx.style.top = ((e ? e.offsetY : 70) - 20) + 'px';
  c.appendChild(fx);
  setTimeout(() => fx.remove(), 600);
  // 轻微震动
  const svg = document.getElementById('cat-svg');
  svg.style.transform = 'translateX(4px)';
  setTimeout(() => svg.style.transform = 'translateX(-4px)', 80);
  setTimeout(() => svg.style.transform = '', 160);
}

function onStroke() {
  idleTimer = 0;
  karma += 5;
  saveAll();
  updateKarmaDisplay();
  showBubble(STROKE_MSGS[Math.floor(Math.random()*STROKE_MSGS.length)]);
  triggerHappy();
  spawnCoin(); spawnCoin();
}

function triggerHappy() {
  const svg = document.getElementById('cat-svg');
  svg.style.transform = 'scale(1.08) rotate(-2deg)';
  setTimeout(() => { svg.style.transform = 'scale(1.04) rotate(2deg)'; }, 150);
  setTimeout(() => { svg.style.transform = ''; }, 300);
}

// ======= 眨眼 =======
function startBlink() {
  function doBlink() {
    const svg = document.getElementById('cat-svg');
    // 通过缩放眼白来模拟眨眼
    const lw = document.getElementById('eye-left-white');
    const rw = document.getElementById('eye-right-white');
    if (lw && rw) {
      lw.setAttribute('ry', '1');
      rw.setAttribute('ry', '1');
      setTimeout(() => {
        lw.setAttribute('ry', '9');
        rw.setAttribute('ry', '9');
      }, 120);
    }
    // 随机间隔 2-6 秒
    blinkTimer = setTimeout(doBlink, 2000 + Math.random() * 4000);
  }
  blinkTimer = setTimeout(doBlink, 1500);
}

// ======= 眼睛跟随 =======
function startMouseTracking() {
  document.addEventListener('mousemove', function(e) {
    const rect = document.getElementById('cat-svg').getBoundingClientRect();
    const cx = rect.left + rect.width * 0.5;
    const cy = rect.top + rect.height * 0.42;
    const dx = e.clientX - cx, dy = e.clientY - cy;
    const dist = Math.sqrt(dx*dx+dy*dy) || 1;
    const max = 2.5;
    const ox = dx/dist*max, oy = dy/dist*max;
    const lp = document.getElementById('eye-left-pupil');
    const rp = document.getElementById('eye-right-pupil');
    if(lp) lp.setAttribute('transform', 'translate('+ox+','+oy+')');
    if(rp) rp.setAttribute('transform', 'translate('+ox+','+oy+')');
  });
}

// ======= 状态系统 =======
function startStateCheck() {
  setInterval(function(){
    idleTimer++;
    if (idleTimer > 30) petState = 'sleepy';
    else if (karma < 20) petState = 'hungry';
    else petState = 'happy';
    updateStateUI();
  }, 1000);
}

function updateStateUI() {
  const st = document.getElementById('state-text');
  const si = document.getElementById('state-icon');
  if (petState === 'sleepy') {
    st.textContent = '😴 困了...';
    si.textContent = '💤'; si.classList.add('show');
  } else if (petState === 'hungry') {
    st.textContent = '🍬 好饿...';
    si.textContent = '🍬'; si.classList.add('show');
  } else {
    st.textContent = '😊 状态良好';
    si.classList.remove('show');
  }
}

// ======= 随机闲话 =======
function startIdleChatter() {
  setInterval(function(){
    if (Math.random() < 0.35) {
      if (petState === 'sleepy') showBubble('Zzz... 打个盹儿...(｡zzZ)');
      else if (petState === 'hungry') showBubble('好饿呀...主人记得喂我 🍬');
      else showBubble(IDLE_MSGS[Math.floor(Math.random()*IDLE_MSGS.length)]);
    }
  }, 7000);
}

// ======= 求签 =======
function doFortune() {
  if (karma < 50) { showBubble('福气不足！需要50福气才能求签 🪙', 3000); return; }
  karma -= 50;
  saveAll(); updateKarmaDisplay();
  const f = FORTUNES[Math.floor(Math.random()*FORTUNES.length)];
  showBubble(f, 5500);
  triggerHappy();
}

// ======= 喂零食 =======
function doFeed() {
  karma += 20;
  idleTimer = 0;
  petState = 'happy';
  saveAll(); updateKarmaDisplay();
  showBubble('好好吃！谢谢主人！(≧∇≦)/ 🍬', 3000);
  triggerHappy();
  spawnCoin(); spawnCoin(); spawnCoin();
}

// ======= 换装 =======
function openWardrobe() {
  document.getElementById('wardrobe').classList.add('open');
}
function closeWardrobe() {
  document.getElementById('wardrobe').classList.remove('open');
}
function renderWardrobe() {
  const list = document.getElementById('hat-list');
  list.innerHTML = '';
  HATS.forEach(function(h) {
    const owned = ownedHats.includes(h.id);
    const equipped = equippedHat === h.id;
    const div = document.createElement('div');
    div.className = 'hat-item' + (equipped ? ' equipped' : '');
    const btnLabel = equipped ? '已装备' : (owned ? '装备' : '购买 🪙'+h.cost);
    div.innerHTML =
      '<span class="hat-emoji">'+h.emoji+'</span>'+
      '<div class="hat-info">'+
        '<div class="hat-name">'+h.name+'</div>'+
        (owned ? '' : '<div class="hat-cost">需要 '+h.cost+' 福气</div>')+
      '</div>'+
      '<button class="hat-btn '+(owned?'owned':'')+'" onclick="handleHat(\''+h.id+'\','+h.cost+','+owned+')">'
        +btnLabel+'</button>';
    list.appendChild(div);
  });
}

function handleHat(id, cost, owned) {
  if (owned || cost === 0) {
    equippedHat = id;
    saveAll(); updateHatOverlay(); renderWardrobe();
    showBubble('换装成功！好看吗？ ✨', 2500);
    closeWardrobe();
  } else {
    if (karma < cost) { showBubble('福气不够！还需要 '+(cost-karma)+' 福气 🪙', 3000); return; }
    karma -= cost;
    ownedHats.push(id);
    equippedHat = id;
    saveAll(); updateKarmaDisplay(); updateHatOverlay(); renderWardrobe();
    showBubble('🎉 购买成功！新帽子超可爱！', 3000);
    closeWardrobe();
    triggerHappy();
  }
}

function updateHatOverlay() {
  const el = document.getElementById('hat-overlay');
  const hat = HATS.find(h => h.id === equippedHat);
  el.textContent = (hat && hat.id !== 'none') ? hat.emoji : '';
}

// ======= UI =======
function showBubble(text, dur) {
  const el = document.getElementById('bubble');
  el.textContent = text;
  el.classList.add('show');
  clearTimeout(bubbleTimer);
  bubbleTimer = setTimeout(() => el.classList.remove('show'), dur || 3500);
}

function updateKarmaDisplay() {
  document.getElementById('karma-count').textContent = karma;
}

// ======= 持久化 =======
function saveAll() {
  if (window.webkit && window.webkit.messageHandlers.petBridge) {
    window.webkit.messageHandlers.petBridge.postMessage({action:'saveKarma', karma:karma});
  }
  setLS('lp_hat', equippedHat);
  setLS('lp_owned', JSON.stringify(ownedHats));
}
function setLS(k,v){ try{localStorage.setItem(k,v);}catch(e){} }
function getLS(k){ try{return localStorage.getItem(k);}catch(e){return null;} }

// ======= 右键 =======
document.addEventListener('contextmenu', function(e) {
  e.preventDefault();
  if (window.webkit && window.webkit.messageHandlers.petBridge) {
    window.webkit.messageHandlers.petBridge.postMessage({action:'showMenu'});
  }
});
</script>
</body>
</html>
"""
}
