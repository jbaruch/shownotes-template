# Utility Scripts

This directory contains utility scripts for migration and maintenance tasks.

## Directory Structure

```text
utils/
├── README.md                    # This file
├── migration/                   # Migration-related utilities
│   ├── migrate_talk.rb          # Main migration script (noti.st → Jekyll)
│   └── test_real_site.rb        # Real site validation utility
└── google_drive/                # Google Drive management utilities
    ├── cleanup_google_drive.rb  # List and cleanup Google Drive files
    ├── delete_google_drive_file.rb # Delete specific Google Drive files
    └── force_delete_files.rb    # Force delete multiple files
```

## Migration Utilities

### migrate_talk.rb

Main migration script for converting talks from noti.st to Jekyll format.

**Usage:**
```bash
cd utils/migration
ruby migrate_talk.rb https://noti.st/yourname/TALK_ID
```

**Features:**
- Extracts talk metadata (title, conference, date)
- Downloads and uploads slides to Google Drive
- Extracts and validates video links
- Generates clean markdown format with minimal frontmatter
- Validates all external resources

### test_real_site.rb

Validates real site functionality and content accessibility.

**Usage:**
```bash
cd utils/migration
ruby test_real_site.rb
```

**Features:**
- Tests site accessibility and responsiveness
- Validates external link integrity
- Checks performance metrics
- Verifies mobile compatibility

## Google Drive Utilities

These utilities help manage Google Drive files during migration and re-migration scenarios.

### cleanup_google_drive.rb

Lists all files in the migration Google Drive folder and provides cleanup options.

**Usage:**
```bash
cd utils/google_drive
ruby cleanup_google_drive.rb
```

**Features:**
- Lists all files in the migration folder
- Shows file sizes and upload dates
- Identifies duplicate or orphaned files
- Provides interactive cleanup options

### delete_google_drive_file.rb

Deletes a specific file from Google Drive by file ID.

**Usage:**
```bash
cd utils/google_drive
ruby delete_google_drive_file.rb FILE_ID
```

**Features:**
- Safely deletes individual files
- Confirms deletion before proceeding
- Handles API errors gracefully

### force_delete_files.rb

Force deletes multiple files from Google Drive (use with caution).

**Usage:**
```bash
cd utils/google_drive
ruby force_delete_files.rb
```

**Features:**
- Batch deletion of multiple files
- Confirmation prompts for safety
- Comprehensive error handling
- Dry-run mode available

## Common Use Cases

### Re-migration Scenario

When you need to re-migrate a talk (e.g., source content changed):

1. **Clean up old files:**
   ```bash
   cd utils/google_drive
   ruby cleanup_google_drive.rb
   # Select files to delete from previous migration
   ```

2. **Re-run migration:**
   ```bash
   cd utils/migration
   ruby migrate_talk.rb https://speaking.jbaru.ch/TALK_ID
   ```

3. **Validate results:**
   ```bash
   cd utils/migration
   ruby test_real_site.rb
   ```

### Google Drive Maintenance

Regular cleanup of Google Drive to manage storage:

```bash
cd utils/google_drive
ruby cleanup_google_drive.rb
# Review and delete outdated or duplicate files
```

### Testing Migration Quality

After migration, validate the results:

```bash
cd utils/migration
ruby test_real_site.rb

# Also run the comprehensive test suite
cd ../..
bundle exec ruby test/run_tests.rb --category migration
```

## Configuration

All scripts require `Google API.json` file in the project root for Google Drive access.

### Required Environment
- Ruby 3.4+
- Google Drive API credentials
- Network access to noti.st and target sites

### Dependencies
- `google-apis-drive_v3`
- `googleauth`
- `nokogiri`
- `yaml`
- `json`

## Security Notes

- **Google API credentials**: Keep `Google API.json` secure and never commit to version control
- **Deletion scripts**: Use with extreme caution, especially `force_delete_files.rb`
- **Network requests**: All scripts make external API calls and network requests
- **File operations**: Scripts modify local files and remote Google Drive content

## Troubleshooting

### Common Issues

**Google API Quota Exceeded:**
- Wait for quota reset (usually 24 hours)
- Use cleanup scripts to reduce API calls
- Contact Google for quota increase if needed

**Network Connectivity:**
- Check internet connection
- Verify noti.st site accessibility
- Test Google Drive API connectivity

**File Permissions:**
- Ensure scripts have execute permissions
- Check Google Drive folder permissions
- Verify API credentials have correct scopes

**Migration Failures:**
- Check source URL accessibility
- Verify Google Drive folder exists
- Review error logs for specific issues
