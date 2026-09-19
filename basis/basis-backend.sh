#!/usr/bin/env bash
# Basis - minimal backend (refresh pipeline + read API)
# Run from the basis/ folder: bash basis-backend.sh
set -euo pipefail

if [ ! -f "package.json" ]; then
  echo "Run this from inside the basis/ folder."
  exit 1
fi

echo "Adding backend ..."

# ---------------------------------------------------------------- src/async.js
cat > src/async.js <<'EOF'
// Small async helpers, kept pure enough to unit test.

// Runs tasks with a concurrency cap. Results keep input order.
// The RPC rate limits at low concurrency, so this is not optional.
export async function mapLimit(items, limit, fn) {
  const results = new Array(items.length);
  let cursor = 0;

  async function worker() {
    while (true) {
      const i = cursor++;
      if (i >= items.length) return;
      results[i] = await fn(items[i], i);
    }
  }

  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

export function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// Retries with linear backoff. Throws the last error if every attempt fails.
export async function retry(fn, { attempts = 3, delayMs = 250 } = {}) {
  let last;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      last = e;
      if (i < attempts - 1) await sleep(delayMs * (i + 1));
    }
  }
  throw last;
}
EOF

# ---------------------------------------------------------------- src/state.js
cat > src/state.js <<'EOF'
// Shape of what the API serves, and the lookups over it.

import { parseDecimal18, isUnit, errorBps } from "./multiplier.js";

export function buildAsset(record, chainMultiplier) {
  const registryScaled = parseDecimal18(record.currentMultiplier);
  const chainScaled = chainMultiplier === null ? null : BigInt(chainMultiplier);

  const known = chainScaled !== null;
  const agree = known && registryScaled !== null ? chainScaled === registryScaled : null;

  return {
    ticker: record.ticker,
    name: record.name,
    address: record.address,
    status: record.status,
    multiplier: {
      chain: chainScaled === null ? null : chainScaled.toString(),
      registry: record.currentMultiplier,
      sourcesAgree: agree,
      isUnit: known ? isUnit(chainScaled) : null,
      errorBps: known ? errorBps(chainScaled) : null
    },
    pendingMultiplier: record.pendingMultiplier,
    naivePricingSafe: known ? isUnit(chainScaled) : null,
    source: {
      registry: "issuer read API",
      chain: "contract uiMultiplier()"
    }
  };
}

export function summarise(assets, blockNumber) {
  const affected = assets.filter((a) => a.naivePricingSafe === false);
  const unknown = assets.filter((a) => a.naivePricingSafe === null);
  const disagree = assets.filter((a) => a.multiplier.sourcesAgree === false);

  return {
    total: assets.length,
    affected: affected.length,
    unknown: unknown.length,
    sourceDisagreements: disagree.length,
    worstBps: affected.reduce((m, a) => Math.max(m, a.multiplier.errorBps ?? 0), 0),
    affectedTickers: affected
      .slice()
      .sort((a, b) => (b.multiplier.errorBps ?? 0) - (a.multiplier.errorBps ?? 0))
      .map((a) => a.ticker),
    verifiedAtBlock: blockNumber ?? null,
    verifiedAt: new Date().toISOString()
  };
}

export function findAsset(assets, ticker) {
  if (!ticker) return null;
  const want = String(ticker).toUpperCase();
  return assets.find((a) => a.ticker?.toUpperCase() === want) ?? null;
}
EOF

# ---------------------------------------------------------------- src/refresh.js
cat > src/refresh.js <<'EOF'
import { writeFileSync } from "node:fs";
import { makeClient } from "./chain.js";
import { fetchAssets, toRecords } from "./registry.js";
import { OPTIONAL_ABI } from "./abi.js";
import { mapLimit, retry } from "./async.js";
import { buildAsset, summarise } from "./state.js";

export const STATE_PATH = "out/state.json";

// Concurrency is deliberately low. The public RPC rejects bursts.
const CONCURRENCY = Number(process.env.BASIS_CONCURRENCY || 4);

