#!/usr/bin/env bash
# Basis - token section + runtime CA swap
# Run from the project root: bash basis-token.sh
set -euo pipefail

cd apps/web
mkdir -p app/api/token-config scripts

# ---------------------------------------------------------------- config endpoint
cat > app/api/token-config/route.js <<'EOF'
export const dynamic = 'force-dynamic';
export const revalidate = 0;

const URL_ = process.env.UPSTASH_REDIS_REST_URL;
const TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;
const ADMIN_KEY = process.env.ADMIN_KEY;
const KEY = 'basis:ca';
const FALLBACK = process.env.BASIS_CA || null;

/* This header is the whole mechanism. Without no-store a CDN caches the
   response and the swap silently does nothing. Verify it with curl -sI. */
const NO_STORE = {
  'content-type': 'application/json',
  'cache-control': 'no-store, no-cache, must-revalidate, max-age=0',
  'cdn-cache-control': 'no-store',
  'vercel-cdn-cache-control': 'no-store'
};

const isAddr = (a) => typeof a === 'string' && /^0x[0-9a-fA-F]{40}$/.test(a);

async function redis(cmd) {
  if (!URL_ || !TOKEN) return null;
  const r = await fetch(URL_, {
    method: 'POST',
    headers: { authorization: `Bearer ${TOKEN}`, 'content-type': 'application/json' },
    body: JSON.stringify(cmd),
    cache: 'no-store'
  });
  if (!r.ok) return null;
  return (await r.json())?.result ?? null;
}

export async function GET() {
  let address = null;
  try { address = await redis(['GET', KEY]); } catch {}
  if (!isAddr(address)) address = isAddr(FALLBACK) ? FALLBACK : null;
  return new Response(JSON.stringify({ address, ts: Date.now() }), { headers: NO_STORE });
}

export async function POST(req) {
  if (!ADMIN_KEY || req.headers.get('x-admin-key') !== ADMIN_KEY) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: NO_STORE });
  }
  let body;
  try { body = await req.json(); }
  catch { return new Response(JSON.stringify({ error: 'bad json' }), { status: 400, headers: NO_STORE }); }

  const { address } = body || {};
  if (address === null) {
    await redis(['DEL', KEY]);
    return new Response(JSON.stringify({ cleared: true }), { headers: NO_STORE });
  }
  if (!isAddr(address)) {
    return new Response(JSON.stringify({ error: 'not an address' }), { status: 400, headers: NO_STORE });
  }
  await redis(['SET', KEY, address]);
  return new Response(JSON.stringify({ address, ok: true }), { headers: NO_STORE });
}
EOF

# ---------------------------------------------------------------- token section
cat > components/Token.js <<'EOF'
"use client";
import { useEffect, useState } from "react";
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
        if (alive) setAddress(isAddr(j?.address) ? j.address : null);
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
          <div className={styles.head}>
            <div className="eyebrow"><i /><span>Token</span></div>
            <h2 className={styles.h2}>BASIS</h2>
            <p className={styles.lead}>
              Fair launch on Robinhood Chain. One billion supply. The contract address
              appears here the moment it exists, and this page updates itself without a
              reload.
            </p>
          </div>

          <div className={styles.panel}>
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
EOF

cat > components/Token.module.css <<'EOF'
.block{
  padding-top:clamp(88px,13vw,170px);
  padding-bottom:clamp(60px,8vw,110px);
  transition:filter 620ms cubic-bezier(.16,1,.3,1),opacity 620ms cubic-bezier(.16,1,.3,1);
}

.head{text-align:center;margin-bottom:clamp(36px,5vw,58px)}
.head :global(.eyebrow){justify-content:center}

.h2{
  margin:0 auto;font-size:34px;font-weight:400;line-height:1;letter-spacing:-1px;
}
@media(min-width:640px){.h2{font-size:48px}}
@media(min-width:1024px){.h2{font-size:64px}}

.lead{
  margin:20px auto 0;font-size:16px;line-height:1.85;color:var(--muted);
  max-width:54ch;text-wrap:balance;
}

