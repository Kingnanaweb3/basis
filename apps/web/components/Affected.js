"use client";
import { useState } from "react";
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

const CUT = 8;

export default function Affected() {
  const [open, setOpen] = useState(false);
  const shown = open ? ASSETS : ASSETS.slice(0, CUT);
  const rest = ASSETS.length - CUT;

  return (
    <section className="s" id="data">
      <div className={styles.block}>
        <div className="wrap">
          <div className={`${styles.head} r r-down`}>
            <div className="eyebrow"><i /><span>The data</span></div>
            <h2 className={styles.h2}>28 of 194 assets price wrong.</h2>
            <p className={styles.lead}>
              Every asset on Robinhood Chain, read from the issuer registry and the token
              contract. These are the ones where the two disagree with a naive price read.
              The other 166 are clean.
            </p>
          </div>

          <div className={`${styles.panel} r r-1`}>
            <div className={styles.thead}>
              <span>Asset</span>
              <span>Multiplier</span>
              <span className={styles.right}>Error</span>
              <span className={styles.hideSm} />
            </div>

            <ol className={styles.list}>
              {shown.map(([ticker, mult, bps]) => (
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

            {!open && (
              <button className={styles.more} onClick={() => setOpen(true)}>
                Show {rest} more <span className={styles.chev}>&darr;</span>
              </button>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
