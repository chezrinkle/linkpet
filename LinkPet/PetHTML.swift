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
  width:200px; height:300px;
  background: transparent;
  overflow: visible;  /* Fix-Bug11: 允许气泡超出顶部 */
  -webkit-user-select: none;
  font-family: -apple-system, 'PingFang SC', sans-serif;
}

/* ===== 主容器 ===== */
#pet-container {
  position: relative;
  width: 200px;
  height: 228px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  overflow: visible;  /* Fix-Bug11: 允许气泡超出 */
}

/* ===== 招财猫 SVG ===== */
#cat-svg {
  width: 164px;
  height: 205px;
  cursor: pointer;
  filter: drop-shadow(0 8px 16px rgba(0,0,0,0.18));
  transition: filter 0.25s;
}
#cat-svg:hover {
  filter: drop-shadow(0 8px 22px rgba(255,185,0,0.45));
}

/* 招手 */
#arm-right {
  transform-origin: 108px 92px;
  animation: wave 1.1s ease-in-out infinite;
}
@keyframes wave {
  0%,100% { transform: rotate(-18deg); }
  50%      { transform: rotate(22deg); }
}
/* 跳舞时加速 */
#cat-svg.dancing #arm-right { animation-duration: 0.35s; }

/* 尾巴 */
#tail {
  transform-origin: 88px 130px;
  animation: tailWag 2.2s ease-in-out infinite;
}
@keyframes tailWag {
  0%,100% { transform: rotate(-5deg); }
  50%      { transform: rotate(9deg); }
}
#cat-svg.dancing #tail { animation-duration: 0.5s; }

/* 呼吸 */
#body-group {
  transform-origin: 60px 116px;
  animation: breathe 3.2s ease-in-out infinite;
}
@keyframes breathe {
  0%,100% { transform: scaleY(1); }
  50%      { transform: scaleY(1.025); }
}

/* 跳舞整体弹跳 — 用wrapper避免和triggerHappy的transform冲突 */
#cat-svg.dancing {
  animation: bounce 0.4s ease-in-out infinite;
  transform-origin: center bottom;
}
@keyframes bounce {
  0%,100% { transform: translateY(0); }
  50%      { transform: translateY(-8px); }
}

/* 专注打字：眼睛变小（css class） */
#cat-svg.focus #eye-left-white { ry: 7; }
#cat-svg.focus #eye-right-white { ry: 7; }

/* ===== 帽子浮层 ===== */
#hat-overlay {
  position: absolute;
  top: 8px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 34px;
  pointer-events: none;
}

/* ===== 状态图标 ===== */
#state-icon {
  position: absolute;
  top: 10px; right: 6px;
  font-size: 15px;
  opacity: 0;
  transition: opacity 0.4s;
  pointer-events: none;
  animation: floatUpDown 2s ease-in-out infinite;
}
#state-icon.show { opacity: 1; }
@keyframes floatUpDown {
  0%,100% { transform: translateY(0); }
  50%      { transform: translateY(-4px); }
}

/* ===== 气泡 ===== */
#bubble {
  /* Fix-G: fixed定位 + 显示在窗口上方，彻底绕开 WKWebView clipBounds */
  position: fixed;
  bottom: 232px; left: 4px; right: 4px;
  transform: none;
  background: rgba(255,250,235,0.97);
  border: 1.5px solid #e8c46a;
  border-radius: 14px;
  padding: 7px 11px;
  font-size: 11.5px;
  color: #3a2800;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s;
  box-shadow: 0 3px 12px rgba(0,0,0,0.14);
  z-index: 9999;
  max-width: 192px;
  white-space: normal;
  text-align: center;
  line-height: 1.45;
}
#bubble.show { opacity: 1; }
/* 气泡尾巴朝下 */
#bubble::after {
  content:''; position:absolute;
  bottom:-8px; left:50%; transform:translateX(-50%);
  border:7px solid transparent;
  border-top-color:#e8c46a; border-bottom:none;
}

/* ===== 底部面板 ===== */
#bottom-panel {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 72px;
  background: linear-gradient(160deg, rgba(255,225,60,0.16), rgba(255,160,30,0.10));
  border-top: 1px solid rgba(255,200,50,0.3);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 0 10px;
}

