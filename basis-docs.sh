#!/usr/bin/env bash
# Basis - docs + repo scaffold for GitBook sync
# Run from your project root: bash basis-docs.sh
set -euo pipefail

echo "Writing docs scaffold ..."

mkdir -p docs/concepts docs/guides docs/reference

# ---------------------------------------------------------------- .gitignore
cat > .gitignore <<'EOF'
node_modules/
out/
.env
.env.local
.DS_Store
*.log
EOF

# ---------------------------------------------------------------- .gitbook.yaml
cat > .gitbook.yaml <<'EOF'
root: ./docs/

structure:
  readme: README.md
  summary: SUMMARY.md
EOF

# ---------------------------------------------------------------- repo README
cat > README.md <<'EOF'
# Basis

Rights and restrictions intelligence for tokenized real-world assets on Robinhood Chain.

Basis answers one question that block explorers do not: can this token actually
move right now, and if not, why not.

Status: early. The transfer probe is the only working component. Everything else
in the documentation is marked as planned or unverified.

## Quick start

    bash basis-probe.sh
    cd basis
    npm install
    npm test
    npm run probe -- --from 0xYourAddress --to 0xOtherAddress

Docs: see `docs/`.
EOF

# ---------------------------------------------------------------- SUMMARY
cat > docs/SUMMARY.md <<'EOF'
# Table of contents

* [Basis](README.md)

## Concepts

* [Rights vs restrictions](concepts/rights-vs-restrictions.md)
* [Status codes](concepts/statuses.md)

## Guides

* [Running the probe](guides/running-the-probe.md)

## Reference

* [Data model](reference/data-model.md)
* [API](reference/api.md)

## Honesty

* [Limitations](limitations.md)
EOF

# ---------------------------------------------------------------- docs/README
cat > docs/README.md <<'EOF'
# Basis

Basis is a rights and restrictions layer for tokenized real world assets on
Robinhood Chain.

## The gap

Robinhood Stock Tokens are tokenised debt securities issued by Robinhood Assets
(Jersey) Limited. They give economic exposure to an underlying security and do
not grant legal or beneficial ownership in it. Dividends are credited as a cash
equivalent inside the Robinhood app rather than as an onchain distribution.
Voting is not passed through.

That is true of every Stock Token. The legal answer is one paragraph, and Basis
states it once.

What is not constant is whether a given token can be moved, minted, redeemed,
priced or used as collateral at this moment. That varies per asset and changes
over time, and it is not visible in a block explorer.

## What Basis builds

A live status layer over the assets, with every field labelled by how it was
established:

* read directly from contract state
* taken from issuer documentation, with a link
* probed by simulation, with its coverage limits stated

The third label is the one that makes Basis different, and it is also the one
with the most caveats. Both are documented.

## Current state

The transfer probe runs and is tested. Nothing else is built yet. Sections
marked "planned" are design, not shipped software.
EOF

# ---------------------------------------------------------------- concepts
cat > docs/concepts/rights-vs-restrictions.md <<'EOF'
# Rights vs restrictions

Basis separates two things that are usually mixed together.

## Rights (static)

What the instrument legally is. For Robinhood Stock Tokens this resolves to a
single record covering all of them:

| Field | Value |
| --- | --- |
| Instrument type | Tokenised debt security |
| Issuer | Robinhood Assets (Jersey) Limited |
| Legal ownership of underlying | No |
| Beneficial ownership of underlying | No |
| Voting rights | Not passed through |
| Economic exposure | Yes |
| Dividend treatment | Cash equivalent, credited offchain |

Source: issuer Base Prospectus and Final Terms. Basis links to them and does not
paraphrase them into anything resembling advice.

## Restrictions (live, per asset)

What you can actually do right now:

* paused or active
* transferable, or blocked by a transfer rule
* mint and redemption window open or closed
* scaled UI multiplier, which changes on corporate actions
* price feed present and fresh
* listed on lending or AMM venues
* jurisdictions where the asset is restricted

This is the part that moves, and the part Basis refreshes.

## Why the split matters

If you merge them, every asset looks identical and the product has nothing to
say. Keeping them apart is what leaves room for a per asset answer.
EOF

cat > docs/concepts/statuses.md <<'EOF'
# Status codes

The probe returns one status per asset.

| Status | Meaning |
| --- | --- |
| `allowed_at_contract` | The contract did not reject the simulated transfer. Contract level only. |
| `blocked_paused` | The asset is paused. |
| `blocked_policy` | A transfer rule rejected it: whitelist, freeze, eligibility or geography. |
| `inconclusive_balance` | Reverted on funds rather than policy. Re-probe with amount zero. |
| `blocked_unknown` | Reverted with no readable reason. Treated as blocked, never assumed clean. |
| `no_contract` | No contract code at that address on this chain. |
| `error` | The probe itself failed. |

