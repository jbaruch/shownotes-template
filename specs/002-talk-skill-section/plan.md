# Implementation Plan: Talk Page Skill Section

**Branch**: `002-talk-skill-section` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-talk-skill-section/spec.md`

## Summary

Let a talk ship an agent skill. A `SKILL.md` dropped at `_skills/{talk-stem}/SKILL.md` is discovered at build time by a new generator plugin, validated (fail the build on bad metadata), rendered and sanitized, attached to the talk document as `page.skill`, and served verbatim at `/skills/{talk-stem}/SKILL.md`. The talk layout renders a Skill section directly under the slides/video row (name, description, one copy-paste install command for the personal Claude Code skills folder, a download link, and the body in a closed disclosure), plus a "Skill Available" badge in the talk header and homepage cards. No file, no section, no badge, byte-identical pages. Skill generation stays in the speaker's publishing tooling.

## Technical Context

**Language/Version**: Ruby 3.4.5 (Jekyll plugin), Liquid templates, HTML5, CSS3 custom properties, vanilla JavaScript (ES5-compatible IIFE, matching `theme.js`)
**Primary Dependencies**: Jekyll 4.4.1, kramdown (GFM input) + rouge, existing `lib/utils/html_sanitizer.rb`; no new gems
**Storage**: Files. Source `_skills/{stem}/SKILL.md`; output `_site/skills/{stem}/SKILL.md`; build-time Hash on the talk document
**Testing**: Minitest + Nokogiri; real-site build pattern (`resource_styling_test.rb`), temp-site pattern (`jekyll_build_test.rb`), plugin unit pattern (`markdown_parser_test.rb`)
**Target Platform**: Static site on GitHub Pages, built by GitHub Actions with `bundle exec jekyll build` (custom plugins allowed); mobile-first, light/dark themes
**Project Type**: Static site generator (Jekyll) with Ruby plugins
**Performance Goals**: Zero additional requests on talks without a skill; one deferred ~1 KB script on talks with one; no measurable build-time change (one file read per skill)
**Constraints**: Existing CSP unchanged (`script-src 'self' 'unsafe-inline'`), WCAG 2.1 AA, no build-time JS toolchain, no `_config.yml` changes required for template users, no warnings during build
**Scale/Scope**: At most one skill per talk; tens of talks per site; 1 plugin, 1 include, 1 JS file, 2 layouts/pages touched, 1 CSS file, 2 workflow files, 4 docs, 1 demo skill, 2 test files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

CONSTITUTION GATE ACTIVE — constitution v1.0.0, 12 enforcement lines extracted (quality standards before release; template-wide changes; optional or universal features; WCAG mandatory; tests for all changes; tests pass before merge; resource links validated; build completes without warnings; PRs verify principles; complexity justified against Simplicity; design justified against Authentic Design).

| Principle | Status | Implementation Approach |
|-----------|--------|------------------------|
| I. Quality-First | ✓ PASS | Malformed skill files fail the build with the file path (never a silent fallback); real-site integration tests cover DOM, position, badges, raw-file byte identity; existing tests untouched (SC-003) |
| II. Simplicity | ✓ PASS | One single-purpose plugin file, one include, native `<details>` (no accordion JS), one small feature-detected script, no new gems, no config keys. The only shared code is a `require_relative` to the existing sanitizer instead of a second regex |
| III. User-Focused | ✓ PASS | Drop one file, rebuild, done (mirrors thumbnails). Section sits where agentic visitors want it (Q3). Copy button for phones; command block scrolls inside itself, page never scrolls sideways |
| IV. Template Integrity | ✓ PASS | `_skills/` is invisible to Jekyll without configuration; URLs derive from `site.url`/`baseurl`; demo skill is marked DEMO and removed with the DEMO talks; no personal data in any new file |
| V. Authentic Design | ✓ PASS | Section reuses the site's brutalist tokens (2px borders, hard shadows, Space Grotesk display heading) so it reads as one system; the install command is styled as the page's one "do this" moment, not a generic code card |

**All gates passed. Proceeding with planning.** Post-design re-check: see "Constitution Check (Post-Design)" at the end.

## Project Structure

### Documentation (this feature)

```text
specs/002-talk-skill-section/
  spec.md              # Feature specification (clarified 2026-09-11)
  plan.md              # This file
  research.md          # Phase 0: decisions R1–R10 with spike evidence
  data-model.md        # Phase 1: SkillFile, Skill, RawSkillFile, InstallInstruction, states, validation
  contracts/
    skill-file.md      # File format, location, build behaviour, served address
    rendered-html.md   # DOM contract for section, badges, copy behaviour, CSS hooks
  quickstart.md        # Implementation order and local verification commands
  checklists/
    requirements.md    # Spec quality checklist (done)
  tasks.md             # Phase 2 output (/speckit-05-tasks — NOT created by this plan)
