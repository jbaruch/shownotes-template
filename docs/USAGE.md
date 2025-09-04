# Usage Guide

How to create and manage conference talk pages.

## Creating Talk Pages

### Option 1: Migrate from Notist (Recommended)

The easiest way to add talks is to migrate them from Notist.

#### Prerequisites

- Google Drive API setup (see [Setup Guide](SETUP.md#google-drive-integration-optional))
- Notist talk URL

#### Migration Process

```bash
# One-command migration
ruby migrate_talk.rb https://noti.st/yourname/your-talk-id

# Example
ruby migrate_talk.rb https://noti.st/jbaruch/PjlHKD/robocoders-judgment-day-ai-ides-face-off
```

#### What the Migration Does

1. **Extracts content** from the Notist page:
   - Talk title, conference, date
   - Abstract/description  
   - Speaker information
   - Resource links

2. **Downloads and processes slides**:
   - Downloads PDF from Notist
   - Uploads to your Google Drive
   - Creates shareable embed link

3. **Downloads thumbnail**:
   - Extracts slide deck preview from Notist
   - Saves as local thumbnail file
   - Automatically displays in talk list

4. **Generates Jekyll markdown**:
   - Creates properly formatted talk file
   - Adds all extracted content
   - Uses clean, minimal frontmatter

5. **Validates everything**:
   - Runs focused tests on the new talk
   - Rebuilds Jekyll site
   - Verifies all resources work

#### Migration Output

```text
✅ Found talk: RoboCoders: Judgment Day – AI IDEs Face Off
✅ Downloaded PDF: 32.5MB
✅ Uploaded to Google Drive: 1PKbvxSb2XPNxDkPasli6IufGisPPTEOT
✅ Downloaded thumbnail: 2025-06-12-devoxx-poland-robocoders-judgment-thumbnail.png
✅ Generated: _talks/2025-06-12-devoxx-poland-robocoders-judgment.md
✅ Tests passed: 18 resources migrated successfully
✅ Jekyll site rebuilt
```

### Option 2: Manual Creation

For talks not on Notist or when you need full control.

#### 1. Create the Talk File

Create `_talks/YYYY-MM-DD-conference-talk-title.md`:

```markdown
---
layout: talk
---

# Your Talk Title

**Conference:** Conference Name YYYY  
**Date:** YYYY-MM-DD  
**Slides:** [View Slides](https://your-slides-url)  
**Video:** [Watch Video](https://your-video-url)  

A presentation at Conference Name YYYY in
                    Month YYYY in
                    City, Country by 
                    {{ site.speaker.display_name | default: site.speaker.name }}

## Abstract

Your talk description here. This should be a compelling summary
that explains what attendees will learn and why it matters.

## Resources

- [Main Resource](https://example.com)
- [Code Repository](https://github.com/yourname/repo)
- [Documentation](https://docs.example.com)
- [Related Tool](https://tool.example.com)
```

#### 2. Add Thumbnail (Optional)

Create or find a representative image:

- **Size**: 400x300 pixels recommended
- **Format**: PNG or JPG
- **Content**: First slide or representative image

Save as `assets/images/thumbnails/YYYY-MM-DD-conference-talk-title-thumbnail.png`

#### 3. Test and Build

```bash
# Test the new talk
TEST_SINGLE_TALK=your-talk-name bundle exec ruby test/migration/migration_test.rb

# Build site
bundle exec jekyll build

# Serve locally to verify
bundle exec jekyll serve
```

## Talk File Format

### Frontmatter

Minimal frontmatter is used:

```yaml
---
layout: talk
---
```

### Required Elements

```markdown
# Talk Title

**Conference:** Name and Year
**Date:** YYYY-MM-DD (ISO format)
**Slides:** [View Slides](URL)
**Video:** [Watch Video](URL) # Optional

A presentation at Conference Name in Month Year...

## Abstract

Description here...

## Resources

- [Resource](URL)
```

### Optional Elements

```markdown
# Additional sections you can add:

## Code Examples
## Demos  
## Follow-up
## References
```

## Resource Management

### Types of Resources

The platform automatically categorizes resources:

- **slides**: Slide deck URLs
- **video**: Video recordings
- **code**: GitHub repositories, code samples
- **link**: Documentation, articles, tools

### Resource URLs

#### Google Drive Slides (Preferred)

```markdown
**Slides:** [View Slides](https://drive.google.com/file/d/FILE_ID/view)
```

Benefits:
- Automatic embedding
- Thumbnail generation
- PDF integrity validation

#### Video Links

```markdown
**Video:** [Watch Video](https://www.youtube.com/watch?v=VIDEO_ID)
**Video:** [Watch Video](https://vimeo.com/VIDEO_ID)
```

#### Code Repositories

```markdown
- [GitHub Repository](https://github.com/username/repo)
- [Code Sample](https://gist.github.com/username/gist_id)
```

#### Documentation and Tools

```markdown
- [Official Documentation](https://docs.example.com)
- [Tool Website](https://tool.example.com)
- [Related Article](https://blog.example.com/article)
```

## Thumbnail Management

### Automatic Thumbnails (Notist Migration)

- Downloaded from Notist `og:image`
- Saved as `{talk-slug}-thumbnail.png`
- Automatically detected by Jekyll template

### Manual Thumbnails

1. **Create thumbnail image**:
   - Screenshot first slide of your presentation
   - Resize to ~400x300 pixels
   - Save as PNG or JPG

2. **Save with correct name**:
   ```bash
   # For talk: 2025-06-12-conference-my-talk.md
   # Save as: assets/images/thumbnails/2025-06-12-conference-my-talk-thumbnail.png
   ```

3. **Verify filename matches**:
   ```bash
   # Talk file basename should match thumbnail
   basename _talks/2025-06-12-conference-my-talk.md .md
   # Should match thumbnail prefix
   ```

### Fallback Behavior

- **Thumbnail exists**: Used automatically
- **Thumbnail missing**: Placeholder SVG used
- **Thumbnail fails to load**: Browser shows placeholder

## Testing Your Talks

### Single Talk Testing

```bash
# Test specific talk during development
TEST_SINGLE_TALK=2025-06-12-conference-talk bundle exec ruby test/migration/migration_test.rb

# This tests:
# - File format validity
# - Resource accessibility  
# - Link validation
# - Thumbnail presence
# - Content completeness
```

### Full Site Testing

```bash
# Test all talks
bundle exec ruby test/run_tests.rb

# Test only migration-related functionality
bundle exec ruby test/run_tests.rb -c migration
```

## Best Practices

### File Naming

```bash
# Good
2025-06-12-devoxx-poland-robocoders-judgment.md
2024-04-15-spring-io-kotlin-coroutines.md

# Avoid spaces, special characters
# Use consistent date format (YYYY-MM-DD)
# Use hyphens for separation
```

### Resource Organization

```markdown
## Resources

# Group by category
### Documentation
- [Official Docs](https://example.com)
- [API Reference](https://api.example.com)

### Code and Examples  
- [GitHub Repository](https://github.com/user/repo)
- [Live Demo](https://demo.example.com)

### Related Reading
- [Blog Post](https://blog.example.com)
- [Research Paper](https://paper.example.com)
```

### Content Quality

- **Abstract**: 2-3 paragraphs explaining the value proposition
- **Resources**: Include only high-quality, relevant links
- **Links**: Test all URLs before publishing
- **Thumbnails**: Use clear, readable slide content

## Troubleshooting

### Migration Issues

#### PDF Download Fails
```bash
# Check Notist URL accessibility
curl -I https://noti.st/yourname/talk-id

# Verify PDF is available for download
# Some talks have PDF download disabled
```

#### Google Drive Upload Fails
```bash
# Verify API credentials
cat "Google API.json" | grep -o '"type".*"service_account"'

# Test API access
bundle exec ruby -c 'require "google-apis-drive_v3"'
```

#### Thumbnail Missing
```bash
# Check if thumbnail downloaded
ls assets/images/thumbnails/*your-talk*

# Manually add if needed
cp your-slide-image.png assets/images/thumbnails/your-talk-slug-thumbnail.png
```

### Manual Creation Issues

#### Talk Not Showing
```bash
# Verify filename format
ls _talks/YYYY-MM-DD-*

# Check Jekyll build
bundle exec jekyll build --verbose
```

#### Resources Not Working
```bash
# Test URLs individually
curl -I https://your-resource-url

# Check for typos in markdown
grep -n "http" _talks/your-talk.md
```

## Advanced Usage

### Custom Talk Templates

Create `_layouts/custom-talk.html` for specialized layouts.

### Bulk Operations

```bash
# Test multiple talks
for talk in _talks/*.md; do
  TEST_SINGLE_TALK=$(basename "$talk" .md) bundle exec ruby test/migration/migration_test.rb
done
```

### Content Validation

```bash
# Comprehensive validation
bundle exec ruby test/impl/integration/content_validation_test.rb
```

## Next Steps

- **Customize appearance**: See [Advanced Features](ADVANCED.md)
- **Deploy your site**: See [Advanced Features](ADVANCED.md#deployment)
- **Contribute to development**: See [Development Guide](DEVELOPMENT.md)
