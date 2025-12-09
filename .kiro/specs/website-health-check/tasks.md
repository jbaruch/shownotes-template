# Implementation Plan

- [x] 1. Investigate plugin execution on production
  - Add debugging output to `_plugins/markdown_parser.rb` to log execution
  - Add logging for number of talks processed and extracted metadata
  - Deploy to production and check GitHub Actions logs
  - Document findings about plugin execution in production environment
  - _Requirements: 4.1, 4.3, 4.4_

- [x] 2. Fix plugin execution issues
- [x] 2.1 Add error handling to markdown parser plugin
  - Wrap extraction methods in try/catch blocks
  - Add Jekyll.logger.error statements for failures
  - Set fallback values when extraction fails (use page.title as fallback)
  - Test with malformed markdown files
  - _Requirements: 1.2, 1.5, 4.5_

- [x] 2.2 Ensure plugin runs with correct priority
  - Verify plugin priority is set to :highest
  - Check plugin execution order in Jekyll generate phase
  - Test that extracted_* variables are available to templates
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2.3 Handle baseurl override in deploy workflow
  - Test plugin behavior with --baseurl flag locally
  - Verify baseurl doesn't affect plugin loading or execution
  - Adjust deploy workflow if needed to ensure plugin runs
  - _Requirements: 4.3, 4.5_

- [x] 2.4 Write unit tests for plugin extraction methods
  - Test extract_title_from_content with valid H1 heading
  - Test extract_title_from_content with missing H1 (fallback behavior)
  - Test extract_metadata_from_content for conference, date, slides, video
  - Test extract_abstract_from_content and extract_resources_from_content
  - Test error handling when content is malformed
  - _Requirements: 1.2, 1.3, 1.5_

- [x] 3. Exclude sample talk from production builds
- [x] 3.1 Move sample talk to documentation directory
  - Create `docs/templates/` directory if it doesn't exist
  - Move `_talks/sample-talk.md` to `docs/templates/sample-talk.md`
  - Update any documentation that references the sample talk location
  - _Requirements: 2.1, 2.5_

- [x] 3.2 Add sample talk to .gitignore
  - Add `_talks/sample-talk.md` to .gitignore to prevent future accidents
  - Verify file is excluded from git status
  - _Requirements: 2.2_

- [x] 3.3 Verify sample talk exclusion
  - Build site locally and verify sample talk doesn't appear in _site/
  - Check that /talks/sample-talk/ directory doesn't exist in _site/
  - Verify talks list doesn't include sample talk
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 4. Checkpoint - Deploy and verify fixes
  - Ensure all tests pass locally
  - Deploy changes to production
  - Verify plugin debugging output in GitHub Actions logs
  - Verify sample talk doesn't appear on production homepage
  - Verify at least one talk page shows proper title and content
  - Ask the user if questions arise

- [x] 5. Add production health tests
- [x] 5.1 Create production health test file
  - Create `test/impl/e2e/production_health_test.rb`
  - Set up test class with Minitest
  - Add helper methods for fetching production HTML
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 5.2 Implement homepage health tests
  - Test that production homepage loads with HTTP 200 status
  - Test that CSS is loaded (check for stylesheet link in HTML)
  - Test that "Highlighted Presentations" section exists
  - Test that at least 3 talks are displayed in highlighted section
  - _Requirements: 3.1, 3.2, 3.6_

- [x] 5.3 Implement talk page health tests
  - Test that a specific talk page loads successfully
  - Test that talk title is extracted from H1, not slugified filename
  - Test that conference name, date, and video status are present
  - Test that talk content includes abstract and resources sections
  - _Requirements: 3.3, 3.5, 3.7_

- [x] 5.4 Implement sample talk exclusion tests
  - Test that sample talk doesn't appear in production talks list
  - Test that /talks/sample-talk/ returns 404 or doesn't exist
  - Test that homepage doesn't contain "Your Amazing Talk Title"
  - _Requirements: 3.4, 2.3, 2.4_

- [x] 5.5 Add production parity tests
  - Compare number of talks between local build and production
  - Verify same talk titles appear on both local and production
  - Test that metadata format matches between environments
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 6. Improve template fallback handling
- [x] 6.1 Add robust fallbacks to talk layout
  - Update `_layouts/talk.html` to handle missing extracted_* variables
  - Add humanization for slugified titles as fallback
  - Add warning comments when fallbacks are used
  - Test with talk that has missing metadata
  - _Requirements: 1.2, 1.5_

- [x] 6.2 Add robust fallbacks to homepage
  - Update `index.md` to handle missing extracted_* variables
  - Ensure "Highlighted Presentations" section handles missing data gracefully
  - Add fallback for missing conference names and dates
  - Test with talks that have incomplete metadata
  - _Requirements: 1.1, 1.3_

- [x] 7. Final checkpoint - Verify all requirements met
  - Run full test suite including new production health tests
  - Verify production site displays properly formatted content
  - Verify sample talk is excluded from production
  - Verify all talk pages show proper titles and metadata
  - Ensure all tests pass, ask the user if questions arise

- [x] 8. Documentation and cleanup
- [x] 8.1 Document root cause and fixes
  - Create documentation explaining why production differed from local
  - Document the plugin execution issue and resolution
  - Document sample talk exclusion approach
  - Add prevention strategies to avoid similar issues
  - _Requirements: 4.1, 4.2, 4.5_

- [x] 8.2 Remove debugging output from plugin
  - Remove or comment out temporary debugging statements
  - Keep essential error logging for production monitoring
  - Test that plugin still works without verbose logging
  - _Requirements: 4.5_

- [x] 8.3 Update development documentation
  - Update SETUP.md or DEVELOPMENT.md with new test information
  - Document how to run production health tests
  - Document sample talk template location
  - Add troubleshooting section for plugin issues
  - _Requirements: 2.5, 4.5_
