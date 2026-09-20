import { keccak_256 } from "@noble/hashes/sha3.js";

/* EIP-55: hash the lowercase address, then uppercase each hex character
   whose corresponding hash nibble is 8 or higher. Mixed case is what makes
   an address self-checking, so display it this way, never all one case. */
export function toChecksum(addr) {
  if (!/^0x[0-9a-fA-F]{40}$/.test(addr || "")) return addr;
  const lower = addr.slice(2).toLowerCase();
  const h = keccak_256(new TextEncoder().encode(lower));
  let hex = "";
  for (const b of h) hex += b.toString(16).padStart(2, "0");
  let out = "0x";
  for (let i = 0; i < 40; i++) {
    out += parseInt(hex[i], 16) >= 8 ? lower[i].toUpperCase() : lower[i];
  }
  return out;
}
