# Running the probe

## Install

    bash basis-probe.sh
    cd basis
    npm install

## Test

    npm test

Eight tests, no network required. They cover the classifier only.

## Probe

    npm run probe -- --from 0xYourAddress --to 0xOtherAddress

Your wallet does not need to hold the token. The probe sends a zero amount by
default.

Output goes to `out/profiles.json`.

## Why amount zero

A prober with no balance always reverts on funds, which looks identical to being
blocked by a rule. Sending zero removes the balance variable, so a revert means a
policy rejected you.

If the wallet does hold a balance, a second one unit probe runs automatically. A
zero amount pass combined with a one unit failure is the signature of a rule that
only applies to real value.

## Adding assets

Edit `assets.json`. Canonical addresses come from the Robinhood Chain docs
contracts page, which is generated from the onchain asset registry. A token with
a matching ticker at a different address is not a Robinhood Stock Token.

## Configuration

Set `BASIS_RPC` to override the default mainnet endpoint.
