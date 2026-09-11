# Contract: Rendered HTML

**Feature**: 002-talk-skill-section
**Consumers**: `_includes/skill_section.html`, `_layouts/talk.html`, `index.md`, `assets/css/main.css`, `assets/js/skill-install.js`, integration tests.

Tests assert on these selectors and attributes, not on visual output. Class names follow the existing `block__element` pattern used by `theme-toggle`.

## Skill section (talk page)

Rendered only when `page.skill` is truthy. Position: the first child of `<article class="talk">` after `<section class="talk-main-content">` (or after `<header class="talk-header">` when the talk has neither slides nor video), and before `<section class="talk-content">`.

```html
<section class="talk-skill" aria-labelledby="talk-skill-heading">
  <h2 id="talk-skill-heading" class="talk-skill__heading">
    <span class="talk-skill__label">Skill</span>
    <span class="talk-skill__name">{name}</span>
  </h2>
  <p class="talk-skill__description">{description}</p>

  <div class="talk-skill__install">
    <h3 class="talk-skill__install-heading">Install</h3>
    <p class="talk-skill__install-label">Claude Code, personal skills folder:</p>
    <div class="talk-skill__command">
      <pre><code id="talk-skill-command">mkdir -p ~/.claude/skills/{name} &amp;&amp; curl -fsSL {absolute raw url} -o ~/.claude/skills/{name}/SKILL.md</code></pre>
      <button type="button" class="talk-skill__copy" data-copy-target="talk-skill-command" aria-describedby="talk-skill-copy-status">Copy</button>
    </div>
    <p id="talk-skill-copy-status" class="talk-skill__copy-status" aria-live="polite"></p>
    <p class="talk-skill__generic">Other assistants: <a class="talk-skill__raw" href="{relative raw url}" download>download SKILL.md</a> and place it where your assistant looks for skills.</p>
  </div>

  <details class="talk-skill__body">
    <summary class="talk-skill__summary">Show skill instructions</summary>
    <div class="talk-skill__content">{html}</div>
  </details>
</section>
<script src="{ '/assets/js/skill-install.js' | relative_url }" defer></script>
```

Invariants:
- `{name}` and `{description}` are Liquid-`escape`d. `{html}` is inserted as-is (already sanitized by the plugin).
- `{absolute raw url}` = `skill.url | absolute_url`; `{relative raw url}` = `skill.url | relative_url`.
- Headings: exactly one `h2` in the section; `h3` for Install; body headings start at `h3`.
- `<details>` has no `open` attribute in the build output.
- The copy button is present in the HTML; the script hides it (`hidden`) when `navigator.clipboard` is unavailable.
- No `talk-skill*` markup and no `skill-install.js` script tag exist on a talk page without a skill.

## Header badge (talk page)

Inside `<div class="talk-meta">`, immediately after the video status badge:

```html
<span class="meta-item status-badge skill-available">Skill Available</span>
```

Absent when `page.skill` is falsy. There is no "skill pending" state.

## Listing badge (homepage)

Same element, same position, in both homepage loops (featured cards and the all-talks list), keyed on `talk.skill`.

## Copy behaviour (`assets/js/skill-install.js`)

| Event | Result |
|---|---|
| Page load, `navigator.clipboard.writeText` available | Buttons with `data-copy-target` stay visible and get a click handler |
| Page load, clipboard unavailable | Buttons get `hidden`; command text remains selectable |
| Click, success | Status element text `Copied to clipboard`; cleared after 2 seconds |
| Click, failure | Status element text `Copy failed. Select the command and copy it manually.` |

Keyboard: the button is a native `<button>`, so Enter/Space work without extra code.

## CSS hooks

`.talk-skill`, `.talk-skill__heading`, `.talk-skill__label`, `.talk-skill__name`, `.talk-skill__description`, `.talk-skill__install`, `.talk-skill__command` (`overflow-x: auto` on the `pre`), `.talk-skill__copy` (min 44×44 target), `.talk-skill__copy-status`, `.talk-skill__body`, `.talk-skill__summary`, `.talk-skill__content`, `.status-badge.skill-available`. Dark theme via existing tokens; any explicit override lives under `[data-theme="dark"]`.
