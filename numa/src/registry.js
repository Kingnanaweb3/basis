// Reads the Robinhood Stock Token asset registry.
// Source: GET https://api.robinhood.com/rhj/assets  (read-only, rate limited 60/s)

export const ASSETS_URL = "https://api.robinhood.com/rhj/assets";
export const CHAIN_ID = 4663;

export async function fetchAssets(url = ASSETS_URL) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Registry returned ${res.status} ${res.statusText}`);
  const body = await res.json();
  if (!Array.isArray(body?.assets)) throw new Error("Registry response had no assets array");
  return body.assets;
}

// Flattens one registry asset to the deployment on Robinhood Chain.
// Returns null when the asset has no deployment on this chain.
export function toRecord(asset, chainId = CHAIN_ID) {
  const deployment = (asset.deployments || []).find((d) => d.chainId === chainId);
  if (!deployment) return null;

  const caps = asset.tradingCapabilities || null;

  return {
    ticker: asset.tokenSymbol,
    name: asset.tokenName,
    address: deployment.contractAddress,
    status: asset.status ?? null,
    currentMultiplier: asset.currentMultiplier ?? null,
    pendingMultiplier: asset.pendingMultiplier || null,
    pendingMultiplierEffectiveTime: asset.pendingMultiplierEffectiveTime ?? null,
    fractionalTradability: caps ? (caps.fractionalTradability ?? null) : null,
    allDayTradability: caps ? (caps.allDayTradability ?? null) : null,
    extendedHoursFractionalTradability: caps ? (caps.extendedHoursFractionalTradability ?? null) : null,
    capabilitiesResolved: caps !== null
  };
}

export function toRecords(assets, chainId = CHAIN_ID) {
  return assets.map((a) => toRecord(a, chainId)).filter(Boolean);
}

// The viability question: how many distinct restriction profiles exist across
// the asset set? One profile for everything means there is no per asset product.
export function profileKey(record) {
  return [
    record.status,
    record.fractionalTradability,
    record.allDayTradability,
    String(record.extendedHoursFractionalTradability),
    record.currentMultiplier === "1.000000000000000000" ? "mult:1" : "mult:other",
    record.pendingMultiplier ? "pending" : "no-pending",
    record.capabilitiesResolved ? "caps" : "no-caps"
  ].join(" | ");
}

export function divergence(records) {
  const groups = new Map();
  for (const r of records) {
    const key = profileKey(r);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(r.ticker);
  }
  const buckets = [...groups.entries()]
    .map(([key, tickers]) => ({ key, count: tickers.length, sample: tickers.slice(0, 6) }))
    .sort((a, b) => b.count - a.count);

  return { total: records.length, distinctProfiles: buckets.length, buckets };
}

// Assets that differ from the single most common profile. These are the ones
// worth putting in a demo.
export function outliers(records) {
  const { buckets } = divergence(records);
  if (buckets.length <= 1) return [];
  const commonest = buckets[0].key;
  return records.filter((r) => profileKey(r) !== commonest);
}
