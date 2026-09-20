#!/usr/bin/env bash
# Basis - affected assets section
# Run from the project root: bash basis-data.sh
set -euo pipefail

cd apps/web

cat > components/Affected.js <<'EOF'
import styles from "./Affected.module.css";

/* Measured on Robinhood Chain at block 67103382. Basis points are the error an
   integrator incurs by ignoring the multiplier; multiplier is 1 + bps/10000.
   Static snapshot until the API is deployed, then this becomes a fetch. */
const ASSETS = [
  ["CRWD", "4.0", 30000],
  ["CCL", "1.0215", 214.86],
  ["SGOV", "1.0051", 51.01],
  ["KSS", "1.0046", 46.1],
  ["PR", "1.0045", 44.77],
  ["UNH", "1.0042", 42.41],
  ["ORCL", "1.0022", 22.1],
  ["UPS", "1.0022", 22.08],
  ["SPY", "1.0017", 17.17],
  ["HPE", "1.0017", 17.16],
  ["TSM", "1.0015", 14.63],
  ["CRM", "1.0011", 11.48],
  ["XOM", "1.0010", 10.39],
  ["NVDA", "1.0008", 7.75],
  ["COST", "1.0006", 6.12],
  ["AAPL", "1.0006", 5.66],
  ["SOXX", "1.0005", 4.5],
  ["MSFT", "1.0004", 4.12],
  ["WDC", "1.0002", 2.17],
  ["GOOGL", "1.0002", 1.93],
  ["VRT", "1.0002", 1.62],
  ["F", "1.0001", 1.45],
  ["ASML", "1.0001", 1.01],
  ["MU", "1.0001", 0.74],
  ["DELL", "1.0001", 0.63],
  ["AMAT", "1.0000", 0.44],
  ["JNJ", "1.0000", 0.21],
  ["LLY", "1.0000", 0.02]
];

const pct = (bps) => {
  const v = bps / 100;
  if (v >= 100) return `${v.toFixed(0)}%`;
  if (v >= 1) return `${v.toFixed(2)}%`;
  return `${v.toFixed(2)}%`;
};

/* bar length is log-scaled: CRWD is 14,000x the smallest error and would
   otherwise flatten every other row to nothing */
const bar = (bps) => {
  const min = Math.log10(0.02), max = Math.log10(30000);
  const t = (Math.log10(bps) - min) / (max - min);
  return Math.max(2, Math.round(t * 100));
};

export default function Affected() {
  return (
    <section className="s" id="data">
      <div className={styles.block}>
        <div className="wrap">
          <div className={styles.head}>
            <div className="eyebrow"><i /><span>The data</span></div>
            <h2 className={styles.h2}>28 of 194 assets price wrong.</h2>
            <p className={styles.lead}>
              Every asset on Robinhood Chain, read from the issuer registry and the token
              contract. These are the ones where the two disagree with a naive price read.
              The other 166 are clean.
            </p>
          </div>

          <div className={styles.panel}>
            <div className={styles.thead}>
              <span>Asset</span>
              <span>Multiplier</span>
              <span className={styles.right}>Error</span>
              <span className={styles.hideSm} />
            </div>

            <ol className={styles.list}>
              {ASSETS.map(([ticker, mult, bps]) => (
                <li className={styles.row} key={ticker}>
                  <span className={styles.ticker}>{ticker}</span>
                  <span className={`${styles.mult} num`}>{mult}</span>
                  <span className={`${styles.err} num ${bps >= 100 ? styles.bad : ""}`}>
                    {pct(bps)}
                  </span>
                  <span className={`${styles.track} ${styles.hideSm}`}>
                    <span className={styles.fill} style={{ width: `${bar(bps)}%` }} />
                  </span>
                </li>
              ))}
            </ol>

            <div className={styles.foot}>
              <span>Snapshot at block 67103382 &middot; 0 unreadable &middot; 0 source disagreements</span>
              <span className={styles.hideSm}>Bars are log scaled</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
EOF

cat > components/Affected.module.css <<'EOF'
.block{
  padding-top:clamp(88px,13vw,170px);
  padding-bottom:clamp(60px,8vw,110px);
  transition:filter 620ms cubic-bezier(.16,1,.3,1),opacity 620ms cubic-bezier(.16,1,.3,1);
}

.head{text-align:center;margin-bottom:clamp(40px,6vw,68px)}
.head :global(.eyebrow){justify-content:center}

.h2{
  margin:0 auto;font-size:30px;font-weight:400;line-height:1.04;letter-spacing:-.5px;
  text-wrap:balance;max-width:18ch;
}
@media(min-width:640px){.h2{font-size:40px}}
@media(min-width:1024px){.h2{font-size:54px}}

.lead{
  margin:20px auto 0;font-size:16px;line-height:1.85;color:var(--muted);
  max-width:58ch;text-wrap:balance;
}

.panel{
  border:1px solid var(--line);border-radius:18px;overflow:hidden;
  background:rgba(14,10,10,.6);backdrop-filter:blur(16px);
  box-shadow:0 40px 90px -40px rgba(0,0,0,.95);
  max-width:820px;margin:0 auto;
}

.thead,.row{
  display:grid;
  grid-template-columns:76px 1fr 82px minmax(120px, 1.4fr);
  align-items:center;gap:14px;
  padding:0 20px;
}
.thead{
  height:44px;border-bottom:1px solid var(--line);
  font-family:var(--mono);font-size:10px;letter-spacing:.12em;
  text-transform:uppercase;color:var(--faint);
}
.right{text-align:right}

.list{list-style:none;margin:0;padding:0}
.row{height:46px;border-top:1px solid rgba(255,255,255,.05)}
.row:first-child{border-top:0}

.ticker{font-family:var(--mono);font-size:12.5px;letter-spacing:.04em;color:var(--ink)}
.mult{font-size:13.5px;color:var(--muted)}
.err{font-size:14px;text-align:right;font-weight:450}
.bad{color:var(--bad)}

.track{height:5px;border-radius:999px;background:rgba(255,255,255,.055);overflow:hidden}
.fill{display:block;height:100%;border-radius:999px;background:var(--accent);opacity:.78}

.foot{
  padding:14px 20px;border-top:1px solid var(--line);
  display:flex;justify-content:space-between;gap:14px;flex-wrap:wrap;
  font-family:var(--mono);font-size:10px;letter-spacing:.05em;color:var(--faint);
}

@media(max-width:700px){
  .hideSm{display:none}
  .thead,.row{grid-template-columns:64px 1fr 74px;gap:10px;padding:0 14px}
  .foot{padding:13px 14px}
  .ticker{font-size:11.5px}
  .mult{font-size:12.5px}
  .err{font-size:13px}
}

:global(body.warp) .block{filter:blur(7px);opacity:.42}
@media(prefers-reduced-motion:reduce){
  .block,:global(body.warp) .block{filter:none;opacity:1;transition:none}
}
EOF

cat > app/page.js <<'EOF'
import Backdrop from "../components/Backdrop";
import Nav from "../components/Nav";
import Hero from "../components/Hero";
import Problem from "../components/Problem";
import Affected from "../components/Affected";

export default function Page() {
  return (
    <>
      <Backdrop />
      <Nav />
      <Hero />
      <Problem />
      <Affected />
      {/* next sections go here */}
    </>
  );
}
EOF

echo "Done."
