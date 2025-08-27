# Analysis Phase: Embed Functionality for Slides and Video

## Intent and Goals

Enhance the talk resource display system to show embedded content (slides and videos) inline instead of just links. This improves user experience by allowing direct content viewing without navigation away from the page.

## Requirements Analysis

### Current State
- Resources are displayed as clickable links in lists
- Users must click away to view slides/videos
- All resources use the same link-based rendering

### Desired State
- Slides (Google Slides) embedded as responsive iframes
- YouTube videos embedded as responsive iframes
- Fallback to links for unsupported URL types
- Mobile-optimized responsive sizing

### Boundaries

**In Scope:**
- Google Slides embed detection and rendering
- YouTube video embed detection and rendering  
- Responsive iframe sizing for mobile devices
- Maintain existing link functionality as fallback
- Support both hash and array resource formats

**Out of Scope:**
- Other video platforms (Vimeo, etc.) - future enhancement
- PDF slide embedding - future enhancement
- Audio embedding - future enhancement
- Full-screen modal views - future enhancement

## Technical Assumptions

### URL Pattern Detection
- Google Slides: Detect `docs.google.com/presentation` URLs
- YouTube: Detect `youtube.com/watch` and `youtu.be/` URLs
- Convert sharing URLs to embed URLs with proper parameters

### Responsive Design
- Mobile-first approach with responsive iframe containers
- Aspect ratio preservation (16:9 for video, slides auto-height)
- CSS-only responsive solution (no JavaScript dependencies)

### Fallback Strategy
- If URL cannot be detected as embeddable, show as link
- Preserve existing accessibility features (target="_blank", rel attributes)
- Maintain existing resource grouping and styling

## Integration Points

### Existing Code Modification
- Extend `generate_resources_html` method in `TalkRenderer`
- Add URL detection and iframe generation logic
- Preserve existing resource parsing for hash/array formats

### Security Considerations
- Validate and sanitize embed URLs
- Use proper iframe sandbox attributes where appropriate
- Maintain CSP compatibility with embedded content

### Performance Considerations  
- Lazy loading for embedded iframes (loading="lazy")
- Minimal impact on existing page load performance
- No additional external dependencies

## Success Criteria

1. Google Slides URLs automatically render as embedded presentations
2. YouTube URLs automatically render as embedded videos
3. Responsive design works on mobile devices
4. Existing link functionality preserved for non-embeddable URLs
5. No breaking changes to existing resource format
6. Security: No XSS vulnerabilities from URL processing