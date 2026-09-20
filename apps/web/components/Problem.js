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
          <div className={`${styles.head} r r-down`}>
            <div className="eyebrow"><i /><span>The problem</span></div>
            <h2 className={styles.h2}>One asset. Two sources. Two very different numbers.</h2>
            <p className={styles.lead}>
              CrowdStrike split four for one. The token carries a multiplier of 4.0.
              The price endpoint does not apply it, and nothing in the contract or a block
              explorer tells you that.
            </p>
          </div>

          <div className={`${styles.table} r r-1`}>
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
