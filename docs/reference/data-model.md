# Data model

Two tiers, because they have different truth values and different refresh rates.

## Tier 1: issuer terms

One record shared by all Stock Tokens. Sourced from issuer documentation. Changes
rarely.

## Tier 2: live asset state

Per asset, refreshed continuously.

    {
      "ticker": "TSLA",
      "address": "0x...",
      "name": "...",
      "symbol": "TSLA",
      "decimals": 18,
      "totalSupply": "...",
      "paused": false,
      "pausedSupported": true,
      "uiMultiplier": "...",
      "uiMultiplierSupported": true,
      "proberBalance": "0",
      "transfer": { "status": "allowed_at_contract", "detail": "..." },
      "transferWithValue": null,
      "probeMethod": "eth_call simulation",
      "coverageCaveat": "...",
      "verifiedAtBlock": "...",
      "verifiedAt": "..."
    }

Every optional read carries a `*Supported` flag. A field that could not be read
is null with the reason recorded, never defaulted to a convenient value.

## Planned fields

Not implemented yet: price feed address and staleness, mint and redemption window
state, lending venue listings, AMM depth, jurisdiction restriction set.
