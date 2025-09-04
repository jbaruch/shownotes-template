# Thumbnail System Documentation

## Overview

The website uses a **local thumbnail system** that automatically looks for thumbnail images in the `/assets/images/thumbnails/` directory. This system is simple, reliable, and avoids CORS/loading issues that were present with remote thumbnail solutions.

## How It Works

### 1. Local Thumbnail Files
- Thumbnails are stored in `/assets/images/thumbnails/`
- File naming pattern: `{talk-slug}-thumbnail.png`
- Example: `2025-06-12-devoxx-poland-robocoders-judgment-thumbnail.png`

### 2. Automatic Detection
The Jekyll template automatically:
- Looks for a local thumbnail file matching the talk filename
- If found: uses the local thumbnail
- If not found: falls back to a placeholder (`/assets/images/placeholder-thumbnail.svg`)

### 3. No Configuration Needed
- No YAML frontmatter required
- No plugin configuration needed
- Works automatically for any talk file

## For Notist Migrations

### Automatic Thumbnail Download
When migrating from Notist, the migration script automatically:
1. Extracts the thumbnail from the Notist page's `og:image` meta tag
2. Downloads the image from `on.notist.cloud/slides/`
3. Saves it locally as `{talk-slug}-thumbnail.png`
4. No manual intervention required

### Migration Process
```bash
# Thumbnails are downloaded as part of standard migration
ruby migrate_talk.rb
```

The migration script will:
- Download the Notist slide deck thumbnail
- Save it in the correct format and location
- Verify the download was successful

## For Non-Notist Talks

### Manual Thumbnail Addition
For talks not migrated from Notist:

1. **Create your thumbnail image**
   - Recommended size: 400x300 pixels
   - Format: PNG (preferred) or JPG
   - Should be a representative image from your slides

2. **Save with correct filename**
   ```
   assets/images/thumbnails/{talk-slug}-thumbnail.png
   ```

3. **Example**
   For talk file: `_talks/2025-06-12-my-awesome-talk.md`
   Thumbnail should be: `assets/images/thumbnails/2025-06-12-my-awesome-talk-thumbnail.png`

### Quick Steps
```bash
# 1. Find your talk filename
ls _talks/2025-06-12-my-awesome-talk.md

# 2. Create thumbnail (extract from your slides or create custom)
# Save as: assets/images/thumbnails/2025-06-12-my-awesome-talk-thumbnail.png

# 3. Rebuild Jekyll
bundle exec jekyll build

# 4. Verify it works
bundle exec jekyll serve --port 4001
```

## Technical Details

### Template Logic
```liquid
{% assign talk_slug = include.talk.path | split: "/" | last | remove: ".md" %}
{% assign local_thumbnail_path = "/assets/images/thumbnails/" | append: talk_slug | append: "-thumbnail.png" %}
{% assign thumb_url = local_thumbnail_path | relative_url %}
```

### Fallback Behavior
- **Thumbnail exists**: Uses local file
- **Thumbnail missing**: Uses placeholder
- **Image fails to load**: Browser's `onerror` attribute shows placeholder

### File Structure
```
assets/images/
├── thumbnails/
│   ├── 2025-06-12-devoxx-poland-robocoders-judgment-thumbnail.png
│   ├── 2025-06-10-ai-fokus-robocoders-judgment-thumbnail.png
│   └── ...
└── placeholder-thumbnail.svg
```

## Testing

### Automated Tests
The test suite includes:
- `test_local_thumbnails_exist_for_talks` - Checks which talks have thumbnails
- `test_local_thumbnails_are_displayed` - Verifies thumbnails appear in generated HTML
- `test_no_remote_thumbnail_urls` - Ensures no remote dependencies

### Manual Testing
```bash
# Run single talk test
TEST_SINGLE_TALK=2025-06-12-devoxx-poland-robocoders-judgment bundle exec ruby migration_test.rb

# Run visual tests
bundle exec ruby test/impl/e2e/visual_test.rb
```

## Benefits

### ✅ Advantages
- **No CORS issues** - All thumbnails are local
- **Fast loading** - No external dependencies
- **Reliable** - No network timeouts or permission issues
- **Simple** - No configuration needed
- **Automatic** - Works with Notist migration out of the box

### 📝 Migration from Google Drive Thumbnails
- **Removed**: Google Drive thumbnail plugin
- **Removed**: Remote thumbnail URL generation
- **Added**: Local file-based thumbnail system
- **Updated**: All tests to reflect new system

## Troubleshooting

### Thumbnail Not Showing
1. **Check filename**: Must match exactly `{talk-slug}-thumbnail.png`
2. **Check file exists**: `ls assets/images/thumbnails/{your-file}`
3. **Rebuild Jekyll**: `bundle exec jekyll build`
4. **Check browser network tab**: Look for 404 errors

### File Naming Issues
```bash
# Get correct talk slug
basename _talks/2025-06-12-my-talk.md .md
# Result: 2025-06-12-my-talk

# Thumbnail should be named:
# assets/images/thumbnails/2025-06-12-my-talk-thumbnail.png
```

### Testing Thumbnail Display
```bash
# Start local server
bundle exec jekyll serve --port 4001

# Visit: http://127.0.0.1:4001/shownotes/
# Check that thumbnails are loading correctly
```

## Migration Examples

### Successful Notist Migration
```
✅ Found Notist slide deck thumbnail: https://on.notist.cloud/slides/...
✅ Downloaded thumbnail: 2025-06-12-devoxx-poland-robocoders-judgment-thumbnail.png
✅ Thumbnail size: 328KB
```

### Manual Addition
```bash
# For non-Notist talk: 2025-07-15-my-conference-my-talk.md
cp my-slide-screenshot.png assets/images/thumbnails/2025-07-15-my-conference-my-talk-thumbnail.png
bundle exec jekyll build
```

## Best Practices

1. **Use consistent sizing** - 400x300 pixels works well
2. **Optimize file size** - Keep under 500KB for fast loading
3. **Use descriptive first slide** - Thumbnail should represent the talk content
4. **Test locally** - Always verify thumbnail shows correctly before deploying
5. **Follow naming convention** - Exact match with talk filename is crucial
