# Research: Talk Page Skill Section

**Feature**: 002-talk-skill-section
**Date**: 2026-09-11

Every decision below was checked against the installed toolchain (Ruby 3.4.5, Jekyll 4.4.1, kramdown GFM) or the vendor documentation named in the entry. Where a claim was verified by running code, the entry says so.

## R1. Where the skill file lives and how the raw file is served

**Decision**: Source path `_skills/{talk-stem}/SKILL.md`. Served verbatim at `/skills/{talk-stem}/SKILL.md` (respecting `baseurl`) by a `Jekyll::StaticFile` subclass that a generator plugin registers on `site.static_files`.

**Rationale**:
- A SKILL.md must start with a `---` front-matter block. Jekyll 4.4.1's `Utils.has_yaml_header?` treats any such file as a convertible page, so anywhere the reader can see it, it would be rendered to `SKILL.html` with the header stripped. That breaks "served unchanged".
- Directories whose name starts with `_` are skipped by `EntryFilter#special?` unless registered as a collection, exactly like `_plugins` and `_data`. So `_skills/` is invisible to the reader with **zero configuration**, which matters for Template Integrity: existing forks pick the feature up by taking the plugin and layout, with no `_config.yml` edit.
- `Site#each_site_file` writes every entry in `site.static_files`; `StaticFile#write` does a byte copy. A generator can therefore add a static file for an otherwise invisible path. **Verified by spike** (scratchpad, Jekyll 4.4.1): `_skills/demo-talk/SKILL.md` was written to `_site/skills/demo-talk/SKILL.md` byte-identical, no `SKILL.html` leaked, `relative_url`/`absolute_url` honoured `baseurl: /sub`, and `jekyll-sitemap` did not list the file.
- `jekyll serve` watches `_skills/` (it is not in `exclude`), so edits rebuild during local preview.
- Mirrors `_talks/` naming, so the convention reads as one system.

