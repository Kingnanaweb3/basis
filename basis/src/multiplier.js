// The one signal that varies per asset on Robinhood Chain: the corporate-action
// multiplier. Everything else (status, pause state, transfer behaviour,
// tradability flags) came back identical across all assets when measured.

const ONE = 10n ** 18n;

// "1.000412952576205964" -> 1000412952576205964n
export function parseDecimal18(value) {
  if (typeof value !== "string" || !/^\d+(\.\d+)?$/.test(value)) return null;
  const [whole, frac = ""] = value.split(".");
  return BigInt(whole) * ONE + BigInt((frac + "0".repeat(18)).slice(0, 18));
}

export function isUnit(scaled) {
  return scaled === ONE;
}

// Error an integrator incurs by ignoring the multiplier, in basis points.
export function errorBps(scaled) {
  if (scaled === null) return null;
  const diff = scaled > ONE ? scaled - ONE : ONE - scaled;
  return Number((diff * 10000n * 100n) / ONE) / 100;
}

// Chain and registry should agree. If they do not, one of them is stale and
// that is itself worth reporting.
export function compare(chainScaled, registryDecimal) {
  const registryScaled = parseDecimal18(registryDecimal);
  if (chainScaled === null || registryScaled === null) {
    return { agree: null, reason: "missing value" };
  }
  return { agree: chainScaled === registryScaled, chainScaled, registryScaled };
}

export function report(rows) {
  const affected = rows.filter((r) => r.scaled !== null && !isUnit(r.scaled));
  const disagreements = rows.filter((r) => r.agree === false);
  return {
    total: rows.length,
    affected: affected.length,
    disagreements: disagreements.length,
    worstBps: affected.reduce((m, r) => Math.max(m, errorBps(r.scaled)), 0),
    rows: affected
      .map((r) => ({ ticker: r.ticker, bps: errorBps(r.scaled) }))
      .sort((a, b) => b.bps - a.bps)
  };
}
