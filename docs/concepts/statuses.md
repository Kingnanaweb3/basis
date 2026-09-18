# Status codes

The probe returns one status per asset.

| Status | Meaning |
| --- | --- |
| `allowed_at_contract` | The contract did not reject the simulated transfer. Contract level only. |
| `blocked_paused` | The asset is paused. |
| `blocked_policy` | A transfer rule rejected it: whitelist, freeze, eligibility or geography. |
| `inconclusive_balance` | Reverted on funds rather than policy. Re-probe with amount zero. |
| `blocked_unknown` | Reverted with no readable reason. Treated as blocked, never assumed clean. |
| `no_contract` | No contract code at that address on this chain. |
| `error` | The probe itself failed. |

## On naming

The success case is called `allowed_at_contract`, not `allowed`. The distinction
is deliberate and survives into the API and the interface, so a partial check is
never displayed as a full clearance.

## On unknowns

An unreadable revert is classified as blocked, not as passing. A rights and
restrictions product that guesses optimistically when it cannot read something
is worse than no product.
