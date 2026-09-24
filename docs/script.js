
(() => {
  "use strict";

  function buildStars() {
    const host = document.getElementById("stars");
    if (!host) return;
    const count = window.innerWidth < 640 ? 60 : 130;
    const frag = document.createDocumentFragment();
    for (let i = 0; i < count; i++) {
      const s = document.createElement("span");
      s.className = "star";
      const size = (Math.random() * 1.6 + 0.6).toFixed(2);
      s.style.setProperty("--s", `${size}px`);
      s.style.top = `${Math.random() * 100}%`;
      s.style.left = `${Math.random() * 100}%`;
      s.style.setProperty("--dur", `${(Math.random() * 3 + 2.5).toFixed(2)}s`);
      s.style.setProperty("--delay", `${(Math.random() * 4).toFixed(2)}s`);
      frag.appendChild(s);
    }
    host.appendChild(frag);
  }

  function initReveal() {
    const items = document.querySelectorAll(".reveal");
    if (!("IntersectionObserver" in window) || items.length === 0) {
      items.forEach((el) => el.classList.add("is-visible"));
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15, rootMargin: "0px 0px -40px 0px" }
    );
    items.forEach((el) => io.observe(el));
  }

  function initCopyButtons() {
    document.querySelectorAll("[data-copy-target]").forEach((btn) => {
      const target = document.getElementById(btn.getAttribute("data-copy-target"));
      if (!target) return;
      btn.addEventListener("click", async () => {
        const text = target.innerText.replace(/\n+$/, "");
        try {
          await navigator.clipboard.writeText(text);
        } catch (err) {
          const range = document.createRange();
          range.selectNodeContents(target);
          const sel = window.getSelection();
          sel.removeAllRanges();
          sel.addRange(range);
        }
        const original = btn.textContent;
        btn.textContent = "Copied!";
        btn.classList.add("copied");
        window.clearTimeout(btn._copyTimer);
        btn._copyTimer = window.setTimeout(() => {
          btn.textContent = original;
          btn.classList.remove("copied");
        }, 1600);
      });
    });
  }

  function initMoonToggle() {
    const toggle = document.getElementById("moonToggle");
    const statusText = document.getElementById("statusText");
    const statusPill = document.getElementById("statusPill");
    if (!toggle) return;

    let bursting = false;

    toggle.addEventListener("click", (event) => {
      if (event.isTrusted) {
        toggle.dataset.userTouched = "1";
      }

      const next = toggle.dataset.state === "active" ? "stopped" : "active";
      toggle.dataset.state = next;

      if (statusText) {
        statusText.textContent =
          next === "active" ? "Sleep prevented — Insomnim is awake" : "Sleep allowed — Insomnim is resting";
      }
      if (statusPill) {
        statusPill.setAttribute("data-hero-state", next);
      }

      if (next === "active" && !bursting) {
        bursting = true;
        toggle.classList.remove("is-bursting");
        void toggle.offsetWidth;
        toggle.classList.add("is-bursting");
        window.setTimeout(() => {
          toggle.classList.remove("is-bursting");
          bursting = false;
        }, 950);
      }
    });
  }

  function playIntro() {
    const toggle = document.getElementById("moonToggle");
    if (!toggle || !document.documentElement.classList.contains("intro-run")) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    window.setTimeout(() => {
      if (!toggle.dataset.userTouched) toggle.click();
    }, 2600);
    window.setTimeout(() => {
      if (!toggle.dataset.userTouched) toggle.click();
    }, 4300);
  }

  document.addEventListener("DOMContentLoaded", () => {
    buildStars();
    initReveal();
    initCopyButtons();
    initMoonToggle();
    playIntro();
  });
})();
