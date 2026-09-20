#!/usr/bin/env bash
# Basis - hero section preview
# Run from the project root: bash basis-hero.sh
set -euo pipefail

mkdir -p apps/web-preview

cat > apps/web-preview/hero.html <<'HTMLEOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Basis</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Geist:wght@100..900&family=Geist+Mono:wght@100..900&display=swap" rel="stylesheet">
<style>
:root{
  color-scheme: dark;
  --bg:#0C0C0C;
  --panel:#171715;
  --ink:#FBFBF7;
  --muted:#B5B3AA;
  --faint:#6E6C66;
  --line:rgba(255,255,255,.10);
  --accent:#D93A2B;
  --bad:#F87171;

  --step--1: clamp(11.5px, 0.6vw + 9.7px, 12.5px);
  --step-0:  clamp(12.5px, 0.7vw + 10.5px, 13.5px);
  --step-1:  clamp(13.5px, 0.8vw + 11.2px, 15px);

  --sans:'Geist',-apple-system,system-ui,sans-serif;
  --mono:'Geist Mono',ui-monospace,'SF Mono',monospace;

  padding-top: env(safe-area-inset-top, 0px);
  padding-bottom: env(safe-area-inset-bottom, 0px);
}
*{box-sizing:border-box}
body{
  margin:0;background:var(--bg);color:var(--ink);
  font-family:var(--sans);font-weight:400;
  font-feature-settings:"cv02","cv03","cv04","cv11";
  letter-spacing:-0.4px;
  font-optical-sizing:auto;font-synthesis:none;
  -webkit-font-smoothing:antialiased;
}
.num{font-variant-numeric:tabular-nums;letter-spacing:-0.5px}
.mono{font-family:var(--mono);font-size:.92em;letter-spacing:0}

/* ---------- nav ---------- */
.nav{
  position:fixed;inset-inline:0;top:0;z-index:50;height:56px;
  display:flex;align-items:center;gap:8px;padding-inline:16px;
  background:transparent;transition:background 200ms,border-color 200ms;
  border-bottom:1px solid transparent;
}
@media(min-width:640px){.nav{padding-inline:32px}}
@media(min-width:1024px){.nav{padding-inline:30px}}
.nav.stuck{background:rgba(12,12,12,.82);backdrop-filter:blur(14px);border-bottom-color:var(--line)}
.brand{display:flex;align-items:center;gap:9px;margin-right:auto;font-weight:500;font-size:16px}
.brand .mk{width:16px;height:16px;border-radius:4px;border:1.5px solid var(--accent);position:relative}
.brand .mk::after{content:'';position:absolute;inset:3.5px;border-radius:1px;background:var(--accent);opacity:.55}
.nav a{
  display:inline-flex;align-items:center;height:34px;padding-inline:11px;border-radius:999px;
  font-size:var(--step-1);font-weight:450;color:var(--muted);text-decoration:none;
  border:1px solid transparent;transition:color 160ms,border-color 160ms,background 160ms;
}
.nav a:hover{color:var(--ink);border-color:var(--line);background:rgba(255,255,255,.03)}
.nav .cta{color:var(--bg);background:var(--ink);font-weight:530;padding-inline:16px;margin-left:6px}
.nav .cta:hover{background:var(--ink);color:var(--bg);opacity:.92}
@media(max-width:860px){.nav .hide-sm{display:none}}

/* ---------- hero ---------- */
.hero{position:relative;min-height:100svh;overflow:hidden;display:flex;flex-direction:column;justify-content:center}
#field{position:absolute;inset:0;width:100%;height:100%;display:block}
.veil{
  position:absolute;inset:0;pointer-events:none;
  background:
    radial-gradient(120% 80% at 34% 30%, rgba(9,1,1,.92) 0%, rgba(9,1,1,.45) 34%, transparent 62%),
    linear-gradient(to bottom, rgba(12,12,12,.86) 0%, rgba(12,12,12,.26) 30%, rgba(12,12,12,.55) 76%, var(--bg) 100%);
}
.inner{
  position:relative;z-index:2;width:100%;
  padding-inline:16px;padding-top:96px;padding-bottom:64px;
  transition:filter 620ms cubic-bezier(.16,1,.3,1),opacity 620ms cubic-bezier(.16,1,.3,1);
}
@media(min-width:640px){.inner{padding-inline:32px}}
.inner.dim{filter:blur(9px);opacity:.34}
.wrap{max-width:1160px;margin:0 auto}

.eyebrow{display:flex;align-items:center;gap:9px;margin-bottom:18px}
.eyebrow i{height:3px;width:18px;border-radius:2px;background:var(--accent);display:block}
.eyebrow span{font-family:var(--mono);font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--faint)}

h1{
  margin:0;font-size:36px;font-weight:400;line-height:.98;letter-spacing:-.5px;
  text-wrap:balance;max-width:20ch;
}
@media(min-width:640px){h1{font-size:48px}}
@media(min-width:768px){h1{font-size:60px}}
@media(min-width:1024px){h1{font-size:76px}}

