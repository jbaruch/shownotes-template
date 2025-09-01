# Test Organization

The Shownotes test suite is organized into categories to accommodate different user needs:

## For Most Users (No Migration Needed)

```bash
# Run all non-migration tests (default)
bundle exec ruby test/run_tests.rb
# or
bundle exec ruby test/run_tests.rb -c all
```

This runs **32 test files** covering:

- Unit tests (core functionality)
- Integration tests (Jekyll integration)
- End-to-end tests (user workflows)
- External tests (non-migration)
- Performance tests
- Tool tests

## For Migration Users (Requires Google Drive API)

```bash
# Run migration-specific tests
bundle exec ruby test/run_tests.rb -c migration
```

This runs **4 test files** covering:

- Migration validation tests
- Google Drive API integration tests

**Requirements for migration tests:**

- `Google API.json` file with service account credentials
- Access to a Google Drive shared drive
- Internet connection

## Specific Test Categories

```bash
# Run only unit tests
bundle exec ruby test/run_tests.rb -c unit

# Run only integration tests  
bundle exec ruby test/run_tests.rb -c integration

# Run speaker configuration tests
bundle exec ruby test/run_tests.rb -c speaker

# See all options
bundle exec ruby test/run_tests.rb --help
```

## Why This Split?

- **Users who just want to use the site** don't need Google Drive API access
- **Users migrating from existing platforms** need the migration tools and tests
- This prevents unnecessary external dependencies for basic usage
- Keeps the core test suite fast and focused
