#!/usr/bin/env bash
# Basis - page-wide backdrop + problem section
# Run from the project root: bash basis-problem.sh
set -euo pipefail

cd apps/web

# ---------------------------------------------------------------- Backdrop
cat > components/Backdrop.js <<'EOF'
"use client";
import Field from "./Field";
import styles from "./Backdrop.module.css";

/* The scale field sits behind the entire page, not just the hero.
   Warp state is published as a body class so any section can react to it. */
export default function Backdrop() {
  const onWarp = (on) => {
    document.body.classList.toggle("warp", on);
  };

  return (
    <div className={styles.backdrop} aria-hidden="true">
      <Field className={styles.field} onWarp={onWarp} />
      <div className={styles.veil} />
    </div>
  );
}
EOF

cat > components/Backdrop.module.css <<'EOF'
.backdrop{position:fixed;inset:0;z-index:0;pointer-events:none}
.field{position:absolute;inset:0;width:100%;height:100%;display:block}
.veil{
  position:absolute;inset:0;
  background:
    radial-gradient(120% 80% at 34% 26%, rgba(9,1,1,.94) 0%, rgba(9,1,1,.52) 32%, transparent 60%),
    linear-gradient(to bottom, rgba(12,12,12,.88) 0%, rgba(12,12,12,.34) 28%, rgba(12,12,12,.72) 64%, rgba(12,12,12,.94) 100%);
}
EOF

