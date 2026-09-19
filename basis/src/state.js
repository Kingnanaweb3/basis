// Shape of what the API serves, and the lookups over it.

import { parseDecimal18, isUnit, errorBps } from "./multiplier.js";

export function buildAsset(record, chainMultiplier) {
  const registryScaled = parseDecimal18(record.currentMultiplier);
  const chainScaled = chainMultiplier === null ? null : BigInt(chainMultiplier);

  const known = chainScaled !== null;
  const agree = known && registryScaled !== null ? chainScaled === registryScaled : null;

  return {
    ticker: record.ticker,
    name: record.name,
    address: record.address,
    status: record.status,
    multiplier: {
      chain: chainScaled === null ? null : chainScaled.toString(),
      registry: record.currentMultiplier,
      sourcesAgree: agree,
      isUnit: known ? isUnit(chainScaled) : null,
      errorBps: known ? errorBps(chainScaled) : null
    },
    pendingMultiplier: record.pendingMultiplier,
    naivePricingSafe: known ? isUnit(chainScaled) : null,
    source: {
      registry: "issuer read API",
      chain: "contract uiMultiplier()"
    }
  };
}

export function summarise(assets, blockNumber) {
  const affected = assets.filter((a) => a.naivePricingSafe === false);
  const unknown = assets.filter((a) => a.naivePricingSafe === null);
  const disagree = assets.filter((a) => a.multiplier.sourcesAgree === false);

  return {
    total: assets.length,
    affected: affected.length,
    unknown: unknown.length,
    sourceDisagreements: disagree.length,
    worstBps: affected.reduce((m, a) => Math.max(m, a.multiplier.errorBps ?? 0), 0),
    affectedTickers: affected
      .slice()
      .sort((a, b) => (b.multiplier.errorBps ?? 0) - (a.multiplier.errorBps ?? 0))
      .map((a) => a.ticker),
    verifiedAtBlock: blockNumber ?? null,
    verifiedAt: new Date().toISOString()
  };
}

export function findAsset(assets, ticker) {
  if (!ticker) return null;
  const want = String(ticker).toUpperCase();
  return assets.find((a) => a.ticker?.toUpperCase() === want) ?? null;
}
