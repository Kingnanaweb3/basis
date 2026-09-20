export const dynamic = 'force-dynamic';
export const revalidate = 0;

const URL_ = process.env.UPSTASH_REDIS_REST_URL;
const TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;
const ADMIN_KEY = process.env.ADMIN_KEY;
const KEY = 'basis:ca';
const FALLBACK = process.env.BASIS_CA || null;

/* This header is the whole mechanism. Without no-store a CDN caches the
   response and the swap silently does nothing. Verify it with curl -sI. */
const NO_STORE = {
  'content-type': 'application/json',
  'cache-control': 'no-store, no-cache, must-revalidate, max-age=0',
  'cdn-cache-control': 'no-store',
  'vercel-cdn-cache-control': 'no-store'
};

const isAddr = (a) => typeof a === 'string' && /^0x[0-9a-fA-F]{40}$/.test(a);

async function redis(cmd) {
  if (!URL_ || !TOKEN) return null;
  const r = await fetch(URL_, {
    method: 'POST',
    headers: { authorization: `Bearer ${TOKEN}`, 'content-type': 'application/json' },
    body: JSON.stringify(cmd),
    cache: 'no-store'
  });
  if (!r.ok) return null;
  return (await r.json())?.result ?? null;
}

export async function GET() {
  let address = null;
  try { address = await redis(['GET', KEY]); } catch {}
  if (!isAddr(address)) address = isAddr(FALLBACK) ? FALLBACK : null;
  return new Response(JSON.stringify({ address, ts: Date.now() }), { headers: NO_STORE });
}

export async function POST(req) {
  if (!ADMIN_KEY || req.headers.get('x-admin-key') !== ADMIN_KEY) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: NO_STORE });
  }
  let body;
  try { body = await req.json(); }
  catch { return new Response(JSON.stringify({ error: 'bad json' }), { status: 400, headers: NO_STORE }); }

  const { address } = body || {};
  if (address === null) {
    await redis(['DEL', KEY]);
    return new Response(JSON.stringify({ cleared: true }), { headers: NO_STORE });
  }
  if (!isAddr(address)) {
    return new Response(JSON.stringify({ error: 'not an address' }), { status: 400, headers: NO_STORE });
  }
  await redis(['SET', KEY, address]);
  return new Response(JSON.stringify({ address, ok: true }), { headers: NO_STORE });
}
