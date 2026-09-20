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
