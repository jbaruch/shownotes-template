# Rendered Output Contract

## Resource iframe

- Valid supported resources render one `<iframe class="responsive-iframe">` inside the existing resource container.
- `src` is provider-normalized and contains no unrelated tracking parameters.
- Unknown, invalid, or untrusted URLs render no iframe and retain the resource link fallback.
- Preview mode renders no iframe.

## Frame policy

- `frame-src` includes YouTube, Vimeo player, Google Slides/Drive, canonical Notist, and configured custom Notist origins.
- Resource origins are not added to unrelated directives.

## Agent guide

- `/llms.txt` contains no HTML document wrapper or unresolved Liquid.
- Talks appear newest first with absolute talk URLs.
- Optional skill, recording, and slide links appear only when present.
- Shared pages contain `<link rel="describedby" ... href="{baseurl}/llms.txt">`.
