"use client";
import { useEffect, useState } from "react";
import { toChecksum } from "../lib/checksum";
import styles from "./Token.module.css";

const EXPLORER = "https://robinhoodchain.blockscout.com/token/";
const isAddr = (a) => typeof a === "string" && /^0x[0-9a-fA-F]{40}$/.test(a);

const FACTS = [
  ["Symbol", "BASIS"],
  ["Supply", "1,000,000,000"],
  ["Launch", "Fair launch"],
  ["Chain", "Robinhood Chain"]
];

export default function Token() {
  const [address, setAddress] = useState(null);
  const [copied, setCopied] = useState(false);

  /* Polls every 5s so tabs already open when the swap lands update themselves.
     Nobody reloads during a launch. */
  useEffect(() => {
    let alive = true;

    const pull = async () => {
      try {
        const r = await fetch(`/api/token-config?t=${Date.now()}`, { cache: "no-store" });
        const j = await r.json();
        if (alive) setAddress(isAddr(j?.address) ? toChecksum(j.address) : null);
      } catch {
        /* keep the last good value rather than flashing empty */
      }
    };

    pull();
    const id = setInterval(pull, 5000);
    return () => { alive = false; clearInterval(id); };
  }, []);

  const copy = async () => {
    if (!address) return;
    try {
      await navigator.clipboard.writeText(address);
      setCopied(true);
      setTimeout(() => setCopied(false), 1600);
    } catch {}
  };

  const short = address ? `${address.slice(0, 10)}\u2026${address.slice(-8)}` : null;

  return (
    <section className="s" id="token">
      <div className={styles.block}>
        <div className="wrap">
          <div className={`${styles.head} r r-down`}>
            <div className="eyebrow"><i /><span>Token</span></div>
            <h2 className={styles.h2}>BASIS</h2>
            <p className={styles.lead}>
              Fair launch on Robinhood Chain. One billion supply. The contract address
              appears here the moment it exists, and this page updates itself without a
              reload.
            </p>
          </div>

          <div className={`${styles.panel} r r-1 r-scale`}>
            <div className={styles.facts}>
              {FACTS.map(([k, v]) => (
                <div className={styles.fact} key={k}>
                  <span className={styles.k}>{k}</span>
                  <span className={styles.v}>{v}</span>
                </div>
              ))}
            </div>

            <div className={styles.ca}>
              <div className={styles.caHead}>
                <span className={`${styles.status} ${address ? styles.live : ""}`} />
                <span className={styles.caLabel}>
                  {address ? "Contract address" : "Not live yet"}
                </span>
              </div>

              {address ? (
                <div className={styles.caRow}>
                  <code className={styles.addr} title={address}>{short}</code>
                  <button className={styles.btn} onClick={copy}>
                    {copied ? "Copied" : "Copy"}
                  </button>
                  <a
                    className={styles.btn}
                    href={`${EXPLORER}${address}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Explorer
                  </a>
                </div>
              ) : (
                <div className={styles.caRow}>
                  <code className={`${styles.addr} ${styles.pending}`}>
                    0x&mdash;&mdash;&mdash;&mdash; awaiting deploy &mdash;&mdash;&mdash;&mdash;
                  </code>
                  <span className={styles.note}>checking every 5s</span>
                </div>
              )}
            </div>

            <p className={styles.warn}>
              Verify the address against this page before sending anything. Basis does not
              post the address anywhere else.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
