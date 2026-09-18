import { readFileSync, writeFileSync } from "node:fs";
import { makeClient } from "./chain.js";
import { profileAsset } from "./probe.js";
import { summarise } from "./classify.js";

function arg(flag, fallback) {
  const i = process.argv.indexOf(flag);
  return i > -1 ? process.argv[i + 1] : fallback;
}

const ZERO_ISH = "0x000000000000000000000000000000000000dEaD";

const from = arg("--from", ZERO_ISH);
const to = arg("--to", ZERO_ISH);
const file = arg("--assets", "assets.json");

const assets = JSON.parse(readFileSync(file, "utf8"));
const client = makeClient();

console.log(`Numa probe  |  chain 4663  |  from ${from}  ->  ${to}\n`);

const results = [];
for (const asset of assets) {
  try {
    const profile = await profileAsset(client, asset, { from, to });
    results.push(profile);
    console.log(
      `${(profile.ticker ?? "?").padEnd(8)} ${summarise(profile).padEnd(26)} ${profile.transfer.detail}`
    );
  } catch (e) {
    console.log(`${(asset.ticker ?? asset.address).padEnd(8)} ERROR  ${e.shortMessage || e.message}`);
    results.push({ ticker: asset.ticker, address: asset.address, error: e.message });
  }
}

writeFileSync("out/profiles.json", JSON.stringify(results, null, 2));
console.log(`\nWrote out/profiles.json (${results.length} assets)`);
