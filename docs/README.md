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
