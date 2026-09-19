# Basis

Basis checks one thing: whether a Robinhood Stock Token carries a corporate
action multiplier that makes naive pricing wrong.

Right now, 28 of 194 assets do. One of them, CRWD, is off by 300 percent.

## Why only one thing

Basis started as a rights and restrictions map for tokenized real world assets.
The assumption was that different tokenized assets carry different rights and
restrictions, and that mapping those differences would be the product.

We measured it across all 194 assets. They do not differ. Same issuer, same
legal wrapper, same status, same pause state, same transfer behaviour. The
tradability fields the issuer documents are empty in production.

One signal varies. See [Findings](findings.md) for the full measurement,
including everything that failed.

## The hazard

The issuer's REST price endpoint returns the raw underlying equity price. The
onchain price feed is multiplier adjusted. Mix the two without applying
`currentMultiplier` and the number is wrong.

CRWD sits at a multiplier of 4.0 after a forward split. A position read naively
is valued at a quarter of its true worth. The other 27 affected assets are off
by between 0.02 and 2.15 percent.

## API

    GET /health
    GET /summary
    GET /assets
    GET /assets/:ticker
    GET /affected

## Run it

    npm install
    npm test
    npm run refresh   # read registry and chain, build state
    npm run serve     # serve the API

## Status

Early. The commands above work and are tested. There is no interface and no
token.
