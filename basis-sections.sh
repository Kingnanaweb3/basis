#!/usr/bin/env bash
# Basis - findings + API sections, fix dead links
# Run from the project root: bash basis-sections.sh
set -euo pipefail

cd apps/web

# ---------------------------------------------------------------- Findings
cat > components/Findings.js <<'EOF'
import styles from "./Findings.module.css";

/* What was measured across all 194 assets, including everything that
   returned nothing useful. Published because the negative results are
   what make the one positive result believable. */
const SIGNALS = [
  ["Legal rights", "Identical for every asset. One issuer, one legal wrapper.", "none"],
  ["Asset status", "Active for every asset.", "none"],
  ["Pause state", "False for every asset.", "none"],
  ["Transfer probe", "Contract level pass for every asset.", "none"],
  ["Tradability flags", "Empty for every asset, though the issuer documents them as populated.", "empty"],
  ["Trading halt flag", "The prices endpoint returned an empty body.", "empty"],
  ["Corporate action multiplier", "Above 1.0 on 28 of 194 assets.", "varies"]
];

const VERDICT = {
  none: "No per asset signal",
  empty: "Not populated",
  varies: "The only signal that varies"
};

export default function Findings() {
  return (
    <section className="s" id="findings">
      <div className={styles.block}>
        <div className="wrap">
          <div className={`${styles.head} r r-down`}>
            <div className="eyebrow"><i /><span>Findings</span></div>
            <h2 className={styles.h2}>We measured seven signals. Six were flat.</h2>
            <p className={styles.lead}>
              Basis started as a rights and restrictions map. Across all 194 assets, almost
              everything came back identical. We publish what failed, because it is the reason
              to trust the one thing that did not.
            </p>
          </div>

          <div className={`${styles.table} r r-1 r-left`}>
            <div className={styles.thead}>
              <span>Signal</span>
              <span>What 194 assets returned</span>
              <span>Verdict</span>
            </div>

            {SIGNALS.map(([signal, result, kind]) => (
              <div className={`${styles.tr} ${kind === "varies" ? styles.hit : ""}`} key={signal}>
                <span className={styles.signal}>{signal}</span>
                <span className={styles.result}>{result}</span>
                <span className={`${styles.verdict} ${styles[kind]}`}>{VERDICT[kind]}</span>
              </div>
            ))}

            <a
              className={styles.more}
              href="https://github.com/Kingnanaweb3/basis/blob/main/docs/findings.md"
              target="_blank"
              rel="noreferrer"
            >
              Read the full findings &rsaquo;
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
EOF

cat > components/Findings.module.css <<'EOF'
.block{padding-top:clamp(88px,13vw,170px);padding-bottom:clamp(60px,8vw,110px)}

.head{text-align:center;margin-bottom:clamp(40px,6vw,68px)}
.head :global(.eyebrow){justify-content:center}
.h2{
  margin:0 auto;font-size:30px;font-weight:400;line-height:1.04;letter-spacing:-.5px;
  text-wrap:balance;max-width:20ch;
}
@media(min-width:640px){.h2{font-size:40px}}
@media(min-width:1024px){.h2{font-size:54px}}
.lead{margin:20px auto 0;font-size:16px;line-height:1.85;color:var(--muted);max-width:58ch;text-wrap:balance}

.table{
  border:1px solid var(--line);border-radius:18px;overflow:hidden;
  background:rgba(255,255,255,.72);backdrop-filter:blur(16px);
  box-shadow:0 40px 90px -40px rgba(90,70,65,.16);
  max-width:980px;margin:0 auto;
}

.thead,.tr{display:grid;grid-template-columns:1fr 1.7fr .95fr;gap:18px;align-items:center;padding:0 22px}
.thead{
  height:46px;border-bottom:1px solid var(--line);
  font-family:var(--mono);font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:var(--faint);
}
.tr{padding-block:16px;border-top:1px solid rgba(0,0,0,.06);transition:background 180ms}
.tr:first-of-type{border-top:0}
.tr:hover{background:rgba(0,0,0,.022)}
.hit{background:rgba(217,58,43,.05)}
.hit:hover{background:rgba(217,58,43,.08)}

.signal{font-size:14.5px;font-weight:500;color:var(--ink)}
.result{font-size:13.5px;line-height:1.6;color:var(--muted)}
.verdict{font-family:var(--mono);font-size:10.5px;letter-spacing:.06em;text-transform:uppercase}
.none{color:var(--faint)}
.empty{color:var(--faint)}
.varies{color:var(--accent)}

.more{
  display:flex;justify-content:center;align-items:center;height:52px;
  border-top:1px solid var(--line);
  font-size:14px;font-weight:500;color:var(--ink);
  transition:background 180ms;
}
.more:hover{background:rgba(0,0,0,.03)}

@media(max-width:760px){
  .thead{display:none}
  .tr{grid-template-columns:1fr;gap:6px;padding:16px 16px}
  .verdict{margin-top:4px}
}
EOF

# ---------------------------------------------------------------- API
cat > components/Api.js <<'EOF'
import styles from "./Api.module.css";

const ENDPOINTS = [
  ["GET", "/health", "Liveness, works before any data is loaded"],
  ["GET", "/summary", "Counts, worst error, block number"],
  ["GET", "/assets", "All 194 assets with both multiplier reads"],
  ["GET", "/assets/:ticker", "One asset, case insensitive"],
  ["GET", "/affected", "Only assets where naive pricing is wrong"]
];

/* Abridged response. Every value shown is from the measured run. */
const SAMPLE = `{
  "ticker": "CRWD",
  "status": "ASSET_STATUS_ACTIVE",
  "multiplier": {
    "chain": "4000000000000000000",
    "registry": "4.000000000000000000",
    "sourcesAgree": true,
    "isUnit": false,
    "errorBps": 30000
  },
  "naivePricingSafe": false
}`;

export default function Api() {
  return (
    <section className="s" id="api">
      <div className={styles.block}>
        <div className="wrap">
          <div className={`${styles.head} r r-down`}>
            <div className="eyebrow"><i /><span>API</span></div>
            <h2 className={styles.h2}>Read it from your own code.</h2>
            <p className={styles.lead}>
              Five read only endpoints over the same data this page shows. Every response
              carries the block it was verified at.
            </p>
          </div>

          <div className={styles.grid}>
            <div className={`${styles.panel} r r-1 r-left`}>
              <div className={styles.panelHead}>Endpoints</div>
              {ENDPOINTS.map(([m, path, desc]) => (
                <div className={styles.ep} key={path}>
                  <div className={styles.epTop}>
                    <span className={styles.method}>{m}</span>
                    <code className={styles.path}>{path}</code>
                  </div>
                  <p className={styles.desc}>{desc}</p>
                </div>
              ))}
            </div>

            <div className={`${styles.panel} ${styles.code} r r-2 r-right`}>
              <div className={styles.panelHead}>
                <span>GET /assets/CRWD</span>
                <span className={styles.tag}>abridged</span>
              </div>
              <pre className={styles.pre}><code>{SAMPLE}</code></pre>
            </div>
          </div>

          <p className={`${styles.note} r r-2`}>
            State refreshes on a schedule: registry read once, then each contract read at
            concurrency 4 with retries. An unreadable multiplier stays null, never 1.
            Public base URL is published at launch.
          </p>
        </div>
      </div>
    </section>
  );
}
EOF

cat > components/Api.module.css <<'EOF'
.block{padding-top:clamp(88px,13vw,170px);padding-bottom:clamp(60px,8vw,110px)}

.head{margin-bottom:clamp(40px,6vw,68px)}
.h2{
  margin:0;font-size:30px;font-weight:400;line-height:1.04;letter-spacing:-.5px;
  text-wrap:balance;max-width:18ch;
}
@media(min-width:640px){.h2{font-size:40px}}
@media(min-width:1024px){.h2{font-size:54px}}
.lead{margin:18px 0 0;font-size:16px;line-height:1.85;color:var(--muted);max-width:54ch}

.grid{display:grid;gap:16px}
@media(min-width:900px){.grid{grid-template-columns:1fr 1.1fr;gap:20px;align-items:stretch}}

.panel{
  border:1px solid var(--line);border-radius:16px;overflow:hidden;
  background:rgba(255,255,255,.72);backdrop-filter:blur(14px);
  box-shadow:0 40px 90px -40px rgba(90,70,65,.16);
}
.panelHead{
  display:flex;justify-content:space-between;align-items:center;
  padding:14px 18px;border-bottom:1px solid var(--line);
  font-family:var(--mono);font-size:10.5px;letter-spacing:.12em;text-transform:uppercase;color:var(--faint);
}
.tag{font-size:9.5px;letter-spacing:.08em;border:1px solid var(--line);border-radius:999px;padding:3px 8px}

.ep{padding:15px 18px;border-top:1px solid rgba(0,0,0,.06);transition:background 180ms}
.ep:first-of-type{border-top:0}
.ep:hover{background:rgba(0,0,0,.022)}
.epTop{display:flex;align-items:center;gap:12px}
.method{
  font-family:var(--mono);font-size:10px;letter-spacing:.08em;color:var(--accent);
  border:1px solid rgba(217,58,43,.3);border-radius:6px;padding:3px 7px;
}
.path{font-family:var(--mono);font-size:13px;color:var(--ink)}
.desc{margin:8px 0 0;font-size:13px;line-height:1.6;color:var(--muted)}

.code{background:#141211;border-color:rgba(0,0,0,.4)}
.code .panelHead{color:#8E8A82;border-bottom-color:rgba(255,255,255,.08)}
.code .tag{border-color:rgba(255,255,255,.14)}
.pre{
  margin:0;padding:20px 18px;overflow-x:auto;
  font-family:var(--mono);font-size:12.5px;line-height:1.75;color:#E9E6DF;
}

.note{
  margin:22px 0 0;max-width:72ch;
  font-size:13px;line-height:1.75;color:var(--faint);
}
EOF

# ---------------------------------------------------------------- fix dead links
python3 - <<'PY'
import pathlib
p = pathlib.Path("components/Nav.js"); s = p.read_text(); b = s
s = s.replace('href="#docs">Docs</a>',
  'href="https://github.com/Kingnanaweb3/basis/tree/main/docs" target="_blank" rel="noreferrer">Docs</a>')
if s != b: p.write_text(s); print("Nav: Docs now points at the repo docs")
else: print("Nav: Docs link unchanged")
PY

# ---------------------------------------------------------------- page order
cat > app/page.js <<'EOF'
import Reveal from "../components/Reveal";
import Backdrop from "../components/Backdrop";
import Nav from "../components/Nav";
import Hero from "../components/Hero";
import Problem from "../components/Problem";
import Steps from "../components/Steps";
import Affected from "../components/Affected";
import Findings from "../components/Findings";
import Api from "../components/Api";
import Token from "../components/Token";
import Footer from "../components/Footer";

export default function Page() {
  return (
    <>
      <Reveal />
      <Backdrop />
      <Nav />
      <Hero />
      <Problem />
      <Steps />
      <Affected />
      <Findings />
      <Api />
      <Token />
      <Footer />
    </>
  );
}
EOF

echo "Done."