# ---------------------------------------------------------------- Hero (field removed, styles untouched)
cat > components/Hero.js <<'EOF'
"use client";
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
  return (
    <header className={styles.hero}>
      <div className={styles.inner}>
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
            <a className="pill-lg solid" href="#problem">
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

# ---------------------------------------------------------------- Problem section
cat > components/Problem.js <<'EOF'
import styles from "./Problem.module.css";

/* Every figure here is arithmetic from one measured value: CRWD's multiplier
   of 4.0. No share price is assumed, so nothing here can go stale on a tick. */
const ROWS = [
  { label: "Source read", naive: "Price endpoint only", basis: "Registry + contract", plain: true },
  { label: "Multiplier applied", naive: "None", basis: "4.0" },
  { label: "Shares per token", naive: "1", basis: "4" },
  { label: "A position quoted at", naive: "$10,000", basis: "$10,000", plain: true },
  { label: "Is actually worth", naive: "$10,000", basis: "$40,000", flag: "naive" },
  { label: "Understated by", naive: "$30,000", basis: "$0", flag: "naive" },
  { label: "Error", naive: "300%", basis: "0%", flag: "naive" }
];

export default function Problem() {
  return (
    <section className="s" id="problem">
      <div className={styles.block}>
        <div className="wrap">
          <div className={styles.head}>
            <div className="eyebrow"><i /><span>The problem</span></div>
            <h2 className={styles.h2}>One asset. Two sources. Two very different numbers.</h2>
            <p className={styles.lead}>
              CrowdStrike split four for one. The token carries a multiplier of 4.0.
              The price endpoint does not apply it, and nothing in the contract or a block
              explorer tells you that.
            </p>
          </div>

          <div className={styles.table}>
            <div className={styles.thead}>
              <div className={styles.th} />
              <div className={styles.th}>
                <span className={styles.thk}>Raw price endpoint</span>
              </div>
              <div className={styles.th}>
                <span className={styles.thk}>Read with Basis</span>
              </div>
            </div>

            {ROWS.map((r) => (
              <div className={styles.tr} key={r.label}>
                <div className={styles.rl}>{r.label}</div>
                <div
                  className={`${styles.rv} ${r.plain ? styles.plain : "num"} ${
                    r.flag === "naive" ? styles.bad : ""
                  }`}
                >
                  {r.naive}
                </div>
                <div className={`${styles.rv} ${r.plain ? styles.plain : "num"}`}>{r.basis}</div>
              </div>
            ))}

            <div className={styles.tfoot}>
              CRWD &middot; multiplier read from both the issuer registry and the token
              contract at block 67103382. The two agree.
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
EOF

cat > components/Problem.module.css <<'EOF'
.block{padding-top:clamp(88px,13vw,170px);padding-bottom:clamp(60px,8vw,110px)}

.head{text-align:center;margin-bottom:clamp(40px,6vw,68px)}
.head :global(.eyebrow){justify-content:center}

.h2{
  margin:0 auto;font-size:30px;font-weight:400;line-height:1.04;letter-spacing:-.5px;
  text-wrap:balance;max-width:20ch;
}
@media(min-width:640px){.h2{font-size:40px}}
@media(min-width:1024px){.h2{font-size:54px}}

.lead{
  margin:20px auto 0;font-size:16px;line-height:1.85;color:var(--muted);
  max-width:56ch;text-wrap:balance;
}

/* ---------- table ---------- */
.table{
  border:1px solid var(--line);border-radius:16px;overflow:hidden;
  background:rgba(14,10,10,.58);backdrop-filter:blur(16px);
  box-shadow:0 40px 90px -40px rgba(0,0,0,.95);
  max-width:940px;margin:0 auto;
}

.thead,.tr{display:grid;grid-template-columns:1.25fr 1fr 1fr;align-items:center}
.thead{border-bottom:1px solid var(--line)}
.th{padding:16px 18px}
.thk{
  font-family:var(--mono);font-size:10.5px;letter-spacing:.12em;
  text-transform:uppercase;color:var(--faint);
}

.tr{border-top:1px solid var(--line)}
.tr:first-of-type{border-top:0}

.rl{
  padding:16px 18px;font-size:13.5px;color:var(--muted);
}
.rv{
  padding:16px 18px;font-size:clamp(15px,1.6vw,19px);font-weight:450;line-height:1;
}
.plain{font-size:13.5px;font-weight:400;color:var(--muted)}
.bad{color:var(--bad)}

.tfoot{
  padding:14px 18px;border-top:1px solid var(--line);
  font-family:var(--mono);font-size:10.5px;letter-spacing:.05em;line-height:1.7;
  color:var(--faint);
}

@media(max-width:640px){
  .thead,.tr{grid-template-columns:1fr .8fr .8fr}
  .rl{font-size:12.5px;padding:13px 12px}
  .rv{padding:13px 12px}
  .th{padding:13px 12px}
  .thk{font-size:9.5px;letter-spacing:.08em}
}
EOF

# ---------------------------------------------------------------- page
cat > app/page.js <<'EOF'
import Backdrop from "../components/Backdrop";
import Nav from "../components/Nav";
import Hero from "../components/Hero";
import Problem from "../components/Problem";

export default function Page() {
  return (
    <>
      <Backdrop />
      <Nav />
      <Hero />
      <Problem />
      {/* next sections go here */}
    </>
  );
}
EOF

# ---------------------------------------------------------------- appended styles (existing edits preserved)
cat >> app/globals.css <<'EOF'

/* content sits above the fixed backdrop */
header, section { position: relative; z-index: 1; }

/* the warp pulse reaches every section, not just the hero */
body.warp .warpable{
  filter: blur(9px);
  opacity: .34;
}
.warpable{
  transition: filter 620ms cubic-bezier(.16,1,.3,1), opacity 620ms cubic-bezier(.16,1,.3,1);
}
@media (prefers-reduced-motion: reduce){
  .warpable, body.warp .warpable{filter:none;opacity:1;transition:none}
}
EOF

cat >> components/Hero.module.css <<'EOF'

/* field moved to the page-wide backdrop */
.hero{min-height:88svh}
:global(body.warp) .inner{filter:blur(9px);opacity:.34}
EOF

cat >> components/Problem.module.css <<'EOF'

:global(body.warp) .block{filter:blur(7px);opacity:.42}
.block{transition:filter 620ms cubic-bezier(.16,1,.3,1),opacity 620ms cubic-bezier(.16,1,.3,1)}
@media(prefers-reduced-motion:reduce){
  .block,:global(body.warp) .block{filter:none;opacity:1;transition:none}
}
EOF

echo "Done. Restart not needed: npm run dev picks this up."
