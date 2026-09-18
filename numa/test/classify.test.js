import { test } from "node:test";
import assert from "node:assert/strict";
import { classifyTransfer, summarise } from "../src/classify.js";

test("success is contract-level allowed, not a full clearance", () => {
  const r = classifyTransfer({ ok: true });
  assert.equal(r.status, "allowed_at_contract");
  assert.match(r.detail, /sequencer/i);
});

test("balance reverts are inconclusive, never blocked", () => {
  const r = classifyTransfer({ ok: false, reason: "ERC20: transfer amount exceeds balance" });
  assert.equal(r.status, "inconclusive_balance");
});

test("pause reverts are separated from policy reverts", () => {
  assert.equal(classifyTransfer({ ok: false, reason: "Pausable: paused" }).status, "blocked_paused");
});

test("policy reverts are detected across common wordings", () => {
  const wordings = [
    "Compliance: transfer not allowed",
    "Recipient not whitelisted",
    "Sender is frozen",
    "KYC required",
    "Jurisdiction restricted"
  ];
  for (const w of wordings) {
    assert.equal(classifyTransfer({ ok: false, reason: w }).status, "blocked_policy", w);
  }
});

test("unreadable reverts are labelled unknown, not assumed clean", () => {
  assert.equal(classifyTransfer({ ok: false, reason: "execution reverted" }).status, "blocked_unknown");
});

test("missing contract is its own status", () => {
  assert.equal(classifyTransfer({ ok: false, reason: "returned no data" }).status, "no_contract");
});

test("paused flag overrides a passing transfer probe", () => {
  const profile = { paused: true, transfer: { status: "allowed_at_contract" } };
  assert.equal(summarise(profile), "PAUSED");
});

test("no outcome is an error, not a pass", () => {
  assert.equal(classifyTransfer(null).status, "error");
});
