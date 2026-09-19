#!/usr/bin/env bash
# Basis - multiplier check (the one surviving feature) + docs correction
# Run from the basis/ folder: bash basis-check.sh
set -euo pipefail

if [ ! -f "package.json" ]; then
  echo "Run this from inside the basis/ folder."
  exit 1
fi

echo "Adding multiplier check ..."

# ---------------------------------------------------------------- src/multiplier.js
cat > src/multiplier.js <<'EOF'
// The one signal that varies per asset on Robinhood Chain: the corporate-action
// multiplier. Everything else (status, pause state, transfer behaviour,
// tradability flags) came back identical across all assets when measured.

const ONE = 10n ** 18n;

// "1.000412952576205964" -> 1000412952576205964n
export function parseDecimal18(value) {
  if (typeof value !== "string" || !/^\d+(\.\d+)?$/.test(value)) return null;
  const [whole, frac = ""] = value.split(".");
  return BigInt(whole) * ONE + BigInt((frac + "0".repeat(18)).slice(0, 18));
}

export function isUnit(scaled) {
  return scaled === ONE;
}

// Error an integrator incurs by ignoring the multiplier, in basis points.
export function errorBps(scaled) {
  if (scaled === null) return null;
  const diff = scaled > ONE ? scaled - ONE : ONE - scaled;
  return Number((diff * 10000n * 100n) / ONE) / 100;
}

// Chain and registry should agree. If they do not, one of them is stale and
// that is itself worth reporting.
export function compare(chainScaled, registryDecimal) {
  const registryScaled = parseDecimal18(registryDecimal);
  if (chainScaled === null || registryScaled === null) {
    return { agree: null, reason: "missing value" };
  }
  return { agree: chainScaled === registryScaled, chainScaled, registryScaled };
}

export function report(rows) {
  const affected = rows.filter((r) => r.scaled !== null && !isUnit(r.scaled));
  const disagreements = rows.filter((r) => r.agree === false);
  return {
    total: rows.length,
    affected: affected.length,
    disagreements: disagreements.length,
    worstBps: affected.reduce((m, r) => Math.max(m, errorBps(r.scaled)), 0),
    rows: affected
      .map((r) => ({ ticker: r.ticker, bps: errorBps(r.scaled) }))
      .sort((a, b) => b.bps - a.bps)
  };
}
EOF

# ---------------------------------------------------------------- src/check.js
cat > src/check.js <<'EOF'
import { readFileSync, writeFileSync } from "node:fs";
import { compare, report } from "./multiplier.js";

const registry = JSON.parse(readFileSync("out/registry.json", "utf8"));
const profiles = JSON.parse(readFileSync("out/profiles.json", "utf8"));

const byTicker = new Map(registry.map((r) => [r.ticker, r]));

const rows = profiles.map((p) => {
  const reg = byTicker.get(p.ticker);
  const scaled = p.uiMultiplier ? BigInt(p.uiMultiplier) : null;
  const cmp = reg ? compare(scaled, reg.currentMultiplier) : { agree: null };
  return { ticker: p.ticker, scaled, agree: cmp.agree };
});

const out = report(rows);

console.log(`\nAssets checked: ${out.total}`);
console.log(`Multiplier not 1 (naive pricing is wrong): ${out.affected}`);
console.log(`Chain and registry disagree: ${out.disagreements}`);
console.log(`Largest error: ${out.worstBps} bps\n`);

for (const r of out.rows.slice(0, 15)) {
  console.log(`${r.ticker.padEnd(8)} ${String(r.bps).padStart(8)} bps`);
}

writeFileSync("out/multiplier-report.json", JSON.stringify(out, null, 2));
console.log(`\nWrote out/multiplier-report.json`);
EOF

# ---------------------------------------------------------------- tests
cat > test/multiplier.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { parseDecimal18, isUnit, errorBps, compare, report } from "../src/multiplier.js";

const ONE = 10n ** 18n;

test("parses an 18dp decimal string exactly", () => {
  assert.equal(parseDecimal18("1.000412952576205964"), 1000412952576205964n);
});

test("parses a whole number", () => {
  assert.equal(parseDecimal18("1"), ONE);
});

test("rejects junk rather than guessing", () => {
  assert.equal(parseDecimal18(""), null);
  assert.equal(parseDecimal18("abc"), null);
  assert.equal(parseDecimal18(null), null);
});

test("unit multiplier is recognised", () => {
  assert.equal(isUnit(ONE), true);
  assert.equal(isUnit(1000412952576205964n), false);
});

test("error is reported in basis points", () => {
  assert.equal(errorBps(ONE), 0);
  assert.equal(errorBps(1005101770003214918n), 51.01);
});

test("chain and registry agreement is detected", () => {
  const r = compare(1000412952576205964n, "1.000412952576205964");
  assert.equal(r.agree, true);
});

test("a stale side is flagged, not smoothed over", () => {
  assert.equal(compare(ONE, "1.000412952576205964").agree, false);
});

test("missing values give null, never a false agreement", () => {
  assert.equal(compare(null, "1").agree, null);
  assert.equal(compare(ONE, "").agree, null);
});

test("report counts only affected assets and sorts by size", () => {
  const rows = [
    { ticker: "A", scaled: ONE, agree: true },
    { ticker: "B", scaled: 1005101770003214918n, agree: true },
    { ticker: "C", scaled: 1000412952576205964n, agree: false }
  ];
  const out = report(rows);
  assert.equal(out.total, 3);
  assert.equal(out.affected, 2);
  assert.equal(out.disagreements, 1);
  assert.equal(out.rows[0].ticker, "B");
});
EOF

node -e '
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
p.scripts.check="node src/check.js";
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n");
console.log("package.json: added npm run check");
'

# ---------------------------------------------------------------- docs correction
if [ -d "../docs" ]; then
cat > ../docs/findings.md <<'EOF'
# Findings

What we measured on Robinhood Chain mainnet, and what it killed.

## Method

Read all assets from the onchain registry via the issuer's read API, then read
contract state and simulate a transfer for each one.

## Results

194 assets on chain 4663.

| Signal | Result | Verdict |
| --- | --- | --- |
| Legal rights | Identical for every asset. One issuer, one wrapper. | No per asset signal |
| Asset status | Active for every asset | No per asset signal |
| Pause state | False for every asset | No per asset signal |
| Transfer probe | Contract level pass for every asset | No per asset signal |
| Tradability flags | Empty strings and nulls for every asset | Not populated in production |
| Trading halt flag | Prices endpoint returned an empty body | Unavailable |
| Corporate action multiplier | Not 1 on 28 of 194 assets | The only signal that varies |

## What this means

The original premise was that tokenized assets differ from one another in their
rights and restrictions, and that mapping those differences per asset would be
the product. On this chain, at this time, they do not differ. The set is uniform
on every dimension except one.

We are documenting this rather than quietly narrowing the pitch, because the
measurement is the useful output even where the result is negative.

## What survives

The corporate action multiplier. 28 assets carry a multiplier above 1, meaning
an integrator who reads a balance and multiplies by the raw price from the REST
endpoint gets a wrong number. The issuer's own documentation notes that the REST
price is not multiplier adjusted while the onchain price feed is.

The error is small, roughly 0.01 to 0.5 percent depending on the asset. It is
not a catastrophic mispricing. It is a quiet, systematic one.

That is what Basis checks.
EOF
echo "docs/findings.md written"
fi

echo "Done. Run: npm test && npm run check"
