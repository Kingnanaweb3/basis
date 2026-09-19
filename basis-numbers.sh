#!/usr/bin/env bash
# Basis - put the real measured numbers into the docs
# Run from the project root: bash basis-numbers.sh
set -euo pipefail

if [ ! -d "docs" ]; then
  echo "Run this from the project root, the folder containing docs/."
  exit 1
fi

cat > docs/findings.md <<'EOF'
# Findings

What we measured on Robinhood Chain mainnet, and what it killed.

## Method

Read every asset from the issuer's asset registry, keep the deployments on chain
4663, then read contract state and simulate a transfer for each one. 194 assets,
verified at block 67103382.

## Results

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

We publish this rather than quietly narrowing the pitch. The measurement is the
useful output even where the result is negative.

## The one signal

28 of 194 assets carry a multiplier above 1. The issuer's REST price endpoint
returns the raw underlying equity price, not multiplier adjusted, while the
onchain price feed is adjusted. Reading a balance and applying the raw price
without the multiplier produces a wrong value on those 28.

The errors are not evenly spread.

| Asset | Multiplier | Error |
| --- | --- | --- |
| CRWD | 4.0 | 300% |
| CCL | 1.0214 | 2.15% |
| SGOV | 1.0051 | 0.51% |
| KSS | 1.0046 | 0.46% |
| PR | 1.0044 | 0.45% |
| UNH | 1.0042 | 0.42% |
| ORCL, UPS, SPY, HPE, TSM, CRM, XOM | 1.001 to 1.0022 | 0.10% to 0.22% |
| NVDA, COST, AAPL, SOXX, MSFT | 1.0004 to 1.0008 | 0.04% to 0.08% |
| WDC, GOOGL, VRT, F, ASML, MU, DELL, AMAT, JNJ, LLY | under 1.0003 | under 0.03% |

CRWD is a 4 for 1 forward split. A holder's position read naively is valued at a
quarter of its true worth. That is not a rounding error.

The remaining 27 are dividend and corporate action accruals. Small, systematic
and silent, and they compound over time as further actions are applied.

## Honesty note

An earlier version of this page put the error range at 0.01 to 0.5 percent. That
was an estimate made before the full set was measured and it was wrong at both
ends. The table above is measured.
EOF

cat > docs/README.md <<'EOF'
# Basis

Basis checks one thing: whether a Robinhood Stock Token carries a corporate
action multiplier that makes naive pricing wrong.

Right now, 28 of 194 assets do. One of them, CRWD, is off by 300 percent.

## Why only one thing

Basis started as a rights and restrictions map for tokenized real world assets.
The assumption was that different tokenized assets carry different rights and
restrictions, and that mapping those differences would be the product.

We measured it across all 194 assets. They do not differ. Same issuer, same
legal wrapper, same status, same pause state, same transfer behaviour. The
tradability fields the issuer documents are empty in production.

One signal varies. See [Findings](findings.md) for the full measurement,
including everything that failed.

## The hazard

The issuer's REST price endpoint returns the raw underlying equity price. The
onchain price feed is multiplier adjusted. Mix the two without applying
`currentMultiplier` and the number is wrong.

CRWD sits at a multiplier of 4.0 after a forward split. A position read naively
is valued at a quarter of its true worth. The other 27 affected assets are off
by between 0.02 and 2.15 percent.

## API

    GET /health
    GET /summary
    GET /assets
    GET /assets/:ticker
    GET /affected

## Run it

    npm install
    npm test
    npm run refresh   # read registry and chain, build state
    npm run serve     # serve the API

## Status

Early. The commands above work and are tested. There is no interface and no
token.
EOF

echo "Done. Updated docs/findings.md and docs/README.md"
