# Scope

## In scope

* Robinhood Chain Stock Tokens
* Reading the corporate action multiplier from both the registry and the chain
* Reporting which assets make naive pricing wrong, and by how much
* Flagging any disagreement between the two sources
* A read only API over that data

## Out of scope

* Rights and restriction mapping. Measured, found uniform, dropped.
* The transfer probe. Kept as a diagnostic, removed from the serving path.
* Price data. Basis reports the multiplier, not the price.
* A portfolio tracker, a screener, a trading venue, or legal advice.
* A token. The only justification depended on the premise that failed.

## Why a blockchain is involved

The multiplier is onchain, and the mismatch it causes is between onchain and
offchain sources. Basis reads both and reports where they diverge.
