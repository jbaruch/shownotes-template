# File Contract, Build & Publishing Requirements Checklist: Talk Page Skill Section

**Purpose**: Validate that the skill-file contract, build-time behaviour, hosting/publishing, and documentation requirements are complete, clear, consistent, and hand-over ready for the external publisher
**Created**: 2026-09-11
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [x] CHK101 - Is the convention location fully determined by the talk identifier alone, including legacy date-prefixed identifiers? [Completeness, Spec FR-001, Edge Cases]
- [x] CHK102 - Are the required metadata fields and their formats specified, including allowed characters and length for `name` given its use as the install directory? [Completeness, Spec FR-002, FR-006, Gap → resolved: slug format and 64-char limit added to FR-002]
- [x] CHK103 - Are all failure modes of the skill file enumerated with the required build outcome for each? [Completeness, Spec FR-009, FR-012, Edge Cases]
- [x] CHK104 - Does the spec require that adding or changing a skill file alone results in publication on the hosted site? [Completeness, Spec US2, Gap → resolved: new FR-018]
- [x] CHK105 - Is the raw file's "unmodified" requirement defined at the byte level? [Clarity, Spec FR-005, US1-2]

## Requirement Clarity

- [x] CHK106 - Is "stable public address" defined as derivable from the talk identifier and site address, unchanged across rebuilds? [Clarity, Spec FR-005 → resolved: wording tightened]
- [x] CHK107 - Is the install command requirement explicit that the copied text needs no manual edits (no placeholders)? [Clarity, Spec FR-006, US1-3]
- [x] CHK108 - Is "personal skills location" tied to the assistant's documented location rather than left to interpretation? [Clarity, Spec FR-006, Clarification Q1, research R5]

## Requirement Consistency

- [x] CHK109 - Are FR-009 (fail the build) and FR-012 (ignore orphans) mutually consistent about what counts as an error? [Consistency, Spec FR-009, FR-012]
- [x] CHK110 - Is the Key Entities description of `name` consistent with its use as an install directory in FR-006? [Consistency, Conflict → resolved: Key Entities updated]
- [x] CHK111 - Do FR-014/SC-003 ("existing tests unchanged") remain satisfiable once FR-017's demo skill is present in the repository? [Consistency, Spec FR-014, FR-017]

## Dependencies & Assumptions

- [x] CHK112 - Are the external publisher's obligations (location, format, required fields) captured in a hand-over-ready form? [Dependencies, Spec Assumptions, contracts/skill-file.md]
- [x] CHK113 - Is the assumption that existing sanitization suffices validated against the "nothing executes" requirement? [Assumption, Spec FR-008, research R4]
- [x] CHK114 - Is the demo content removal path specified alongside the existing demo removal instructions? [Completeness, Spec FR-017]

## Documentation

- [x] CHK115 - Are all documentation targets enumerated (location, metadata, page behaviour, malformed outcome, project-level alternative, demo removal)? [Completeness, Spec FR-013, FR-017]
- [x] CHK116 - Is local preview behaviour (rebuild on change) required to be documented? [Completeness, Gap → resolved: added to FR-013]

## Notes

- Check items off as completed: `[x]`
- Items are numbered sequentially (CHK101, CHK102, etc.)
- Every "resolved" marker corresponds to a spec edit recorded under "Checklist gap resolutions" in spec.md's Clarifications section.