.lead{
  margin:22px 0 0;font-size:16px;line-height:1.9;color:var(--muted);
  max-width:52ch;text-wrap:balance;
}
@media(min-width:640px){.lead{font-size:19px}}

.actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:34px}
.pill-lg{
  display:inline-flex;align-items:center;gap:9px;height:52px;padding:0 26px 0 22px;
  border-radius:999px;font-size:16px;font-weight:530;text-decoration:none;
  transition:transform 180ms,opacity 180ms,background 180ms;
}
.pill-lg.solid{background:var(--ink);color:var(--bg)}
.pill-lg.solid:hover{transform:translateY(-1px);opacity:.92}
.pill-lg.ghost{background:transparent;color:var(--ink);border:1px solid var(--line)}
.pill-lg.ghost:hover{transform:translateY(-1px);background:rgba(255,255,255,.04)}

/* ---------- readout card ---------- */
.card{
  margin-top:clamp(40px,6vw,72px);
  border:1px solid var(--line);border-radius:16px;overflow:hidden;
  background:rgba(14,10,10,.62);
  backdrop-filter:blur(16px);
  box-shadow:0 40px 90px -40px rgba(0,0,0,.95);
  max-width:820px;
}
.card-head{
  display:flex;align-items:center;gap:10px;padding:14px 18px;
  border-bottom:1px solid var(--line);
}
.card-head .mk{width:14px;height:14px;border-radius:4px;border:1.5px solid var(--accent)}
.card-head span{font-family:var(--mono);font-size:10.5px;letter-spacing:.14em;text-transform:uppercase;color:var(--faint)}
.chain{display:flex;align-items:center;gap:10px;flex-wrap:wrap;padding:18px}
.chip{
  font-family:var(--mono);font-size:11px;letter-spacing:.04em;color:var(--muted);
  border:1px solid var(--line);border-radius:8px;padding:9px 13px;background:rgba(255,255,255,.015);
}
.arrow{color:var(--faint);font-size:12px}
.row{
  display:grid;gap:14px;padding:18px;border-top:1px solid var(--line);
}
@media(min-width:720px){.row{grid-template-columns:1fr 1fr 1fr}}
.cell .k{font-family:var(--mono);font-size:10.5px;letter-spacing:.08em;text-transform:uppercase;color:var(--faint)}
.cell .v{display:block;margin-top:10px;font-size:clamp(24px,3vw,32px);font-weight:400;letter-spacing:-1px;line-height:1}
.cell .n{margin:10px 0 0;font-size:13px;color:var(--muted)}
.cell.flag .v{color:var(--bad)}
.foot{
  padding:13px 18px;border-top:1px solid var(--line);
  font-family:var(--mono);font-size:10.5px;letter-spacing:.06em;color:var(--faint);
  display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;
}
@media(prefers-reduced-motion:reduce){
  .inner,.inner.dim{filter:none;opacity:1;transition:none}
}
</style>
</head>
<body>

<nav class="nav" id="nav">
  <div class="brand"><span class="mk"></span>basis</div>
  <a class="hide-sm" href="#">Findings</a>
  <a class="hide-sm" href="#">Docs</a>
  <a class="hide-sm" href="#">API</a>
  <a class="cta" href="#">View the data</a>
</nav>

<header class="hero">
  <canvas id="field"></canvas>
  <div class="veil"></div>

  <div class="inner" id="inner">
    <div class="wrap">
      <div class="eyebrow"><i></i><span>Robinhood Chain &middot; 194 assets</span></div>

      <h1>Check the multiplier before you trust the price.</h1>

      <p class="lead">
        Tokenized stock prices come from two sources that do not agree.
        Basis reads both and tells you which assets are wrong, and by how much.
      </p>

      <div class="actions">
        <a class="pill-lg solid" href="#">See the 28 affected &rsaquo;</a>
        <a class="pill-lg ghost" href="#">Read the findings</a>
      </div>

      <div class="card">
        <div class="card-head"><span class="mk"></span><span>Basis check</span></div>

        <div class="chain">
          <span class="chip">registry.read()</span>
          <span class="arrow">&rarr;</span>
          <span class="chip">chain.read()</span>
          <span class="arrow">&rarr;</span>
          <span class="chip">compare()</span>
        </div>

        <div class="row">
          <div class="cell">
            <div class="k">Asset</div>
            <span class="v">CRWD</span>
            <p class="n">CrowdStrike &middot; Robinhood Token</p>
          </div>
          <div class="cell">
            <div class="k">Multiplier</div>
            <span class="v num">4.0</span>
            <p class="n">Registry and chain agree</p>
          </div>
          <div class="cell flag">
            <div class="k">Naive pricing error</div>
            <span class="v num">300%</span>
            <p class="n">Position valued at a quarter of its worth</p>
          </div>
        </div>

        <div class="foot">
          <span>28 of 194 assets affected</span>
          <span>verified at block 67103382</span>
        </div>
      </div>

    </div>
  </div>
