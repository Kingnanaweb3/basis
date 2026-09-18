#!/usr/bin/env bash
# Numa - registry sync + divergence counter
# Run from the numa/ folder: bash numa-sync.sh
set -euo pipefail

if [ ! -f "package.json" ]; then
  echo "Run this from inside the numa/ folder (the one with package.json)."
  exit 1
fi

echo "Adding registry sync ..."

# ---------------------------------------------------------------- src/registry.js
cat > src/registry.js <<'EOF'
// Reads the Robinhood Stock Token asset registry.
// Source: GET https://api.robinhood.com/rhj/assets  (read-only, rate limited 60/s)

export const ASSETS_URL = "https://api.robinhood.com/rhj/assets";
export const CHAIN_ID = 4663;

export async function fetchAssets(url = ASSETS_URL) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Registry returned ${res.status} ${res.statusText}`);
  const body = await res.json();
  if (!Array.isArray(body?.assets)) throw new Error("Registry response had no assets array");
  return body.assets;
}

// Flattens one registry asset to the deployment on Robinhood Chain.
// Returns null when the asset has no deployment on this chain.
export function toRecord(asset, chainId = CHAIN_ID) {
  const deployment = (asset.deployments || []).find((d) => d.chainId === chainId);
  if (!deployment) return null;

  const caps = asset.tradingCapabilities || null;

  return {
    ticker: asset.tokenSymbol,
    name: asset.tokenName,
    address: deployment.contractAddress,
    status: asset.status ?? null,
    currentMultiplier: asset.currentMultiplier ?? null,
    pendingMultiplier: asset.pendingMultiplier || null,
    pendingMultiplierEffectiveTime: asset.pendingMultiplierEffectiveTime ?? null,
    fractionalTradability: caps ? (caps.fractionalTradability ?? null) : null,
    allDayTradability: caps ? (caps.allDayTradability ?? null) : null,
    extendedHoursFractionalTradability: caps ? (caps.extendedHoursFractionalTradability ?? null) : null,
    capabilitiesResolved: caps !== null
  };
}

export function toRecords(assets, chainId = CHAIN_ID) {
  return assets.map((a) => toRecord(a, chainId)).filter(Boolean);
}

// The viability question: how many distinct restriction profiles exist across
// the asset set? One profile for everything means there is no per asset product.
export function profileKey(record) {
  return [
    record.status,
    record.fractionalTradability,
    record.allDayTradability,
    String(record.extendedHoursFractionalTradability),
    record.currentMultiplier === "1.000000000000000000" ? "mult:1" : "mult:other",
    record.pendingMultiplier ? "pending" : "no-pending",
    record.capabilitiesResolved ? "caps" : "no-caps"
  ].join(" | ");
}

export function divergence(records) {
  const groups = new Map();
  for (const r of records) {
    const key = profileKey(r);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(r.ticker);
  }
  const buckets = [...groups.entries()]
    .map(([key, tickers]) => ({ key, count: tickers.length, sample: tickers.slice(0, 6) }))
    .sort((a, b) => b.count - a.count);

  return { total: records.length, distinctProfiles: buckets.length, buckets };
}

// Assets that differ from the single most common profile. These are the ones
// worth putting in a demo.
export function outliers(records) {
  const { buckets } = divergence(records);
  if (buckets.length <= 1) return [];
  const commonest = buckets[0].key;
  return records.filter((r) => profileKey(r) !== commonest);
}
EOF

# ---------------------------------------------------------------- src/sync.js
cat > src/sync.js <<'EOF'
import { writeFileSync } from "node:fs";
import { fetchAssets, toRecords, divergence, outliers } from "./registry.js";

const records = toRecords(await fetchAssets());

writeFileSync("out/registry.json", JSON.stringify(records, null, 2));
writeFileSync(
  "assets.json",
  JSON.stringify(records.map((r) => ({ ticker: r.ticker, address: r.address })), null, 2)
);

const d = divergence(records);

console.log(`\nAssets on chain 4663: ${d.total}`);
console.log(`Distinct restriction profiles: ${d.distinctProfiles}\n`);

for (const b of d.buckets) {
  console.log(`${String(b.count).padStart(4)}  ${b.key}`);
  console.log(`      e.g. ${b.sample.join(", ")}`);
}

const odd = outliers(records);
console.log(`\nAssets differing from the commonest profile: ${odd.length}`);
if (odd.length) {
  console.log(`Demo candidates: ${odd.slice(0, 12).map((r) => r.ticker).join(", ")}`);
}

writeFileSync("out/outliers.json", JSON.stringify(odd, null, 2));
console.log(`\nWrote assets.json, out/registry.json, out/outliers.json`);
EOF

# ---------------------------------------------------------------- test
cat > test/registry.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { toRecord, toRecords, divergence, outliers, profileKey } from "../src/registry.js";

const MULT_ONE = "1.000000000000000000";

function asset(symbol, overrides = {}) {
  return {
    tokenSymbol: symbol,
    tokenName: `${symbol} Token`,
    deployments: [{ contractAddress: `0x${symbol}`, chainId: 4663 }],
    currentMultiplier: MULT_ONE,
    pendingMultiplier: "",
    status: "ASSET_STATUS_ACTIVE",
    tradingCapabilities: {
      fractionalTradability: "tradable",
      allDayTradability: "tradable",
      extendedHoursFractionalTradability: true
    },
    ...overrides
  };
}

test("picks the deployment on the requested chain", () => {
  const r = toRecord(asset("AAPL"));
  assert.equal(r.address, "0xAAPL");
  assert.equal(r.ticker, "AAPL");
});

test("assets with no deployment on this chain are dropped, not guessed", () => {
  const a = asset("XXX", { deployments: [{ contractAddress: "0xelse", chainId: 1 }] });
  assert.equal(toRecord(a), null);
  assert.equal(toRecords([a]).length, 0);
});

test("missing tradingCapabilities is recorded as unresolved, not defaulted", () => {
  const r = toRecord(asset("NOC", { tradingCapabilities: null }));
  assert.equal(r.capabilitiesResolved, false);
  assert.equal(r.allDayTradability, null);
});

test("a null sub-field is distinct from an absent capabilities object", () => {
  const r = toRecord(
    asset("NUL", {
      tradingCapabilities: {
        fractionalTradability: "tradable",
        allDayTradability: null,
        extendedHoursFractionalTradability: null
      }
    })
  );
  assert.equal(r.capabilitiesResolved, true);
  assert.equal(r.allDayTradability, null);
});

test("identical assets collapse to one profile", () => {
  const d = divergence(toRecords([asset("A"), asset("B"), asset("C")]));
  assert.equal(d.total, 3);
  assert.equal(d.distinctProfiles, 1);
});

test("a differing tradability flag creates a second profile", () => {
  const records = toRecords([
    asset("A"),
    asset("B", {
      tradingCapabilities: {
        fractionalTradability: "tradable",
        allDayTradability: "untradable",
        extendedHoursFractionalTradability: false
      }
    })
  ]);
  assert.equal(divergence(records).distinctProfiles, 2);
});

test("a pending multiplier separates an asset from its peers", () => {
  const records = toRecords([asset("A"), asset("B", { pendingMultiplier: "4.000000000000000000" })]);
  assert.equal(divergence(records).distinctProfiles, 2);
});

test("outliers exclude the commonest profile and name the rest", () => {
  const records = toRecords([
    asset("A"),
    asset("B"),
    asset("C"),
    asset("ODD", { status: "ASSET_STATUS_INACTIVE" })
  ]);
  const odd = outliers(records);
  assert.equal(odd.length, 1);
  assert.equal(odd[0].ticker, "ODD");
});

test("a single profile set has no outliers", () => {
  assert.equal(outliers(toRecords([asset("A"), asset("B")])).length, 0);
});

test("profileKey is stable for identical inputs", () => {
  assert.equal(profileKey(toRecord(asset("A"))), profileKey(toRecord(asset("B"))));
});
EOF

# ---------------------------------------------------------------- patch scripts
node -e '
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
p.scripts = p.scripts || {};
p.scripts.sync = "node src/sync.js";
fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");
console.log("package.json: added npm run sync");
'

echo "Done. Run: npm test && npm run sync"
