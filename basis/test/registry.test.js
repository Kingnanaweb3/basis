import { test } from "node:test";
import assert from "node:assert/strict";
import { toRecord, toRecords, divergence, outliers, profileKey } from "../src/registry.js";

const MULT_ONE = "1.000000000000000000";

function asset(symbol, overrides = {}) {
  return {
    tokenSymbol: symbol,
    tokenName: `${symbol} Token`,
    deployments: [{ contractAddress: `0x${symbol}`, chainId: 4663 }],
    currentMultiplier: MULT_ONE,
    pendingMultiplier: "",
    status: "ASSET_STATUS_ACTIVE",
    tradingCapabilities: {
      fractionalTradability: "tradable",
      allDayTradability: "tradable",
      extendedHoursFractionalTradability: true
    },
    ...overrides
  };
}

test("picks the deployment on the requested chain", () => {
  const r = toRecord(asset("AAPL"));
  assert.equal(r.address, "0xAAPL");
  assert.equal(r.ticker, "AAPL");
});

test("assets with no deployment on this chain are dropped, not guessed", () => {
  const a = asset("XXX", { deployments: [{ contractAddress: "0xelse", chainId: 1 }] });
  assert.equal(toRecord(a), null);
  assert.equal(toRecords([a]).length, 0);
});

test("missing tradingCapabilities is recorded as unresolved, not defaulted", () => {
  const r = toRecord(asset("NOC", { tradingCapabilities: null }));
  assert.equal(r.capabilitiesResolved, false);
  assert.equal(r.allDayTradability, null);
});

test("a null sub-field is distinct from an absent capabilities object", () => {
  const r = toRecord(
    asset("NUL", {
      tradingCapabilities: {
        fractionalTradability: "tradable",
        allDayTradability: null,
        extendedHoursFractionalTradability: null
      }
    })
  );
  assert.equal(r.capabilitiesResolved, true);
  assert.equal(r.allDayTradability, null);
});

test("identical assets collapse to one profile", () => {
  const d = divergence(toRecords([asset("A"), asset("B"), asset("C")]));
  assert.equal(d.total, 3);
  assert.equal(d.distinctProfiles, 1);
});

test("a differing tradability flag creates a second profile", () => {
  const records = toRecords([
    asset("A"),
    asset("B", {
      tradingCapabilities: {
        fractionalTradability: "tradable",
        allDayTradability: "untradable",
        extendedHoursFractionalTradability: false
      }
    })
  ]);
  assert.equal(divergence(records).distinctProfiles, 2);
});

test("a pending multiplier separates an asset from its peers", () => {
  const records = toRecords([asset("A"), asset("B", { pendingMultiplier: "4.000000000000000000" })]);
  assert.equal(divergence(records).distinctProfiles, 2);
});

test("outliers exclude the commonest profile and name the rest", () => {
  const records = toRecords([
    asset("A"),
    asset("B"),
    asset("C"),
    asset("ODD", { status: "ASSET_STATUS_INACTIVE" })
  ]);
  const odd = outliers(records);
  assert.equal(odd.length, 1);
  assert.equal(odd[0].ticker, "ODD");
});

test("a single profile set has no outliers", () => {
  assert.equal(outliers(toRecords([asset("A"), asset("B")])).length, 0);
});

test("profileKey is stable for identical inputs", () => {
  assert.equal(profileKey(toRecord(asset("A"))), profileKey(toRecord(asset("B"))));
});
