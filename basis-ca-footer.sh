#!/usr/bin/env bash
# Basis - hero CA line + footer
# Run from the project root: bash basis-ca-footer.sh
set -euo pipefail

cd apps/web

# ---------------------------------------------------------------- CA line
cat > components/CaLine.js <<'EOF'
"use client";
import { useEffect, useState } from "react";
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
        if (alive) setAddress(isAddr(j?.address) ? j.address : null);
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
EOF

cat > components/CaLine.module.css <<'EOF'
.line{
  display:flex;align-items:center;justify-content:center;gap:12px;flex-wrap:wrap;
  padding:14px 18px;border-top:1px solid var(--line);
  background:rgba(255,255,255,.012);
}
.label{
  display:inline-flex;align-items:center;gap:8px;
  font-family:var(--mono);font-size:10.5px;letter-spacing:.14em;
  text-transform:uppercase;color:var(--faint);
}
.dot{width:6px;height:6px;border-radius:50%;background:var(--faint);flex:none}
.live{background:var(--accent);box-shadow:0 0 0 3px rgba(217,58,43,.18)}

.addr{
  font-family:var(--mono);font-size:12px;letter-spacing:.02em;color:var(--ink);
  max-width:100%;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;
}
.soon{font-family:var(--mono);font-size:12px;letter-spacing:.04em;color:var(--muted)}

.copy{
  height:30px;padding-inline:12px;border-radius:8px;
  border:1px solid var(--line);background:rgba(255,255,255,.02);
  color:var(--muted);font-family:var(--sans);font-size:12.5px;font-weight:450;
  letter-spacing:-0.4px;cursor:pointer;
  transition:color 160ms,background 160ms;
}
.copy:hover{color:var(--ink);background:rgba(255,255,255,.055)}

@media(max-width:560px){
  .addr{font-size:10.5px}
}
EOF

# ---------------------------------------------------------------- wire into hero
python3 - <<'PY'
import pathlib
p = pathlib.Path("components/Hero.js")
s = p.read_text()

if "CaLine" not in s:
    s = s.replace(
        'import styles from "./Hero.module.css";',
        'import CaLine from "./CaLine";\nimport styles from "./Hero.module.css";'
    )
    s = s.replace(
        '            <div className={styles.foot}>',
        '            <CaLine />\n\n            <div className={styles.foot}>'
    )
    p.write_text(s)
    print("wired CaLine into Hero.js")
else:
    print("CaLine already present")
PY

# ---------------------------------------------------------------- footer
cat > components/Footer.js <<'EOF'
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
        <div className={styles.top}>
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

        <div className={styles.bottom}>
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
EOF

cat > components/Footer.module.css <<'EOF'
.footer{
  position:relative;z-index:1;
  border-top:1px solid var(--line);
  background:rgba(8,6,6,.72);backdrop-filter:blur(16px);
  padding-top:clamp(56px,7vw,88px);
  padding-bottom:clamp(30px,4vw,44px);
}

.top{display:grid;gap:40px}
@media(min-width:860px){.top{grid-template-columns:1.1fr 1.6fr;gap:60px}}

.brand{display:flex;align-items:center;gap:9px;font-weight:500;font-size:17px}
.mk{width:16px;height:16px;border-radius:4px;border:1.5px solid var(--accent);position:relative;flex:none}
.mk::after{content:'';position:absolute;inset:3.5px;border-radius:1px;background:var(--accent);opacity:.55}

.blurb{margin:16px 0 0;font-size:14px;line-height:1.75;color:var(--muted);max-width:40ch}

.cols{display:grid;grid-template-columns:1fr 1fr;gap:32px}
@media(min-width:640px){.cols{grid-template-columns:repeat(3,1fr)}}

.col{display:flex;flex-direction:column;gap:12px}
.colTitle{
  font-family:var(--mono);font-size:10px;letter-spacing:.14em;
  text-transform:uppercase;color:var(--faint);margin-bottom:2px;
}
.link{font-size:13.5px;color:var(--muted);transition:color 160ms;width:fit-content}
.link:hover{color:var(--ink)}

.bottom{
  margin-top:clamp(40px,6vw,64px);padding-top:22px;
  border-top:1px solid var(--line);
  display:grid;gap:14px;
}
@media(min-width:860px){.bottom{grid-template-columns:1fr auto;align-items:end;gap:40px}}

.fine{margin:0;font-size:12px;line-height:1.75;color:var(--faint);max-width:78ch}
.stamp{
  font-family:var(--mono);font-size:10px;letter-spacing:.08em;
  text-transform:uppercase;color:var(--faint);white-space:nowrap;
}
EOF

# ---------------------------------------------------------------- page
cat > app/page.js <<'EOF'
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
