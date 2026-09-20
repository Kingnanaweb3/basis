"use client";
import { useEffect, useState } from "react";
import { toChecksum } from "../lib/checksum";
import styles from "./CaLine.module.css";

const isAddr = (a) => typeof a === "string" && /^0x[0-9a-fA-F]{40}$/.test(a);

/* Same 5s poll as the token section. Two pollers is fine and keeps the
   components independent of each other. */
export default function CaLine() {
  const [address, setAddress] = useState(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    let alive = true;
    const pull = async () => {
      try {
        const r = await fetch(`/api/token-config?t=${Date.now()}`, { cache: "no-store" });
        const j = await r.json();
        if (alive) setAddress(isAddr(j?.address) ? toChecksum(j.address) : null);
      } catch {}
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

  return (
    <div className={styles.line}>
      <span className={styles.label}>
        <span className={`${styles.dot} ${address ? styles.live : ""}`} />
        BASIS CA
      </span>

      {address ? (
        <>
          <code className={styles.addr} title={address}>{address}</code>
          <button className={styles.copy} onClick={copy}>{copied ? "Copied" : "Copy"}</button>
        </>
      ) : (
        <span className={styles.soon}>Address coming soon</span>
      )}
    </div>
  );
}