/* Karma 行 */
#karma-row {
  display: flex; align-items: center; gap: 5px;
  width: 100%;
}
#karma-icon { font-size: 17px; }
#karma-count {
  font-size: 20px; font-weight: 800; color: #c8760a;
  min-width: 48px; text-align: left;
}
#karma-label { font-size: 11px; color: #a06010; flex:1; }

/* 心情条 */
#mood-row {
  display: flex; align-items: center; gap: 5px; width: 100%;
}
#mood-label { font-size: 10px; color: #888; width: 34px; }
#mood-bar-bg {
  flex:1; height: 7px; background: rgba(0,0,0,0.08);
  border-radius: 4px; overflow: hidden;
}
#mood-bar-fill {
  height: 100%; border-radius: 4px;
  background: linear-gradient(90deg, #ff9999, #ffcc00, #66dd66);
  transition: width 0.5s ease, background 0.5s;
}
#mood-emoji { font-size: 13px; }

/* 状态文字 */
#state-text { font-size: 10.5px; color: #999; }

/* ===== 金币飞出 ===== */
.coin-popup {
  position:absolute; font-size:14px; pointer-events:none;
  animation: coinFly 0.9s ease-out forwards; z-index:100;
}
@keyframes coinFly {
  0%   { opacity:1; transform:translateY(0) scale(1) rotate(0deg); }
  100% { opacity:0; transform:translateY(-70px) scale(0.35) rotate(200deg); }
}

/* 里程碑特效 */
.milestone-fx {
  position:absolute; font-size:22px; pointer-events:none;
  animation:milestonePop 1.2s ease-out forwards; z-index:200;
}
@keyframes milestonePop {
  0%  {opacity:1;transform:scale(0.3) translateY(0);}
  40% {opacity:1;transform:scale(1.5) translateY(-20px);}
  100%{opacity:0;transform:scale(1) translateY(-60px);}
}

/* ===== 戳戳特效 ===== */
.poke-effect {
  position:absolute; font-size:20px; pointer-events:none;
  animation:pokePop 0.55s ease-out forwards; z-index:100;
}
@keyframes pokePop {
  0%  {opacity:1;transform:scale(0.4);}
  40% {opacity:1;transform:scale(1.4);}
  100%{opacity:0;transform:scale(0.7);}
}

