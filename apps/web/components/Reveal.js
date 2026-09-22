"use client";
import { useEffect } from "react";

/* Two-way: elements animate in as they enter and back out as they leave,
   in both scroll directions. */
export default function Reveal() {
  useEffect(() => {
    const els = document.querySelectorAll(".r");
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) {
      els.forEach((el) => el.classList.add("in"));
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) e.target.classList.toggle("in", e.isIntersecting);
      },
      { rootMargin: "-8% 0px -8% 0px", threshold: 0.12 }
    );
    els.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);
  return null;
}
