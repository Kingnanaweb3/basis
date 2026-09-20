"use client";
import styles from "./Words.module.css";

/* Above the fold, so this runs on load rather than on scroll. Word level,
   not letter level: letter-by-letter on a 48px headline reads as a template
   effect and hurts legibility on the first paint. */
export default function Words({ text, className }) {
  return (
    <span className={className}>
      {text.split(" ").map((w, i) => (
        <span className={styles.mask} key={`${w}-${i}`}>
          <span className={styles.word} style={{ animationDelay: `${60 + i * 55}ms` }}>
            {w}
          </span>
        </span>
      ))}
    </span>
  );
}
