"use client";
import { useEffect } from "react";

/* One observer for the whole page. Elements marked .r rise and fade in once,
   then stop being observed. Section-level, not per card in a grid, except
   where a grid's children are genuinely sequential. */
export default function Reveal() {
  useEffect(() => {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) {
      document.querySelectorAll(".r").forEach((el) => el.classList.add("in"));
      return;
    }

    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add("in");
            io.unobserve(e.target);
          }
        }
      },
      { rootMargin: "0px 0px -12% 0px", threshold: 0.08 }
    );

    document.querySelectorAll(".r").forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  return null;
}
