# Rights vs restrictions

Basis separates two things that are usually mixed together.

## Rights (static)

What the instrument legally is. For Robinhood Stock Tokens this resolves to a
single record covering all of them:

| Field | Value |
| --- | --- |
| Instrument type | Tokenised debt security |
| Issuer | Robinhood Assets (Jersey) Limited |
| Legal ownership of underlying | No |
| Beneficial ownership of underlying | No |
| Voting rights | Not passed through |
| Economic exposure | Yes |
| Dividend treatment | Cash equivalent, credited offchain |

Source: issuer Base Prospectus and Final Terms. Basis links to them and does not
paraphrase them into anything resembling advice.

## Restrictions (live, per asset)

What you can actually do right now:

* paused or active
* transferable, or blocked by a transfer rule
* mint and redemption window open or closed
* scaled UI multiplier, which changes on corporate actions
* price feed present and fresh
* listed on lending or AMM venues
* jurisdictions where the asset is restricted

This is the part that moves, and the part Basis refreshes.

## Why the split matters

If you merge them, every asset looks identical and the product has nothing to
say. Keeping them apart is what leaves room for a per asset answer.
