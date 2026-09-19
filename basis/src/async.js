// Small async helpers, kept pure enough to unit test.

// Runs tasks with a concurrency cap. Results keep input order.
// The RPC rate limits at low concurrency, so this is not optional.
export async function mapLimit(items, limit, fn) {
  const results = new Array(items.length);
  let cursor = 0;

  async function worker() {
    while (true) {
      const i = cursor++;
      if (i >= items.length) return;
      results[i] = await fn(items[i], i);
    }
  }

  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

export function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// Retries with linear backoff. Throws the last error if every attempt fails.
export async function retry(fn, { attempts = 3, delayMs = 250 } = {}) {
  let last;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      last = e;
      if (i < attempts - 1) await sleep(delayMs * (i + 1));
    }
  }
  throw last;
}
