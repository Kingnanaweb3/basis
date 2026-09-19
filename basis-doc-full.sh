#!/usr/bin/env bash
# Basis - full project documentation
# Run from your project root (the folder containing docs/): bash basis-doc-full.sh
set -euo pipefail

if [ ! -d "docs" ]; then
  echo "No docs/ folder here. Run this from the project root, after basis-docs.sh."
  exit 1
fi

echo "Adding project documentation ..."

mkdir -p docs/overview docs/reference

# ---------------------------------------------------------------- overview
cat > docs/overview/problem.md <<'EOF'
# The problem

A token can represent exposure to a real world asset without giving the holder
the rights that owning the underlying asset would give.

Depending on the instrument, a token may carry economic exposure, a claim on
distributions, redemption rights, transfer rights, collateral eligibility,
voting rights, or none of these. Today that information sits scattered across
token contracts, issuer documentation, legal terms, protocol documentation and
chain state.

## What we found when we checked

The original premise for this project assumed that different tokenized assets
would carry different rights, and that mapping them per asset would be the
product.

For Robinhood Stock Tokens, that assumption does not hold. They are tokenised
debt securities issued by a single issuer, Robinhood Assets (Jersey) Limited.
They give economic exposure and do not grant legal or beneficial ownership in
the underlying security. Voting is not passed through. Dividends are credited as
a cash equivalent inside the Robinhood app rather than as an onchain event. The
contracts share a standardised template.

So the legal answer is the same for every one of them. Mapping ninety six assets
would produce ninety six identical cards.

## The real gap

What is not constant is the operational layer. Whether a specific token can be
moved, minted, redeemed, priced or used as collateral right now varies per asset
and changes over time. None of it is visible in a block explorer.

That is where Basis is aimed.

## Positioning

Category: rights and restrictions intelligence for tokenized assets.

Core sentence: know what you can actually do with this token, right now.
EOF

cat > docs/overview/scope.md <<'EOF'
# Scope

## In scope

* Robinhood Chain Stock Tokens
* One shared issuer terms record, sourced and linked
* Per asset live restriction and status data
* Transfer probing, with its coverage limits stated
* A read interface and, later, a read API

## Out of scope

Basis is deliberately not any of the following:

* a stock token screener
* a portfolio tracker
* a trading venue
* a price dashboard
* a generic RWA explorer
* a source of legal advice

The product is about rights and restrictions attached to tokenized assets.
Anything that pulls it toward price or trading dilutes that.

## Why a blockchain is involved

The chain provides verifiable asset and token state. Basis's job is to translate
that state, plus authoritative issuer documentation, into a standardised layer
that people and applications can read.

The chain is not the product. The claim information is the product.
EOF

# ---------------------------------------------------------------- architecture
cat > docs/architecture.md <<'EOF'
# Architecture

## Chain

Robinhood Chain, an EVM compatible Arbitrum based Layer 2. Chain id 4663. Gas is
paid in ETH, not in any project token.

## Components

**Reader.** Pulls contract level state per asset: name, symbol, decimals, total
supply, paused state, scaled UI multiplier. Every optional read is attempted and
allowed to fail, with the failure recorded rather than defaulted.

**Prober.** Simulates transfers to establish whether a rule rejects them. Probes
at zero amount to isolate policy from balance, and at one unit where a balance
exists. Built. See Limitations for what it does not cover.

**Classifier.** Pure function mapping a raw outcome to a status. No network code,
unit tested in isolation.

**Store.** Planned. Postgres, one row per asset per observation, every row
carrying the block number it was read at. History matters here: a restriction
that appeared last Tuesday is the interesting signal.

**Interface and API.** Planned. See the API reference.

## Data sourcing rule

Every field carries how it was established:

* read from contract state
* taken from issuer documentation, with a link
* probed by simulation, with coverage caveats attached

These three labels never merge. Uncertain information is never presented as
fact, and an unreadable value is never defaulted to a convenient one.

## Stack

Solidity with Foundry for contracts. Node with viem for the reader and prober.
Standard Ethereum tooling works on this chain without modification.
EOF

# ---------------------------------------------------------------- token
cat > docs/reference/token.md <<'EOF'
# BASIS token

Status: proposed. No contract is deployed. Nothing on this page exists yet.

## Honest framing

A read only data product does not inherently need a token. There is one
defensible justification, and the design below rests entirely on it: the core
risk of this product is bad data, and a token can act as the bond that makes
published data costly to get wrong.

If that justification does not convince you, it should not convince anyone else
either. It is stated plainly rather than dressed up.

## Proposed design

**BASIS**, an ERC-20 on Robinhood Chain. It has no gas role, because gas on this
chain is paid in ETH.

**Attestation bonds.** Publishing or updating a claim profile requires posting a
BASIS bond. The entry goes live immediately.

**Challenge and slash.** A challenge window during which anyone can dispute an
entry by matching the bond. A wrong publisher loses their bond to the
challenger. A wrong challenger loses theirs to the publisher.

**Query fees.** High volume API consumers pay in BASIS. Fees route to bonded
attesters.

## Known weaknesses

Dispute resolution in a first version would be arbitrated by a project
controlled multisig. Real decentralised arbitration is a long project, not a
short one. This is a centralisation point and is named as such.

With no users, token price would be driven by liquidity and narrative rather
than fee flow. Any claim otherwise would be false.
EOF

# ---------------------------------------------------------------- roadmap
cat > docs/roadmap.md <<'EOF'
# Roadmap

Honest status labels only. Built means it runs and is tested.

## Built

* Transfer prober with zero amount and one unit probing
* Status classifier with eight unit tests
* Contract state reader with per field support flags
* JSON profile output with block number and timestamp

## Next

* Verify the probe against live mainnet state
* Confirm the optional ABI fragments against a real deployment
* Read the asset list from the onchain registry rather than a manual file
* Measure how many assets actually diverge from one another. This number decides
  whether the product is viable, and it is not yet known.

## Later

* Price feed presence and staleness per asset
* Mint and redemption window state
* Lending and AMM venue listings
* Jurisdiction restriction sets
* Persistence and change history
* Read API
* Web interface

## Open questions

* Does a real signed transaction get screened differently from a simulation? This
  is untested and it determines how much of the product is real.
* Is the divergence between assets large enough to justify a per asset view?
* Does the token design survive contact with someone who is not already sold on
  it?
EOF

# ---------------------------------------------------------------- SUMMARY
cat > docs/SUMMARY.md <<'EOF'
# Table of contents

* [Basis](README.md)

## Overview

* [The problem](overview/problem.md)
* [Scope](overview/scope.md)

## Concepts

* [Rights vs restrictions](concepts/rights-vs-restrictions.md)
* [Status codes](concepts/statuses.md)

## Build

* [Architecture](architecture.md)
* [Running the probe](guides/running-the-probe.md)

## Reference

* [Data model](reference/data-model.md)
* [API](reference/api.md)
* [BASIS token](reference/token.md)

## Honesty

* [Roadmap](roadmap.md)
* [Limitations](limitations.md)
EOF

echo "Done. Added overview/, architecture.md, roadmap.md, reference/token.md, updated SUMMARY.md"
