# Test Scenarios: Embed Functionality

## Test Scenario Group: Google Slides Embedding

### TS-E01: Google Slides URL Detection
**Given** a resource with URL "https://docs.google.com/presentation/d/1ABC123/edit#slide=id.p1"  
**When** the system generates resource HTML  
**Then** it should detect this as a Google Slides URL  
**And** it should convert it to embed format  

### TS-E02: Google Slides Embed HTML Generation  
**Given** a Google Slides URL has been detected  
**When** the system generates the embed HTML  
**Then** it should create a responsive iframe container with slides-embed class  
**And** the iframe should use the converted embed URL  
**And** the iframe should include proper attributes (frameborder="0", allowfullscreen, loading="lazy")  

### TS-E03: Google Slides Embed URL Conversion
**Given** a Google Slides sharing URL "https://docs.google.com/presentation/d/1ABC123/edit#slide=id.p1"  
**When** the system converts it to embed format  
**Then** the result should be "https://docs.google.com/presentation/d/e/1ABC123/pubembed?start=false&loop=false&delayms=3000"  

### TS-E04: Google Slides Malformed URL Handling
**Given** a malformed Google Slides URL  
**When** the system attempts to process it  
**Then** it should fall back to displaying it as a standard link  
**And** no errors should be raised  

## Test Scenario Group: YouTube Video Embedding  

### TS-E05: YouTube Watch URL Detection
**Given** a resource with URL "https://www.youtube.com/watch?v=dQw4w9WgXcQ"  
**When** the system generates resource HTML  
**Then** it should detect this as a YouTube URL  

### TS-E06: YouTube Short URL Detection  
**Given** a resource with URL "https://youtu.be/dQw4w9WgXcQ"  
**When** the system generates resource HTML  
**Then** it should detect this as a YouTube URL  

### TS-E07: YouTube Embed HTML Generation
**Given** a YouTube URL has been detected  
**When** the system generates the embed HTML  
**Then** it should create a responsive iframe container with video-embed class  
**And** the iframe should use YouTube nocookie embed URL  
**And** the iframe should have 16:9 aspect ratio styling  

### TS-E08: YouTube Embed URL Conversion
**Given** a YouTube URL "https://www.youtube.com/watch?v=dQw4w9WgXcQ"  
**When** the system converts it to embed format  
**Then** the result should be "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"  

### TS-E09: YouTube URL with Parameters
**Given** a YouTube URL with additional parameters "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s"  
**When** the system converts it to embed format  
**Then** it should extract only the video ID  
**And** use the clean nocookie embed URL  

## Test Scenario Group: Responsive Design

### TS-E10: Mobile Responsive Iframe  
**Given** an embedded iframe is rendered  
**When** viewed on a mobile device  
**Then** the iframe should scale to fit the container width  
**And** it should not cause horizontal scrolling  

### TS-E11: Video Aspect Ratio Preservation
**Given** a YouTube video embed  
**When** the container width changes  
**Then** the video should maintain 16:9 aspect ratio  
**And** the height should adjust automatically  

### TS-E12: Slides Flexible Height
**Given** a Google Slides embed  
**When** rendered in different container sizes  
**Then** the slides should scale appropriately  
**And** maintain readable content  

## Test Scenario Group: Fallback Behavior

### TS-E13: Non-Embeddable URL Fallback
**Given** a resource with URL "https://example.com/document.pdf"  
**When** the system generates resource HTML  
**Then** it should display as a standard clickable link  
**And** preserve all existing link attributes  

### TS-E14: Empty or Invalid URL Handling
**Given** a resource with an empty or invalid URL  
**When** the system processes the resource  
**Then** it should handle gracefully without errors  
**And** either skip the resource or show appropriate fallback  

### TS-E15: Mixed Resource Types in Group
**Given** a resource group containing both embeddable and non-embeddable URLs  
**When** the system generates the group HTML  
**Then** embeddable resources should show as iframes  
**And** non-embeddable resources should show as links  
**And** the overall group structure should be preserved  

## Test Scenario Group: Security

### TS-E16: URL Validation and Sanitization
**Given** a potentially malicious URL with script injection  
**When** the system processes the URL for embedding  
**Then** it should validate the URL format strictly  
**And** reject URLs that don't match expected patterns  
**And** fall back to link display for rejected URLs  

### TS-E17: HTML Output Escaping  
**Given** resource data with HTML special characters  
**When** the system generates the embed HTML  
**Then** all dynamic content should be properly HTML escaped  
**And** no raw HTML injection should be possible  

### TS-E18: Iframe Security Attributes
**Given** an iframe is generated for embedding  
**When** the HTML is rendered  
**Then** the iframe should include appropriate security attributes  
**And** use HTTPS URLs only  
**And** follow CSP requirements  

## Test Scenario Group: Integration and Compatibility

### TS-E19: Hash Resource Format Compatibility
**Given** resources in hash format with embeddable URLs  
**When** the system generates resource HTML  
**Then** the embedding should work correctly  
**And** existing hash resource behavior should be preserved  

### TS-E20: Array Resource Format Compatibility  
**Given** resources in array format with embeddable URLs  
**When** the system generates resource HTML  
**Then** the embedding should work correctly  
**And** existing array resource behavior should be preserved  

### TS-E21: Resource Grouping Preservation
**Given** resources are grouped by type (slides, video, links)  
**When** embedding is applied  
**Then** the grouping structure should remain intact  
**And** CSS classes should be preserved for styling  

### TS-E22: Performance Impact Measurement
**Given** a talk with multiple embeddable resources  
**When** the system generates the complete resource HTML  
**Then** the generation time should not increase significantly (< 5ms additional)  
**And** the output size should be reasonable  

## Test Scenario Group: Edge Cases

### TS-E23: Very Long URLs
**Given** an extremely long but valid embeddable URL  
**When** the system processes the URL  
**Then** it should handle the URL correctly  
**And** generate proper embed HTML  

### TS-E24: Unicode Characters in URLs
**Given** URLs containing Unicode characters  
**When** the system processes these URLs  
**Then** it should handle character encoding correctly  
**And** generate valid embed URLs  

### TS-E25: Missing Resource Data
**Given** a resource with missing URL or title data  
**When** the system processes the resource  
**Then** it should handle the missing data gracefully  
**And** not break the overall resource rendering  

Total Test Scenarios: 25 covering all aspects of embed functionality