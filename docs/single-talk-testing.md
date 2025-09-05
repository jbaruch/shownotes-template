# Single Talk Migration Testing

This enhanced testing framework allows you to test individual talks during migration, making the development process much faster and more focused.

## Quick Start

### Basic Single Talk Testing
```bash
# Test core migration for a single talk
bundle exec ruby test_single_talk.rb <talk_name>

# Example
bundle exec ruby test_single_talk.rb robocoders-judgment-day-ai-ides-face-off
```

### Enhanced Asset Testing
```bash
# Test migration + all assets (PDF, video, thumbnail, resources)
bundle exec ruby test_single_talk_assets.rb <talk_name>

# Example  
bundle exec ruby test_single_talk_assets.rb robocoders-judgment-day-ai-ides-face-off
```

## Migration Workflow

### 1. Migrate a New Talk
```bash
# The migration script now automatically runs focused tests
bundle exec ruby migrate_talk.rb https://speaking.jbaru.ch/PjlHKD/robocoders-judgment-day-ai-ides-face-off
```

The migration script will:
- Extract content and upload PDF to Google Drive
- Generate thumbnails
- **Automatically run focused tests on just the migrated talk**
- Build and test the Jekyll site

### 2. Test Individual Talk (Development)
```bash
# During development, test only one talk for fast feedback
bundle exec ruby test_single_talk.rb robocoders-judgment-day-ai-ides-face-off
```

### 3. Full Validation (Before Push)
```bash
# Before pushing changes, run the full test suite
bundle exec rake test:migration
```

## What's Tested

### Core Migration Tests (`test_single_talk.rb`)
- ✅ Content migration accuracy
- ✅ Resource URL validation  
- ✅ Slides proper formatting (Google Drive)
- ✅ Video availability
- ✅ Thumbnail URL generation

### Enhanced Asset Tests (`test_single_talk_assets.rb`)
- ✅ Everything from core tests
- ✅ PDF accessibility on Google Drive
- ✅ Video link functionality
- ✅ Thumbnail file existence and size
- ✅ Resource count validation

## Environment Variables

The testing framework uses environment variables to control scope:

```bash
# Test only one talk
export TEST_SINGLE_TALK="talk-name"
bundle exec ruby test/migration/migration_test.rb

# Test all talks (default)
unset TEST_SINGLE_TALK
bundle exec ruby test/migration/migration_test.rb
```

## Integration with Migration

The `migrate_talk.rb` script automatically:

1. Sets `TEST_SINGLE_TALK=<migrated_talk_name>`
2. Runs focused tests on just the new talk
3. Provides fast feedback during migration
4. Falls back to full tests if needed

## Benefits

### Before (Old Workflow)
- Migration tested all 54+ talks every time
- Slow feedback cycle (30+ seconds)
- Hard to debug specific talk issues
- Inefficient for single talk development

### After (New Workflow)  
- Migration tests only the new talk (1-2 seconds)
- Fast feedback during development
- Easy to debug specific issues
- Focused asset validation
- Full test suite still available when needed

## Examples

### Test a Specific Talk
```bash
bundle exec ruby test_single_talk.rb 2023-09-07-devops-talks-singapore-devops-reframed
```

Output:
```
✅ SUCCESS: All tests passed for 2023-09-07-devops-talks-singapore-devops-reframed
   ✓ Content migration accurate
   ✓ Resource URLs valid  
   ✓ Slides properly formatted
   ✓ Video availability correct
   ✓ Thumbnails accessible
```

### Test Assets for a Talk
```bash
bundle exec ruby test_single_talk_assets.rb 2023-09-07-devops-talks-singapore-devops-reframed
```

Output:
```
📄 Found PDF: https://drive.google.com/file/d/1XDc2kYEy3VJc8AyusigzYUttZacmF92e/view
   ✅ PDF accessible
🎬 Found video: https://www.youtube.com/watch?v=uTEL8Ff1Zvk
   ✅ Video accessible  
📋 Found 14 resources in Resources section
```

## Development Tips

1. **Fast Iteration**: Use `test_single_talk.rb` during talk development
2. **Asset Validation**: Use `test_single_talk_assets.rb` to verify all resources work
3. **Pre-commit**: Run full suite with `bundle exec rake test:migration`
4. **Local Testing**: Test changes with Jekyll: `bundle exec jekyll serve --port 4000 --detach`