export async function refresh({ write = true } = {}) {
  const client = makeClient();
  const records = toRecords(await fetchAssets());

  const multipliers = await mapLimit(records, CONCURRENCY, async (r) => {
    try {
      const v = await retry(() =>
        client.readContract({ address: r.address, abi: OPTIONAL_ABI, functionName: "uiMultiplier" })
      );
      return v.toString();
    } catch {
      return null; // unread, never defaulted to 1
    }
  });

  const assets = records.map((r, i) => buildAsset(r, multipliers[i]));

  let block = null;
  try {
    block = (await client.getBlockNumber()).toString();
  } catch {
    block = null;
  }

  const state = { summary: summarise(assets, block), assets };
  if (write) writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
  return state;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const s = await refresh();
  console.log(`\nAssets: ${s.summary.total}`);
  console.log(`Naive pricing unsafe: ${s.summary.affected}`);
  console.log(`Multiplier unreadable: ${s.summary.unknown}`);
  console.log(`Chain and registry disagree: ${s.summary.sourceDisagreements}`);
  console.log(`Largest error: ${s.summary.worstBps} bps`);
  console.log(`\nWrote ${STATE_PATH}`);
}
EOF

# ---------------------------------------------------------------- src/server.js
cat > src/server.js <<'EOF'
import { createServer } from "node:http";
import { readFileSync, existsSync } from "node:fs";
import { findAsset } from "./state.js";
import { refresh, STATE_PATH } from "./refresh.js";

const PORT = Number(process.env.PORT || 8787);

let state = null;
let loadedAt = null;

function load() {
  if (!existsSync(STATE_PATH)) return null;
  state = JSON.parse(readFileSync(STATE_PATH, "utf8"));
  loadedAt = new Date().toISOString();
  return state;
}

function send(res, code, body) {
  const payload = JSON.stringify(body, null, 2);
  res.writeHead(code, {
    "content-type": "application/json",
    "access-control-allow-origin": "*"
  });
  res.end(payload);
}

export function route(pathname, current) {
  if (pathname === "/health") {
    return [200, { ok: true, hasState: current !== null, loadedAt }];
  }
  if (current === null) {
    return [503, { error: "no state yet. run npm run refresh" }];
  }
  if (pathname === "/summary") return [200, current.summary];
  if (pathname === "/assets") return [200, { assets: current.assets }];
  if (pathname === "/affected") {
    return [200, { assets: current.assets.filter((a) => a.naivePricingSafe === false) }];
  }
  const m = pathname.match(/^\/assets\/([A-Za-z0-9._-]+)$/);
  if (m) {
    const asset = findAsset(current.assets, m[1]);
    return asset ? [200, asset] : [404, { error: "unknown ticker" }];
  }
  return [404, { error: "not found" }];
}

load();

function start() {
  createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    const [code, body] = route(pathname, state);
    send(res, code, body);
  }).listen(PORT, () => {
    console.log(`Basis API on http://localhost:${PORT}`);
    console.log(`  /health  /summary  /assets  /assets/:ticker  /affected`);
    if (!state) console.log(`\nNo ${STATE_PATH} yet. Run: npm run refresh`);
  });

  // Optional periodic refresh. Off unless BASIS_REFRESH_MINUTES is set.
  const mins = Number(process.env.BASIS_REFRESH_MINUTES || 0);
  if (mins > 0) {
    setInterval(async () => {
      try {
        await refresh();
        load();
        console.log(`refreshed at ${loadedAt}`);
      } catch (e) {
        console.error(`refresh failed: ${e.message}`);
      }
    }, mins * 60_000);
  }
}

// Only listen when run directly. Importing this module for tests must not
// start a server or the test process never exits.
if (import.meta.url === `file://${process.argv[1]}`) start();
EOF

# ---------------------------------------------------------------- tests
cat > test/backend.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { mapLimit, retry } from "../src/async.js";
import { buildAsset, summarise, findAsset } from "../src/state.js";
import { route } from "../src/server.js";

const ONE = (10n ** 18n).toString();
const OFF = "1005101770003214918";

function record(ticker, mult = "1.000000000000000000", extra = {}) {
  return {
    ticker,
    name: `${ticker} Token`,
    address: `0x${ticker}`,
    status: "ASSET_STATUS_ACTIVE",
    currentMultiplier: mult,
    pendingMultiplier: null,
    ...extra
  };
}

