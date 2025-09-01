# Test Organization

This directory contains the organized test suite for the shownotes project.

## Directory Structure

```text
test/
├── run_tests.rb                 # Main test runner
├── test_runner.rb               # Legacy runner (redirects to main)
├── speaker_configuration_test_runner.rb  # Speaker-specific runner
├── fixtures/                   # Test fixtures and mock data
├── screenshots/                # Visual test screenshots
├── spec/                       # Test specifications
├── migration/                  # Migration-related tests
│   ├── migration_test.rb       # Main migration validation
│   ├── dynamic_migration_test.rb
│   └── run_migration_tests.rb
├── external/                   # Tests for external dependencies
│   ├── google_drive_test.rb    # Google Drive API tests
│   ├── google_drive_permissions_test.rb
│   ├── real_site_test.rb       # Real site validation
│   └── test_upload.txt
├── tools/                      # Tests for build/migration tools
│   ├── markdown_parser_test.rb
│   └── markdown_parser_simple_test.rb
└── impl/                       # Implementation tests
    ├── unit/                   # Unit tests
    ├── integration/            # Integration tests
    ├── e2e/                    # End-to-end tests
    │   └── visual_test.rb
    └── performance/            # Performance tests
```

## Running Tests

### Run All Tests

```bash
bundle exec ruby test/run_tests.rb
```

### Run Specific Test Categories

```bash
bundle exec ruby test/run_tests.rb --category unit
bundle exec ruby test/run_tests.rb --category integration
bundle exec ruby test/run_tests.rb --category migration
bundle exec ruby test/run_tests.rb --category external
bundle exec ruby test/run_tests.rb --category speaker
```

### Run Specific Test Suites

```bash
# Migration tests only
bundle exec ruby test/migration/migration_test.rb

# Speaker configuration tests
bundle exec ruby test/speaker_configuration_test_runner.rb

# Individual test files
bundle exec ruby test/impl/unit/speaker_configuration_test.rb
```

## Test Categories

- **Unit Tests**: Fast, isolated tests for individual components
- **Integration Tests**: Tests for component interactions and Jekyll integration
- **E2E Tests**: Full end-to-end tests including visual validation
- **Migration Tests**: Validation of migration scripts and data integrity
- **External Tests**: Tests for external dependencies (Google Drive, APIs)
- **Tools Tests**: Tests for build tools and parsers
- **Performance Tests**: Performance and load testing

## Test File Naming

- All test files should end with `_test.rb`
- Test files should be descriptive: `component_name_test.rb`
- Test classes should inherit from `Minitest::Test`
- Use clear, descriptive test method names: `test_description_of_what_is_tested`
