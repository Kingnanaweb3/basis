// Pure function: turns a raw probe outcome into a Basis status.
// Kept free of network code so it is unit testable.

const POLICY_HINTS = [
  "compliance", "restricted", "not allowed", "unauthorized", "unauthorised",
  "blocklist", "blacklist", "frozen", "freeze", "kyc", "whitelist",
  "sanction", "jurisdiction", "eligib", "forbidden", "denied"
];

const PAUSE_HINTS = ["pause", "halted", "suspended"];

const BALANCE_HINTS = ["insufficient balance", "exceeds balance", "insufficient funds", "transfer amount exceeds"];

export function classifyTransfer(outcome) {
  if (!outcome) return { status: "error", detail: "no outcome" };

  if (outcome.ok) {
    return {
      status: "allowed_at_contract",
      detail: "Contract-level simulation succeeded. Sequencer-level screening is NOT covered by this result."
    };
  }

  const raw = String(outcome.reason || outcome.error || "").toLowerCase();

  if (raw.includes("no contract") || raw.includes("returned no data")) {
    return { status: "no_contract", detail: "No contract code at this address on this chain." };
  }
  if (BALANCE_HINTS.some((h) => raw.includes(h))) {
    return { status: "inconclusive_balance", detail: "Reverted on balance, not on policy. Re-probe with amount 0." };
  }
  if (PAUSE_HINTS.some((h) => raw.includes(h))) {
    return { status: "blocked_paused", detail: outcome.reason || "Paused." };
  }
  if (POLICY_HINTS.some((h) => raw.includes(h))) {
    return { status: "blocked_policy", detail: outcome.reason || "Blocked by a transfer policy." };
  }
  return { status: "blocked_unknown", detail: outcome.reason || outcome.error || "Reverted without a readable reason." };
}

export function summarise(profile) {
  if (profile.paused === true) return "PAUSED";
  switch (profile.transfer.status) {
    case "allowed_at_contract": return "MOVABLE (contract level)";
    case "blocked_paused": return "PAUSED";
    case "blocked_policy": return "BLOCKED (policy)";
    case "inconclusive_balance": return "INCONCLUSIVE";
    case "no_contract": return "NOT FOUND";
    default: return "BLOCKED (unknown)";
  }
}
