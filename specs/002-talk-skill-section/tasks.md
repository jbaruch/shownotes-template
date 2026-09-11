# Tasks: Talk Page Skill Section

**Feature**: 002-talk-skill-section
**Generated**: 2026-09-11
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Data model**: [data-model.md](./data-model.md) | **Contracts**: [contracts/](./contracts/)

**Tests**: Included. The constitution requires tests for all changes and its change process writes tests before the minimal implementation, so every story starts with its tests and they must fail before the implementation task runs.

**Organization**: Setup → Foundational (the plugin, shared by US1/US2/US4) → one phase per user story in priority order → Polish.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Paths are repository-root relative

## Phase 1: Setup

- [X] T001 Create `_skills/.gitkeep` so the convention directory exists in a clean template checkout (mirrors `_talks/.gitkeep`)
- [X] T002 [P] Add `'_skills/**'` to the `paths:` list under `on.push` in `.github/workflows/deploy.yml` (FR-018)
- [X] T003 [P] Add `'_skills/**'` to the `paths:` list under `on.push` in `.github/workflows/ci.yml`

---

## Phase 2: Foundational (Skill Processor Plugin)

*Blocking: US1, US2, and US4 all read `page.skill`; nothing renders until the plugin attaches it.*

- [X] T004 Write failing unit tests in `test/impl/unit/skill_processor_test.rb` (`require_relative '../../../_plugins/skill_processor'`, call private helpers via `send`) covering data-model.md validation rules 1–5 with the exact `Skill _skills/{stem}/SKILL.md: …` message prefixes from research.md R3, `<script>` neutralisation via `HtmlSanitizer`, heading demotion (`h1`→`h3`, `h4`→`h6`, `h5`/`h6` clamp), Unicode round-trip, `install_dir` = `~/.claude/skills/{name}`, and blank body → `html == ""`
- [X] T005 Implement `_plugins/skill_processor.rb`: `Jekyll::SkillRawFile < Jekyll::StaticFile` (`url` `/skills/{stem}/SKILL.md`, `destination` `{dest}/skills/{stem}/SKILL.md`) and `Jekyll::SkillProcessor < Jekyll::Generator` (`priority :high`) that globs `_skills/*/SKILL.md`, parses front matter with `Jekyll::Document::YAML_FRONT_MATTER_REGEXP` + `SafeYAML.load`, raises `Jekyll::Errors::FatalException` per R3, renders the body through the site markdown converter → `HtmlSanitizer#sanitize_html` (`require_relative '../lib/utils/html_sanitizer'`) → heading demotion, attaches `doc.data['skill']` per data-model.md, registers the static file, and logs orphans at `info`; T004 tests pass
- [X] T006 [P] Create the demo skill `_skills/DEMO-ai-coding-assistants-2025/SKILL.md` per contracts/skill-file.md: slug `name`, one-sentence `description`, a `# DEMO CONTENT – delete with the DEMO talks` YAML comment in the front matter, and a body with an `h1`, a list, and a fenced code block; no personal data (FR-017)

**Checkpoint**: `bundle exec ruby -Itest test/impl/unit/skill_processor_test.rb` green; `bundle exec jekyll build --config _config_test.yml` succeeds and writes `_site/skills/DEMO-ai-coding-assistants-2025/SKILL.md` byte-identical to the source.

---

## Phase 3: User Story 1 - Visitor reads and installs the talk's skill (Priority: P1) MVP

**Goal**: The DEMO skill talk renders a Skill section directly under the media row with name, description, personal-folder install command, download link, and the body in a closed disclosure; the raw file is served unchanged.

**Independent Test**: Build the real site; the DEMO skill talk page contains exactly one `.talk-skill` between `.talk-main-content` and `.talk-content` matching contracts/rendered-html.md, and `_test_site/skills/DEMO-ai-coding-assistants-2025/SKILL.md` equals the source bytes.

### Tests for User Story 1

