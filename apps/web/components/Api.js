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
