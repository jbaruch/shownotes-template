# Feature Specification: Talk Page Skill Section

**Feature Branch**: `002-talk-skill-section`
**Created**: 2026-09-11
**Status**: Draft
**Input**: User description: "Talk page Skill section: each talk can ship an AI-agent skill (SKILL.md with a metadata header carrying name/description plus a markdown body) distilled from the talk transcript. The skill file lives at a filename-convention path keyed by the talk page stem (like thumbnails). When present, the talk page renders a Skill section (name, description, rendered body, raw-file link, copy-paste install instructions). When absent, the section is omitted with no placeholder. Skill generation is out of scope (an external publisher drops the file). This repo owns the convention, rendering, styling, tests, docs. Must work for all template users, optional per talk, no hardcoded personal data."

## Context

A talk page today carries slides, video, abstract, and resources. This feature adds a fourth takeaway: an **agent skill** distilled from the talk, so a visitor can hand the talk's know-how to their coding assistant instead of re-watching an hour of video to reconstruct it.

The skill is a single self-describing file in the widely used SKILL.md shape: a metadata header with at least a `name` and a `description`, followed by a markdown body with the instructions. The file is produced elsewhere (the speaker's publishing tooling generates it from the transcript when the video is published). This repository only has to notice the file, show it well, and make it easy to install.

For visitors who work through a coding agent, the skill is the primary takeaway: it stands in for the resources list, and arguably for the video and slides themselves. It therefore sits directly under the media row, not at the bottom of the page.

The talk page follows an established convention for optional assets: **omit, don't placeholder**. A talk without slides shows no slides block; a talk without a video shows "Video Coming Soon" only because that state is deliberately meaningful. The skill follows the stricter form: no file, no section, no hint.

## Clarifications

### Session 2026-09-11

- Q: Where should the copy-paste Claude Code install command put the skill? -> A: The visitor's personal (user-level) skills location; the project-level variant is described in the docs as an alternative.
- Q: How should the skill's body be presented on the page? -> A: Collapsed by default behind a keyboard-operable disclosure; name, description, and install block always visible.
- Q: Where on the talk page does the Skill section go? -> A: Directly under the slides/video row, before the presentation context, abstract, and resources. For visitors who work through an agent the skill stands in for the resources (and arguably for the slides and video), so it gets top placement while the media panels keep the very top.
- Q: Should the template ship a demo skill for one of the DEMO talks? -> A: Yes, exactly one, clearly marked as demo content and removed together with the other DEMO content.
- Q: Keep the "Skill Available" header badge in scope? -> A: Yes, in scope now as a firm requirement, mirroring the existing video availability badge wherever that badge is shown.

### Checklist gap resolutions (2026-09-11)

Defaults applied while running the UX and integration requirement checklists; each is a spec addition, not a behaviour change already agreed elsewhere.

- FR-002: `name` must be a lowercase slug (letters, digits, hyphens; max 64) because it becomes the install directory and slash-command name (CHK102, CHK110).
- FR-003: disclosure is closed on every page load; a skill with an empty body renders name, description, and install block and omits the disclosure; the description is shown in full, never truncated (CHK009, CHK016, CHK017).
- FR-004: talk pages without a skill load no additional assets (CHK011, CHK020).
- FR-005: "stable" means derived only from the talk identifier and site address (CHK106).
- FR-007: a failed copy action is reported and leaves the command selectable (CHK005).
- FR-008: name and description are escaped as text (CHK018).
- FR-010: phone width means down to 320px; interactive controls have 44×44 CSS px touch targets; any motion respects reduced-motion preferences (CHK007, CHK019, CHK022).
- FR-011: headings inside the body sit below the section heading in the page outline (CHK003).
- FR-013: documentation covers local preview (CHK116).
- FR-015: the indicator sits immediately after the video status (CHK004).
- FR-018 (new): adding or changing a skill file alone must trigger publication on the hosted site (CHK104).
- SC-002 and SC-004 rewritten to be measurable (CHK013, CHK014).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visitor reads and installs the talk's skill (Priority: P1)

A developer opens a talk page after watching the video. Directly under the slides and video they find a "Skill" section showing the skill's name, a one-line description of what it does, and the skill's full instructions. They copy a single install command for their assistant, run it, and the skill is available in their next coding session. If they use an assistant the page doesn't name, they download the raw file and place it wherever their tool expects.

**Why this priority**: This is the whole point of the feature. Without the visitor being able to read and install the skill, nothing else matters.

**Independent Test**: Build the site with one talk that has a skill file at the convention location. Open that talk page. Confirm the section shows the name and description from the file's metadata, the rendered body, a working link to the raw file, and install instructions whose target address resolves to that raw file.

**Acceptance Scenarios**:

1. **Given** a talk with a skill file at the convention location, **When** a visitor opens the talk page, **Then** a "Skill" section is present showing the skill's name, description, and rendered body.
2. **Given** the Skill section is shown, **When** the visitor follows the raw-file link, **Then** they receive the skill file unchanged (same bytes as committed).
3. **Given** the Skill section is shown, **When** the visitor copies the install instructions for the named assistant and runs them, **Then** the skill file lands in that assistant's skills location without manual edits to the command.
4. **Given** the site is hosted under a sub-path (not at the domain root), **When** the visitor uses the raw-file link or the install command, **Then** the address still resolves correctly.
5. **Given** the site's theme is dark, **When** the visitor views the Skill section, **Then** text, code, links, and controls remain readable with adequate contrast, and likewise in light theme.

---

### User Story 2 - Speaker adds a skill to a talk by dropping one file (Priority: P1)

A speaker (or their publishing tooling) has a finished skill file for a talk that is already published. They place the file at the convention location keyed by the talk page's identifier, rebuild, and the Skill section appears. They edit nothing else: not the talk page, not the site configuration. Talks without a skill file are unaffected.

**Why this priority**: Zero-touch placement is what makes the feature usable by automation and by non-technical template users alike. It mirrors how thumbnails already work, so there is nothing new to learn.

**Independent Test**: Take a site with two talks, neither with a skill. Add a skill file for one of them at the convention location and rebuild. Confirm that talk now shows the Skill section, the other talk shows nothing skill-related (no heading, no empty block, no badge), and no talk page or configuration file was modified.

**Acceptance Scenarios**:

1. **Given** a published talk without a skill, **When** a correctly formed skill file is placed at the convention location and the site is rebuilt, **Then** the talk page shows the Skill section and no other file needed changing.
2. **Given** a talk with no skill file, **When** the site is built, **Then** the talk page contains no Skill section, no placeholder, and no "coming soon" indicator.
3. **Given** a skill file whose metadata is missing the name or the description, **When** the site is built, **Then** the build fails with a message naming the offending file and the missing field, and no page is published with a partial Skill section.
4. **Given** a skill file at the convention location for a talk identifier that has no talk page, **When** the site is built, **Then** the build succeeds and the orphan file is simply not shown anywhere.

---

### User Story 3 - Visitor copies install instructions on a phone (Priority: P2)

A visitor scanned the QR code from the slides and is reading the talk page on a phone during the conference. They want the skill later but don't want to fight with selecting text on a touch screen. The install block offers a one-tap copy for the command, and the block never forces the page to scroll sideways.

**Why this priority**: The site is mobile-first by constitution. A section that works only on a laptop is a section that doesn't work at the conference.

**Independent Test**: Render the talk page at phone width. Confirm the Skill section, including the install command block, fits without horizontal scrolling of the page body, and that the copy action places the exact command on the clipboard.

**Acceptance Scenarios**:

1. **Given** a talk page with a Skill section viewed at phone width, **When** the visitor scrolls the page, **Then** the page body does not scroll horizontally; only the command block itself may scroll within its own bounds.
2. **Given** the install block is visible, **When** the visitor activates the copy control by touch or keyboard, **Then** the full command is copied and the control confirms the copy in a way that is also announced to assistive technology.
3. **Given** the copy capability is unavailable in the visitor's browser context, **When** the visitor views the install block, **Then** the command remains selectable and readable as plain text.

---

### User Story 4 - Visitor discovers that a talk has a skill (Priority: P3)

A visitor browsing the talk header sees an indicator that this talk ships a skill, next to the existing "Video Available" status, so they know to scroll down for it.

**Why this priority**: In scope, but the section works without it. Discoverability is cheap and consistent with how video availability is already surfaced, and listings gain a way to tell which talks ship a skill.

**Independent Test**: Build with one talk with a skill and one without. Confirm the header and the listing entry of the first carry a skill indicator and those of the second do not.

**Acceptance Scenarios**:

1. **Given** a talk with a skill, **When** the visitor views the talk header or a talk listing, **Then** an indicator states that a skill is available, next to the video status.
2. **Given** a talk without a skill, **When** the visitor views the talk header or a talk listing, **Then** no skill indicator of any kind is present.

---

### Edge Cases

- **Malformed metadata**: header present but unparseable, or name/description empty. The build fails visibly with the file path and reason. Silent fallbacks are not acceptable (a page showing "Untitled Skill" is worse than a failed build).
- **Body contains markup or scripts**: the rendered body must be sanitized with the same protections applied to other rendered talk content. Nothing in a skill file may execute in the visitor's browser.
- **Very long body**: the name, description, and install instructions are always immediately visible; the body is collapsed by default (FR-003) so the section does not bury the rest of the page. A body of any length must expand fully; no truncation.
- **Legacy talk identifiers**: talks whose page identifier carries a date prefix use that full identifier in the convention, exactly as thumbnails do. Renaming published talks is never required.
- **Orphan skill file**: a skill file for a talk identifier with no page is ignored, not an error.
- **Sub-path hosting**: raw-file links and install commands must respect the site's configured base path.
- **Skill name differs from talk title**: expected and allowed. The skill's own name is what the section shows.
- **Non-ASCII content**: the body and metadata may contain any Unicode; it must render and download intact.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each talk MAY have at most one associated skill, located at a predictable location derived solely from the talk page's identifier. Locating the skill MUST NOT require any edit to the talk page or to site configuration.
- **FR-002**: The skill file MUST be in the SKILL.md shape: a metadata header carrying at least `name` and `description`, followed by a markdown body. `name` MUST be a lowercase slug (letters, digits, and single hyphens; at most 64 characters) because it becomes the install directory and therefore the assistant's command name. `description` MUST be non-empty text; it has no length limit and is never truncated on the page.
- **FR-003**: When a talk's skill file exists, the talk page MUST render a Skill section containing, in this order: the skill's name, its description, install instructions, and the rendered body. The body MUST sit inside a disclosure that is closed on every page load, operable by keyboard, and whose open/closed state is announced to assistive technology; name, description, and install instructions MUST be visible without expanding anything. When the body is empty, the disclosure is omitted and the rest of the section still renders.
- **FR-004**: When a talk's skill file does not exist, the talk page MUST contain no Skill section, no placeholder, no empty heading, no availability indicator, and MUST NOT load any additional asset introduced by this feature.
- **FR-005**: The Skill section MUST link to the raw skill file, served byte-for-byte unmodified at a public address derived only from the talk identifier and the site's configured address (so it does not change across rebuilds), and the link MUST resolve correctly when the site is hosted under a sub-path.
- **FR-006**: Install instructions MUST include at minimum: (a) a copy-paste command that places the skill in the visitor's personal (user-level) Claude Code skills location, and (b) a generic "download the file and place it where your assistant expects skills" path. Every address in the instructions MUST be derived from the site's configured address and the talk's identifier, never hardcoded.
- **FR-007**: The install command MUST offer a copy control that copies the exact command text. When copying is unavailable, the control is not offered and the command MUST remain readable and selectable. When a copy attempt fails, the failure MUST be reported in the same announced manner as success, and the command MUST remain selectable.
- **FR-008**: The rendered body MUST be sanitized with the same protections applied to other rendered talk content, and the name and description MUST be rendered as escaped text, never as markup; no content from a skill file may execute in the visitor's browser.
- **FR-009**: A skill file with a missing or empty `name` or `description`, or an unparseable metadata header, MUST cause the site build to fail with a message that names the file and the problem. A page MUST NOT be published with a partial or fallback Skill section.
- **FR-010**: The Skill section MUST render correctly in both light and dark themes and at phone widths down to 320px, with no horizontal scrolling of the page body; only the command block may scroll within itself. Interactive controls MUST have touch targets of at least 44×44 CSS pixels. Any motion (disclosure, copy feedback) MUST respect the visitor's reduced-motion preference.
- **FR-011**: The Skill section MUST meet the site's accessibility bar (WCAG 2.1 AA): correct heading hierarchy within the page (headings inside the skill body MUST sit below the section's own heading in the outline, whatever level the file uses), sufficient contrast, keyboard operability of every control, and assistive-technology announcements for the copy confirmation and any collapsed/expanded state.
- **FR-012**: A skill file for a talk identifier that has no talk page MUST be ignored without failing the build.
- **FR-013**: The feature MUST be documented for template users: where the file goes, the required metadata, what the page shows, what happens when the file is malformed, how to preview locally, and the project-level install alternative for visitors. Sample content MUST be free of personal data and clearly marked as demo content, matching existing demo talks.
- **FR-014**: Existing tests for talk pages without a skill MUST continue to pass unchanged; the feature MUST NOT alter the rendering of talks that have no skill.
- **FR-015**: When a talk has a skill, a "Skill Available" indicator MUST appear immediately after the existing video availability status, in every view where that status is shown (talk header and talk listings). When a talk has no skill, no indicator of any kind is present.
- **FR-016**: The Skill section MUST appear immediately after the slides/video area and before the presentation context, abstract, and resources. On talks with no slides and no video, it MUST be the first section after the header.
- **FR-017**: The template MUST ship exactly one demo skill, attached to one of the existing DEMO talks, so the Skill section is visible in a fresh checkout. The demo skill MUST be marked as demo content in the same way the DEMO talks are, MUST contain no personal data, and MUST be listed in the "delete demo content" instructions alongside the DEMO talks.
- **FR-018**: On the hosted site, adding, changing, or removing a skill file alone MUST be sufficient to trigger publication of the updated pages and raw file, with no other change required.

