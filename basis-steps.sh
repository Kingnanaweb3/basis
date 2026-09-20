#!/usr/bin/env bash
# Basis - remove data footer, add "how it works" three-card section
# Run from the project root: bash basis-steps.sh
set -euo pipefail

cd apps/web

# ---------------------------------------------------------------- drop the footer line
python3 - <<'PY'
import pathlib
p = pathlib.Path("components/Affected.js")
s = p.read_text()
old = """
            <div className={styles.foot}>
              <span>Snapshot at block 67103382 &middot; 0 unreadable &middot; 0 source disagreements</span>
              <span className={styles.hideSm}>Bars are log scaled</span>
            </div>
"""
if old in s:
    p.write_text(s.replace(old, ""))
    print("removed footer from Affected.js")
else:
    print("footer block not found, left Affected.js alone")
PY

# ---------------------------------------------------------------- Steps
cat > components/Steps.js <<'EOF'
import styles from "./Steps.module.css";

function ArtRegistry() {
  return (
    <svg viewBox="0 0 200 150" className={styles.svg} aria-hidden="true">
      <circle cx="100" cy="75" r="52" className={styles.ring} />
      <circle cx="100" cy="75" r="34" className={styles.ring} />
      <circle cx="100" cy="75" r="17" className={styles.ringOn} />
      <circle cx="100" cy="75" r="3.5" className={styles.dot} />
    </svg>
  );
}

function ArtContract() {
  return (
    <svg viewBox="0 0 200 150" className={styles.svg} aria-hidden="true">
      <rect x="52" y="92" width="96" height="16" rx="4" className={styles.plate} />
      <rect x="62" y="70" width="76" height="16" rx="4" className={styles.plate} />
      <rect x="72" y="48" width="56" height="16" rx="4" className={styles.plateOn} />
      <path d="M100 42 L118 26 M100 42 L82 26" className={styles.beam} />
    </svg>
  );
}

function ArtCompare() {
  return (
    <svg viewBox="0 0 200 150" className={styles.svg} aria-hidden="true">
      <rect x="62" y="86" width="26" height="34" rx="4" className={styles.plate} />
      <rect x="112" y="34" width="26" height="86" rx="4" className={styles.plateOn} />
      <path d="M58 120 H146" className={styles.base} />
      <path d="M92 60 H108" className={styles.gap} />
      <path d="M100 60 V104" className={styles.gap} />
    </svg>
  );
}

const STEPS = [
  {
    n: "01",
    key: "Read the registry",
    art: <ArtRegistry />,
    body:
      "Pull every asset from the issuer's own registry, keep the ones deployed on Robinhood Chain, and record the multiplier it reports for each."
  },
  {
    n: "02",
    key: "Read the contract",
    art: <ArtContract />,
    body:
      "Call uiMultiplier() on each token contract directly, at a known block. Retries on failure, and an unreadable value stays unreadable rather than defaulting to safe."
  },
  {
    n: "03",
    key: "Compare",
    art: <ArtCompare />,
    body:
      "Check the two against each other, then against 1.0. Anything above 1.0 means a naive price read is wrong, and the gap is reported in basis points."
  }
];

export default function Steps() {
  return (
    <section className="s" id="how">
      <div className={styles.block}>
        <div className="wrap">
          <div className={styles.head}>
            <div className="eyebrow"><i /><span>How it works</span></div>
            <h2 className={styles.h2}>Three reads, one answer.</h2>
            <p className={styles.lead}>Two sources. Checked against each other, not trusted.</p>
          </div>

          <div className={styles.grid}>
            {STEPS.map((s) => (
              <article className={styles.card} key={s.n}>
                <div className={styles.art}>{s.art}</div>
                <div className={styles.meta}>
                  <span className={styles.n}>{s.n}</span>
                  <span className={styles.slash}>/</span>
                  <span className={styles.key}>{s.key}</span>
                </div>
                <p className={styles.body}>{s.body}</p>
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
EOF

cat > components/Steps.module.css <<'EOF'
.block{
  padding-top:clamp(88px,13vw,170px);
  padding-bottom:clamp(60px,8vw,110px);
  transition:filter 620ms cubic-bezier(.16,1,.3,1),opacity 620ms cubic-bezier(.16,1,.3,1);
}

.head{margin-bottom:clamp(40px,6vw,72px)}

.h2{
  margin:0;font-size:30px;font-weight:400;line-height:1.04;letter-spacing:-.5px;
  text-wrap:balance;max-width:18ch;
}
@media(min-width:640px){.h2{font-size:40px}}
@media(min-width:1024px){.h2{font-size:54px}}

.lead{margin:18px 0 0;font-size:16px;line-height:1.85;color:var(--muted);max-width:54ch}

.grid{display:grid;gap:16px}
@media(min-width:860px){.grid{grid-template-columns:repeat(3,1fr);gap:20px}}

.card{
  border:1px solid var(--line);border-radius:16px;overflow:hidden;
  background:rgba(14,10,10,.52);backdrop-filter:blur(14px);
  display:flex;flex-direction:column;
}

.art{
  margin:14px 14px 0;border-radius:12px;
  border:1px solid rgba(255,255,255,.05);
  background:
    radial-gradient(120% 90% at 50% 8%, rgba(217,58,43,.10) 0%, transparent 62%),
    rgba(255,255,255,.012);
  aspect-ratio:4/3;display:grid;place-items:center;
}
.svg{width:100%;height:100%;display:block}

.ring{fill:none;stroke:rgba(255,255,255,.12);stroke-width:1.2}
.ringOn{fill:none;stroke:var(--accent);stroke-width:1.4;opacity:.85}
.dot{fill:var(--accent)}

.plate{fill:rgba(255,255,255,.05);stroke:rgba(255,255,255,.10);stroke-width:1}
.plateOn{fill:rgba(217,58,43,.16);stroke:var(--accent);stroke-width:1.2}
.beam{stroke:rgba(217,58,43,.5);stroke-width:1.2;fill:none}
.base{stroke:rgba(255,255,255,.12);stroke-width:1}
.gap{stroke:rgba(255,255,255,.22);stroke-width:1;stroke-dasharray:3 4}

.meta{
  display:flex;align-items:center;gap:9px;
  padding:22px 22px 0;
  font-family:var(--mono);font-size:10.5px;letter-spacing:.12em;text-transform:uppercase;
}
.n{color:var(--accent)}
.slash{color:var(--faint)}
.key{color:var(--faint)}

.body{
  margin:14px 22px 26px;
  font-size:14.5px;line-height:1.75;color:var(--muted);
}

@media(max-width:859px){
  .art{aspect-ratio:16/8}
  .body{margin:12px 18px 22px;font-size:14px}
  .meta{padding:18px 18px 0}
}

:global(body.warp) .block{filter:blur(7px);opacity:.42}
@media(prefers-reduced-motion:reduce){
  .block,:global(body.warp) .block{filter:none;opacity:1;transition:none}
}
EOF

# ---------------------------------------------------------------- page
cat > app/page.js <<'EOF'
import Backdrop from "../components/Backdrop";
import Nav from "../components/Nav";
import Hero from "../components/Hero";
import Problem from "../components/Problem";
import Steps from "../components/Steps";
import Affected from "../components/Affected";

export default function Page() {
  return (
    <>
      <Backdrop />
      <Nav />
      <Hero />
      <Problem />
      <Steps />
      <Affected />
      {/* token section next */}
    </>
  );
}
EOF

echo "Done."
