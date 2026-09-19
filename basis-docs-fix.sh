#!/usr/bin/env bash
# Basis - align docs with what was actually measured
# Run from the project root (the folder containing docs/): bash basis-docs-fix.sh
set -euo pipefail

if [ ! -d "docs" ]; then
  echo "Run this from the project root, the folder containing docs/."
  exit 1
fi

echo "Correcting docs ..."

# ---------------------------------------------------------------- remove pages that are now false
rm -f docs/reference/token.md docs/reference/api.md
echo "removed reference/token.md and reference/api.md"

# ---------------------------------------------------------------- landing page
cat > docs/README.md <<'EOF'
# Basis

Basis checks one thing: whether a Robinhood Stock Token carries a corporate
action multiplier that makes naive pricing wrong.

## Why only one thing

Basis started as a rights and restrictions map for tokenized real world assets.
The assumption was that different tokenized assets carry different rights and
restrictions, and that mapping those differences would be the product.

We measured it across all 194 assets on Robinhood Chain. They do not differ.
Same issuer, same legal wrapper, same status, same pause state, same transfer
behaviour. The tradability fields the issuer documents are empty in production.

One signal varies. 28 of 194 assets carry a corporate action multiplier above 1.

See [Findings](findings.md) for the full measurement, including everything that
failed.

## What the multiplier does

The issuer's REST price endpoint returns the raw underlying equity price, not
multiplier adjusted. The onchain price feed is multiplier adjusted. An
integrator who reads a token balance and multiplies by the REST price without
applying the multiplier gets a wrong number on those 28 assets.

The error is roughly 0.01 to 0.5 percent. Small, systematic and silent.

## Run it

    npm install
    npm test
    npm run sync     # read the asset registry
    npm run probe    # read contract state per asset
    npm run check    # report multiplier exposure

## Status

Early. The three commands above work and are tested. There is no interface, no
API and no token.
EOF

# ---------------------------------------------------------------- roadmap
cat > docs/roadmap.md <<'EOF'
# Roadmap

## Built

* Asset registry sync from the issuer read API, filtered to chain 4663
* Contract state reader with per field support flags
* Transfer probe with zero amount and one unit probing
* Status classifier
* Multiplier check comparing chain state against the registry
* 27 unit tests

## Measured and dropped

The per asset rights and restrictions layer. See [Findings](findings.md). Every
signal except the multiplier returned an identical value across all 194 assets.

## Possible next

* Watch for multiplier changes over time and alert on them. The corporate
  actions endpoint explains why a multiplier moved, so a change log is feasible.
* Check whether the chain and the registry ever disagree on a multiplier. The
  check reports this. If it is always zero, there is nothing here.
* A small published dataset of which assets are affected.

## Not planned

A token. The only justification for one was bonding attestations on rights data,
and that data turned out not to vary. Without the premise there is no reason for
it, so it was removed rather than rewritten.
EOF

# ---------------------------------------------------------------- data model
cat > docs/reference/data-model.md <<'EOF'
# Data model

Three files, all under `out/`.

## registry.json

One record per asset deployed on chain 4663, from the issuer read API.

    {
      "ticker": "CRM",
      "name": "...",
      "address": "0x...",
      "status": "ASSET_STATUS_ACTIVE",
      "currentMultiplier": "1.005101770003214918",
      "pendingMultiplier": null,
      "fractionalTradability": "",
      "allDayTradability": "",
      "extendedHoursFractionalTradability": null,
      "capabilitiesResolved": true
    }

Note the empty tradability fields. The issuer documents these as populated
enums. In production they come back blank for every asset. We record what was
returned rather than what was documented.

## profiles.json

One record per asset, read from contract state, including `paused`,
`uiMultiplier`, the transfer probe result and the block number it was read at.

Every optional read carries a `*Supported` flag. A field that could not be read
is null with the reason recorded, never defaulted.

## multiplier-report.json

Assets whose multiplier is not 1, sorted by the size of the pricing error in
basis points, plus a count of any disagreements between chain and registry.
EOF

# ---------------------------------------------------------------- append corrections
cat >> docs/concepts/rights-vs-restrictions.md <<'EOF'

## Correction

The restrictions listed above were expected to vary per asset. They were
measured across all 194 assets and they do not. Status, pause state and transfer
behaviour returned identical values throughout, and the tradability fields came
back empty.

This page is kept because the distinction between rights and restrictions is
still the right way to think about the problem. It just has no per asset answer
on this chain today. See [Findings](../findings.md).
EOF

cat >> docs/architecture.md <<'EOF'

## Components added since

**Registry sync.** Reads the issuer asset API, keeps deployments on chain 4663,
rewrites the asset list and groups assets by restriction profile to count how
many genuinely differ.

**Multiplier check.** Compares the onchain multiplier against the registry value
and reports the pricing error in basis points, plus any disagreement between the
two sources.

**Store.** Still not built. Flat JSON files under `out/` for now.
EOF

# ---------------------------------------------------------------- summary
cat > docs/SUMMARY.md <<'EOF'
# Table of contents

* [Basis](README.md)
* [Findings](findings.md)

## Overview

* [The problem](overview/problem.md)
* [Scope](overview/scope.md)

## Concepts

* [Rights vs restrictions](concepts/rights-vs-restrictions.md)
* [Status codes](concepts/statuses.md)

## Build

* [Architecture](architecture.md)
* [Running the probe](guides/running-the-probe.md)
* [Data model](reference/data-model.md)

## Status

* [Roadmap](roadmap.md)
* [Limitations](limitations.md)
EOF

echo "Done."
