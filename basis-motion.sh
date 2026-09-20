#!/usr/bin/env bash
# Basis - footer mobile fix + motion pass
# Run from the project root: bash basis-motion.sh
set -euo pipefail

cd apps/web

# ---------------------------------------------------------------- reveal observer
cat > components/Reveal.js <<'EOF'
"use client";
import { useEffect } from "react";

/* One observer for the whole page. Elements marked .r rise and fade in once,
   then stop being observed. Section-level, not per card in a grid, except
   where a grid's children are genuinely sequential. */
export default function Reveal() {
  useEffect(() => {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) {
      document.querySelectorAll(".r").forEach((el) => el.classList.add("in"));
      return;
    }

    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add("in");
            io.unobserve(e.target);
          }
        }
      },
      { rootMargin: "0px 0px -12% 0px", threshold: 0.08 }
    );

    document.querySelectorAll(".r").forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  return null;
}
EOF

# ---------------------------------------------------------------- hero headline words
cat > components/Words.js <<'EOF'
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
          {i < text.split(" ").length - 1 ? " " : ""}
        </span>
      ))}
    </span>
  );
}
EOF

cat > components/Words.module.css <<'EOF'
.mask{display:inline-block;overflow:hidden;vertical-align:bottom}
.word{
  display:inline-block;
  transform:translateY(105%);
  opacity:0;
  animation:rise .82s cubic-bezier(.16,1,.3,1) forwards;
}
@keyframes rise{
  to{transform:translateY(0);opacity:1}
}
@media(prefers-reduced-motion:reduce){
  .word{transform:none;opacity:1;animation:none}
}
EOF

# ---------------------------------------------------------------- reveal styles
cat >> app/globals.css <<'EOF'

/* scroll reveal, one effect used consistently */
.r{
  opacity:0;
  transform:translateY(18px);
  transition:opacity .7s cubic-bezier(.16,1,.3,1), transform .7s cubic-bezier(.16,1,.3,1);
}
.r.in{opacity:1;transform:none}
.r-1{transition-delay:.06s}
.r-2{transition-delay:.12s}
.r-3{transition-delay:.18s}
@media (prefers-reduced-motion: reduce){
  .r{opacity:1;transform:none;transition:none}
}
EOF

# ---------------------------------------------------------------- footer padding fix
cat >> components/Footer.module.css <<'EOF'

/* section.s only matches <section>, and this is a <footer>, so the page
   padding never applied here. Set it on the element itself. */
.footer{padding-inline:16px}
@media(min-width:640px){.footer{padding-inline:32px}}
@media(min-width:1024px){.footer{padding-inline:30px}}

.fine{max-width:68ch;overflow-wrap:anywhere}

@media(max-width:640px){
  .top{gap:34px}
  .cols{gap:28px}
  .blurb{font-size:13.5px}
  .bottom{margin-top:34px}
  .fine{font-size:11.5px}
  .stamp{font-size:9.5px}
}
EOF

# ---------------------------------------------------------------- apply .r and Words
python3 - <<'PY'
import pathlib, re

def patch(path, pairs, label):
    p = pathlib.Path(path)
    s = p.read_text()
    changed = False
    for old, new in pairs:
        if old in s and new not in s:
            s = s.replace(old, new, 1)
            changed = True
    if changed:
        p.write_text(s)
        print(f"{label}: patched")
    else:
        print(f"{label}: no change needed")

patch("components/Problem.js", [
    ('<div className={styles.head}>', '<div className={`${styles.head} r`}>'),
    ('<div className={styles.table}>', '<div className={`${styles.table} r r-1`}>')
], "Problem")

patch("components/Steps.js", [
    ('<div className={styles.head}>', '<div className={`${styles.head} r`}>'),
    ('{STEPS.map((s) => (\n              <article className={styles.card} key={s.n}>',
     '{STEPS.map((s, i) => (\n              <article className={`${styles.card} r r-${i + 1}`} key={s.n}>')
], "Steps")

patch("components/Affected.js", [
    ('<div className={styles.head}>', '<div className={`${styles.head} r`}>'),
    ('<div className={styles.panel}>', '<div className={`${styles.panel} r r-1`}>')
], "Affected")

patch("components/Token.js", [
    ('<div className={styles.head}>', '<div className={`${styles.head} r`}>'),
    ('<div className={styles.panel}>', '<div className={`${styles.panel} r r-1`}>')
], "Token")

patch("components/Footer.js", [
    ('<div className={styles.top}>', '<div className={`${styles.top} r`}>'),
    ('<div className={styles.bottom}>', '<div className={`${styles.bottom} r r-1`}>')
], "Footer")

# hero card reveals on scroll, headline animates on load
patch("components/Hero.js", [
    ('import CaLine from "./CaLine";', 'import CaLine from "./CaLine";\nimport Words from "./Words";'),
    ('<h1 className={styles.h1}>Check the multiplier before you trust the price.</h1>',
     '<h1 className={styles.h1}>\n            <Words text="Check the multiplier before you trust the price." />\n          </h1>'),
    ('<div className={styles.card}>', '<div className={`${styles.card} r r-1`}>')
], "Hero")
PY

# ---------------------------------------------------------------- page
cat > app/page.js <<'EOF'
import Reveal from "../components/Reveal";
import Backdrop from "../components/Backdrop";
import Nav from "../components/Nav";
import Hero from "../components/Hero";
import Problem from "../components/Problem";
import Steps from "../components/Steps";
import Affected from "../components/Affected";
import Token from "../components/Token";
import Footer from "../components/Footer";

export default function Page() {
  return (
    <>
      <Reveal />
      <Backdrop />
      <Nav />
      <Hero />
      <Problem />
      <Steps />
      <Affected />
      <Token />
      <Footer />
    </>
  );
}
EOF

echo "Done."