## On naming

The success case is called `allowed_at_contract`, not `allowed`. The distinction
is deliberate and survives into the API and the interface, so a partial check is
never displayed as a full clearance.

## On unknowns

An unreadable revert is classified as blocked, not as passing. A rights and
restrictions product that guesses optimistically when it cannot read something
is worse than no product.
EOF

# ---------------------------------------------------------------- guides
cat > docs/guides/running-the-probe.md <<'EOF'
# Running the probe

## Install

    bash basis-probe.sh
    cd basis
    npm install

## Test

    npm test

Eight tests, no network required. They cover the classifier only.

## Probe

    npm run probe -- --from 0xYourAddress --to 0xOtherAddress

Your wallet does not need to hold the token. The probe sends a zero amount by
default.

Output goes to `out/profiles.json`.

## Why amount zero

A prober with no balance always reverts on funds, which looks identical to being
blocked by a rule. Sending zero removes the balance variable, so a revert means a
policy rejected you.

If the wallet does hold a balance, a second one unit probe runs automatically. A
zero amount pass combined with a one unit failure is the signature of a rule that
only applies to real value.

## Adding assets

Edit `assets.json`. Canonical addresses come from the Robinhood Chain docs
contracts page, which is generated from the onchain asset registry. A token with
a matching ticker at a different address is not a Robinhood Stock Token.

## Configuration

Set `BASIS_RPC` to override the default mainnet endpoint.
EOF

# ---------------------------------------------------------------- reference
cat > docs/reference/data-model.md <<'EOF'
# Data model

Two tiers, because they have different truth values and different refresh rates.

## Tier 1: issuer terms

One record shared by all Stock Tokens. Sourced from issuer documentation. Changes
rarely.

## Tier 2: live asset state

Per asset, refreshed continuously.

    {
      "ticker": "TSLA",
      "address": "0x...",
      "name": "...",
      "symbol": "TSLA",
      "decimals": 18,
      "totalSupply": "...",
      "paused": false,
      "pausedSupported": true,
      "uiMultiplier": "...",
      "uiMultiplierSupported": true,
      "proberBalance": "0",
      "transfer": { "status": "allowed_at_contract", "detail": "..." },
      "transferWithValue": null,
      "probeMethod": "eth_call simulation",
      "coverageCaveat": "...",
      "verifiedAtBlock": "...",
      "verifiedAt": "..."
    }

Every optional read carries a `*Supported` flag. A field that could not be read
is null with the reason recorded, never defaulted to a convenient value.

## Planned fields

Not implemented yet: price feed address and staleness, mint and redemption window
state, lending venue listings, AMM depth, jurisdiction restriction set.
EOF

cat > docs/reference/api.md <<'EOF'
# API

Planned. Not built. Listed here as design, so the shape is reviewable before any
of it exists.

    GET /assets
    GET /assets/{asset}
    GET /assets/{asset}/terms        # tier 1, issuer terms
    GET /assets/{asset}/state        # tier 2, live state
    GET /assets/{asset}/probe        # transfer probe result
    GET /assets/{asset}/sources

Every response is expected to carry the block number it was verified at, and a
per field source label. No endpoint is live today.
EOF

# ---------------------------------------------------------------- limitations
cat > docs/limitations.md <<'EOF'
# Limitations

## The probe does not cover sequencer screening

Robinhood Chain performs compliance filtering inside the sequencer, which
simulates a transaction before sequencing it and rejects it if it violates a
rule. An `eth_call` simulation does not pass through that engine.

So a contract level pass is not a guarantee that a real signed transaction will
be sequenced. Every profile carries this caveat in a `coverageCaveat` field, and
the status name says `allowed_at_contract` rather than `allowed`.

Closing the gap requires sending a real signed transaction and observing whether
it is sequenced. That costs gas and has not been done yet.

## ABI assumptions

The optional reads for `paused` and `uiMultiplier` are attempted, not assumed.
If a read fails the field is null and the error is recorded. The exact issuer
contract surface has not been fully verified against a live deployment.

## Coverage

The asset list is manually maintained. It is not yet read from the onchain asset
registry.

## Not legal advice

Basis reports what documentation and chain state say. It links to primary sources
and does not interpret them. It is not advice of any kind, and the underlying
assets are restricted in a number of jurisdictions.
EOF

echo "Done. docs/ and .gitbook.yaml written."
