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