**Alternatives considered**:
- `skills/{stem}/SKILL.md` (user's original example) plus `exclude: [skills]` in config. Works the same way but needs a config line in every instance and the watcher ignores excluded paths during `jekyll serve`. Rejected: configuration burden on template users.
- A `skills` collection with `output: false`. Jekyll would parse the front matter for us, but it needs `collections:` entries in `_config.yml`, `_config_test.yml`, and every fork. Rejected for the same reason.
- `assets/skills/{stem}/SKILL.md`. Still has a front-matter header, still rendered as a page. Rejected.

## R2. How the talk page learns about its skill

**Decision**: A new generator plugin `_plugins/skill_processor.rb` (`Jekyll::SkillProcessor < Generator`, `priority :high`) reads `_skills/*/SKILL.md`, validates each file, renders the body, and attaches a `skill` hash to the matching talk document's `data`. Templates test `page.skill` / `talk.skill` for truthiness exactly as they test `extracted_video` today.

**Rationale**:
- Liquid cannot check file existence; thumbnails only "work" by convention because a broken `<img>` falls back via `onerror`. A raw-file link and an install command cannot fail softly, so the decision has to be made at build time in Ruby.
- Matching by talk stem (`File.basename(doc.path, '.md')`) is the same key the thumbnail convention uses (`talk.path | split: '/' | last | replace: '.md', ''`), including legacy date-prefixed stems.
- Keeping this in a separate plugin file rather than extending `markdown_parser.rb` keeps each plugin single-purpose and lets `markdown_parser.rb` stay byte-identical (SC-003: talks without a skill render exactly as before).

**Alternatives considered**:
- Extending `MarkdownTalkProcessor`. Rejected: mixes two concerns and forces a change to a file the live instance has already diverged on.
- A Liquid tag/filter that reads the file at render time. Rejected: validation would run per page render, and failing the build from inside a render is uglier than failing from a generator.

## R3. Front-matter parsing and validation

**Decision**: Parse with `Jekyll::Document::YAML_FRONT_MATTER_REGEXP` and `SafeYAML.load` (the same primitives Jekyll uses for documents). Validation rules, each raising `Jekyll::Errors::FatalException` whose message begins with the source path:

| Check | Failure message (prefix `Skill _skills/{stem}/SKILL.md:`) |
|---|---|
| Front-matter block present | `missing front matter (file must start with ---)` |
| Front matter parses as a mapping | `front matter is not valid YAML: {yaml error}` |
| `name` is a non-empty string | `missing required field 'name'` |
| `description` is a non-empty string | `missing required field 'description'` |
| `name` is a shell-safe slug `^[a-z0-9]+(-[a-z0-9]+)*$`, max 64 chars | `'name' must be lowercase letters, digits and hyphens (used as the install directory)` |

**Rationale**:
- `FatalException` aborts `jekyll build` with a non-zero exit and prints the message; inside tests `Site#process` raises it, so both paths are testable (FR-009, SC-005).
- The Claude Code documentation (`https://code.claude.com/docs/en/skills.md`, checked 2026-09-11) says only the `---` markers are required and `name` is a display label; **the directory name becomes the slash command**. Our install command creates that directory from `name`, so `name` must be a safe path segment with no quoting. The slug rule is stricter than Claude Code requires, deliberately: it guarantees the copy-paste command needs no escaping and produces a clean `/command`.
- Validation is fail-loud by project rule: an "Untitled Skill" fallback would ship a broken page silently.

**Alternatives considered**:
- Deriving the install directory from the talk stem instead of `name`. Rejected: stems like `DEMO-ai-coding-assistants-2025` or legacy `2025-06-12-devoxx-...` make poor command names, and the skill's own name is what the visitor sees on the page.
- Warning instead of failing on bad metadata. Rejected: constitution says builds complete without warnings, and the user's rules forbid silent error swallowing.

## R4. Rendering and sanitizing the body

**Decision**: Render the markdown body in the plugin with `site.find_converter_instance(Jekyll::Converters::Markdown)` (the same converter `markdownify` uses, so kramdown GFM settings from `_config.yml` apply), then pass the HTML through the existing `HtmlSanitizer#sanitize_html` from `lib/utils/html_sanitizer.rb` (`require_relative` from the plugin), then demote headings by two levels (`h1`→`h3` … `h4`→`h6`, `h5`/`h6` clamp to `h6`). Store the result as `skill.html`; the layout outputs it without further filters.

**Rationale**:
- FR-008 asks for "the same protections applied to other rendered talk content". `HtmlSanitizer` is the project's single source of truth for that (it neutralises `<script>` blocks, leaving a visible `[removed]` marker). Reusing it beats a second regex. **Verified by spike**: a `<script>alert(1)</script>` in the body did not survive rendering.
- kramdown passes raw HTML through and the site's CSP allows inline scripts, so without stripping, a script in a skill body **would** execute. The sanitizer closes that.
- Heading demotion keeps the page's outline valid for assistive technology: `h1` talk title → `h2` "Skill" section → `h3` install/body headings (FR-011). A skill body conventionally starts with an `h1`.
- Rendering in the plugin (not `markdownify` in Liquid) is what makes the sanitizer reachable; it also means the rendered HTML is available to tests through `doc.data['skill']['html']`.

**Alternatives considered**:
- `{{ page.skill.body | markdownify }}` in Liquid. Simplest, but no sanitizer hook and no heading demotion. Rejected.
- A full HTML sanitizer gem (Sanitize/Loofah). Rejected: new dependency for a file the site owner authors; parity with existing content is the requirement, not a new trust boundary.

## R5. Install instructions

**Decision** (revised mid-implementation on the speaker's prompt): one universal copy-paste command using the open Agent Skills CLI, personal scope:

```bash
npx skills add {site.url}{baseurl}/skills/{stem}/SKILL.md -g
```

Fallback for visitors without Node.js: a `download`-attributed link to the raw file plus the layout to place it in, `{name}/SKILL.md` inside the agent's skills folder, with Claude Code's `~/.claude/skills/{name}/SKILL.md` as the worked example. Docs mention dropping `-g` for project scope.

**Evidence**:
- Agent Skills is an open specification (`https://agentskills.io/specification`, read 2026-09-11): `name` is 1–64 lowercase alphanumerics and hyphens, no leading/trailing/consecutive hyphens, and must match the parent directory name; `description` is 1–1024 characters. Our validation now matches both rules exactly. The spec defines the format, not an install location; each agent scans its own well-known directories.
- The `npx skills` CLI (`https://github.com/vercel-labs/skills`, README read 2026-09-11) accepts direct download URLs to a SKILL.md, installs into every supported agent it detects (75+ listed, including Claude Code, Codex, Cursor, Gemini CLI, Copilot, OpenCode), and `-g` selects the user directory over the project directory.
- **Verified empirically**: against the local test build, `HOME=<throwaway> npx skills add http://127.0.0.1:4001/skills/DEMO-ai-coding-assistants-2025/SKILL.md -g -y -a claude-code` installed `~/.agents/skills/evaluate-ai-assistant-claims` and copied it to `~/.claude/skills/evaluate-ai-assistant-claims/SKILL.md`, byte-identical to the served file. The directory name came from the `name` field, so the command never needs the name.

**Rationale**:
- One command that works for every supporting agent beats one command that works for one agent plus a "figure out your own path" sentence. Personal scope (`-g`) keeps clarification Q1's intent.
- The Claude Code fallback path is kept because it is verified (`https://code.claude.com/docs/en/skills.md`, 2026-09-11: personal skills at `~/.claude/skills/<dir>/SKILL.md`, project skills at `.claude/skills/<dir>/SKILL.md`, picked up within the running session).
- The absolute URL is built with `absolute_url`, so it is derived from `site.url` + `site.baseurl` (FR-006: nothing hardcoded). Under `jekyll serve`, Jekyll substitutes the local server address, which is why the empirical test above worked against localhost.

**Alternatives considered**:
- `mkdir -p ~/.claude/skills/{name} && curl -fsSL {url} -o …` as the primary (the original plan). Correct for Claude Code only; demoted to the worked example in the fallback sentence.
- Two copyable commands (CLI + curl). Rejected: doubles the install block on a phone (clarification Q1 reasoning still applies).
- A per-agent path picker. Rejected: the CLI already knows the paths; a picker would duplicate its table and drift.

## R6. Copy control and disclosure

**Decision**:
- Body disclosure: native `<details>`/`<summary>`, closed by default. No script needed; keyboard operable; open/closed state is exposed to assistive technology by the browser.
- Copy control: a `<button type="button">` next to the command, wired by a small progressive-enhancement script `assets/js/skill-install.js` loaded (deferred) only from the skill include. It uses `navigator.clipboard.writeText`; when the API is unavailable (insecure context, old browser) the script hides the button and the `<pre><code>` block stays selectable. Success/failure text goes into an `aria-live="polite"` status element and clears after a short delay.

**Rationale**:
- Matches the site's existing JS posture (`theme.js`: vanilla, IIFE, feature-detected, no framework). CSP already permits `script-src 'self'`.
- The clipboard API requires a secure context; GitHub Pages is HTTPS and `localhost` counts as secure, so the hide-when-unavailable path is a true edge case, not the common case.
- Native disclosure avoids ARIA re-implementation and satisfies "operable by keyboard, state announced" with zero code.

**Alternatives considered**:
- `document.execCommand('copy')` fallback. Rejected: deprecated, and the spec explicitly allows "remains selectable" as the fallback.
- A JS-driven accordion. Rejected: native element does it better.

## R7. Tests

**Decision**: Follow the two patterns already in the suite.
- **Unit** (`test/impl/unit/skill_processor_test.rb`): `require_relative '../../../_plugins/skill_processor'`, call private helpers via `send`, cover every validation row in R3, script stripping, heading demotion, Unicode round-trip.
- **Integration, real site** (`test/impl/integration/skill_section_test.rb`): build the repository with `Jekyll.configuration('source' => Dir.pwd, 'destination' => '_test_site')` like `resource_styling_test.rb`, then assert the DOM contract on the DEMO talk that ships a skill, the absence of any skill markup on the other DEMO talks and on their homepage cards, the raw file's byte identity at `_test_site/skills/{stem}/SKILL.md`, and section position.
- **Integration, temp site** (same file): build a `Dir.mktmpdir` site that copies `_plugins/` and a minimal layout to prove a malformed skill raises `Jekyll::Errors::FatalException` naming the file, and an orphan skill neither fails the build nor produces output.

**Rationale**: `jekyll_build_test.rb` builds a synthetic site with its own layouts, and the a11y/security unit tests render through `SimpleTalkRenderer`; neither touches the real plugin or `talk.html`. The real-site pattern is the only one that exercises what ships. `_test_site/` is already git-ignored.

## R8. Deployment triggers

**Decision**: Add `_skills/**` to the `paths:` filters of `.github/workflows/deploy.yml` and `.github/workflows/ci.yml`.

**Rationale**: Both workflows are path-filtered. Without the entry, dropping a skill file (the whole point of US2) would not deploy. This is the one non-obvious operational gap the thumbnail convention never had, because thumbnails live under `assets/**`, which is already listed.

## R9. Demo content

**Decision**: Ship `_skills/DEMO-ai-coding-assistants-2025/SKILL.md`, a self-contained demo skill for the existing DEMO talk of the same stem, with a `# DEMO CONTENT` YAML comment in the front matter and no personal data. README's clean-up step becomes `rm _talks/DEMO-*.md && rm -rf _skills/DEMO-*`. A `docs/templates/sample-skill.md` sits next to `sample-talk.md`.

**Rationale**: Clarification Q4; one working example is the fastest documentation and the fixture the real-site tests need.

## R10. Live-instance divergence (noted, not solved here)

The production instance at `~/Projects/shownotes` has diverged from this template in `_plugins/markdown_parser.rb`, `_layouts/talk.html`, `_includes/embedded_resource.html`, and `assets/css/main.css`. This feature touches `talk.html`, `index.md`, and `main.css`, so porting to the instance is a follow-up merge, not a copy. The new plugin, include, JS, and `_skills/` directory are additive and copy cleanly. The speaker-toolkit publisher change (generate the skill from the transcript and drop it at the convention path) is a separate feature in that repository.
