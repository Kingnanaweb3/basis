import { test } from "node:test";
import assert from "node:assert/strict";
import { mapLimit, retry } from "../src/async.js";
import { buildAsset, summarise, findAsset } from "../src/state.js";
import { route } from "../src/server.js";

const ONE = (10n ** 18n).toString();
const OFF = "1005101770003214918";

function record(ticker, mult = "1.000000000000000000", extra = {}) {
  return {
    ticker,
    name: `${ticker} Token`,
    address: `0x${ticker}`,
    status: "ASSET_STATUS_ACTIVE",
    currentMultiplier: mult,
    pendingMultiplier: null,
    ...extra
  };
}

test("mapLimit preserves input order regardless of finish order", async () => {
  const out = await mapLimit([30, 10, 20], 2, async (ms) => {
    await new Promise((r) => setTimeout(r, ms));
    return ms;
  });
  assert.deepEqual(out, [30, 10, 20]);
});

test("mapLimit never exceeds its concurrency cap", async () => {
  let active = 0;
  let peak = 0;
  await mapLimit([1, 2, 3, 4, 5, 6], 2, async () => {
    active++;
    peak = Math.max(peak, active);
    await new Promise((r) => setTimeout(r, 5));
    active--;
  });
  assert.ok(peak <= 2, `peak was ${peak}`);
});

test("retry succeeds after transient failures", async () => {
  let n = 0;
  const v = await retry(
    async () => {
      if (++n < 3) throw new Error("boom");
      return "ok";
    },
    { attempts: 3, delayMs: 1 }
  );
  assert.equal(v, "ok");
  assert.equal(n, 3);
});

test("retry rethrows after exhausting attempts", async () => {
  await assert.rejects(
    retry(async () => { throw new Error("always"); }, { attempts: 2, delayMs: 1 }),
    /always/
  );
});

test("a unit multiplier marks naive pricing safe", () => {
  const a = buildAsset(record("AAA"), ONE);
  assert.equal(a.naivePricingSafe, true);
  assert.equal(a.multiplier.errorBps, 0);
});

test("a non unit multiplier marks naive pricing unsafe and reports bps", () => {
  const a = buildAsset(record("CRM", "1.005101770003214918"), OFF);
  assert.equal(a.naivePricingSafe, false);
  assert.equal(a.multiplier.errorBps, 51.01);
  assert.equal(a.multiplier.sourcesAgree, true);
});

test("an unread multiplier is null, never assumed safe", () => {
  const a = buildAsset(record("XXX"), null);
  assert.equal(a.naivePricingSafe, null);
  assert.equal(a.multiplier.errorBps, null);
});

test("chain and registry disagreement is surfaced", () => {
  const a = buildAsset(record("BBB", "1.005101770003214918"), ONE);
  assert.equal(a.multiplier.sourcesAgree, false);
});

test("summary counts affected, unknown and disagreements separately", () => {
  const assets = [
    buildAsset(record("A"), ONE),
    buildAsset(record("B", "1.005101770003214918"), OFF),
    buildAsset(record("C"), null),
    buildAsset(record("D", "1.005101770003214918"), ONE)
  ];
  const s = summarise(assets, "123");
  assert.equal(s.total, 4);
  assert.equal(s.affected, 1);
  assert.equal(s.unknown, 1);
  assert.equal(s.sourceDisagreements, 1);
  assert.equal(s.verifiedAtBlock, "123");
});

test("ticker lookup is case insensitive and misses return null", () => {
  const assets = [buildAsset(record("CRM"), ONE)];
  assert.equal(findAsset(assets, "crm").ticker, "CRM");
  assert.equal(findAsset(assets, "nope"), null);
  assert.equal(findAsset(assets, null), null);
});

test("health works before any state is loaded", () => {
  const [code, body] = route("/health", null);
  assert.equal(code, 200);
  assert.equal(body.hasState, false);
});

test("data routes return 503 rather than empty data when unloaded", () => {
  assert.equal(route("/summary", null)[0], 503);
  assert.equal(route("/assets", null)[0], 503);
});

test("routes serve summary, assets, affected and single asset", () => {
  const state = {
    summary: { total: 2 },
    assets: [buildAsset(record("A"), ONE), buildAsset(record("B", "1.005101770003214918"), OFF)]
  };
  assert.equal(route("/summary", state)[1].total, 2);
  assert.equal(route("/assets", state)[1].assets.length, 2);
  assert.equal(route("/affected", state)[1].assets.length, 1);
  assert.equal(route("/assets/b", state)[1].ticker, "B");
  assert.equal(route("/assets/zz", state)[0], 404);
  assert.equal(route("/nonsense", state)[0], 404);
});
