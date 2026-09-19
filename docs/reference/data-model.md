# Data model

Three files, all under `out/`.

## registry.json

One record per asset deployed on chain 4663, from the issuer read API.

    {
      "ticker": "CRM",
      "name": "...",
      "address": "0x...",
      "status": "ASSET_STATUS_ACTIVE",
      "currentMultiplier": "1.005101770003214918",
      "pendingMultiplier": null,
      "fractionalTradability": "",
      "allDayTradability": "",
      "extendedHoursFractionalTradability": null,
      "capabilitiesResolved": true
    }

Note the empty tradability fields. The issuer documents these as populated
enums. In production they come back blank for every asset. We record what was
returned rather than what was documented.

## profiles.json

One record per asset, read from contract state, including `paused`,
`uiMultiplier`, the transfer probe result and the block number it was read at.

Every optional read carries a `*Supported` flag. A field that could not be read
is null with the reason recorded, never defaulted.

## multiplier-report.json

Assets whose multiplier is not 1, sorted by the size of the pricing error in
basis points, plus a count of any disagreements between chain and registry.
