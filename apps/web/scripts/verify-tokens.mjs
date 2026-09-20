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
