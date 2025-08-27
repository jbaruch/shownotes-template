# Requirements: Embed Functionality for Slides and Video

## Feature Requirements

### FR-E1: Google Slides Embedding
**Requirement**: When a resource URL contains `docs.google.com/presentation`, the system MUST render it as an embedded iframe instead of a link.

**Acceptance Criteria**:
- Google Slides sharing URLs are automatically converted to embed format
- Slides display inline without requiring navigation away from page
- Responsive sizing works on mobile and desktop devices
- Original link functionality preserved as fallback

### FR-E2: YouTube Video Embedding  
**Requirement**: When a resource URL contains `youtube.com/watch` or `youtu.be/`, the system MUST render it as an embedded video player instead of a link.

**Acceptance Criteria**:
- YouTube URLs automatically converted to embed format
- Video player displays inline with standard YouTube controls
- 16:9 aspect ratio maintained across device sizes
- Privacy-enhanced mode used for GDPR compliance

### FR-E3: Responsive Iframe Design
**Requirement**: All embedded iframes MUST be responsive and mobile-optimized.

**Acceptance Criteria**:
- Iframes scale to container width without horizontal scrolling
- Aspect ratios preserved on different screen sizes
- Touch-friendly sizing on mobile devices (minimum 44px touch targets)
- Loading performance optimized with lazy loading

### FR-E4: Fallback Link Behavior
**Requirement**: URLs that cannot be detected as embeddable MUST display as standard clickable links.

**Acceptance Criteria**:
- Non-embeddable URLs show traditional link format
- All existing accessibility attributes preserved (target="_blank", rel="noopener")
- No broken functionality for existing resource formats
- Graceful handling of malformed or edge case URLs

### FR-E5: Security Requirements
**Requirement**: All embedded content MUST be properly sanitized to prevent XSS attacks.

**Acceptance Criteria**:
- URL validation prevents malicious iframe sources
- HTML output is properly escaped
- CSP compatibility maintained
- No user-controlled HTML injection possible

## Technical Specifications

### TS-E1: URL Pattern Detection
```ruby
# Google Slides detection
url.match?(/docs\.google\.com\/presentation/)

# YouTube detection  
url.match?(/(?:youtube\.com\/watch\?v=|youtu\.be\/)/)
```

### TS-E2: Iframe Generation
```html
<!-- Google Slides Template -->
<div class="embed-container slides-embed">
  <iframe src="[EMBED_URL]" 
          frameborder="0" 
          allowfullscreen="true"
          loading="lazy"
          class="responsive-iframe">
  </iframe>
</div>

<!-- YouTube Video Template -->  
<div class="embed-container video-embed">
  <iframe src="[EMBED_URL]" 
          frameborder="0"
          allowfullscreen
          loading="lazy"
          class="responsive-iframe">
  </iframe>
</div>
```

### TS-E3: CSS Responsive Design
```css
.embed-container {
  position: relative;
  width: 100%;
  margin: 1rem 0;
}

.video-embed {
  aspect-ratio: 16 / 9;
}

.responsive-iframe {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
}
```

## Integration Requirements

### IR-E1: TalkRenderer Integration
**Requirement**: Embed functionality MUST integrate seamlessly with existing `TalkRenderer#generate_resources_html` method.

**Acceptance Criteria**:
- No breaking changes to existing resource formats
- Hash and array resource formats both supported
- Resource grouping and styling preserved
- Method signature and return type unchanged

### IR-E2: URL Conversion Logic
**Requirement**: System MUST convert sharing URLs to proper embed URLs.

**URL Conversions**:
```ruby
# Google Slides: Extract presentation ID and convert to embed format
"https://docs.google.com/presentation/d/1ABC123/edit#slide=id.p1"
# Converts to:
"https://docs.google.com/presentation/d/e/1ABC123/pubembed?start=false&loop=false&delayms=3000"

# YouTube: Extract video ID and use privacy-enhanced embed
"https://www.youtube.com/watch?v=dQw4w9WgXcQ"
# Converts to:  
"https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
```

## Quality Requirements

### QR-E1: Performance
- Embed detection adds < 5ms to page generation time
- Lazy loading prevents impact on initial page load
- No external API calls during rendering

### QR-E2: Compatibility  
- Works with all modern browsers (Chrome, Firefox, Safari, Edge)
- Graceful degradation for older browsers
- No JavaScript dependencies for core functionality

### QR-E3: Accessibility
- Proper iframe titles for screen readers
- Keyboard navigation support maintained  
- ARIA labels where appropriate
- Color contrast requirements met