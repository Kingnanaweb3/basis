"use client";
import Field from "./Field";
import styles from "./Backdrop.module.css";

/* The scale field sits behind the entire page, not just the hero.
   Warp state is published as a body class so any section can react to it. */
export default function Backdrop() {
  const onWarp = (on) => {
    document.body.classList.toggle("warp", on);
  };

  return (
    <div className={styles.backdrop} aria-hidden="true">
      <Field className={styles.field} onWarp={onWarp} />
      <div className={styles.veil} />
    </div>
  );
}
