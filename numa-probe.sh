#!/usr/bin/env bash
# Numa MVP - transfer probe
# Drop this in your project root and run: bash numa-probe.sh
set -euo pipefail

ROOT="numa"
echo "Writing $ROOT/ ..."

mkdir -p "$ROOT/src" "$ROOT/test" "$ROOT/out"

# ---------------------------------------------------------------- package.json
cat > "$ROOT/package.json" <<'EOF'
{
  "name": "numa-probe",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "probe": "node src/cli.js",
    "test": "node --test test/*.test.js"
  },
  "dependencies": {
    "viem": "^2.21.0"
  }
}
EOF

# ---------------------------------------------------------------- assets.json
cat > "$ROOT/assets.json" <<'EOF'
[
  { "ticker": "TSLA", "address": "0x322F0929c4625eD5bAd873c95208D54E1c003b2d" }
]
EOF

# ---------------------------------------------------------------- src/chain.js
cat > "$ROOT/src/chain.js" <<'EOF'
import { createPublicClient, http, defineChain } from "viem";

export const robinhoodChain = defineChain({
  id: 4663,
  name: "Robinhood Chain",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: [process.env.NUMA_RPC || "https://rpc.mainnet.chain.robinhood.com"] }
  },
  blockExplorers: {
    default: { name: "Blockscout", url: "https://robinhoodchain.blockscout.com" }
  }
});

export function makeClient() {
  return createPublicClient({
    chain: robinhoodChain,
    transport: http()
  });
}
EOF

# ---------------------------------------------------------------- src/abi.js
cat > "$ROOT/src/abi.js" <<'EOF'
// Minimal ABI fragments. Every optional read is attempted and allowed to fail,
// because the exact Stock.sol surface is not assumed here.

export const ERC20_ABI = [
  { type: "function", name: "name", stateMutability: "view", inputs: [], outputs: [{ type: "string" }] },
  { type: "function", name: "symbol", stateMutability: "view", inputs: [], outputs: [{ type: "string" }] },
  { type: "function", name: "decimals", stateMutability: "view", inputs: [], outputs: [{ type: "uint8" }] },
  { type: "function", name: "totalSupply", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
  {
    type: "function", name: "balanceOf", stateMutability: "view",
    inputs: [{ name: "account", type: "address" }], outputs: [{ type: "uint256" }]
  },
  {
    type: "function", name: "transfer", stateMutability: "nonpayable",
    inputs: [{ name: "to", type: "address" }, { name: "amount", type: "uint256" }],
    outputs: [{ type: "bool" }]
  }
];

export const OPTIONAL_ABI = [
  { type: "function", name: "paused", stateMutability: "view", inputs: [], outputs: [{ type: "bool" }] },
  { type: "function", name: "uiMultiplier", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] }
];
EOF

# ---------------------------------------------------------------- src/classify.js
cat > "$ROOT/src/classify.js" <<'EOF'
// Pure function: turns a raw probe outcome into a Numa status.
// Kept free of network code so it is unit testable.

const POLICY_HINTS = [
  "compliance", "restricted", "not allowed", "unauthorized", "unauthorised",
  "blocklist", "blacklist", "frozen", "freeze", "kyc", "whitelist",
  "sanction", "jurisdiction", "eligib", "forbidden", "denied"
];

const PAUSE_HINTS = ["pause", "halted", "suspended"];

const BALANCE_HINTS = ["insufficient balance", "exceeds balance", "insufficient funds", "transfer amount exceeds"];

export function classifyTransfer(outcome) {
  if (!outcome) return { status: "error", detail: "no outcome" };

  if (outcome.ok) {
    return {
      status: "allowed_at_contract",
      detail: "Contract-level simulation succeeded. Sequencer-level screening is NOT covered by this result."
    };
  }

  const raw = String(outcome.reason || outcome.error || "").toLowerCase();

  if (raw.includes("no contract") || raw.includes("returned no data")) {
    return { status: "no_contract", detail: "No contract code at this address on this chain." };
  }
  if (BALANCE_HINTS.some((h) => raw.includes(h))) {
    return { status: "inconclusive_balance", detail: "Reverted on balance, not on policy. Re-probe with amount 0." };
  }
  if (PAUSE_HINTS.some((h) => raw.includes(h))) {
    return { status: "blocked_paused", detail: outcome.reason || "Paused." };
  }
  if (POLICY_HINTS.some((h) => raw.includes(h))) {
    return { status: "blocked_policy", detail: outcome.reason || "Blocked by a transfer policy." };
  }
  return { status: "blocked_unknown", detail: outcome.reason || outcome.error || "Reverted without a readable reason." };
}