.panel{
  border:1px solid var(--line);border-radius:18px;overflow:hidden;
  background:rgba(14,10,10,.6);backdrop-filter:blur(16px);
  box-shadow:0 40px 90px -40px rgba(0,0,0,.95);
  max-width:820px;margin:0 auto;
}

.facts{display:grid;grid-template-columns:1fr 1fr}
@media(min-width:720px){.facts{grid-template-columns:repeat(4,1fr)}}
.fact{
  padding:22px 20px;display:flex;flex-direction:column;gap:11px;
  border-right:1px solid var(--line);border-bottom:1px solid var(--line);
}
.fact:nth-child(2n){border-right:0}
@media(min-width:720px){
  .fact{border-bottom:0}
  .fact:nth-child(2n){border-right:1px solid var(--line)}
  .fact:last-child{border-right:0}
}
.k{font-family:var(--mono);font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:var(--faint)}
.v{font-size:15px;font-weight:450;font-variant-numeric:tabular-nums}

.ca{padding:24px 20px 20px;border-top:1px solid var(--line)}
.caHead{display:flex;align-items:center;gap:9px;margin-bottom:14px}
.status{
  width:7px;height:7px;border-radius:50%;
  background:var(--faint);flex:none;
}
.live{background:var(--accent);box-shadow:0 0 0 4px rgba(217,58,43,.16)}
.caLabel{font-family:var(--mono);font-size:10.5px;letter-spacing:.12em;text-transform:uppercase;color:var(--faint)}

.caRow{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.addr{
  flex:1 1 320px;min-width:0;
  font-family:var(--mono);font-size:13px;letter-spacing:.02em;color:var(--ink);
  border:1px solid var(--line);border-radius:10px;
  padding:13px 15px;background:rgba(255,255,255,.015);
  overflow:hidden;text-overflow:ellipsis;white-space:nowrap;
}
.pending{color:var(--faint)}
.note{font-family:var(--mono);font-size:10.5px;letter-spacing:.06em;color:var(--faint)}

.btn{
  height:44px;padding-inline:17px;border-radius:10px;
  border:1px solid var(--line);background:rgba(255,255,255,.015);
  color:var(--muted);font-family:var(--sans);font-size:13.5px;font-weight:450;
  letter-spacing:-0.4px;cursor:pointer;display:inline-flex;align-items:center;
  transition:color 160ms,background 160ms,border-color 160ms;
}
.btn:hover{color:var(--ink);background:rgba(255,255,255,.05)}

.warn{
  margin:0;padding:14px 20px;border-top:1px solid var(--line);
  font-size:12.5px;line-height:1.7;color:var(--faint);
}

:global(body.warp) .block{filter:blur(7px);opacity:.42}
@media(prefers-reduced-motion:reduce){
  .block,:global(body.warp) .block{filter:none;opacity:1;transition:none}
}
EOF

# ---------------------------------------------------------------- operator CLI
cat > scripts/registry.mjs <<'EOF'
#!/usr/bin/env node
/* Operator CLI for the live contract address.
   Reads credentials from .env.swap (gitignored). */
import { readFileSync } from "node:fs";

const env = {};
try {
  for (const line of readFileSync(".env.swap", "utf8").split("\n")) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m) env[m[1]] = m[2].replace(/^['"]|['"]$/g, "");
  }
} catch {
  console.error("No .env.swap found. Copy .env.swap.example and fill it in.");
  process.exit(1);
}

const URL_ = env.UPSTASH_REDIS_REST_URL;
const TOKEN = env.UPSTASH_REDIS_REST_TOKEN;
const KEY = "basis:ca";

if (!URL_ || !TOKEN) {
  console.error("UPSTASH_REDIS_REST_URL / _TOKEN missing from .env.swap");
  process.exit(1);
}

const isAddr = (a) => /^0x[0-9a-fA-F]{40}$/.test(a || "");

async function redis(cmd) {
  const r = await fetch(URL_, {
    method: "POST",
    headers: { authorization: `Bearer ${TOKEN}`, "content-type": "application/json" },
    body: JSON.stringify(cmd)
  });
  if (!r.ok) throw new Error(`redis ${r.status} ${await r.text()}`);
  return (await r.json())?.result ?? null;
}

const [cmd, a1] = process.argv.slice(2);

if (cmd === "show") {
  console.log((await redis(["GET", KEY])) ?? "(not set)");
} else if (cmd === "swap") {
  if (!isAddr(a1)) { console.error("usage: registry.mjs swap 0xADDRESS"); process.exit(1); }
  await redis(["SET", KEY, a1]);
  console.log(`set ${a1}`);
  console.log("now run: node scripts/verify-tokens.mjs BASIS");
} else if (cmd === "clear") {
  await redis(["DEL", KEY]);
  console.log("cleared");
} else {
  console.log("usage: registry.mjs show | swap 0xADDRESS | clear");
}
EOF

# ---------------------------------------------------------------- verifier
cat > scripts/verify-tokens.mjs <<'EOF'
#!/usr/bin/env node
/* Reads the live address, then asks the chain what it actually is.
   Exits non-zero on mismatch so it can gate an announcement. */
import { readFileSync } from "node:fs";

const env = {};
try {
  for (const line of readFileSync(".env.swap", "utf8").split("\n")) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m) env[m[1]] = m[2].replace(/^['"]|['"]$/g, "");
  }
} catch {}

const URL_ = env.UPSTASH_REDIS_REST_URL;
const TOKEN = env.UPSTASH_REDIS_REST_TOKEN;
const RPC = env.BASIS_RPC || "https://rpc.mainnet.chain.robinhood.com";
const KEY = "basis:ca";
const expected = process.argv[2] || null;

async function redis(cmd) {
  const r = await fetch(URL_, {
    method: "POST",
    headers: { authorization: `Bearer ${TOKEN}`, "content-type": "application/json" },
    body: JSON.stringify(cmd)
  });
  if (!r.ok) throw new Error(`redis ${r.status}`);
  return (await r.json())?.result ?? null;
}

async function call(to, data) {
  const r = await fetch(RPC, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "eth_call", params: [{ to, data }, "latest"] })
  });
  const j = await r.json();
  if (j.error) throw new Error(j.error.message);
  return j.result;
}

