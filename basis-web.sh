#!/usr/bin/env bash
# Basis - Next.js app, hero section only
# Run from the project root: bash basis-web.sh
set -euo pipefail

mkdir -p apps/web/app apps/web/components

# ---------------------------------------------------------------- package.json
cat > apps/web/package.json <<'EOF'
{
  "name": "basis-web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^15.1.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
EOF

cat > apps/web/next.config.mjs <<'EOF'
const nextConfig = { reactStrictMode: true };
export default nextConfig;
EOF

cat > apps/web/.gitignore <<'EOF'
node_modules/
.next/
.env*.local
.env.swap
EOF

# ---------------------------------------------------------------- layout
cat > apps/web/app/layout.js <<'EOF'
import "./globals.css";

export const metadata = {
  title: "Basis",
  description:
    "Tokenized stock prices come from two sources that do not agree. Basis reads both and tells you which assets are wrong, and by how much."
};

export const viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#0C0C0C"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        {/* full variable range on purpose: discrete weights silently fall back */}
        <link
          href="https://fonts.googleapis.com/css2?family=Geist:wght@100..900&family=Geist+Mono:wght@100..900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
EOF

# ---------------------------------------------------------------- page
cat > apps/web/app/page.js <<'EOF'
import Nav from "../components/Nav";
import Hero from "../components/Hero";

export default function Page() {
  return (
    <>
      <Nav />
      <Hero />
      {/* next sections go here */}
    </>
  );
}
EOF

# ---------------------------------------------------------------- globals
cat > apps/web/app/globals.css <<'EOF'
:root{
  color-scheme: dark;

  /* swap these to reskin the whole page */
  --bg:#0C0C0C;
  --panel:#171715;
  --ink:#FBFBF7;
  --muted:#B5B3AA;
  --faint:#6E6C66;
  --line:rgba(255,255,255,.10);
  --accent:#D93A2B;

  --good:#5DD68E;
  --warn:#E0A85A;
  --bad:#F87171;

  --step--2: clamp(10px, 0.55vw + 8.4px, 11.5px);
  --step--1: clamp(11.5px, 0.6vw + 9.7px, 12.5px);
  --step-0:  clamp(12.5px, 0.7vw + 10.5px, 13.5px);
  --step-1:  clamp(13.5px, 0.8vw + 11.2px, 15px);
  --step-2:  clamp(15px, 1vw + 12.2px, 17px);
  --step-3:  clamp(18px, 1.6vw + 13.8px, 22px);
  --step-4:  clamp(21px, 2.4vw + 14.6px, 28px);
  --step-5:  clamp(24px, 3.4vw + 15px, 34px);

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
a{color:inherit;text-decoration:none}
.num{font-variant-numeric:tabular-nums;letter-spacing:-0.5px}
.mono{font-family:var(--mono);font-size:.92em;letter-spacing:0}

/* shared layout rhythm, used by every section from here on */
section.s{padding-inline:16px}
@media(min-width:640px){section.s{padding-inline:32px}}
@media(min-width:1024px){section.s{padding-inline:30px}}
.wrap{max-width:1160px;margin:0 auto}
.wrap-narrow{max-width:860px;margin:0 auto}

.eyebrow{display:flex;align-items:center;gap:9px;margin-bottom:18px}
.eyebrow i{height:3px;width:18px;border-radius:2px;background:var(--accent);display:block}
.eyebrow span{font-family:var(--mono);font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--faint)}

.pill-lg{
  display:inline-flex;align-items:center;gap:9px;height:52px;padding:0 26px 0 22px;
  border-radius:999px;font-size:16px;font-weight:530;
  transition:transform 180ms,opacity 180ms,background 180ms;
}
.pill-lg.solid{background:var(--ink);color:var(--bg)}
.pill-lg.solid:hover{transform:translateY(-1px);opacity:.92}
.pill-lg.ghost{background:transparent;color:var(--ink);border:1px solid var(--line)}
.pill-lg.ghost:hover{transform:translateY(-1px);background:rgba(255,255,255,.04)}
EOF

# ---------------------------------------------------------------- Nav
cat > apps/web/components/Nav.js <<'EOF'
"use client";
import { useEffect, useState } from "react";
import styles from "./Nav.module.css";

export default function Nav() {
  const [stuck, setStuck] = useState(false);

  useEffect(() => {
    const onScroll = () => setStuck(window.scrollY > 24);
    onScroll();
    addEventListener("scroll", onScroll, { passive: true });
    return () => removeEventListener("scroll", onScroll);
  }, []);

  return (
    <nav className={`${styles.nav} ${stuck ? styles.stuck : ""}`}>
      <div className={styles.brand}>
        <span className={styles.mk} />
        basis
      </div>
      <a className={`${styles.link} ${styles.hideSm}`} href="#findings">Findings</a>
      <a className={`${styles.link} ${styles.hideSm}`} href="#docs">Docs</a>
      <a className={`${styles.link} ${styles.hideSm}`} href="#api">API</a>
      <a className={`${styles.link} ${styles.cta}`} href="#data">View the data</a>
    </nav>
  );
}
EOF

cat > apps/web/components/Nav.module.css <<'EOF'
.nav{
  position:fixed;inset-inline:0;top:0;z-index:50;height:56px;
  display:flex;align-items:center;gap:8px;padding-inline:16px;
  background:transparent;border-bottom:1px solid transparent;
  transition:background 200ms,border-color 200ms;
}
@media(min-width:640px){.nav{padding-inline:32px}}
@media(min-width:1024px){.nav{padding-inline:30px}}

.stuck{
  background:rgba(12,12,12,.82);
  backdrop-filter:blur(14px);
  border-bottom-color:var(--line);
}

.brand{display:flex;align-items:center;gap:9px;margin-right:auto;font-weight:500;font-size:16px}
.mk{width:16px;height:16px;border-radius:4px;border:1.5px solid var(--accent);position:relative}
.mk::after{content:'';position:absolute;inset:3.5px;border-radius:1px;background:var(--accent);opacity:.55}

.link{
  display:inline-flex;align-items:center;height:34px;padding-inline:11px;border-radius:999px;
  font-size:var(--step-1);font-weight:450;color:var(--muted);
  border:1px solid transparent;
  transition:color 160ms,border-color 160ms,background 160ms;
}
.link:hover{color:var(--ink);border-color:var(--line);background:rgba(255,255,255,.03)}

.cta{color:var(--bg);background:var(--ink);font-weight:530;padding-inline:16px;margin-left:6px}
.cta:hover{color:var(--bg);background:var(--ink);opacity:.92}

@media(max-width:860px){.hideSm{display:none}}
EOF

# ---------------------------------------------------------------- Field (canvas)
cat > apps/web/components/Field.js <<'EOF'
"use client";
import { useEffect, useRef } from "react";

/* Spiral field of 3D red scales receding into a vortex.
   Calls onWarp(boolean) so the foreground can blur in sync. */
export default function Field({ onWarp, className }) {
  const ref = useRef(null);
  const warpRef = useRef(onWarp);
  warpRef.current = onWarp;

  useEffect(() => {
    const cv = ref.current;
    const ctx = cv.getContext("2d", { alpha: false });
    const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;

    let W = 0, H = 0, DPR = 1, RINGS = 0, PER = 0, raf = 0, dimmed = false;

    const size = () => {
      DPR = Math.min(devicePixelRatio || 1, 2);
      W = innerWidth; H = innerHeight;
      cv.width = W * DPR; cv.height = H * DPR;
      ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
      const dense = W * H > 900000;
      RINGS = dense ? 26 : 20;
      PER = dense ? 30 : 22;
    };
    size();
    addEventListener("resize", size);

    const RAMP = [
      [9, 1, 1], [19, 3, 2], [37, 3, 3], [58, 2, 1],
      [106, 10, 8], [161, 5, 2], [204, 5, 1], [240, 0, 0]
    ];
    const ramp = (t) => {
      const x = Math.max(0, Math.min(0.999, t)) * (RAMP.length - 1);
      const i = Math.floor(x), f = x - i;
      const a = RAMP[i], b = RAMP[i + 1] || a;
      return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f];
    };

    const CYCLE = 8200, WARP_IN = 1250, WARP_HOLD = 620, WARP_OUT = 900;
    const easeIn = (x) => x * x;
    const easeOut = (x) => 1 - Math.pow(1 - x, 3);
    const warpAt = (ms) => {
      const t = ms % CYCLE;
      if (t < WARP_IN) return 0;
      const u = t - WARP_IN;
      if (u < WARP_HOLD) return easeIn(u / WARP_HOLD);
      const v = u - WARP_HOLD;
      if (v < WARP_OUT) return 1 - easeOut(v / WARP_OUT);
      return 0;
    };

    const frame = (ms) => {
      const warp = reduce ? 0 : warpAt(ms);
      const t = reduce ? 0 : ms * 0.00006;

      if (!reduce) {
        const want = warp > 0.42;
        if (want !== dimmed) { dimmed = want; warpRef.current?.(want); }
      }

      ctx.fillStyle = "#080101";
      ctx.fillRect(0, 0, W, H);

      const cx = W * 0.34, cy = H * 0.30;
      const maxR = Math.hypot(W, H) * 0.86;

      for (let i = 0; i < RINGS; i++) {
        const d0 = (i + 1) / RINGS;
        const d = d0 * (1 - warp * 0.82);
        const r = Math.pow(d, 1.75) * maxR;

        const scale = 0.16 + Math.pow(d, 1.5) * 1.5;
        const w = 26 * scale, h = 15 * scale;

        const s = ramp(Math.pow(d0, 1.15) * (1 - warp * 0.55));
        const fill = `rgb(${s[0] | 0},${s[1] | 0},${s[2] | 0})`;
        const l = ramp(Math.min(0.999, Math.pow(d0, 1.05) * (1 - warp * 0.55) + 0.14));
        const hi = `rgb(${l[0] | 0},${l[1] | 0},${l[2] | 0})`;

        const alpha = Math.max(0, 1 - warp * 0.92);

        for (let j = 0; j < PER; j++) {
          const a = (j / PER) * Math.PI * 2 + i * 0.26 + t + warp * 1.5;
          const x = cx + Math.cos(a) * r * 1.28;
          const y = cy + Math.sin(a) * r * 0.92;
          if (x < -80 || x > W + 80 || y < -80 || y > H + 80) continue;

          ctx.save();
          ctx.translate(x, y);
          ctx.rotate(a + Math.PI / 2);
          ctx.globalAlpha = alpha;

          ctx.beginPath();
          ctx.ellipse(0, h * 0.34, w, h, 0, 0, Math.PI * 2);
          ctx.fillStyle = "rgba(0,0,0,.72)";
          ctx.fill();

          ctx.beginPath();
          ctx.ellipse(0, 0, w, h, 0, 0, Math.PI * 2);
          ctx.fillStyle = fill;
          ctx.fill();

          ctx.globalAlpha = alpha * 0.55;
          ctx.beginPath();
          ctx.ellipse(0, h * 0.24, w * 0.74, h * 0.48, 0, 0, Math.PI * 2);
          ctx.fillStyle = hi;
          ctx.fill();

          ctx.restore();
        }
      }

      ctx.globalAlpha = 1;
      raf = requestAnimationFrame(frame);
    };

    raf = requestAnimationFrame(frame);

    return () => {
      cancelAnimationFrame(raf);
      removeEventListener("resize", size);
    };
  }, []);

  return <canvas ref={ref} className={className} />;
}
EOF