</header>

<script>
/* nav */
addEventListener('scroll', () => {
  document.getElementById('nav').classList.toggle('stuck', scrollY > 24);
}, { passive: true });

/* ---------- spiral scale field ---------- */
const cv = document.getElementById('field');
const ctx = cv.getContext('2d', { alpha: false });
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;

let W = 0, H = 0, DPR = 1, RINGS = 0, PER = 0;

function size() {
  DPR = Math.min(devicePixelRatio || 1, 2);
  W = innerWidth; H = innerHeight;
  cv.width = W * DPR; cv.height = H * DPR;
  ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  const dense = W * H > 900000;
  RINGS = dense ? 26 : 20;
  PER = dense ? 30 : 22;
}
size();
addEventListener('resize', size);

/* palette: vortex black -> foreground saturated red */
const RAMP = [
  [9, 1, 1], [19, 3, 2], [37, 3, 3], [58, 2, 1],
  [106, 10, 8], [161, 5, 2], [204, 5, 1], [240, 0, 0]
];
function ramp(t) {
  const x = Math.max(0, Math.min(0.999, t)) * (RAMP.length - 1);
  const i = Math.floor(x), f = x - i;
  const a = RAMP[i], b = RAMP[i + 1] || a;
  return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f];
}

/* collapse cycle: mostly settled, a short warp, then rebuild */
const CYCLE = 8200, WARP_IN = 1250, WARP_HOLD = 620, WARP_OUT = 900;
function warpAt(ms) {
  const t = ms % CYCLE;
  if (t < WARP_IN) return 0;
  const u = t - WARP_IN;
  if (u < WARP_HOLD) return easeIn(u / WARP_HOLD);
  const v = u - WARP_HOLD;
  if (v < WARP_OUT) return 1 - easeOut(v / WARP_OUT);
  return 0;
}
const easeIn = (x) => x * x;
const easeOut = (x) => 1 - Math.pow(1 - x, 3);

const inner = document.getElementById('inner');
let dimmed = false;

function frame(ms) {
  const warp = reduce ? 0 : warpAt(ms);
  const t = reduce ? 0 : ms * 0.00006;

  if (!reduce) {
    const want = warp > 0.42;
    if (want !== dimmed) { dimmed = want; inner.classList.toggle('dim', want); }
  }

  ctx.fillStyle = '#080101';
  ctx.fillRect(0, 0, W, H);

  const cx = W * 0.34, cy = H * 0.30;
  const maxR = Math.hypot(W, H) * 0.86;

  for (let i = 0; i < RINGS; i++) {
    const d0 = (i + 1) / RINGS;
    /* warp pulls the whole field toward the vortex and dims it */
    const d = d0 * (1 - warp * 0.82);
    const r = Math.pow(d, 1.75) * maxR;

    const scale = 0.16 + Math.pow(d, 1.5) * 1.5;
    const w = 26 * scale, h = 15 * scale;

    const shade = ramp(Math.pow(d0, 1.15) * (1 - warp * 0.55));
    const fill = `rgb(${shade[0] | 0},${shade[1] | 0},${shade[2] | 0})`;
    const lift = ramp(Math.min(0.999, Math.pow(d0, 1.05) * (1 - warp * 0.55) + 0.14));
    const hi = `rgb(${lift[0] | 0},${lift[1] | 0},${lift[2] | 0})`;

    ctx.globalAlpha = Math.max(0, 1 - warp * 0.92);

    for (let j = 0; j < PER; j++) {
      const a = (j / PER) * Math.PI * 2 + i * 0.26 + t + warp * 1.5;
      const x = cx + Math.cos(a) * r * 1.28;
      const y = cy + Math.sin(a) * r * 0.92;
      if (x < -80 || x > W + 80 || y < -80 || y > H + 80) continue;

      ctx.save();
      ctx.translate(x, y);
      ctx.rotate(a + Math.PI / 2);

      /* shadow under the scale */
      ctx.beginPath();
      ctx.ellipse(0, h * 0.34, w, h, 0, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(0,0,0,.72)';
      ctx.fill();

      /* body */
      ctx.beginPath();
      ctx.ellipse(0, 0, w, h, 0, 0, Math.PI * 2);
      ctx.fillStyle = fill;
      ctx.fill();

      /* front highlight, offset toward the viewer edge */
      ctx.beginPath();
      ctx.ellipse(0, h * 0.24, w * 0.74, h * 0.48, 0, 0, Math.PI * 2);
      ctx.fillStyle = hi;
      ctx.globalAlpha *= 0.55;
      ctx.fill();
      ctx.globalAlpha /= 0.55;

      ctx.restore();
    }
  }

  ctx.globalAlpha = 1;
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
</script>
</body>
</html>
HTMLEOF

echo "Wrote apps/web-preview/hero.html"
command -v open >/dev/null && open apps/web-preview/hero.html || echo "Open apps/web-preview/hero.html in a browser"
