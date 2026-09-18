# Limitations

## The probe does not cover sequencer screening

Robinhood Chain performs compliance filtering inside the sequencer, which
simulates a transaction before sequencing it and rejects it if it violates a
rule. An `eth_call` simulation does not pass through that engine.

So a contract level pass is not a guarantee that a real signed transaction will
be sequenced. Every profile carries this caveat in a `coverageCaveat` field, and
the status name says `allowed_at_contract` rather than `allowed`.

Closing the gap requires sending a real signed transaction and observing whether
it is sequenced. That costs gas and has not been done yet.

## ABI assumptions

The optional reads for `paused` and `uiMultiplier` are attempted, not assumed.
If a read fails the field is null and the error is recorded. The exact issuer
contract surface has not been fully verified against a live deployment.

## Coverage

The asset list is manually maintained. It is not yet read from the onchain asset
registry.

## Not legal advice

Numa reports what documentation and chain state say. It links to primary sources
and does not interpret them. It is not advice of any kind, and the underlying
assets are restricted in a number of jurisdictions.
