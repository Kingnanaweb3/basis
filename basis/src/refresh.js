import { writeFileSync } from "node:fs";
import { makeClient } from "./chain.js";
import { fetchAssets, toRecords } from "./registry.js";
import { OPTIONAL_ABI } from "./abi.js";
import { mapLimit, retry } from "./async.js";
import { buildAsset, summarise } from "./state.js";

export const STATE_PATH = "out/state.json";

// Concurrency is deliberately low. The public RPC rejects bursts.
const CONCURRENCY = Number(process.env.BASIS_CONCURRENCY || 4);

export async function refresh({ write = true } = {}) {
  const client = makeClient();
  const records = toRecords(await fetchAssets());

  const multipliers = await mapLimit(records, CONCURRENCY, async (r) => {
    try {
      const v = await retry(() =>
        client.readContract({ address: r.address, abi: OPTIONAL_ABI, functionName: "uiMultiplier" })
      );
      return v.toString();
    } catch {
      return null; // unread, never defaulted to 1
    }
  });

  const assets = records.map((r, i) => buildAsset(r, multipliers[i]));

  let block = null;
  try {
    block = (await client.getBlockNumber()).toString();
  } catch {
    block = null;
  }

  const state = { summary: summarise(assets, block), assets };
  if (write) writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
  return state;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const s = await refresh();
  console.log(`\nAssets: ${s.summary.total}`);
  console.log(`Naive pricing unsafe: ${s.summary.affected}`);
  console.log(`Multiplier unreadable: ${s.summary.unknown}`);
  console.log(`Chain and registry disagree: ${s.summary.sourceDisagreements}`);
  console.log(`Largest error: ${s.summary.worstBps} bps`);
  console.log(`\nWrote ${STATE_PATH}`);
}
