"use client";
import CaLine from "./CaLine";
import Words from "./Words";
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

          <h1 className={styles.h1}>
            <Words text="Price Reconciliation Infrastructure" />
          </h1>

          <CaLine />

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

          <div className={`${styles.card} r r-card r-1`}>
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