# ---------------------------------------------------------------- Hero
cat > apps/web/components/Hero.js <<'EOF'
"use client";
import { useState } from "react";
import Field from "./Field";
import styles from "./Hero.module.css";

/* Hardcoded until the Railway API is live. Swap for a fetch then. */
const READING = {
  ticker: "CRWD",
  name: "CrowdStrike \u00b7 Robinhood Token",
  multiplier: "4.0",
  errorPct: "300%",
  affected: 28,
  total: 194,
  block: "67103382"
};

export default function Hero() {
  const [dim, setDim] = useState(false);

  return (
    <header className={styles.hero}>
      <Field className={styles.field} onWarp={setDim} />
      <div className={styles.veil} />

      <div className={`${styles.inner} ${dim ? styles.dim : ""}`}>
        <div className="wrap">
          <div className="eyebrow">
            <i />
            <span>Robinhood Chain &middot; {READING.total} assets</span>
          </div>

          <h1 className={styles.h1}>Check the multiplier before you trust the price.</h1>

          <p className={styles.lead}>
            Tokenized stock prices come from two sources that do not agree. Basis reads both
            and tells you which assets are wrong, and by how much.
          </p>

          <div className={styles.actions}>
            <a className="pill-lg solid" href="#data">
              See the {READING.affected} affected &rsaquo;
            </a>
            <a className="pill-lg ghost" href="#findings">Read the findings</a>
          </div>

          <div className={styles.card}>
            <div className={styles.cardHead}>
              <span className={styles.mk} />
              <span>Basis check</span>
            </div>

            <div className={styles.chain}>
              <span className={styles.chip}>registry.read()</span>
              <span className={styles.arrow}>&rarr;</span>
              <span className={styles.chip}>chain.read()</span>
              <span className={styles.arrow}>&rarr;</span>
              <span className={styles.chip}>compare()</span>
            </div>

            <div className={styles.row}>
              <div className={styles.cell}>
                <div className={styles.k}>Asset</div>
                <span className={styles.v}>{READING.ticker}</span>
                <p className={styles.n}>{READING.name}</p>
              </div>
              <div className={styles.cell}>
                <div className={styles.k}>Multiplier</div>
                <span className={`${styles.v} num`}>{READING.multiplier}</span>
                <p className={styles.n}>Registry and chain agree</p>
              </div>
              <div className={`${styles.cell} ${styles.flag}`}>
                <div className={styles.k}>Naive pricing error</div>
                <span className={`${styles.v} num`}>{READING.errorPct}</span>
                <p className={styles.n}>Position valued at a quarter of its worth</p>
              </div>
            </div>

            <div className={styles.foot}>
              <span>{READING.affected} of {READING.total} assets affected</span>
              <span>verified at block {READING.block}</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
EOF

cat > apps/web/components/Hero.module.css <<'EOF'
.hero{
  position:relative;min-height:100svh;overflow:hidden;
  display:flex;flex-direction:column;justify-content:center;
}
.field{position:absolute;inset:0;width:100%;height:100%;display:block}
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
.dim{filter:blur(9px);opacity:.34}

.h1{
  margin:0;font-size:36px;font-weight:400;line-height:.98;letter-spacing:-.5px;
  text-wrap:balance;max-width:20ch;
}
@media(min-width:640px){.h1{font-size:48px}}
@media(min-width:768px){.h1{font-size:60px}}
@media(min-width:1024px){.h1{font-size:76px}}

.lead{
  margin:22px 0 0;font-size:16px;line-height:1.9;color:var(--muted);
  max-width:52ch;text-wrap:balance;
}
@media(min-width:640px){.lead{font-size:19px}}

.actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:34px}

.card{
  margin-top:clamp(40px,6vw,72px);
  border:1px solid var(--line);border-radius:16px;overflow:hidden;
  background:rgba(14,10,10,.62);
  backdrop-filter:blur(16px);
  box-shadow:0 40px 90px -40px rgba(0,0,0,.95);
  max-width:820px;
}
.cardHead{display:flex;align-items:center;gap:10px;padding:14px 18px;border-bottom:1px solid var(--line)}
.cardHead span:last-child{
  font-family:var(--mono);font-size:10.5px;letter-spacing:.14em;
  text-transform:uppercase;color:var(--faint);
}
.mk{width:14px;height:14px;border-radius:4px;border:1.5px solid var(--accent);flex:none}

.chain{display:flex;align-items:center;gap:10px;flex-wrap:wrap;padding:18px}
.chip{
  font-family:var(--mono);font-size:11px;letter-spacing:.04em;color:var(--muted);
  border:1px solid var(--line);border-radius:8px;padding:9px 13px;background:rgba(255,255,255,.015);
}
.arrow{color:var(--faint);font-size:12px}

.row{display:grid;gap:14px;padding:18px;border-top:1px solid var(--line)}
@media(min-width:720px){.row{grid-template-columns:1fr 1fr 1fr}}
.k{font-family:var(--mono);font-size:10.5px;letter-spacing:.08em;text-transform:uppercase;color:var(--faint)}
.v{display:block;margin-top:10px;font-size:clamp(24px,3vw,32px);font-weight:400;letter-spacing:-1px;line-height:1}
.n{margin:10px 0 0;font-size:13px;color:var(--muted)}
.flag .v{color:var(--bad)}

.foot{
  padding:13px 18px;border-top:1px solid var(--line);
  font-family:var(--mono);font-size:10.5px;letter-spacing:.06em;color:var(--faint);
  display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;
}

@media(prefers-reduced-motion:reduce){
  .inner,.dim{filter:none;opacity:1;transition:none}
}
EOF

echo "Done."
echo "Next: cd apps/web && npm install && npm run dev"