test("mapLimit preserves input order regardless of finish order", async () => {
  const out = await mapLimit([30, 10, 20], 2, async (ms) => {
    await new Promise((r) => setTimeout(r, ms));
    return ms;
  });
  assert.deepEqual(out, [30, 10, 20]);
});

test("mapLimit never exceeds its concurrency cap", async () => {
  let active = 0;
  let peak = 0;
  await mapLimit([1, 2, 3, 4, 5, 6], 2, async () => {
    active++;
    peak = Math.max(peak, active);
    await new Promise((r) => setTimeout(r, 5));
    active--;
  });
  assert.ok(peak <= 2, `peak was ${peak}`);
});

test("retry succeeds after transient failures", async () => {
  let n = 0;
  const v = await retry(
    async () => {
      if (++n < 3) throw new Error("boom");
      return "ok";
    },
    { attempts: 3, delayMs: 1 }
  );
  assert.equal(v, "ok");
  assert.equal(n, 3);
});

test("retry rethrows after exhausting attempts", async () => {
  await assert.rejects(
    retry(async () => { throw new Error("always"); }, { attempts: 2, delayMs: 1 }),
    /always/
  );
});

test("a unit multiplier marks naive pricing safe", () => {
  const a = buildAsset(record("AAA"), ONE);
  assert.equal(a.naivePricingSafe, true);
  assert.equal(a.multiplier.errorBps, 0);
});

test("a non unit multiplier marks naive pricing unsafe and reports bps", () => {
  const a = buildAsset(record("CRM", "1.005101770003214918"), OFF);
  assert.equal(a.naivePricingSafe, false);
  assert.equal(a.multiplier.errorBps, 51.01);
  assert.equal(a.multiplier.sourcesAgree, true);
});

test("an unread multiplier is null, never assumed safe", () => {
  const a = buildAsset(record("XXX"), null);
  assert.equal(a.naivePricingSafe, null);
  assert.equal(a.multiplier.errorBps, null);
});

test("chain and registry disagreement is surfaced", () => {
  const a = buildAsset(record("BBB", "1.005101770003214918"), ONE);
  assert.equal(a.multiplier.sourcesAgree, false);
});

test("summary counts affected, unknown and disagreements separately", () => {
  const assets = [
    buildAsset(record("A"), ONE),
    buildAsset(record("B", "1.005101770003214918"), OFF),
    buildAsset(record("C"), null),
    buildAsset(record("D", "1.005101770003214918"), ONE)
  ];
  const s = summarise(assets, "123");
  assert.equal(s.total, 4);
  assert.equal(s.affected, 1);
  assert.equal(s.unknown, 1);
  assert.equal(s.sourceDisagreements, 1);
  assert.equal(s.verifiedAtBlock, "123");
});

test("ticker lookup is case insensitive and misses return null", () => {
  const assets = [buildAsset(record("CRM"), ONE)];
  assert.equal(findAsset(assets, "crm").ticker, "CRM");
  assert.equal(findAsset(assets, "nope"), null);
  assert.equal(findAsset(assets, null), null);
});

test("health works before any state is loaded", () => {
  const [code, body] = route("/health", null);
  assert.equal(code, 200);
  assert.equal(body.hasState, false);
});

test("data routes return 503 rather than empty data when unloaded", () => {
  assert.equal(route("/summary", null)[0], 503);
  assert.equal(route("/assets", null)[0], 503);
});

test("routes serve summary, assets, affected and single asset", () => {
  const state = {
    summary: { total: 2 },
    assets: [buildAsset(record("A"), ONE), buildAsset(record("B", "1.005101770003214918"), OFF)]
  };
  assert.equal(route("/summary", state)[1].total, 2);
  assert.equal(route("/assets", state)[1].assets.length, 2);
  assert.equal(route("/affected", state)[1].assets.length, 1);
  assert.equal(route("/assets/b", state)[1].ticker, "B");
  assert.equal(route("/assets/zz", state)[0], 404);
  assert.equal(route("/nonsense", state)[0], 404);
});
EOF

node -e '
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
p.scripts.refresh="node src/refresh.js";
p.scripts.serve="node src/server.js";
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n");
console.log("package.json: added npm run refresh and npm run serve");
'

echo "Done. Run: npm test && npm run refresh && npm run serve"
