# Embedding External Content

This platform automatically embeds supported content types as responsive iframes instead of showing them as links.

## Supported Platforms

### Google Slides
- **URL Formats**: `https://docs.google.com/presentation/d/{ID}/edit` or `/present`
- **Requirements**: Presentation must be published to web or shared publicly
- **How to make public**: 
  1. In Google Slides: File → Share → Publish to web
  2. Or: Share → Change to "Anyone with the link"
- **Embed Format**: Converts to `https://docs.google.com/presentation/d/e/{ID}/pubembed`

### YouTube Videos
- **URL Formats**: 
  - `https://www.youtube.com/watch?v={ID}`
  - `https://youtu.be/{ID}`
  - `https://m.youtube.com/watch?v={ID}`
- **Requirements**: Video must be publicly accessible (not private/unlisted)
- **Embed Format**: Converts to `https://www.youtube-nocookie.com/embed/{ID}`
- **Privacy**: Uses youtube-nocookie.com for enhanced privacy

## Features

### Security
- XSS prevention through URL validation
- HTML escaping for user-provided content
- HTTPS-only embed URLs
- Malicious URL rejection

### Responsive Design
- Mobile-friendly responsive iframes
- 16:9 aspect ratio containers
- Loading animations
- Lazy loading for performance

### Graceful Fallback
- Non-embeddable URLs display as regular links
- Broken or private URLs fall back to links
- Maintains accessibility with proper link attributes

## Usage in Jekyll

Resources are automatically processed in `_layouts/talk.html` using the `_includes/embedded_resource.html` include.

### YAML Format
```yaml
resources:
  - type: "slides"
    title: "My Presentation"
    url: "https://docs.google.com/presentation/d/1ABC123/edit"
    description: "Presentation slides"
  - type: "video"
    title: "Recording"
    url: "https://www.youtube.com/watch?v=ABC123"
    description: "Video recording"
```

### Output
- Embeddable URLs → Responsive iframes
- Non-embeddable URLs → Regular links with `target="_blank"`