- [ ] T007 [US1] Write failing real-site integration tests in `test/impl/integration/skill_section_test.rb` (build with `Jekyll.configuration('source' => Dir.pwd, 'destination' => File.join(Dir.pwd, '_test_site'))` like `resource_styling_test.rb`, parse with Nokogiri): exactly one `section.talk-skill[aria-labelledby=talk-skill-heading]` on the DEMO skill talk; it is the next element sibling after `section.talk-main-content` and precedes `section.talk-content`; `h2#talk-skill-heading` contains the label `Skill` and the skill name; `.talk-skill__description` text equals the front-matter description; `#talk-skill-command` text contains `mkdir -p ~/.claude/skills/{name}`, `curl -fsSL`, and `/skills/DEMO-ai-coding-assistants-2025/SKILL.md`; `a.talk-skill__raw[download]` href equals `/skills/DEMO-ai-coding-assistants-2025/SKILL.md`; `details.talk-skill__body` exists without an `open` attribute; every heading inside `.talk-skill__content` is `h3` or lower and the section has exactly one `h2`; `_test_site/skills/…/SKILL.md` is byte-identical to `_skills/…/SKILL.md`
- [ ] T008 [US1] Add a temp-site harness to `test/impl/integration/skill_section_test.rb` (`Dir.mktmpdir`, copy `_plugins/`, `_includes/skill_section.html`, `lib/utils/html_sanitizer.rb`, minimal `_layouts/default.html` + `_layouts/talk.html` that includes the section, one talk, one skill) with failing tests for: `baseurl: /sub` → raw link href and command contain `/sub/skills/{stem}/SKILL.md` (US1-4); a talk with neither slides nor video → the section is the first element after `header.talk-header` (FR-016); a skill with a blank body → no `details.talk-skill__body` but name, description, and command present (FR-003); a skill whose description contains `<b>x</b>` renders `&lt;b&gt;` in `.talk-skill__description` and no `<b>` element (FR-008; `name` cannot carry markup because of the slug rule tested in T004)

### Implementation for User Story 1

