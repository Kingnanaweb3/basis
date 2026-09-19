import { createServer } from "node:http";
import { readFileSync, existsSync } from "node:fs";
import { findAsset } from "./state.js";
import { refresh, STATE_PATH } from "./refresh.js";

const PORT = Number(process.env.PORT || 8787);

let state = null;
let loadedAt = null;

function load() {
  if (!existsSync(STATE_PATH)) return null;
  state = JSON.parse(readFileSync(STATE_PATH, "utf8"));
  loadedAt = new Date().toISOString();
  return state;
}

function send(res, code, body) {
  const payload = JSON.stringify(body, null, 2);
  res.writeHead(code, {
    "content-type": "application/json",
    "access-control-allow-origin": "*"
  });
  res.end(payload);
}

export function route(pathname, current) {
  if (pathname === "/health") {
    return [200, { ok: true, hasState: current !== null, loadedAt }];
  }
  if (current === null) {
    return [503, { error: "no state yet. run npm run refresh" }];
  }
  if (pathname === "/summary") return [200, current.summary];
  if (pathname === "/assets") return [200, { assets: current.assets }];
  if (pathname === "/affected") {
    return [200, { assets: current.assets.filter((a) => a.naivePricingSafe === false) }];
  }
  const m = pathname.match(/^\/assets\/([A-Za-z0-9._-]+)$/);
  if (m) {
    const asset = findAsset(current.assets, m[1]);
    return asset ? [200, asset] : [404, { error: "unknown ticker" }];
  }
  return [404, { error: "not found" }];
}

load();

function start() {
  createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    const [code, body] = route(pathname, state);
    send(res, code, body);
  }).listen(PORT, () => {
    console.log(`Basis API on http://localhost:${PORT}`);
    console.log(`  /health  /summary  /assets  /assets/:ticker  /affected`);
    if (!state) console.log(`\nNo ${STATE_PATH} yet. Run: npm run refresh`);
  });

  // Optional periodic refresh. Off unless BASIS_REFRESH_MINUTES is set.
  const mins = Number(process.env.BASIS_REFRESH_MINUTES || 0);
  if (mins > 0) {
    setInterval(async () => {
      try {
        await refresh();
        load();
        console.log(`refreshed at ${loadedAt}`);
      } catch (e) {
        console.error(`refresh failed: ${e.message}`);
      }
    }, mins * 60_000);
  }
}

// Only listen when run directly. Importing this module for tests must not
// start a server or the test process never exits.
if (import.meta.url === `file://${process.argv[1]}`) start();
