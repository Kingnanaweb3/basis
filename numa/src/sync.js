import { writeFileSync } from "node:fs";
import { fetchAssets, toRecords, divergence, outliers } from "./registry.js";

const records = toRecords(await fetchAssets());

writeFileSync("out/registry.json", JSON.stringify(records, null, 2));
writeFileSync(
  "assets.json",
  JSON.stringify(records.map((r) => ({ ticker: r.ticker, address: r.address })), null, 2)
);

const d = divergence(records);

console.log(`\nAssets on chain 4663: ${d.total}`);
console.log(`Distinct restriction profiles: ${d.distinctProfiles}\n`);

for (const b of d.buckets) {
  console.log(`${String(b.count).padStart(4)}  ${b.key}`);
  console.log(`      e.g. ${b.sample.join(", ")}`);
}

const odd = outliers(records);
console.log(`\nAssets differing from the commonest profile: ${odd.length}`);
if (odd.length) {
  console.log(`Demo candidates: ${odd.slice(0, 12).map((r) => r.ticker).join(", ")}`);
}

writeFileSync("out/outliers.json", JSON.stringify(odd, null, 2));
console.log(`\nWrote assets.json, out/registry.json, out/outliers.json`);