/* decode a solidity string return (offset, length, bytes) */
function decodeString(hex) {
  if (!hex || hex === "0x") return null;
  const b = hex.slice(2);
  if (b.length < 128) return null;
  const len = parseInt(b.slice(64, 128), 16);
  const body = b.slice(128, 128 + len * 2);
  return Buffer.from(body, "hex").toString("utf8");
}

const address = await redis(["GET", KEY]);
if (!address) { console.error("FAIL: no address set"); process.exit(1); }
console.log(`address:  ${address}`);

let symbol = null, decimals = null;
try { symbol = decodeString(await call(address, "0x95d89b41")); } catch (e) { console.error(`symbol() failed: ${e.message}`); }
try { decimals = parseInt(await call(address, "0x313ce567"), 16); } catch {}

console.log(`symbol:   ${symbol ?? "(unreadable)"}`);
console.log(`decimals: ${Number.isFinite(decimals) ? decimals : "(unreadable)"}`);

if (!symbol) { console.error("FAIL: symbol() unreadable. Do not announce."); process.exit(1); }
if (expected && symbol.toUpperCase() !== expected.toUpperCase()) {
  console.error(`FAIL: on-chain symbol is ${symbol}, expected ${expected}. Do not announce.`);
  process.exit(1);
}
console.log("OK");
EOF

cat > .env.swap.example <<'EOF'
# copy to .env.swap and fill in. .env.swap is gitignored.
UPSTASH_REDIS_REST_URL=https://your-db.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-rest-token
BASIS_RPC=https://rpc.mainnet.chain.robinhood.com
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
    </>
  );
}
EOF

echo "Done."
