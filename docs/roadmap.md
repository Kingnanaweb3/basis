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