export function summarise(profile) {
  if (profile.paused === true) return "PAUSED";
  switch (profile.transfer.status) {
    case "allowed_at_contract": return "MOVABLE (contract level)";
    case "blocked_paused": return "PAUSED";
    case "blocked_policy": return "BLOCKED (policy)";
    case "inconclusive_balance": return "INCONCLUSIVE";
    case "no_contract": return "NOT FOUND";
    default: return "BLOCKED (unknown)";
  }
}
EOF

# ---------------------------------------------------------------- src/probe.js
cat > "$ROOT/src/probe.js" <<'EOF'
import { ERC20_ABI, OPTIONAL_ABI } from "./abi.js";
import { classifyTransfer } from "./classify.js";

async function tryRead(client, address, abi, functionName) {
  try {
    const value = await client.readContract({ address, abi, functionName });
    return { supported: true, value };
  } catch (e) {
    return { supported: false, value: null, error: shortError(e) };
  }
}

function shortError(e) {
  const m = e?.shortMessage || e?.details || e?.message || String(e);
  return m.split("\n")[0].slice(0, 300);
}

// Probes with amount = 0 by default. A zero-value transfer isolates POLICY from
// BALANCE: a holder-less prober address would otherwise always revert on funds.
export async function probeTransfer(client, address, { from, to, amount = 0n }) {
  try {
    await client.simulateContract({
      address,
      abi: ERC20_ABI,
      functionName: "transfer",
      args: [to, amount],
      account: from
    });
    return classifyTransfer({ ok: true });
  } catch (e) {
    return classifyTransfer({ ok: false, reason: shortError(e) });
  }
}

export async function profileAsset(client, asset, { from, to }) {
  const address = asset.address;

  const [name, symbol, decimals, supply, paused, multiplier, balance] = await Promise.all([
    tryRead(client, address, ERC20_ABI, "name"),
    tryRead(client, address, ERC20_ABI, "symbol"),
    tryRead(client, address, ERC20_ABI, "decimals"),
    tryRead(client, address, ERC20_ABI, "totalSupply"),
    tryRead(client, address, OPTIONAL_ABI, "paused"),
    tryRead(client, address, OPTIONAL_ABI, "uiMultiplier"),
    client
      .readContract({ address, abi: ERC20_ABI, functionName: "balanceOf", args: [from] })
      .then((v) => ({ supported: true, value: v }))
      .catch((e) => ({ supported: false, value: null, error: shortError(e) }))
  ]);

  const zeroProbe = await probeTransfer(client, address, { from, to, amount: 0n });

  // If the prober holds a balance, also probe a real 1-unit move. A zero-amount
  // pass plus a one-unit fail is the signature of an amount- or state-gated rule.
  let unitProbe = null;
  if (balance.supported && balance.value > 0n) {
    unitProbe = await probeTransfer(client, address, { from, to, amount: 1n });
  }

  const block = await client.getBlockNumber();

  return {
    ticker: asset.ticker ?? symbol.value ?? null,
    address,
    name: name.value,
    symbol: symbol.value,
    decimals: decimals.value,
    totalSupply: supply.value?.toString() ?? null,
    paused: paused.supported ? paused.value : null,
    pausedSupported: paused.supported,
    uiMultiplier: multiplier.supported ? multiplier.value.toString() : null,
    uiMultiplierSupported: multiplier.supported,
    proberBalance: balance.supported ? balance.value.toString() : null,
    transfer: zeroProbe,
    transferWithValue: unitProbe,
    probeMethod: "eth_call simulation",
    coverageCaveat:
      "eth_call does not pass through the sequencer compliance engine. A pass here does not guarantee a real signed transaction is sequenced.",
    verifiedAtBlock: block.toString(),
    verifiedAt: new Date().toISOString()
  };
}
EOF

# ---------------------------------------------------------------- src/cli.js
cat > "$ROOT/src/cli.js" <<'EOF'
import { readFileSync, writeFileSync } from "node:fs";
import { makeClient } from "./chain.js";
import { profileAsset } from "./probe.js";
import { summarise } from "./classify.js";

