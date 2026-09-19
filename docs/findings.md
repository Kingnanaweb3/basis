# Findings

What we measured on Robinhood Chain mainnet, and what it killed.

## Method

Read all assets from the onchain registry via the issuer's read API, then read
contract state and simulate a transfer for each one.

## Results

194 assets on chain 4663.

| Signal | Result | Verdict |
| --- | --- | --- |
| Legal rights | Identical for every asset. One issuer, one wrapper. | No per asset signal |
| Asset status | Active for every asset | No per asset signal |
| Pause state | False for every asset | No per asset signal |
| Transfer probe | Contract level pass for every asset | No per asset signal |
| Tradability flags | Empty strings and nulls for every asset | Not populated in production |
| Trading halt flag | Prices endpoint returned an empty body | Unavailable |
| Corporate action multiplier | Not 1 on 28 of 194 assets | The only signal that varies |

## What this means

The original premise was that tokenized assets differ from one another in their
rights and restrictions, and that mapping those differences per asset would be
the product. On this chain, at this time, they do not differ. The set is uniform
on every dimension except one.

We are documenting this rather than quietly narrowing the pitch, because the
measurement is the useful output even where the result is negative.

## What survives

The corporate action multiplier. 28 assets carry a multiplier above 1, meaning
an integrator who reads a balance and multiplies by the raw price from the REST
endpoint gets a wrong number. The issuer's own documentation notes that the REST
price is not multiplier adjusted while the onchain price feed is.

The error is small, roughly 0.01 to 0.5 percent depending on the asset. It is
not a catastrophic mispricing. It is a quiet, systematic one.

That is what Basis checks.
