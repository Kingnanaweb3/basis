import { fileURLToPath } from "node:url";
import path from "node:path";

/* A package-lock.json in the home folder makes Next infer the wrong
   workspace root. Pin it to this app so builds are deterministic. */
const root = path.dirname(fileURLToPath(import.meta.url));

const nextConfig = { reactStrictMode: true, outputFileTracingRoot: root };
export default nextConfig;