### Key Entities *(include if feature involves data)*

- **Talk page**: an existing published talk, identified by its page identifier (stem). Already carries title, conference, date, slides, video, abstract, resources, and an optional thumbnail resolved by convention from the same identifier.
- **Skill**: a single file associated with exactly one talk by convention. Attributes: `name` (a short lowercase slug that doubles as the install directory and command name), `description` (what the skill does and when to use it; shown in full), `body` (markdown instructions; may be empty). Also has a public raw address once published.
- **Install instruction**: a labelled, copyable recipe for one assistant, composed from the skill's public raw address and the assistant's expected skills location. The set of assistants is a small, extensible list; Claude Code and the generic download path are required.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A speaker can add a skill to an existing talk by adding exactly one file and rebuilding; zero edits to talk pages or configuration are needed.
- **SC-002**: Starting from the open talk page with a terminal available and the named assistant already installed, a visitor can get a correctly placed skill file into that assistant in under one minute using only the on-page instructions, with a single copy-and-run.
- **SC-003**: Talk pages without a skill render identically before and after this feature; the existing test suite passes without modification to those tests.
- **SC-004**: The Skill section passes automated structural accessibility checks in the feature's own tests (one section heading at the correct level, body headings below it, a labelled copy control with an announced status region, a native keyboard-operable disclosure closed by default) and a manual keyboard, contrast, and 320px-width pass in light and dark themes with no horizontal page scrolling.
- **SC-005**: 100% of malformed skill files (missing/empty name or description, unparseable header) are caught at build time with a message naming the file, before anything is published.
- **SC-006**: A new template user, following the documentation alone, can add a skill to a talk and see it rendered on the first attempt; a fresh checkout already shows one working Skill section on a DEMO talk.

## Assumptions

- The proposed convention location is a per-talk folder keyed by the talk page identifier containing the skill file (the user suggested `skills/{talk-stem}/SKILL.md`). The exact location and how the raw file is served are fixed during planning; the spec only requires that it be derived from the identifier alone.
- Install instructions target Claude Code first because it is the assistant with a documented skills directory convention that maps one-to-one onto a SKILL.md file. The on-page command installs to the personal (user-level) location; the documentation describes the project-level location as an alternative for visitors who want the skill to travel with a repository. Other assistants can be added later as further entries in the same list without changing the feature.
- Skill generation, transcript handling, and publishing to any skill registry are the publishing tooling's job and are outside this repository.
- The site's existing content sanitization is sufficient for the skill body; the body is treated exactly like resources content.

## Out of Scope

- Generating the skill from a transcript (belongs to the speaker's publishing tooling).
- Publishing the skill to any external registry or marketplace.
- More than one skill per talk, skill versioning, or changelogs.
- An index page listing all skills across talks.
- Per-assistant install instructions beyond Claude Code and the generic download path (may be added later as data, not as new behaviour).