```

### Source Code (repository root)

```text
_plugins/
  markdown_parser.rb          # existing, unchanged
  skill_processor.rb          # NEW: SkillRawFile (StaticFile subclass) + SkillProcessor (Generator)

_skills/                      # NEW convention directory (invisible to Jekyll's reader)
  DEMO-ai-coding-assistants-2025/
    SKILL.md                  # NEW: demo skill for the DEMO talk of the same stem

_includes/
  skill_section.html          # NEW: Skill section markup per contracts/rendered-html.md

_layouts/
  talk.html                   # MODIFY: badge in header; include section after talk-main-content

index.md                      # MODIFY: badge in both talk loops

assets/
  css/main.css                # MODIFY: .talk-skill* rules, .skill-available badge, mobile rules
  js/skill-install.js         # NEW: clipboard progressive enhancement

lib/utils/html_sanitizer.rb   # existing, reused via require_relative (unchanged)

.github/workflows/
  deploy.yml                  # MODIFY: add _skills/** to paths
  ci.yml                      # MODIFY: add _skills/** to paths

docs/
  USAGE.md                    # MODIFY: "Skills" section
  TESTING.md                  # MODIFY: new test files
  DEVELOPMENT.md              # MODIFY: pipeline mention
  templates/sample-skill.md   # NEW: starter file next to sample-talk.md
README.md                     # MODIFY: Quick Start step + clean-up command

test/impl/unit/skill_processor_test.rb          # NEW: validation, sanitizing, demotion
test/impl/integration/skill_section_test.rb     # NEW: real-site DOM/raw-file/badges; temp-site failure + orphan
```

**Structure Decision**: Enhance the existing Jekyll structure. One new convention directory (`_skills/`, underscore-prefixed so the reader ignores it like `_plugins`), one new plugin, one new include, one new script. No new gems, no config keys, no changes to `markdown_parser.rb`.

## Design

### Build pipeline (per skill file)

```text
_skills/{stem}/SKILL.md
   │ read (utf-8)
   ▼
front matter split ──✗──▶ FatalException "Skill _skills/{stem}/SKILL.md: missing front matter (file must start with ---)"
   │
   ▼
SafeYAML.load ──✗──▶ FatalException "...: front matter is not valid YAML: {error}"
   │
   ▼
validate name/description ──✗──▶ FatalException "...: missing required field 'name'" | "...'description'" | "...'name' must be lowercase letters, digits and hyphens (used as the install directory)"
   │
   ▼
find talk doc by stem ──none──▶ Jekyll.logger.info "SkillProcessor:", "orphan skill _skills/{stem}/SKILL.md has no talk; skipped"
   │
   ▼
render body: site markdown converter → HtmlSanitizer#sanitize_html → demote h1–h4 by two levels
   │
   ▼
