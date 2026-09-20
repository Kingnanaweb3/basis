import styles from "./Footer.module.css";

const LINKS = [
  ["Product", [
    ["The problem", "#problem"],
    ["How it works", "#how"],
    ["The data", "#data"],
    ["Token", "#token"]
  ]],
  ["Build", [
    ["GitHub", "https://github.com/Kingnanaweb3/basis"],
    ["Documentation", "https://github.com/Kingnanaweb3/basis/tree/main/docs"],
    ["Findings", "https://github.com/Kingnanaweb3/basis/blob/main/docs/findings.md"],
    ["Limitations", "https://github.com/Kingnanaweb3/basis/blob/main/docs/limitations.md"]
  ]],
  ["Chain", [
    ["Robinhood Chain", "https://docs.robinhood.com/chain/"],
    ["Explorer", "https://robinhoodchain.blockscout.com"]
  ]]
];

export default function Footer() {
  return (
    <footer className={`s ${styles.footer}`}>
      <div className="wrap">
        <div className={`${styles.top} r`}>
          <div className={styles.brandCol}>
            <div className={styles.brand}>
              <span className={styles.mk} />
              basis
            </div>
            <p className={styles.blurb}>
              A pricing safety check for tokenized assets on Robinhood Chain.
              28 of 194 assets price wrong without it.
            </p>
          </div>

          <div className={styles.cols}>
            {LINKS.map(([title, items]) => (
              <nav className={styles.col} key={title}>
                <span className={styles.colTitle}>{title}</span>
                {items.map(([label, href]) => (
                  <a
                    className={styles.link}
                    key={label}
                    href={href}
                    {...(href.startsWith("http") ? { target: "_blank", rel: "noreferrer" } : {})}
                  >
                    {label}
                  </a>
                ))}
              </nav>
            ))}
          </div>
        </div>

        <div className={`${styles.bottom} r r-1`}>
          <p className={styles.fine}>
            Basis reports measurements read from public sources. It is not financial or
            legal advice, and it does not quote prices. Robinhood Stock Tokens are issued
            by Robinhood Assets (Jersey) Limited and are restricted in a number of
            jurisdictions.
          </p>
          <span className={styles.stamp}>Read at block 67103382</span>
        </div>
      </div>
    </footer>
  );
}
