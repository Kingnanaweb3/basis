# API

Planned. Not built. Listed here as design, so the shape is reviewable before any
of it exists.

    GET /assets
    GET /assets/{asset}
    GET /assets/{asset}/terms        # tier 1, issuer terms
    GET /assets/{asset}/state        # tier 2, live state
    GET /assets/{asset}/probe        # transfer probe result
    GET /assets/{asset}/sources

Every response is expected to carry the block number it was verified at, and a
per field source label. No endpoint is live today.
