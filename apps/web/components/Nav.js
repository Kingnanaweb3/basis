"use client";
import { useEffect, useState } from "react";
import styles from "./Nav.module.css";

export default function Nav() {
  const [stuck, setStuck] = useState(false);

  useEffect(() => {
    const onScroll = () => setStuck(window.scrollY > 24);
    onScroll();
    addEventListener("scroll", onScroll, { passive: true });
    return () => removeEventListener("scroll", onScroll);
  }, []);

  return (
    <nav className={`${styles.nav} ${stuck ? styles.stuck : ""}`}>
      <div className={styles.brand}>
        <span className={styles.mk} />
        basis
      </div>
      <a className={`${styles.link} ${styles.hideSm}`} href="#findings">Findings</a>
      <a className={`${styles.link} ${styles.hideSm}`} href="#docs">Docs</a>
      <a className={`${styles.link} ${styles.hideSm}`} href="#api">API</a>
      <a className={`${styles.link} ${styles.cta}`} href="#data">View the data</a>
    </nav>
  );
}
