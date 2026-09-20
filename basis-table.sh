#!/usr/bin/env bash
# Basis - grouped comparison table
# Run from the project root: bash basis-table.sh
set -euo pipefail

cd apps/web

cat > components/Problem.js <<'EOF'
import styles from "./Problem.module.css";

const YES = "\u2713";
const NO = "\u2715";

/* Every figure derives from one measured value: CRWD's multiplier of 4.0.
   No share price is assumed, so nothing here goes stale on a tick. */
const GROUPS = [
  {
    label: "What it reads",
    rows: [
      { label: "Issuer asset registry", basis: YES, naive: NO, mark: true },
      { label: "Token contract state", basis: YES, naive: NO, mark: true },
      { label: "Price endpoint", basis: YES, naive: YES, mark: true },
      { label: "Cross-checks the two sources", basis: YES, naive: NO, mark: true }
    ]
  },
  {
    label: "CRWD, after a 4 for 1 split",
    rows: [
      { label: "Multiplier applied", basis: "4.0", naive: "None" },
      { label: "Shares per token", basis: "4", naive: "1" },
      { label: "A position quoted at $10,000", basis: "$40,000", naive: "$10,000" },
      { label: "Understated by", basis: "$0", naive: "$30,000" },
      { label: "Error", basis: "0%", naive: "300%" }
    ]
  }
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
              <div className={`${styles.th} ${styles.own}`}>
                <span className={styles.mk} />
                <span className={styles.thk}>Read with Basis</span>
              </div>
              <div className={styles.th}>
                <span className={styles.thk}>Price endpoint only</span>
              </div>
            </div>

            {GROUPS.map((g) => (
              <div key={g.label}>
                <div className={styles.group}>
                  <span>{g.label}</span>
                </div>

                {g.rows.map((r) => (
                  <div className={styles.tr} key={r.label}>
                    <div className={styles.rl}>{r.label}</div>

                    <div className={`${styles.rv} ${styles.own}`}>
                      <span className={r.mark ? styles.yes : "num"}>{r.basis}</span>
                    </div>

                    <div className={styles.rv}>
                      <span
                        className={
                          r.mark
                            ? r.naive === YES ? styles.yes : styles.no
                            : `num ${styles.bad}`
                        }
                      >
                        {r.naive}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            ))}

            <div className={styles.cta}>
              <a className={styles.ctaBtn} href="#data">
                See all 28 affected assets <span className={styles.chev}>&rsaquo;</span>
              </a>
            </div>

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
.block{
  padding-top:clamp(88px,13vw,170px);
  padding-bottom:clamp(60px,8vw,110px);
  transition:filter 620ms cubic-bezier(.16,1,.3,1),opacity 620ms cubic-bezier(.16,1,.3,1);
}

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
  border:1px solid var(--line);border-radius:18px;overflow:hidden;
  background:rgba(14,10,10,.6);backdrop-filter:blur(16px);
  box-shadow:0 40px 90px -40px rgba(0,0,0,.95);
  max-width:980px;margin:0 auto;
}

.thead,.tr{display:grid;grid-template-columns:1.3fr 1fr 1fr}
.thead{border-bottom:1px solid var(--line)}

.th{
  padding:22px 20px;display:flex;flex-direction:column;align-items:center;
  justify-content:flex-end;gap:12px;min-height:104px;
}
.thk{
  font-family:var(--mono);font-size:10.5px;letter-spacing:.14em;
  text-transform:uppercase;color:var(--faint);text-align:center;
}
.mk{
  width:20px;height:20px;border-radius:6px;border:1.5px solid var(--accent);
  position:relative;flex:none;
}
.mk::after{content:'';position:absolute;inset:4.5px;border-radius:2px;background:var(--accent);opacity:.55}

/* the Basis column reads as the subject of the table, not the winner */
.own{background:rgba(217,58,43,.045);box-shadow:inset 1px 0 0 var(--line),inset -1px 0 0 var(--line)}

.group{
  padding:26px 20px 12px;
  font-family:var(--mono);font-size:10.5px;letter-spacing:.12em;
  text-transform:uppercase;color:var(--accent);
  border-top:1px solid var(--line);
}
.thead + div > .group{border-top:0}

.tr{align-items:center}
.rl{padding:15px 20px;font-size:13.5px;color:var(--muted)}
.rv{
  padding:15px 20px;display:flex;justify-content:center;align-items:center;
  font-size:clamp(14px,1.5vw,18px);font-weight:450;line-height:1;
}
.yes{color:var(--ink);font-size:15px}
.no{color:var(--faint);font-size:15px}
.bad{color:var(--bad)}

.cta{padding:26px 20px 22px;border-top:1px solid var(--line)}
.ctaBtn{
  display:flex;align-items:center;justify-content:center;gap:10px;
  height:50px;border-radius:999px;
  background:var(--ink);color:var(--bg);
  font-size:15px;font-weight:530;
  transition:transform 180ms,opacity 180ms;
}
.ctaBtn:hover{transform:translateY(-1px);opacity:.92}
.chev{opacity:.6}

.tfoot{
  padding:14px 20px;border-top:1px solid var(--line);
  font-family:var(--mono);font-size:10.5px;letter-spacing:.05em;line-height:1.7;
  color:var(--faint);
}

@media(max-width:640px){
  .thead,.tr{grid-template-columns:1.1fr .75fr .75fr}
  .th{padding:16px 10px;min-height:88px}
  .thk{font-size:9px;letter-spacing:.06em}
  .rl{font-size:12px;padding:13px 12px}
  .rv{padding:13px 8px;font-size:14px}
  .group{padding:20px 12px 10px;font-size:9.5px}
  .cta{padding:20px 12px 18px}
  .ctaBtn{font-size:14px;height:46px}
  .tfoot{padding:13px 12px}
}

:global(body.warp) .block{filter:blur(7px);opacity:.42}
@media(prefers-reduced-motion:reduce){
  .block,:global(body.warp) .block{filter:none;opacity:1;transition:none}
}
EOF

echo "Done."
