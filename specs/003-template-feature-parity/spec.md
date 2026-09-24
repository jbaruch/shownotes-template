# Feature Specification: Template Feature Parity

**Feature Branch**: `003-template-feature-parity`
**Created**: 2026-09-23
**Status**: Ready
**Input**: User description: "Check which reusable features from shownotes are missing in shownotes-template and port them"

## User Scenarios & Testing

### User Story 1 - Embed recordings accurately (Priority: P1)

As a visitor, I can watch supported YouTube and Vimeo recordings on the talk page, starting at the speaker-selected timestamp when one is present.

**Why this priority**: Recordings are the primary talk content and must work without sending visitors through broken or misleading embeds.

**Independent Test**: Render supported Vimeo and YouTube URL shapes and verify the iframe target, timestamp, fallback, preview, and frame policy.

**Acceptance Scenarios**:

1. **Given** a Vimeo recording URL, **When** its talk page renders, **Then** the page contains a Vimeo player with tracking parameters removed and any privacy hash retained.
2. **Given** a YouTube recording URL with a timestamp, **When** its talk page renders, **Then** the player begins at the equivalent number of seconds.
3. **Given** an invalid or lookalike media URL, **When** its talk page renders, **Then** the page uses a safe link fallback instead of an iframe.

---

### User Story 2 - Embed Notist slides safely (Priority: P2)

As a speaker, I can use canonical Notist URLs or explicitly configured custom Notist domains and have the slides appear on the talk page.

**Why this priority**: Embedded slides keep supporting material available in context, but custom domains must remain portable and explicitly trusted.

**Independent Test**: Render canonical, configured-custom-domain, unconfigured, and malformed Notist URLs and compare the iframe origins with the page frame policy.

**Acceptance Scenarios**:

1. **Given** a canonical Notist presentation URL, **When** its talk page renders, **Then** the canonical embed appears.
2. **Given** a custom Notist hostname listed in site configuration, **When** its talk page renders, **Then** its embed appears and its origin is permitted by the frame policy.
3. **Given** an unconfigured custom hostname, **When** its talk page renders, **Then** it remains a normal resource link.

---

### User Story 3 - Guide AI agents to talk sources (Priority: P3)

As a site owner, I publish one discoverable text guide that lists talks, available skills, recordings, and slides and explains how agents should choose among those sources.

**Why this priority**: The guide makes existing public content easier for agents to use accurately without changing the visitor-facing archive.

**Independent Test**: Build both root-hosted and subpath-hosted demo sites and verify the guide content, absolute resource links, ordering, optional skill section, and discovery link.

**Acceptance Scenarios**:

1. **Given** a built site, **When** an agent requests `/llms.txt`, **Then** it receives plain Markdown-style guidance and every talk is listed newest first.
2. **Given** a talk with an Agent Skill, **When** the guide renders, **Then** the skill is listed as the preferred knowledge source.
3. **Given** any page using the shared layout, **When** its head renders, **Then** it advertises the guide with a base-path-safe discovery link.

### Edge Cases

- Media URLs may contain reordered query parameters, fragments, timestamp units, tracking data, or malformed escaping.
- Vimeo URLs may use public, unlisted, channel, or player forms.
- A Notist custom-domain list may be absent or empty.
- A site may contain no skills while still containing talks.
- The site may be hosted at the domain root or under a base path.

## Requirements

### Functional Requirements

- **FR-001**: The site MUST embed valid public and unlisted Vimeo recordings and preserve required privacy hashes.
- **FR-002**: The site MUST recognize supported YouTube URL shapes and preserve valid start timestamps in seconds.
- **FR-003**: Invalid, malformed, and host-lookalike media URLs MUST NOT create third-party iframes.
- **FR-004**: The site MUST embed canonical Notist presentations.
- **FR-005**: The site MUST embed custom-domain Notist presentations only when their hostname is explicitly configured.
- **FR-006**: Every generated iframe origin MUST be allowed by the page frame policy without broadening unrelated policy directives.
- **FR-007**: Preview cards MUST remain non-iframe, linked previews with local or placeholder imagery.
- **FR-008**: The site MUST publish a generated `/llms.txt` that lists all talks newest first and includes available skill, recording, and slide links.
- **FR-009**: Pages using the shared layout MUST expose a base-path-safe discovery link to `/llms.txt`.
- **FR-010**: Changes to the guide and embed implementation MUST trigger continuous integration and deployment workflows.
- **FR-011**: User-facing configuration and behavior MUST be documented without speaker-specific defaults.
- **FR-012**: Automated tests MUST cover valid, invalid, root-hosted, and subpath-hosted behavior.

### Key Entities

- **Embedded resource**: A source URL, resource type, normalized player URL, preview behavior, and trusted origin.
- **Talk guide entry**: A talk title, conference, date, page URL, and optional skill, recording, and slide URLs.
- **Trusted Notist domain**: A site-configured hostname allowed both for URL normalization and iframe framing.

### Assumptions

- Existing talk Markdown fields and extracted metadata remain the source of truth.
- Vimeo previews use the existing placeholder because Vimeo has no equivalent to YouTube's stable static-thumbnail pattern.
- Custom Notist domains serve embeds at `/{presentation-id}/embed` over HTTPS.
- The guide is public site navigation and guidance, not a transcript retrieval service.

## Success Criteria

### Measurable Outcomes

- **SC-001**: All supported YouTube, Vimeo, and Notist URL variants in the automated compatibility matrix render the expected player URL.
- **SC-002**: All malformed, untrusted, and lookalike URLs in the security matrix render zero iframes.
- **SC-003**: Every rendered iframe origin is present only in the frame policy for both development and production builds.
- **SC-004**: Root and subpath builds each publish one guide containing 100% of rendered talks in newest-first order.
- **SC-005**: A clean template build and the complete non-external test suite pass without warnings introduced by this feature.
