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

That is where Numa is aimed.

## Positioning

Category: rights and restrictions intelligence for tokenized assets.

Core sentence: know what you can actually do with this token, right now.