- [ ] T009 [US1] Create `_includes/skill_section.html` exactly per contracts/rendered-html.md: `include.skill` → heading with label + escaped name, escaped description, install block with `mkdir -p {{ install_dir }} && curl -fsSL {{ url | absolute_url }} -o {{ install_dir }}/SKILL.md` (values from `include.skill`, so the plugin's `install_dir` is the single source of truth), copy button with `data-copy-target`, `aria-live="polite"` status, download link via `relative_url`, `{% if include.skill.html != "" %}` around the `<details>`, and the deferred `skill-install.js` script tag
- [ ] T010 [US1] In `_layouts/talk.html`, add `{% if page.skill %}{% include skill_section.html skill=page.skill %}{% endif %}` immediately after the closing `{% endif %}` of the `talk-main-content` block and before `<section class="talk-content">` (FR-016)
- [ ] T011 [US1] Add `.talk-skill`, `.talk-skill__heading`, `.talk-skill__label`, `.talk-skill__name`, `.talk-skill__description`, `.talk-skill__install`, `.talk-skill__install-heading`, `.talk-skill__install-label`, `.talk-skill__command` (with `pre { overflow-x: auto }` and accent hard shadow), `.talk-skill__copy-status`, `.talk-skill__generic`, `.talk-skill__body`, `.talk-skill__summary` (custom marker, `:focus-visible` ring), `.talk-skill__content` rules to `assets/css/main.css` next to `.talk-resources`, using existing tokens; add `[data-theme="dark"]` overrides only where a token does not already switch (plan.md "Styles")

**Checkpoint**: T007 and T008 tests green; open `http://localhost:4000/talks/DEMO-ai-coding-assistants-2025/` in light and dark and confirm the section reads as part of the existing design.

---

## Phase 4: User Story 2 - Speaker adds a skill by dropping one file (Priority: P1)

**Goal**: Adding a valid file is the only step; talks without a skill are byte-for-byte unchanged; bad files fail the build naming the file; orphans are ignored.

**Independent Test**: The two DEMO talks without a skill have no skill markup or script; a temp-site build with a malformed skill raises naming `_skills/{stem}/SKILL.md`; a temp-site build with an orphan skill succeeds and writes nothing under `skills/`.

### Tests for User Story 2

- [ ] T012 [US2] Add failing tests to `test/impl/integration/skill_section_test.rb`: `DEMO-devops-revolution-2025` and `DEMO-kubernetes-security-2024` pages contain no element matching `.talk-skill, .skill-available, script[src*="skill-install"]` (FR-004); temp-site build with `_skills/{stem}/SKILL.md` lacking `name` raises `Jekyll::Errors::FatalException` whose message includes `_skills/{stem}/SKILL.md` and `'name'` and leaves no `_site/talks/{stem}/index.html` (FR-009); temp-site build with a valid skill whose stem has no talk succeeds and creates no `_site/skills/` directory (FR-012); temp-site build with no `_skills/` directory at all succeeds (clean template state)

### Implementation for User Story 2

- [ ] T013 [US2] Confirm the plugin's orphan and missing-directory paths from T005 satisfy T012 (adjust `_plugins/skill_processor.rb` only if a T012 test fails); run `bundle exec jekyll build --config _config_test.yml` twice, once with the demo skill and once with `_skills/` emptied, and confirm both complete with zero warnings

**Checkpoint**: T012 green; `git diff --stat -- test/` shows only new files (FR-014).

---

## Phase 5: User Story 3 - Visitor copies install instructions on a phone (Priority: P2)

**Goal**: One-tap copy with announced feedback; the command block scrolls within itself; nothing on the page scrolls sideways at 320px.

**Independent Test**: The skill page has a `button.talk-skill__copy[type=button][data-copy-target]` with `aria-describedby` pointing at the `aria-live` status; `skill-install.js` is served and only referenced from skill pages; CSS declares `overflow-x: auto` on the command `pre` and 44px minimum targets; a manual 320px pass shows no horizontal page scroll.

### Tests for User Story 3

- [ ] T014 [US3] Add failing tests to `test/impl/integration/skill_section_test.rb`: `button.talk-skill__copy` has `type="button"`, `data-copy-target="talk-skill-command"`, and `aria-describedby="talk-skill-copy-status"`; `#talk-skill-copy-status[aria-live="polite"]` exists; `script[src$="/assets/js/skill-install.js"][defer]` exists on the skill page only; `_test_site/assets/js/skill-install.js` exists; `assets/css/main.css` contains a `.talk-skill__command pre` rule with `overflow-x: auto` and a `.talk-skill__copy` rule with `min-height: 44px` and `min-width: 44px`

### Implementation for User Story 3

- [ ] T015 [US3] Create `assets/js/skill-install.js` (IIFE, `'use strict'`, matching `theme.js` style): on `DOMContentLoaded`, if `navigator.clipboard && navigator.clipboard.writeText` is falsy set `hidden` on every `[data-copy-target]` and return; else on click `writeText(target.textContent.trim())` → status `Copied to clipboard` cleared after 2000 ms; on rejection status `Copy failed. Select the command and copy it manually.` (contracts/rendered-html.md "Copy behaviour")
- [ ] T016 [US3] In `assets/css/main.css`: `.talk-skill__copy` button styles (44×44 min, accent border, `:focus-visible`), `.talk-skill__command` positioning (button top-right on wide screens), and inside the existing `@media (max-width: 768px)` and `@media (max-width: 480px)` blocks: reduce `.talk-skill` padding to `--space-4`, stack the button below the `pre`, keep `pre` scrolling internally; no transitions anywhere in the section (FR-010)
- [ ] T017 [US3] Manual verification per quickstart.md: serve with `_config_test.yml`, view the DEMO skill page at 320px, 480px, and desktop widths in light and dark, confirm no horizontal page scroll, tab to the copy button and the disclosure and operate both with the keyboard, click copy and paste the result; record the outcome in the commit message

**Checkpoint**: T014 green; manual pass recorded.

---

## Phase 6: User Story 4 - Visitor discovers that a talk has a skill (Priority: P3)

**Goal**: "Skill Available" badge immediately after the video status in the talk header and in both homepage loops, only for talks with a skill.

**Independent Test**: The DEMO skill talk header and its homepage card(s) carry `.status-badge.skill-available` right after the video badge; the other DEMO talks and their cards carry none.

### Tests for User Story 4

- [ ] T018 [US4] Add failing tests to `test/impl/integration/skill_section_test.rb`: on the DEMO skill talk page, `.talk-meta .status-badge.skill-available` exists with text `Skill Available` and its previous element sibling is the video `status-badge`; on `_test_site/index.html`, every card linking to `/talks/DEMO-ai-coding-assistants-2025/` contains `.skill-available` and cards linking to the other two DEMO talks contain none

### Implementation for User Story 4

- [ ] T019 [P] [US4] In `_layouts/talk.html` `.talk-meta`, after the video badge `{% endif %}`, add `{% if page.skill %}<span class="meta-item status-badge skill-available">Skill Available</span>{% endif %}`
- [ ] T020 [P] [US4] In `index.md`, add the same badge keyed on `talk.skill` after the video badge in both the featured-talks loop and the all-talks loop
- [ ] T021 [P] [US4] Add `.meta-item.status-badge.skill-available` (accent color, same weight/tracking as `.video-published`) and its `[data-theme="dark"]` variant to `assets/css/main.css` next to the video badge rules

**Checkpoint**: T018 green.

---

## Phase 7: Polish & Cross-Cutting

- [ ] T022 [P] Update `README.md`: new optional Quick Start step "Add a Skill" (file location, required fields, what renders) between "Add a Thumbnail" and "Deploy", and change the clean-up command to `rm _talks/DEMO-*.md && rm -rf _skills/DEMO-*` (FR-013, FR-017)
- [ ] T023 [P] Add a "Skills" section to `docs/USAGE.md` covering location, required metadata and the `name` slug rule, what the page shows, install alternatives including project-level `.claude/skills/{name}/SKILL.md`, the exact build failure messages, orphan behaviour, and local preview with `jekyll serve` (FR-013)
- [ ] T024 [P] Update `docs/TESTING.md` (list `skill_processor_test.rb` and `skill_section_test.rb` under their categories) and `docs/DEVELOPMENT.md` (add the skill processor to the talk-processing pipeline description)
- [ ] T025 [P] Create `docs/templates/sample-skill.md` as a copy-and-edit starter next to `sample-talk.md`
- [ ] T026 Run `bundle exec rake test:unit` and `bundle exec rake test:integration` and `bundle exec rake quick`; all green with no modified pre-existing test files (SC-003)
- [ ] T027 Run the quickstart.md "Verify locally" block end to end (test-config build, `grep` counts, `cmp` on the raw file, failure-mode build exits non-zero naming the file, clean-up) and confirm `bundle exec jekyll build` prints no warnings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none
- **Foundational (Phase 2)**: T005 depends on T004 (tests first); T006 is independent
- **US1 (Phase 3)**: depends on T005 and T006; T009 after T007/T008; T010 after T009; T011 after T010
- **US2 (Phase 4)**: T012 depends on T010 (absence tests need the include to exist); T013 after T012
- **US3 (Phase 5)**: builds on US1's include (the button lives in it); T014 after T010; T015/T016 after T014; T017 after T016
- **US4 (Phase 6)**: depends only on Phase 2 (`page.skill`), independent of US1; T019–T021 after T018
- **Polish (Phase 7)**: T022–T025 after Phase 2 (they document decided behaviour); T026/T027 after everything else

### Critical Path

T001 → T004 → T005 → T007 → T009 → T010 → T011 → T014 → T015 → T016 → T017 → T026 → T027 (13 tasks deep)

### Parallel Opportunities

- T002 ∥ T003 (two workflow files)
- T006 ∥ T004/T005 (fixture vs plugin)
- T007 ∥ T008 (same file, but independent test groups; write sequentially if one author)
- T019 ∥ T020 ∥ T021 (three different files)
- T022 ∥ T023 ∥ T024 ∥ T025 (four doc files)
- US4 (Phase 6) ∥ US1 (Phase 3) once Phase 2 is done

### Story Independence

- US1 and US4 are independently deliverable on top of Phase 2.
- US2 is tests-and-verification on top of Phase 2 plus US1's include (its absence tests need something to be absent).
- US3 extends US1's include; it is P2 after P1, so the dependency direction is correct.

## Implementation Strategy

**MVP** = Phase 1 + Phase 2 + Phase 3 (US1). That already delivers a working section, install command, and raw file for the DEMO talk. Phase 4 (US2) locks down the negative paths, Phase 5 (US3) adds the phone-friendly copy control, Phase 6 (US4) adds the badges, Phase 7 documents and gates.

Commit after each task or checkpoint on branch `002-talk-skill-section`.

## Notes

- [P] tasks = different files, no dependencies
- Each test task must be observed failing before its implementation task is started
- Never modify a pre-existing test file (FR-014, SC-003); if one breaks, the implementation is wrong
- No `2>/dev/null`, `|| true`, or empty rescue in any new Ruby, shell, or JS