doc.data['skill'] = {name, description, html, url, source_path, install_dir}
site.static_files << SkillRawFile (url /skills/{stem}/SKILL.md, destination {dest}/skills/{stem}/SKILL.md)
```

Generator priority `:high` (runs after `MarkdownTalkProcessor` at `:highest`, before rendering). Logging at `info` only: the constitution forbids warnings in a clean build, and an orphan is a legitimate intermediate state (skill dropped before the talk page exists).

### Templates

- `talk.html` header: after the video badge block, `{% if page.skill %}<span class="meta-item status-badge skill-available">Skill Available</span>{% endif %}`.
- `talk.html` body: after the `talk-main-content` section (outside its `{% if %}`), `{% if page.skill %}{% include skill_section.html skill=page.skill %}{% endif %}`. With no slides and no video the section is therefore the first thing after the header (FR-016).
- `index.md`: same badge in the featured loop and the all-talks loop, keyed on `talk.skill`.
- `skill_section.html`: exact markup in [contracts/rendered-html.md](./contracts/rendered-html.md). The `<details>` block is wrapped in `{% if include.skill.html != "" %}` so a metadata-only skill renders without an empty disclosure (FR-003). Install command uses `include.skill.url | absolute_url`; download link uses `| relative_url`. Script tag is emitted by the include so it exists only on skill pages.

### Styles

- `.talk-skill`: surface background, 2px border, `--space-8` padding, `--shadow-md`; margin matches `.talk-main-content` spacing so it slots into the rhythm.
- `.talk-skill__heading`: display font, `--font-size-xl`, bottom rule like `.media-item h2`; label rendered as an uppercase `--font-size-xs` kicker before the name.
- `.talk-skill__command`: `pre` with `overflow-x: auto`, monospace, `--color-surface-elevated` background, hard shadow in the accent color (this is the page's single call-to-action); button absolutely positioned top-right on wide screens, stacked below the `pre` under 480px; `min-width/min-height: 44px`.
- `.talk-skill__summary`: cursor pointer, custom marker via `::before`, focus ring per existing `:focus-visible` rule.
- `.status-badge.skill-available`: accent color text, same weight/tracking as `.video-published`; dark theme uses `--color-accent-light` (already redefined for dark).
- Mobile: inside the existing `@media (max-width: 768px)` block, reduce padding to `--space-4` and let the button wrap; verified down to 320px (FR-010).
- Motion: none. No transitions on the disclosure or the copy status, so the existing `prefers-reduced-motion` rule has nothing to override (FR-010).

### Script (`assets/js/skill-install.js`)

IIFE. On `DOMContentLoaded`: if `!(navigator.clipboard && navigator.clipboard.writeText)` set `hidden` on every `[data-copy-target]` and return. Else for each button: on click, `writeText(target.textContent.trim())` → status text "Copied to clipboard", `setTimeout` clear after 2000 ms; on rejection → "Copy failed. Select the command and copy it manually." No global state, no dependencies.

### Tests

| File | What it proves |
|---|---|
| `test/impl/unit/skill_processor_test.rb` | Each validation rule raises with the source path in the message; valid file parses; `<script>` neutralised; headings demoted (`h1`→`h3`, `h5`→`h6`); Unicode preserved; `install_dir` derived from `name` |
| `test/impl/integration/skill_section_test.rb` (real site) | DEMO talk page has exactly one `.talk-skill`, located after `.talk-main-content` and before `.talk-content`; heading text/order; `details` closed; button and `aria-live` present; download link `href` equals raw URL; command contains `~/.claude/skills/{name}` and the raw URL; header badge present; other DEMO pages have no `.talk-skill`, no `skill-available`, no `skill-install.js`; homepage cards show the badge only for the skill talk; `_test_site/skills/{stem}/SKILL.md` byte-identical to source; CSS contains the `.talk-skill__command pre { overflow-x: auto }` rule |
| same file (temp site) | Copy `_plugins/` + minimal layouts into `Dir.mktmpdir`; malformed skill → `Jekyll::Errors::FatalException` message includes `_skills/{stem}/SKILL.md`; orphan skill → build succeeds, no `_site/skills/` output |

Existing tests are not modified (SC-003, FR-014).

### Docs

- README Quick Start: new optional step "Add a Skill" between thumbnail and deploy; clean-up command becomes `rm _talks/DEMO-*.md && rm -rf _skills/DEMO-*`.
- `docs/USAGE.md`: "Skills" section (location, required fields, what renders, install alternatives incl. project-level `.claude/skills/`, failure messages, orphan behaviour, `jekyll serve` note).
- `docs/TESTING.md`: list the two new test files under their categories.
- `docs/DEVELOPMENT.md`: add the skill processor to the talk-processing pipeline description.
- `docs/templates/sample-skill.md`: starter file.

## Complexity Tracking

No constitution violations to justify. Two judgement calls recorded for reviewers:

| Choice | Why | Simpler alternative rejected because |
|--------|-----|-------------------------------------|
| Plugin `require_relative`s `lib/utils/html_sanitizer.rb` | Single source of truth for script stripping (FR-008 parity) | Duplicating the regex in the plugin creates two sanitizers to keep in sync |
| Separate `skill-install.js` file rather than inline script in the include | Matches `theme.js` convention; CSP-friendly; testable as a static asset | Inline script would be re-emitted per page and harder to lint |

## Constitution Check (Post-Design)

Re-evaluated after Phase 1 against v1.0.0:

- **Quality-First**: fail-loud validation, byte-identity test on the raw file, tests for every state in data-model.md. PASS.
- **Simplicity**: no new dependencies, no config surface, native disclosure, ~150 lines of Ruby. PASS.
- **User-Focused**: single-file drop-in, one-tap copy, section placed per the speaker's own clarification. PASS.
- **Template Integrity**: `_skills/` needs no config; URLs from site config; demo content marked and removable; live-instance port is additive except three already-diverged files (research R10). PASS.
- **Authentic Design**: tokens and rhythm of the existing brutalist system; one accent-shadowed command block as the deliberate focal point. PASS.

Validated against constitution v1.0.0.
