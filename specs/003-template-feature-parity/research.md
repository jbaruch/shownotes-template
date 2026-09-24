# Research: Template Feature Parity

## Decisions

### Normalize URLs in a Liquid filter plugin

Parsing query strings and validating hosts in Liquid markup is error-prone. A small Ruby filter can use URI parsing, return only normalized values, and fail closed. This follows the populated site's YouTube/Notist approach while extending the same validation to Vimeo.

### Configure custom Notist domains

The populated site recognizes `speaking.gamov.io`, but a personal hostname cannot be a template default. The template accepts an optional list of trusted hostnames in `_config.yml`; canonical `noti.st` support remains automatic.

### Test CSP alongside each embed

An iframe that renders in HTML but is absent from `frame-src` is not functional in browsers. Tests compare normalized iframe origins with the rendered policy and ensure those origins do not broaden other directives. Vimeo's player origin is included as part of the port.

### Generate rather than maintain the guide index

The guide iterates over the existing talks collection and skill metadata, so it cannot drift from talk additions. `absolute_url` handles root and subpath hosting consistently.

## Alternatives Rejected

- **Copy source markup verbatim**: Rejected because it contains a personal custom domain and weak Vimeo host matching.
- **Add a JavaScript player layer**: Rejected because server-rendered iframes are simpler, faster, and already used by the template.
- **Maintain a manual talk list in `llms.txt`**: Rejected because it would become stale and duplicate collection metadata.
