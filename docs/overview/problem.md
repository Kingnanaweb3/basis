# The problem

A token can represent exposure to a real world asset without giving the holder
the rights that owning the underlying asset would give. Mapping those rights per
asset was the original idea behind this project.

It did not survive measurement. Robinhood Stock Tokens are issued by a single
issuer under one legal wrapper, and they returned identical values on every
dimension we could read. See [Findings](../findings.md).

## What the problem turned out to be

Not rights. Pricing.

The issuer exposes a corporate action multiplier that adjusts how many shares a
token represents. The REST price endpoint is not multiplier adjusted. The
onchain price feed is. An integrator who mixes the two gets a wrong number, and
nothing in the token contract or a block explorer warns them.

28 of 194 assets are currently affected. CRWD, after a 4 for 1 split, is off by
300 percent.

## Positioning

Category: a pricing safety check for tokenized assets.

Core sentence: check the multiplier before you trust the price.
