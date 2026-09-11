# UX & Accessibility Requirements Checklist: Talk Page Skill Section

**Purpose**: Validate that the UX, accessibility, responsiveness, and theming requirements are complete, clear, consistent, and measurable before task generation
**Created**: 2026-09-11
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [x] CHK001 - Are the contents and their order inside the Skill section fully enumerated? [Completeness, Spec FR-003]
- [x] CHK002 - Is the section's position defined relative to every other page region, including the case with neither slides nor video? [Completeness, Spec FR-016]
- [x] CHK003 - Are requirements defined for headings inside the skill body relative to the page's heading outline? [Completeness, Gap → resolved: FR-011 now requires body headings to sit below the section heading]
- [x] CHK004 - Is the indicator's position relative to the video status specified for each view where it appears? [Clarity, Spec FR-015, US4 → resolved: "immediately after"]
- [x] CHK005 - Are all states of the copy control specified (available, unavailable, success, failure)? [Completeness, Spec FR-007, US3 → resolved: failure state added to FR-007]

## Requirement Clarity

- [x] CHK006 - Is "adequate contrast" tied to a measurable threshold? [Clarity, Spec US1-5, FR-011 (WCAG 2.1 AA)]
- [x] CHK007 - Is "phone width" quantified? [Clarity, Spec FR-010, SC-004 → resolved: 320px minimum, matching the existing responsive test standard]
- [x] CHK008 - Is the copy confirmation requirement specific about what is announced and to whom? [Clarity, Spec US3-2, FR-011]
- [x] CHK009 - Is "closed by default" unambiguous about persistence (no remembered open state across page loads)? [Clarity, Spec FR-003 → resolved: "on every page load"]

## Requirement Consistency

- [x] CHK010 - Are the FR-003 disclosure requirements consistent with the "Very long body" edge case (no truncation)? [Consistency, Spec FR-003, Edge Cases]
- [x] CHK011 - Is the "omit, don't placeholder" rule applied consistently to the section, the indicator, and any page assets the feature introduces? [Consistency, Spec FR-004, FR-015, SC-003 → resolved: FR-004 now also forbids extra assets on skill-less pages]
- [x] CHK012 - Are theme requirements consistent with the site's existing light/dark/system mechanism? [Consistency, Spec FR-010, US1-5]

## Acceptance Criteria Quality

- [x] CHK013 - Can SC-004 be objectively verified given which accessibility checks actually exist in the project? [Measurability, Spec SC-004, Ambiguity → resolved: SC-004 rewritten to name the structural checks and a manual pass]
- [x] CHK014 - Is SC-002's "under one minute" bounded by a defined starting state? [Measurability, Spec SC-002 → resolved: starting state added]
- [x] CHK015 - Do US1 scenarios cover both the raw-file link and the install command under sub-path hosting? [Coverage, Spec US1-4]

## Scenario & Edge Case Coverage

- [x] CHK016 - Is behaviour specified for a skill file with valid metadata but an empty body? [Edge Case, Gap → resolved: disclosure omitted, rest renders]
- [x] CHK017 - Is behaviour specified for a very long description? [Edge Case, Gap → resolved: shown in full, never truncated]
- [x] CHK018 - Are protection requirements defined for the name and description text, not only the body? [Edge Case, Spec FR-008, Gap → resolved: name and description are escaped]
- [x] CHK019 - Is the stance on motion defined for the disclosure and copy feedback (respecting reduced-motion preferences)? [Edge Case, Gap → resolved: added to FR-010]

## Non-Functional Requirements

- [x] CHK020 - Are performance requirements stated for talks without a skill and for talks with one? [NFR, Spec SC-003, FR-004 → resolved: no additional assets on skill-less pages]
- [x] CHK021 - Are keyboard requirements defined for every interactive element introduced (disclosure, copy control, links)? [Coverage, Spec FR-011]
- [x] CHK022 - Are requirements defined for the interactive elements' touch-target size on phones? [Coverage, Spec US3, Gap → resolved: 44×44 CSS px minimum, matching the existing responsive test standard]

## Notes

- Check items off as completed: `[x]`
- Items are numbered sequentially (CHK001, CHK002, etc.)
- Every "resolved" marker corresponds to a spec edit recorded under "Checklist gap resolutions" in spec.md's Clarifications section.
