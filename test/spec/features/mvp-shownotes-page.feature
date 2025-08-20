Feature: MVP Shownotes Page
  As a conference attendee
  I want to access a simple shownotes page for a talk
  So that I can bookmark resources, verify QR codes work, and return later for content

  Background:
    Given a Jekyll site is configured for the shownotes platform
    And a talk exists with complete frontmatter metadata

  # Maps to TS-001 through TS-005: Talk Information Display
  Scenario: Talk page displays core information correctly
    Given a talk page with title "Modern JavaScript Patterns"
    And speaker "Jane Developer"
    And conference "JSConf 2024" on "2024-03-15"
    And status "completed"
    And description "Exploring modern JavaScript patterns and best practices"
    When I visit the talk page
    Then I should see "Modern JavaScript Patterns" as the main H1 heading
    And I should see "Jane Developer" displayed prominently in the header
    And I should see "JSConf 2024" and "March 15, 2024" in the metadata section
    And I should see the status "completed" with CSS class "status-completed"
    And I should see "Exploring modern JavaScript patterns and best practices" as the description

  # Maps to TS-006 through TS-010: Resource Management
  Scenario: Talk page displays resources correctly
    Given a talk with slides URL "https://slides.example.com/js-patterns"
    And code repository URL "https://github.com/jane/js-patterns-demo"
    And additional link "MDN Guide" pointing to "https://developer.mozilla.org/guide"
    When I visit the talk page
    Then I should see a slides link labeled "Slides" pointing to "https://slides.example.com/js-patterns"
    And I should see a code link labeled "Code" pointing to "https://github.com/jane/js-patterns-demo"
    And I should see "MDN Guide" link pointing to "https://developer.mozilla.org/guide"
    And all external links should open in new tabs with rel="noopener"

  # Maps to TS-009: Missing Resources Handling
  Scenario: Talk page handles missing resources gracefully
    Given a talk with no slides URL
    And no code repository URL
    And no additional links
    When I visit the talk page
    Then the slides section should not appear or show a placeholder
    And the code section should not appear or show a placeholder
    And the additional links section should not appear or show a placeholder
    And the page layout should not be broken

  # Maps to TS-011 through TS-014: Content Rendering
  Scenario: Talk page processes Markdown and frontmatter correctly
    Given a talk file with YAML frontmatter containing title and speaker
    And Markdown content with headers, links, and code blocks
    When Jekyll processes the talk file
    Then the YAML frontmatter should populate template variables
    And the Markdown should convert to proper HTML structure
    And code blocks should render with syntax highlighting
    And special characters should be HTML-escaped safely

  # Maps to TS-015 through TS-018: Responsive Design
  Scenario: Talk page displays correctly on mobile devices
    Given a talk page
    When I view it on a device with 320px viewport width
    Then all content should fit within the viewport without horizontal scrolling
    And interactive elements should be at least 44px in touch target size
    And text should be readable without zooming
    And the layout should stack vertically for mobile consumption

  # Maps to TS-019 through TS-021: Mobile Performance
  Scenario: Talk page loads quickly on slow connections
    Given a 3G network connection simulation
    When I load a talk page
    Then the page should reach First Contentful Paint within 5 seconds
    And all core content (title, speaker, resources) should be accessible
    And the page should function completely with JavaScript disabled
    And intermittent connection issues should not break the experience

  # Maps to TS-022 through TS-024: URL Structure
  Scenario: Talk pages generate clean, stable URLs
    Given a talk with conference "JSConf 2024" and title "Modern JavaScript Patterns"
    When Jekyll generates the site
    Then the talk URL should be "/talks/jsconf-2024/modern-javascript-patterns/"
    And the URL should contain only lowercase letters, numbers, and hyphens
    And the URL should remain stable when content is updated
    And the URL should work when shared on social media and messaging platforms

  # Maps to TS-025 through TS-027: Social Sharing
  Scenario: Talk page provides proper social sharing metadata
    Given a talk page with complete metadata
    When the HTML is generated
    Then Open Graph meta tags should include og:title, og:description, og:type
    And the page title should format as "[Talk Title] - [Speaker] - [Conference]"
    And social media platforms should show proper preview cards
    And meta descriptions should truncate appropriately for different platforms

  # Maps to TS-028 through TS-031: Jekyll Implementation
  Scenario: Jekyll processes talk collection correctly
    Given a Jekyll site configuration with talk collection enabled
    And talk files in the _talks directory
    When the Jekyll build process runs
    Then Jekyll should process all files without errors
    And Liquid templates should access frontmatter variables correctly
    And the talk collection should generate individual pages with proper URLs
    And the site should deploy successfully to GitHub Pages

  # Maps to TS-032 through TS-034: Markdown Support
  Scenario: YAML frontmatter validates and processes correctly
    Given talk files with various YAML frontmatter configurations
    When Jekyll processes the files
    Then valid YAML should populate template variables correctly
    And invalid YAML should show clear error messages without breaking the site
    And standard Markdown syntax should render correctly
    And frontmatter validation should prevent malformed content from publishing

  # Maps to TS-035 through TS-038: Page Load Performance
  Scenario: Talk page meets performance requirements
    Given a performance testing environment
    When a talk page loads on simulated 3G connection
    Then First Contentful Paint should occur within 3 seconds
    And Cumulative Layout Shift should measure less than 0.1
    And images should be served in optimized formats
    And CSS and JavaScript files should be minified for production

  # Maps to TS-039 through TS-041: Browser Compatibility
  Scenario Outline: Talk page functions across required browsers
    Given a talk page
    When viewed in <browser> <version>
    Then core functionality should work completely
    And enhanced features should degrade gracefully if unsupported
    And the page should provide a usable experience

    Examples:
      | browser        | version      |
      | Mobile Safari  | iOS 12+      |
      | Chrome Mobile  | Android 8+   |
      | Desktop Chrome | latest 2     |
      | Desktop Safari | macOS 10.14+ |
      | Desktop Firefox| latest 2     |
      | Edge           | Chromium     |

  # Maps to TS-042 through TS-044: Content Security
  Scenario: Talk page handles content securely
    Given various content inputs including potential XSS vectors
    When Jekyll processes the content
    Then all user-provided content should be properly escaped
    And Content Security Policy headers should prevent inline scripts
    And external links should include rel="noopener" for security
    And no script injection vulnerabilities should exist

  # Maps to user journey: QR code verification during talk
  Scenario: QR code verification workflow during presentation
    Given I am attending a conference talk
    When I scan the QR code displayed by the speaker
    Then I should see the talk page load within reasonable time
    And I should be able to verify the correct content is displayed
    And I should be able to bookmark the page for later reference
    And the URL should be clean and shareable with colleagues

  # Maps to user journey: Post-talk return and resource access
  Scenario: Post-talk resource access workflow
    Given I bookmarked a shownotes page during a talk
    When I return to the bookmarked page after the talk
    Then the page should load reliably
    And I should easily find slides and presentation materials
    And I should see any code repositories or demos
    And I should find relevant links mentioned during the talk
    And resources should be organized in a logical, scannable order