/* ===== 换装面板 ===== */
#wardrobe {
  display:none; position:fixed; top:0;left:0;right:0;bottom:0;
  background:rgba(0,0,0,0.48); z-index:200;
  align-items:center; justify-content:center;
}
#wardrobe.open { display:flex; }
#wardrobe-box {
  background:#fffbf0; border-radius:18px;
  padding:14px; width:178px;
  box-shadow:0 8px 30px rgba(0,0,0,0.28);
  max-height:260px; overflow-y:auto;
}
#wardrobe-box h3 {
  font-size:13px; color:#5a3800; text-align:center; margin-bottom:8px;
}
.hat-item {
  display:flex; align-items:center; justify-content:space-between;
  padding:5px 7px; border-radius:10px; margin-bottom:5px;
  cursor:pointer; border:1.5px solid transparent; transition:all 0.2s;
}
.hat-item:hover { background:#fff3d0; border-color:#e8c46a; }
.hat-item.equipped { background:#fff0b0; border-color:#d4a00a; }
.hat-item .hat-emoji { font-size:18px; }
.hat-item .hat-info { flex:1; margin-left:6px; }
.hat-item .hat-name { font-size:11px; font-weight:600; color:#3a2800; }
.hat-item .hat-cost { font-size:10px; color:#a06010; }
.hat-item .hat-btn {
  font-size:10px; padding:3px 7px;
  background:#e8c46a; color:#5a3000;
  border:none; border-radius:8px; cursor:pointer; font-weight:600;
}
.hat-item .hat-btn.owned { background:#c8e88a; color:#2a5000; }
#wardrobe-close {
  width:100%; margin-top:8px; padding:7px;
  border:none; border-radius:10px;
  background:#f0d888; color:#5a3000;
  font-size:12px; font-weight:600; cursor:pointer;
}

/* ===== 签文历史面板 ===== */
#history-panel {
  display:none; position:fixed; top:0;left:0;right:0;bottom:0;
  background:rgba(0,0,0,0.48); z-index:200;
  align-items:center; justify-content:center;
}
#history-panel.open { display:flex; }
#history-box {
  background:#fffbf0; border-radius:18px;
  padding:14px; width:178px;
  box-shadow:0 8px 30px rgba(0,0,0,0.28);
}
#history-box h3 { font-size:13px; color:#5a3800; text-align:center; margin-bottom:8px; }
.history-item {
  font-size:11px; color:#5a3800;
  padding:6px 8px; border-radius:8px;
  background:rgba(255,215,0,0.12);
  margin-bottom:5px; line-height:1.4;
}
.history-item .h-date { font-size:9px; color:#aaa; margin-top:2px; }
#history-empty { font-size:12px; color:#aaa; text-align:center; padding:12px; }
#history-close {
  width:100%; margin-top:8px; padding:7px;
  border:none; border-radius:10px;
  background:#f0d888; color:#5a3000;
  font-size:12px; font-weight:600; cursor:pointer;
}
</style>
</head>
<body>

<div id="pet-container">
  <div id="state-icon"></div>
  <div id="hat-overlay"></div>
  <div id="bubble"></div>

  <svg id="cat-svg" viewBox="0 0 120 160" xmlns="http://www.w3.org/2000/svg"
       onclick="onCatClick(event)">

    <!-- 尾巴 -->
    <g id="tail">
      <path d="M85 132 Q108 122 112 105 Q116 90 102 87"
            stroke="#E8C8A0" stroke-width="7" fill="none" stroke-linecap="round"/>
      <path d="M85 132 Q108 122 112 105 Q116 90 102 87"
            stroke="#FFF8F0" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.7"/>
    </g>

    <!-- 身体 -->
    <g id="body-group">
      <ellipse cx="60" cy="116" rx="37" ry="30" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
      <ellipse cx="60" cy="118" rx="22" ry="17" fill="#FFE4C4" opacity="0.55"/>
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
    <ellipse cx="60" cy="63" rx="13" ry="7" fill="#F4A460" opacity="0.22"/>
    <path d="M36 52 Q41 44 51 50" stroke="#F4A460" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.65"/>
    <path d="M84 52 Q79 44 69 50" stroke="#F4A460" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.65"/>

    <!-- 耳朵 -->
    <polygon points="29,47 19,24 43,40" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
    <polygon points="29,47 23,30 39,42" fill="#FFB6C1" opacity="0.75"/>
    <polygon points="91,47 101,24 77,40" fill="#FFF8F0" stroke="#E8C8A0" stroke-width="1.5"/>
    <polygon points="91,47 97,30 81,42" fill="#FFB6C1" opacity="0.75"/>

    <!-- 眼睛 -->
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

    <!-- 打字时专注眼（JS切换） -->
    <g id="focus-eyes" style="display:none">
      <ellipse cx="47" cy="68" rx="9" ry="5" fill="white" stroke="#333" stroke-width="1.2"/>
      <circle cx="47" cy="68" r="3.5" fill="#1a1a2e"/>
      <ellipse cx="73" cy="68" rx="9" ry="5" fill="white" stroke="#333" stroke-width="1.2"/>
      <circle cx="73" cy="68" r="3.5" fill="#1a1a2e"/>
    </g>

    <!-- 鼻+嘴 -->
    <ellipse id="nose" cx="60" cy="80" rx="3.5" ry="2.2" fill="#FF9999"/>
    <path id="mouth" d="M57 83 Q60 87 63 83" stroke="#FF9999" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <!-- 开心嘴（大笑） -->
    <path id="mouth-happy" d="M54 82 Q60 90 66 82" stroke="#FF8080" stroke-width="1.8" fill="#FFB6B6" opacity="0" stroke-linecap="round"/>
    <!-- 胡须 -->
    <line x1="18" y1="79" x2="44" y2="80" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <line x1="18" y1="84" x2="44" y2="82" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <line x1="76" y1="80" x2="102" y2="79" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <line x1="76" y1="82" x2="102" y2="84" stroke="#BBB" stroke-width="1" opacity="0.65"/>
    <!-- 腮红 -->
    <ellipse cx="36" cy="78" rx="7" ry="4" fill="#FFB6C1" opacity="0.45"/>
    <ellipse cx="84" cy="78" rx="7" ry="4" fill="#FFB6C1" opacity="0.45"/>

    <!-- 右爪招手 -->
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

<!-- 底部面板 -->
<div id="bottom-panel">
  <div id="karma-row">
    <span id="karma-icon">🪙</span>
    <div id="karma-count">0</div>
    <span id="karma-label">福气值</span>
    <span id="state-text"></span>
  </div>
  <div id="mood-row">
    <span id="mood-label">心情</span>
    <div id="mood-bar-bg"><div id="mood-bar-fill" style="width:80%"></div></div>
    <span id="mood-emoji">😊</span>
  </div>
</div>

<!-- 换装面板 -->
<div id="wardrobe">
  <div id="wardrobe-box">
    <h3>🎀 换装衣橱</h3>
    <div id="hat-list"></div>
    <button id="wardrobe-close" onclick="closeWardrobe()">关闭</button>
  </div>
</div>

<!-- 签文历史面板 -->
<div id="history-panel">
  <div id="history-box">
    <h3>📜 签文历史</h3>
    <div id="history-list"></div>
    <button id="history-close" onclick="closeHistory()">关闭</button>
  </div>
</div>

<script>
// ======= 全局状态 =======
var karma = \(karmaJS);
var mood = parseInt(getLS('lp_mood') || '80');        // 0-100
var equippedHat = getLS('lp_hat') || 'none';
var ownedHats = JSON.parse(getLS('lp_owned') || '["none"]');
var fortuneHistory = JSON.parse(getLS('lp_fortune_history') || '[]'); // [{text,date}]
var petState = 'happy';   // happy / sleepy / hungry / excited / focused
var idleSeconds = 0;
var keystrokeBuffer = 0; // 短时间内击键数（用于判断专注）
var bubbleTimer = null;
var isDancing = false;
var focusTimer = null;

// ======= 帽子数据 =======
const HATS = [
  {id:'none',   name:'无帽子',   emoji:'❌', cost:0},
  {id:'crown',  name:'金皇冠',   emoji:'👑', cost:100},
  {id:'santa',  name:'圣诞帽',   emoji:'🎅', cost:80},
  {id:'witch',  name:'魔女帽',   emoji:'🧙', cost:120},
  {id:'tophat', name:'绅士帽',   emoji:'🎩', cost:150},
  {id:'flower', name:'花朵发饰', emoji:'🌸', cost:60},
  {id:'bow',    name:'蝴蝶结',   emoji:'🎀', cost:50},
  {id:'halo',   name:'天使光环', emoji:'😇', cost:200},
  {id:'party',  name:'派对帽',   emoji:'🎉', cost:80},
  {id:'rainbow',name:'彩虹发带', emoji:'🌈', cost:90},
];

// ======= 签文 =======
const FORTUNES = [
  "🌸 上上签：今日诸事皆宜，出门必遇贵人！",
  "🌟 大吉：财运亨通，有意外之财降临～",
  "✨ 上签：坚持努力，好事将近！",
  "🍀 吉签：平稳前行，步步为赢",
  "🌙 中签：静待时机，蓄势待发",
  "🎋 小吉：知足常乐，心态平和万事顺",
  "🔮 吉：机遇将至，保持警觉！",
  "💫 大吉：今日与贵人有缘，留意结交",
  "🌺 上上签：大吉大利！诸事皆成！",
  "⭐ 吉签：梦想正在变为现实，继续！",
  "🎯 上签：目标明确，全力以赴必有收获",
  "🌈 大吉：彩虹之后是晴天，好运已在路上",
  "🦋 中上签：蜕变时刻来临，迎接新的自己",
  "🌊 吉：随波逐流未必坏，顺势而为",
  "🌻 上签：阳光总在风雨后，坚持就是胜利",
  "🎪 中签：生活多彩，好好享受当下",
  "🍯 吉：甜蜜时刻将来临，期待惊喜",
  "🐉 上上签：龙马精神，大展宏图！",
  "🎵 吉签：心情愉快，好事自然来",
  "💎 大吉：珍贵机遇即将到来，把握住！",
  "🏆 上签：付出终有回报，坚持到底！",
  "🌙 平签：今日宜休息，养精蓄锐",
  "🌟 小吉：小事顺利，积少成多",
  "🎊 大吉：喜事将至，好好准备迎接！",
  "🍃 中签：顺其自然，心平则万物平",
];

// ======= 互动话语 =======
const POKE_MSGS = [
  "哎！别戳我！(＞﹏＜)", "嗷～轻点嘛！",
  "好痒！OwO", "再戳就生气啦！", "欸欸欸！手拿开！",
];
const STROKE_MSGS = [
  "呼噜呼噜～♪", "好舒服呀 (o´▽`o)",
  "再摸摸嘛～", "最喜欢主人啦！❤️", "摸头好幸福～",
];
const IDLE_MSGS = [
  "今天也要带来好运哦！✨", "嘿嘿～(≧▽≦)",
  "主人辛苦啦！加油！", "🪙 福气越来越多了！",
  "喵～有什么需要吗？", "打字快点！来积福气！",
  "我在陪着你哦 ♡", "今日运势：大吉！",
  "困了...打个盹好嘛", "🍬 好想吃零食...",
  "轻轻摇着尾巴... 🐾", "招财招财～ 🪙🪙",
];
const MILESTONE_MSGS = {
  100:  "🎉 100福气！解锁金皇冠！",
  300:  "✨ 300福气！你真棒！",
  500:  "🏆 500福气里程碑达成！",
  1000: "🌟 1000福气！！传说级铲屎官！",
};

// ======= 初始化 =======
document.addEventListener('DOMContentLoaded', function() {
  updateKarmaDisplay();
  updateMoodBar();
  updateHatOverlay();
  renderWardrobe();
  startBlink();
  startMouseTracking();
  startIdleLoop();
  setTimeout(function(){ showBubble("你好呀！我是招财猫～\\n打字就能积累福气！🪙"); }, 600);
});

// ======= 键击（Swift调用）=======
var keystrokeCount = 0;
function onKeystroke() {
  karma += 1;
  keystrokeCount++;
  idleSeconds = 0;

  // 专注模式：快速打字时切换表情
  clearTimeout(focusTimer);
  setFocusEyes(true);
  focusTimer = setTimeout(function(){ setFocusEyes(false); }, 1200);

  mood = Math.min(100, mood + 0.3);
  saveAll();
  updateKarmaDisplay();
  updateMoodBar();

  // 35% 概率飞金币
  if (Math.random() < 0.35) spawnCoin();

  // 里程碑
  checkMilestone(karma);

  // 每50次兴奋叫一下
  if (karma % 50 === 0) {
    showBubble("🎉 已积 " + karma + " 福气！");
    triggerHappy();
  }
}

// ======= 专注眼（打字中） =======
function setFocusEyes(on) {
  const normal = document.querySelectorAll('#eye-left-group, #eye-right-group');
  const focus = document.getElementById('focus-eyes');
  if (on) {
    normal.forEach(e => e.style.display='none');
    focus.style.display='';
  } else {
    normal.forEach(e => e.style.display='');
    focus.style.display='none';
  }
}

// ======= 里程碑 =======
var reachedMilestones = JSON.parse(getLS('lp_milestones') || '[]');
function checkMilestone(k) {
  const milestones = [100, 300, 500, 1000, 2000, 5000];
  milestones.forEach(function(m) {
    if (k >= m && !reachedMilestones.includes(m)) {
      reachedMilestones.push(m);
      setLS('lp_milestones', JSON.stringify(reachedMilestones));
      const msg = MILESTONE_MSGS[m] || ('🎊 ' + m + '福气里程碑！');
      showBubble(msg, 5000);
      triggerMilestoneFX();
    }
  });
}

function triggerMilestoneFX() {
  const c = document.getElementById('pet-container');
  const emojis = ['🌟','✨','🎊','🪙','💫'];
  emojis.forEach(function(em, i) {
    setTimeout(function(){
      const el = document.createElement('div');
      el.className = 'milestone-fx';
      el.textContent = em;
      el.style.left = (20 + Math.random()*140) + 'px';
      el.style.top = (40 + Math.random()*80) + 'px';
      c.appendChild(el);
      setTimeout(() => el.remove(), 1300);
    }, i * 150);
  });
}

// ======= 金币飞出 =======
function spawnCoin() {
  const c = document.getElementById('pet-container');
  const el = document.createElement('div');
  el.className = 'coin-popup';
  el.textContent = '🪙';
  el.style.left = (30 + Math.random()*110) + 'px';
  el.style.top = (80 + Math.random()*50) + 'px';
  c.appendChild(el);
  setTimeout(() => el.remove(), 920);
}

// ======= 点击交互 =======
var clickCount = 0, clickTimer = null;
function onCatClick(e) {
  clickCount++;
  clearTimeout(clickTimer);
  clickTimer = setTimeout(function(){
    if (clickCount >= 2) onStroke();
    else onPoke(e);
    clickCount = 0;
  }, 250);
}

function onPoke(e) {
  idleSeconds = 0;
  mood = Math.max(0, mood - 5);
  updateMoodBar();
  showBubble(POKE_MSGS[Math.floor(Math.random()*POKE_MSGS.length)]);
  const c = document.getElementById('pet-container');
  const fx = document.createElement('div');
  fx.className = 'poke-effect';
  fx.textContent = '💢';
  fx.style.left = ((e ? e.offsetX : 80) - 12) + 'px';
  fx.style.top = ((e ? e.offsetY : 70) - 20) + 'px';
  c.appendChild(fx);
  setTimeout(() => fx.remove(), 600);
  // 震动
  const svg = document.getElementById('cat-svg');
  svg.style.transform = 'translateX(5px)';
  setTimeout(() => svg.style.transform = 'translateX(-5px)', 80);
  setTimeout(() => svg.style.transform = '', 160);
}

function onStroke() {
  idleSeconds = 0;
  karma += 5;
  mood = Math.min(100, mood + 15);
  saveAll(); updateKarmaDisplay(); updateMoodBar();
  showBubble(STROKE_MSGS[Math.floor(Math.random()*STROKE_MSGS.length)]);
  triggerHappy();
  spawnCoin(); spawnCoin();
}

function triggerHappy() {
  const svg = document.getElementById('cat-svg');
  // 大笑嘴
  document.getElementById('mouth-happy').setAttribute('opacity', '1');
  document.getElementById('mouth').style.opacity = '0';
  svg.style.transform = 'scale(1.07) rotate(-2deg)';
  setTimeout(() => { svg.style.transform = 'scale(1.04) rotate(2deg)'; }, 130);
  setTimeout(() => {
    svg.style.transform = '';
    document.getElementById('mouth-happy').setAttribute('opacity', '0');
    document.getElementById('mouth').style.opacity = '1';
  }, 280);
}

// ======= 跳舞（Swift和右键触发）=======
function doDance() {
  if (isDancing) return;
  isDancing = true;
  const svg = document.getElementById('cat-svg');
  svg.classList.add('dancing');
  showBubble('🎵 耶耶耶！跳舞啦！♪ヽ(´▽｀)/', 3000);
  // 通知 Swift 摇窗口
  bridgePost({action:'dance'});
  // 生成音符特效
  const notes = ['🎵','🎶','♪','♫'];
  for (let i = 0; i < 8; i++) {
    setTimeout(function(){
      const c = document.getElementById('pet-container');
      const el = document.createElement('div');
      el.className = 'coin-popup';
      el.textContent = notes[Math.floor(Math.random()*notes.length)];
      el.style.left = (20 + Math.random()*150) + 'px';
      el.style.top = (50 + Math.random()*80) + 'px';
      c.appendChild(el);
      setTimeout(() => el.remove(), 920);
    }, i * 250);
  }
  setTimeout(function(){
    svg.classList.remove('dancing');
    isDancing = false;
  }, 3000);
}

// ======= 求签 =======
function doFortune() {
  if (karma < 50) { showBubble('福气不足！需要50福气才能求签 🪙', 3000); return; }
  karma -= 50;
  mood = Math.min(100, mood + 10);
  saveAll(); updateKarmaDisplay(); updateMoodBar();
  const f = FORTUNES[Math.floor(Math.random()*FORTUNES.length)];
  showBubble(f, 6000);
  triggerHappy();
  // 存历史
  const now = new Date();
  const dateStr = now.getMonth()+1 + '/' + now.getDate() + ' ' +
                  now.getHours() + ':' + String(now.getMinutes()).padStart(2,'0');
  fortuneHistory.unshift({text: f, date: dateStr});
  if (fortuneHistory.length > 10) fortuneHistory = fortuneHistory.slice(0, 10);
  setLS('lp_fortune_history', JSON.stringify(fortuneHistory));
}

// ======= 喂零食 =======
function doFeed() {
  karma += 20;
  mood = Math.min(100, mood + 20);
  idleSeconds = 0;
  saveAll(); updateKarmaDisplay(); updateMoodBar();
  showBubble('好好吃！谢谢主人！(≧∇≦)/ 🍬', 3000);
  triggerHappy();
  for(let i=0;i<3;i++) setTimeout(spawnCoin, i*120);
}

// ======= 眨眼 =======
function startBlink() {
  function doBlink() {
    const lw = document.getElementById('eye-left-white');
    const rw = document.getElementById('eye-right-white');
    if (lw && rw && document.getElementById('focus-eyes').style.display === 'none') {
      const cur_ry = parseFloat(lw.getAttribute('ry'));
      lw.setAttribute('ry','1'); rw.setAttribute('ry','1');
      setTimeout(function(){ lw.setAttribute('ry', cur_ry||'9'); rw.setAttribute('ry', cur_ry||'9'); }, 110);
    }
    setTimeout(doBlink, 2200 + Math.random()*3800);
  }
  setTimeout(doBlink, 1800);
}

// ======= 眼睛跟随 =======
function startMouseTracking() {
  document.addEventListener('mousemove', function(e) {
    const rect = document.getElementById('cat-svg').getBoundingClientRect();
    const cx = rect.left + rect.width*0.5, cy = rect.top + rect.height*0.43;
    const dx = e.clientX - cx, dy = e.clientY - cy;
    const dist = Math.sqrt(dx*dx+dy*dy)||1;
    const mx = 2.5, ox = dx/dist*mx, oy = dy/dist*mx;
    const lp = document.getElementById('eye-left-pupil');
    const rp = document.getElementById('eye-right-pupil');
    if(lp) lp.setAttribute('transform','translate('+ox+','+oy+')');
    if(rp) rp.setAttribute('transform','translate('+ox+','+oy+')');
  });
}

// ======= 状态 + 心情循环 =======
function startIdleLoop() {
  setInterval(function(){
    idleSeconds++;
    mood = Math.max(0, mood - 0.08);
    updateMoodBar();
    saveAll();

    // 状态判断
    if (idleSeconds > 45) petState = 'sleepy';
    else if (mood < 25)   petState = 'hungry';
    else if (mood > 85)   petState = 'happy';
    else                   petState = 'normal';

    updateStateUI();

    // 随机闲话
    if (idleSeconds % 10 === 0 && Math.random() < 0.45) {
      if (petState === 'sleepy') showBubble('Zzz... 打个盹儿...(｡zzZ)');
      else if (petState === 'hungry') showBubble('好饿呀...主人记得喂我 🍬');
      else showBubble(IDLE_MSGS[Math.floor(Math.random()*IDLE_MSGS.length)]);
    }
  }, 1000);
}

function updateStateUI() {
  const si = document.getElementById('state-icon');
  if (petState === 'sleepy') {
    si.textContent = '💤'; si.classList.add('show');
  } else if (petState === 'hungry') {
    si.textContent = '🍬'; si.classList.add('show');
  } else {
    si.classList.remove('show');
  }
}

// ======= 心情条 =======
function updateMoodBar() {
  const fill = document.getElementById('mood-bar-fill');
  const emoji = document.getElementById('mood-emoji');
  const pct = Math.max(0, Math.min(100, mood));
  fill.style.width = pct + '%';
  if (pct > 70)      { fill.style.background='linear-gradient(90deg,#88dd66,#44cc44)'; emoji.textContent='😊'; }
  else if (pct > 40) { fill.style.background='linear-gradient(90deg,#ffcc44,#ff9933)'; emoji.textContent='😐'; }
  else               { fill.style.background='linear-gradient(90deg,#ff8888,#ff4444)'; emoji.textContent='😢'; }
}

// ======= 换装 =======
function openWardrobe() {
  renderWardrobe();
  document.getElementById('wardrobe').classList.add('open');
}
function closeWardrobe() {
  document.getElementById('wardrobe').classList.remove('open');
}
function renderWardrobe() {
  const list = document.getElementById('hat-list');
  list.innerHTML = '';
  HATS.forEach(function(h){
    const owned = ownedHats.includes(h.id);
    const equipped = equippedHat === h.id;
    const div = document.createElement('div');
    div.className = 'hat-item' + (equipped?' equipped':'');
    let btnText = equipped ? '✓装备中' : (owned ? '装备' : ('买 🪙'+h.cost));
    div.innerHTML =
      '<span class="hat-emoji">'+h.emoji+'</span>'+
      '<div class="hat-info">'+
        '<div class="hat-name">'+h.name+'</div>'+
        (!owned && h.cost>0 ? '<div class="hat-cost">需'+h.cost+'福气</div>' : '')+
      '</div>'+
      '<button class="hat-btn'+(owned?' owned':'')
      +'" onclick="handleHat(\''+h.id+'\','+h.cost+','+owned+')">'+btnText+'</button>';
    list.appendChild(div);
  });
}

function handleHat(id, cost, owned) {
  if (owned || cost===0) {
    equippedHat = id; saveAll(); updateHatOverlay(); renderWardrobe();
    showBubble('换装成功！好看吗？ ✨', 2500); closeWardrobe();
  } else {
    if (karma < cost) { showBubble('福气不够！还差'+(cost-karma)+'🪙', 2500); return; }
    karma -= cost; ownedHats.push(id); equippedHat = id;
    saveAll(); updateKarmaDisplay(); updateHatOverlay(); renderWardrobe();
    showBubble('🎉 购买成功！新帽子超可爱！', 3000); closeWardrobe(); triggerHappy();
  }
}
function updateHatOverlay() {
  const el = document.getElementById('hat-overlay');
  const h = HATS.find(x => x.id===equippedHat);
  el.textContent = (h && h.id!=='none') ? h.emoji : '';
}

// ======= 签文历史 =======
function showFortuneHistory() {
  const list = document.getElementById('history-list');
  list.innerHTML = '';
  if (fortuneHistory.length === 0) {
    list.innerHTML = '<div id="history-empty">还没有求过签哦～<br>右键→求签 试试！</div>';
  } else {
    fortuneHistory.forEach(function(item){
      const div = document.createElement('div');
      div.className = 'history-item';
      div.innerHTML = item.text + '<div class="h-date">'+item.date+'</div>';
      list.appendChild(div);
    });
  }
  document.getElementById('history-panel').classList.add('open');
}
function closeHistory() {
  document.getElementById('history-panel').classList.remove('open');
}

// ======= UI =======
function showBubble(text, dur) {
  const el = document.getElementById('bubble');
  el.textContent = text;
  el.classList.add('show');
  clearTimeout(bubbleTimer);
  bubbleTimer = setTimeout(() => el.classList.remove('show'), dur||3500);
}
function updateKarmaDisplay() {
  document.getElementById('karma-count').textContent = karma;
}

// ======= 持久化 =======
// Fix-H: saveAll 节流——每500ms最多向 Swift 发一次 saveKarma，避免高频打字大量 bridge 调用
var saveTimer = null;
function saveAll() {
  setLS('lp_mood', Math.round(mood));
  setLS('lp_hat', equippedHat);
  setLS('lp_owned', JSON.stringify(ownedHats));
  clearTimeout(saveTimer);
  saveTimer = setTimeout(function(){
    bridgePost({action:'saveKarma', karma:karma});
  }, 500);
}
function bridgePost(obj) {
  try { window.webkit.messageHandlers.petBridge.postMessage(obj); } catch(e){}
}
function setLS(k,v){ try{localStorage.setItem(k,v);}catch(e){} }
function getLS(k){ try{return localStorage.getItem(k);}catch(e){return null;} }

// ======= 右键 =======
document.addEventListener('contextmenu', function(e){
  e.preventDefault();
  bridgePost({action:'showMenu'});
});
</script>
</body>
</html>
"""
}
