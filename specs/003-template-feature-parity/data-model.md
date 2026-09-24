# Data Model: Template Feature Parity

## EmbeddedResource

- `source_url`: Original talk metadata URL.
- `kind`: YouTube, Vimeo, Notist, Google Slides, Drive PDF, or fallback.
- `embed_url`: Validated and normalized player URL, when supported.
- `video_id`: Provider identifier used for preview imagery, when available.
- `preview`: Existing local thumbnail or placeholder behavior.

Invalid resources have no `embed_url` and render through the existing link fallback.

## TrustedNotistDomain

- `hostname`: Explicitly configured DNS hostname without a path.
- `origin`: Derived HTTPS origin admitted to the frame policy.

Canonical `noti.st` is built in. Custom domains are optional and empty by default.

## TalkGuideEntry

- `title`, `conference`, `date`, `talk_url`
- optional `skill_url` and skill description
- optional `recording_url`
- optional `slides_url`

Entries are derived at build time from the talks collection and ordered by extracted date descending.
