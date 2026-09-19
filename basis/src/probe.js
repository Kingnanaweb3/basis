import { ERC20_ABI, OPTIONAL_ABI } from "./abi.js";
import { classifyTransfer } from "./classify.js";

async function tryRead(client, address, abi, functionName) {
  try {
    const value = await client.readContract({ address, abi, functionName });
    return { supported: true, value };
  } catch (e) {
    return { supported: false, value: null, error: shortError(e) };
  }
}

function shortError(e) {
  const m = e?.shortMessage || e?.details || e?.message || String(e);
  return m.split("\n")[0].slice(0, 300);
}

// Probes with amount = 0 by default. A zero-value transfer isolates POLICY from
// BALANCE: a holder-less prober address would otherwise always revert on funds.
export async function probeTransfer(client, address, { from, to, amount = 0n }) {
  try {
    await client.simulateContract({
      address,
      abi: ERC20_ABI,
      functionName: "transfer",
      args: [to, amount],
      account: from
    });
    return classifyTransfer({ ok: true });
  } catch (e) {
    return classifyTransfer({ ok: false, reason: shortError(e) });
  }
}

export async function profileAsset(client, asset, { from, to }) {
  const address = asset.address;

  const [name, symbol, decimals, supply, paused, multiplier, balance] = await Promise.all([
    tryRead(client, address, ERC20_ABI, "name"),
    tryRead(client, address, ERC20_ABI, "symbol"),
    tryRead(client, address, ERC20_ABI, "decimals"),
    tryRead(client, address, ERC20_ABI, "totalSupply"),
    tryRead(client, address, OPTIONAL_ABI, "paused"),
    tryRead(client, address, OPTIONAL_ABI, "uiMultiplier"),
    client
      .readContract({ address, abi: ERC20_ABI, functionName: "balanceOf", args: [from] })
      .then((v) => ({ supported: true, value: v }))
      .catch((e) => ({ supported: false, value: null, error: shortError(e) }))
  ]);

  const zeroProbe = await probeTransfer(client, address, { from, to, amount: 0n });

  // If the prober holds a balance, also probe a real 1-unit move. A zero-amount
  // pass plus a one-unit fail is the signature of an amount- or state-gated rule.
  let unitProbe = null;
  if (balance.supported && balance.value > 0n) {
    unitProbe = await probeTransfer(client, address, { from, to, amount: 1n });
  }

  const block = await client.getBlockNumber();

  return {
    ticker: asset.ticker ?? symbol.value ?? null,
    address,
    name: name.value,
    symbol: symbol.value,
    decimals: decimals.value,
    totalSupply: supply.value?.toString() ?? null,
    paused: paused.supported ? paused.value : null,
    pausedSupported: paused.supported,
    uiMultiplier: multiplier.supported ? multiplier.value.toString() : null,
    uiMultiplierSupported: multiplier.supported,
    proberBalance: balance.supported ? balance.value.toString() : null,
    transfer: zeroProbe,
    transferWithValue: unitProbe,
    probeMethod: "eth_call simulation",
    coverageCaveat:
      "eth_call does not pass through the sequencer compliance engine. A pass here does not guarantee a real signed transaction is sequenced.",
    verifiedAtBlock: block.toString(),
    verifiedAt: new Date().toISOString()
  };
}
