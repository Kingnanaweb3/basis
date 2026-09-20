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
          <div className={`${styles.head} r r-down`}>
            <div className="eyebrow"><i /><span>How it works</span></div>
            <h2 className={styles.h2}>Three reads, one answer.</h2>
            <p className={styles.lead}>Two sources. Checked against each other, not trusted.</p>
          </div>

          <div className={styles.grid}>
            {STEPS.map((s, i) => (
              <article className={`${styles.card} r r-card r-${i + 1}`} key={s.n}>
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
