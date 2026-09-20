"use client";
import { useEffect, useRef } from "react";

/* Spiral field of 3D red scales receding into a vortex.
   Calls onWarp(boolean) so the foreground can blur in sync. */
export default function Field({ onWarp, className }) {
  const ref = useRef(null);
  const warpRef = useRef(onWarp);
  warpRef.current = onWarp;

  useEffect(() => {
    const cv = ref.current;
    const ctx = cv.getContext("2d", { alpha: false });
    const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;

    let W = 0, H = 0, DPR = 1, RINGS = 0, PER = 0, raf = 0, dimmed = false;

    const size = () => {
      DPR = Math.min(devicePixelRatio || 1, 2);
      W = innerWidth; H = innerHeight;
      cv.width = W * DPR; cv.height = H * DPR;
      ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
      const dense = W * H > 900000;
      RINGS = dense ? 26 : 20;
      PER = dense ? 30 : 22;
    };
    size();
    addEventListener("resize", size);

    /* light palette: paper white at the vortex, saturated red in the
       foreground. Same ramp shape, inverted lightness. */
    const RAMP = [
      [246, 245, 241], [242, 232, 228], [238, 208, 200], [232, 176, 164],
      [224, 132, 114], [214, 84, 62], [201, 46, 26], [186, 26, 10]
    ];
    const ramp = (t) => {
      const x = Math.max(0, Math.min(0.999, t)) * (RAMP.length - 1);
      const i = Math.floor(x), f = x - i;
      const a = RAMP[i], b = RAMP[i + 1] || a;
      return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f];
    };

    const CYCLE = 8200, WARP_IN = 1250, WARP_HOLD = 620, WARP_OUT = 900;
    const easeIn = (x) => x * x;
    const easeOut = (x) => 1 - Math.pow(1 - x, 3);
    const warpAt = (ms) => {
      const t = ms % CYCLE;
      if (t < WARP_IN) return 0;
      const u = t - WARP_IN;
      if (u < WARP_HOLD) return easeIn(u / WARP_HOLD);
      const v = u - WARP_HOLD;
      if (v < WARP_OUT) return 1 - easeOut(v / WARP_OUT);
      return 0;
    };

    const frame = (ms) => {
      const warp = reduce ? 0 : warpAt(ms);
      const t = reduce ? 0 : ms * 0.00006;

      if (!reduce) {
        const want = warp > 0.42;
        if (want !== dimmed) { dimmed = want; warpRef.current?.(want); }
      }

      ctx.fillStyle = "#F6F5F1";
      ctx.fillRect(0, 0, W, H);

      const cx = W * 0.34, cy = H * 0.30;
      const maxR = Math.hypot(W, H) * 0.86;

      for (let i = 0; i < RINGS; i++) {
        const d0 = (i + 1) / RINGS;
        const d = d0 * (1 - warp * 0.82);
        const r = Math.pow(d, 1.75) * maxR;

        const scale = 0.16 + Math.pow(d, 1.5) * 1.5;
        const w = 26 * scale, h = 15 * scale;

        const s = ramp(Math.pow(d0, 1.15) * (1 - warp * 0.55));
        const fill = `rgb(${s[0] | 0},${s[1] | 0},${s[2] | 0})`;
        const l = ramp(Math.max(0, Math.pow(d0, 1.05) * (1 - warp * 0.55) - 0.14));
        const hi = `rgb(${l[0] | 0},${l[1] | 0},${l[2] | 0})`;

        const alpha = Math.max(0, 1 - warp * 0.92);

        for (let j = 0; j < PER; j++) {
          const a = (j / PER) * Math.PI * 2 + i * 0.26 + t + warp * 1.5;
          const x = cx + Math.cos(a) * r * 1.28;
          const y = cy + Math.sin(a) * r * 0.92;
          if (x < -80 || x > W + 80 || y < -80 || y > H + 80) continue;

          ctx.save();
          ctx.translate(x, y);
          ctx.rotate(a + Math.PI / 2);
          ctx.globalAlpha = alpha;

          ctx.beginPath();
          ctx.ellipse(0, h * 0.34, w, h, 0, 0, Math.PI * 2);
          ctx.fillStyle = "rgba(120,60,50,.20)";
          ctx.fill();

          ctx.beginPath();
          ctx.ellipse(0, 0, w, h, 0, 0, Math.PI * 2);
          ctx.fillStyle = fill;
          ctx.fill();

          ctx.globalAlpha = alpha * 0.55;
          ctx.beginPath();
          ctx.ellipse(0, h * 0.24, w * 0.74, h * 0.48, 0, 0, Math.PI * 2);
          ctx.fillStyle = hi;
          ctx.fill();

          ctx.restore();
        }
      }

      ctx.globalAlpha = 1;
      raf = requestAnimationFrame(frame);
    };

    raf = requestAnimationFrame(frame);

    /* rAF pauses in a background tab. If it pauses mid-warp the page stays
       blurred forever, so clear the state whenever we lose the tab. */
    const onHide = () => {
      if (document.hidden) { dimmed = false; warpRef.current?.(false); }
    };
    document.addEventListener("visibilitychange", onHide);

    return () => {
      cancelAnimationFrame(raf);
      removeEventListener("resize", size);
      document.removeEventListener("visibilitychange", onHide);
    };
  }, []);

  return <canvas ref={ref} className={className} />;
}
