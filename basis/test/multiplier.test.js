import { test } from "node:test";
import assert from "node:assert/strict";
import { parseDecimal18, isUnit, errorBps, compare, report } from "../src/multiplier.js";

const ONE = 10n ** 18n;

test("parses an 18dp decimal string exactly", () => {
  assert.equal(parseDecimal18("1.000412952576205964"), 1000412952576205964n);
});

test("parses a whole number", () => {
  assert.equal(parseDecimal18("1"), ONE);
});

test("rejects junk rather than guessing", () => {
  assert.equal(parseDecimal18(""), null);
  assert.equal(parseDecimal18("abc"), null);
  assert.equal(parseDecimal18(null), null);
});

test("unit multiplier is recognised", () => {
  assert.equal(isUnit(ONE), true);
  assert.equal(isUnit(1000412952576205964n), false);
});

test("error is reported in basis points", () => {
  assert.equal(errorBps(ONE), 0);
  assert.equal(errorBps(1005101770003214918n), 51.01);
});

test("chain and registry agreement is detected", () => {
  const r = compare(1000412952576205964n, "1.000412952576205964");
  assert.equal(r.agree, true);
});

test("a stale side is flagged, not smoothed over", () => {
  assert.equal(compare(ONE, "1.000412952576205964").agree, false);
});

test("missing values give null, never a false agreement", () => {
  assert.equal(compare(null, "1").agree, null);
  assert.equal(compare(ONE, "").agree, null);
});

test("report counts only affected assets and sorts by size", () => {
  const rows = [
    { ticker: "A", scaled: ONE, agree: true },
    { ticker: "B", scaled: 1005101770003214918n, agree: true },
    { ticker: "C", scaled: 1000412952576205964n, agree: false }
  ];
  const out = report(rows);
  assert.equal(out.total, 3);
  assert.equal(out.affected, 2);
  assert.equal(out.disagreements, 1);
  assert.equal(out.rows[0].ticker, "B");
});
