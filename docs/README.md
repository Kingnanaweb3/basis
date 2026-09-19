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