function arg(flag, fallback) {
  const i = process.argv.indexOf(flag);
  return i > -1 ? process.argv[i + 1] : fallback;
}

const ZERO_ISH = "0x000000000000000000000000000000000000dEaD";

const from = arg("--from", ZERO_ISH);
const to = arg("--to", ZERO_ISH);
const file = arg("--assets", "assets.json");

const assets = JSON.parse(readFileSync(file, "utf8"));
const client = makeClient();

console.log(`Numa probe  |  chain 4663  |  from ${from}  ->  ${to}\n`);

const results = [];
for (const asset of assets) {
  try {
    const profile = await profileAsset(client, asset, { from, to });
    results.push(profile);
    console.log(
      `${(profile.ticker ?? "?").padEnd(8)} ${summarise(profile).padEnd(26)} ${profile.transfer.detail}`
    );
  } catch (e) {
    console.log(`${(asset.ticker ?? asset.address).padEnd(8)} ERROR  ${e.shortMessage || e.message}`);
    results.push({ ticker: asset.ticker, address: asset.address, error: e.message });
  }
}

writeFileSync("out/profiles.json", JSON.stringify(results, null, 2));
console.log(`\nWrote out/profiles.json (${results.length} assets)`);
EOF

# ---------------------------------------------------------------- test
cat > "$ROOT/test/classify.test.js" <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { classifyTransfer, summarise } from "../src/classify.js";

test("success is contract-level allowed, not a full clearance", () => {
  const r = classifyTransfer({ ok: true });
  assert.equal(r.status, "allowed_at_contract");
  assert.match(r.detail, /sequencer/i);
});

test("balance reverts are inconclusive, never blocked", () => {
  const r = classifyTransfer({ ok: false, reason: "ERC20: transfer amount exceeds balance" });
  assert.equal(r.status, "inconclusive_balance");
});

test("pause reverts are separated from policy reverts", () => {
  assert.equal(classifyTransfer({ ok: false, reason: "Pausable: paused" }).status, "blocked_paused");
});

test("policy reverts are detected across common wordings", () => {
  const wordings = [
    "Compliance: transfer not allowed",
    "Recipient not whitelisted",
    "Sender is frozen",
    "KYC required",
    "Jurisdiction restricted"
  ];
  for (const w of wordings) {
    assert.equal(classifyTransfer({ ok: false, reason: w }).status, "blocked_policy", w);
  }
});

test("unreadable reverts are labelled unknown, not assumed clean", () => {
  assert.equal(classifyTransfer({ ok: false, reason: "execution reverted" }).status, "blocked_unknown");
});

test("missing contract is its own status", () => {
  assert.equal(classifyTransfer({ ok: false, reason: "returned no data" }).status, "no_contract");
});

test("paused flag overrides a passing transfer probe", () => {
  const profile = { paused: true, transfer: { status: "allowed_at_contract" } };
  assert.equal(summarise(profile), "PAUSED");
});

test("no outcome is an error, not a pass", () => {
  assert.equal(classifyTransfer(null).status, "error");
});
EOF

# ---------------------------------------------------------------- README
cat > "$ROOT/README.md" <<'EOF'
# Numa probe (MVP)

One question: can this Stock Token actually move right now?

## Run

    cd numa
    npm install
    npm test
    npm run probe -- --from 0xYourAddress --to 0xSomeOtherAddress

Add assets to `assets.json`. Canonical addresses come from the Robinhood Chain
docs contracts page, which is generated from the on-chain asset registry. A
matching ticker at a different address is not a Robinhood Stock Token.

## What the statuses mean

- `allowed_at_contract` - the contract did not reject it. Says nothing about
  sequencer-level compliance screening.
- `blocked_paused` - the asset is paused.
- `blocked_policy` - a transfer rule rejected it (whitelist, freeze, geography).
- `inconclusive_balance` - reverted on funds, not policy.
- `blocked_unknown` - reverted with no readable reason.
- `no_contract` - nothing deployed at that address.

## Known limit

`eth_call` does not run the sequencer compliance engine. A pass here is a
contract-level pass only. Closing that gap needs a real signed transaction, and
that is the next thing to test.
EOF

echo "Done. Next: cd $ROOT && npm install && npm test"
