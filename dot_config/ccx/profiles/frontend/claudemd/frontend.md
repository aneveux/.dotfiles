# Frontend Conventions

Generation and aesthetics are handled by the `frontend-design` plugin; chart and
palette work by the `dataviz` skill (authoritative — don't restate its color rules).
These are the always-on constraints.

## Accessibility

- Semantic HTML for structure; DOM order matches visual order. ARIA only to fill gaps
  native elements can't, never to replace them.
- Contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text and UI components. Never rely on
  color alone to convey meaning.
- Full keyboard operability with a visible focus indicator — never strip outlines. Every
  form control has an associated label.
- Honor `prefers-reduced-motion`. Layout must reflow at 320px width and 200% text zoom.

## Style

- Use design tokens / CSS custom properties — no inline styles, no hardcoded hex.
- Mobile-first; a fixed spacing scale (4px grid). Reuse existing components before adding new ones.

## Verification

- Verify UI visually (screenshot or a running build), not just by reading the code.

## Docs

- WCAG 2 (contrast, keyboard, reflow): https://www.w3.org/WAI/standards-guidelines/wcag/
- MDN Accessibility: https://developer.mozilla.org/en-US/docs/Web/Accessibility
