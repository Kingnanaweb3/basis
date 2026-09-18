# Numa probe (MVP)

One question: can this Stock Token actually move right now?

## Run

    cd numa
    npm install
    npm test
    npm run probe -- --from 0xYourAddress --to 0xSomeOtherAddress

Add assets to `assets.json`. Canonical addresses come from the Robinhood Chain
docs contracts page, which is generated from the on-chain asset registry. A
matching ticker at a different address is not a Robinhood Stock Token.

## What the statuses mean

- `allowed_at_contract` - the contract did not reject it. Says nothing about
  sequencer-level compliance screening.
- `blocked_paused` - the asset is paused.
- `blocked_policy` - a transfer rule rejected it (whitelist, freeze, geography).
- `inconclusive_balance` - reverted on funds, not policy.
- `blocked_unknown` - reverted with no readable reason.
- `no_contract` - nothing deployed at that address.

## Known limit

`eth_call` does not run the sequencer compliance engine. A pass here is a
contract-level pass only. Closing that gap needs a real signed transaction, and
that is the next thing to test.
