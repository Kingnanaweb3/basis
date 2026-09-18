# Roadmap

Honest status labels only. Built means it runs and is tested.

## Built

* Transfer prober with zero amount and one unit probing
* Status classifier with eight unit tests
* Contract state reader with per field support flags
* JSON profile output with block number and timestamp

## Next

* Verify the probe against live mainnet state
* Confirm the optional ABI fragments against a real deployment
* Read the asset list from the onchain registry rather than a manual file
* Measure how many assets actually diverge from one another. This number decides
  whether the product is viable, and it is not yet known.

## Later

* Price feed presence and staleness per asset
* Mint and redemption window state
* Lending and AMM venue listings
* Jurisdiction restriction sets
* Persistence and change history
* Read API
* Web interface

## Open questions

* Does a real signed transaction get screened differently from a simulation? This
  is untested and it determines how much of the product is real.
* Is the divergence between assets large enough to justify a per asset view?
* Does the token design survive contact with someone who is not already sold on
  it?
