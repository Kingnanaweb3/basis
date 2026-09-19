import { readFileSync, writeFileSync } from "node:fs";
import { compare, report } from "./multiplier.js";

const registry = JSON.parse(readFileSync("out/registry.json", "utf8"));
const profiles = JSON.parse(readFileSync("out/profiles.json", "utf8"));

const byTicker = new Map(registry.map((r) => [r.ticker, r]));

const rows = profiles.map((p) => {
  const reg = byTicker.get(p.ticker);
  const scaled = p.uiMultiplier ? BigInt(p.uiMultiplier) : null;
  const cmp = reg ? compare(scaled, reg.currentMultiplier) : { agree: null };
  return { ticker: p.ticker, scaled, agree: cmp.agree };
});

const out = report(rows);

console.log(`\nAssets checked: ${out.total}`);
console.log(`Multiplier not 1 (naive pricing is wrong): ${out.affected}`);
console.log(`Chain and registry disagree: ${out.disagreements}`);
console.log(`Largest error: ${out.worstBps} bps\n`);

for (const r of out.rows.slice(0, 15)) {
  console.log(`${r.ticker.padEnd(8)} ${String(r.bps).padStart(8)} bps`);
}

writeFileSync("out/multiplier-report.json", JSON.stringify(out, null, 2));
console.log(`\nWrote out/multiplier-report.json`);
