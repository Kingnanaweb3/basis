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
