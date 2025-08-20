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

  # Maps to TS-045 through TS-048: WCAG Compliance
  Scenario: Talk page meets accessibility standards
    Given a talk page with complete content
    When evaluated with accessibility testing tools
    Then WCAG 2.1 AA automated tests should pass
    And screen readers should navigate all content sections
    And all interactive elements should be reachable via keyboard only
    And color contrast ratios should measure at least 4.5:1 for normal text

  # Maps to TS-049 through TS-052: Semantic Structure
  Scenario: Talk page uses proper semantic HTML structure
    Given a rendered talk page
    When analyzing the HTML markup
    Then semantic HTML elements should be used (article, section, nav)
    And headings should follow logical hierarchy (h1 → h2 → h3)
    And all images should have descriptive alt attributes
    And skip navigation links should enable content jumping

  # Maps to TS-053 through TS-055: Notification Placeholders
  Scenario: Talk page includes future feature placeholders
    Given a talk page design
    When reviewing the layout sections
    Then placeholder for email notifications should be visible
    And future feature areas should be designed into layout
    And design patterns should remain consistent across sections

  # Maps to TS-056 through TS-059: GitHub Pages Deployment
  Scenario: Site deploys automatically via GitHub Pages
    Given a GitHub repository with Jekyll site
    When code is pushed to main branch
    Then GitHub Actions workflow should run successfully
    And site should deploy to GitHub Pages automatically
    And custom domain should serve content correctly
    And all connections should redirect to HTTPS

  # Maps to TS-060 through TS-063: File Structure
  Scenario: Jekyll site maintains proper file organization
    Given a Jekyll site file structure
    When examining the organization
    Then talks should be stored in _talks/ directory
    And URLs should follow hierarchical structure
    And file naming should follow consistent conventions
    And assets should be organized logically by type

  # Maps to TS-064 through TS-067: Build Performance
  Scenario: Jekyll build process performs efficiently
    Given Jekyll build process
    When site builds are triggered
    Then full builds should complete within 5 minutes
    And incremental builds should be faster than full builds
    And build failures should not break the deployment
    And error messages should clearly indicate problems

  # Maps to TS-068 through TS-071: Progressive Enhancement
  Scenario: Talk page provides progressive enhancement
    Given various browser capabilities
    When JavaScript is disabled or CSS fails to load
    Then core functionality should work (reading content, following links)
    And JavaScript-enhanced features should degrade gracefully
    And older browsers should receive usable experience
    And missing CSS should not break content accessibility

  # Maps to TS-072 through TS-075: Transport Security
  Scenario: Talk page enforces proper security measures
    Given HTTP requests to the site
    When analyzing security headers and responses
    Then all HTTP requests should redirect to HTTPS
    And HSTS headers should prevent downgrade attacks
    And CSP headers should prevent code injection
    And X-Frame-Options should prevent clickjacking

  # Maps to TS-076 through TS-081: Required Fields
  Scenario Outline: Talk frontmatter validates required fields correctly
    Given talk frontmatter data with <field> as <value>
    When validating required fields
    Then <field> should <validation_result>

    Examples:
      | field      | value                    | validation_result                    |
      | slug       | "unique-talk-identifier" | be unique across all talks          |
      | title      | "Valid Title"            | be present and ≤ 200 characters     |
      | speaker    | "Jane Developer"         | be present and ≤ 100 characters     |
      | conference | "JSConf 2024"           | be present and ≤ 100 characters     |
      | date       | "2024-03-15"            | follow ISO 8601 format              |
      | status     | "completed"             | be one of: upcoming|completed|in-progress |

  # Maps to TS-082 through TS-085: Optional Fields
  Scenario: Talk frontmatter handles optional fields correctly
    Given talk frontmatter with various optional fields
    When processing the content
    Then location should validate as ≤ 200 characters when present
    And description should validate as ≤ 500 characters when present
    And abstract should validate as ≤ 2000 characters when present
    And level should validate as beginner|intermediate|advanced when present
    And missing optional fields should not cause errors

  # Maps to TS-086 through TS-089: Resource Structure
  Scenario: Resources validate proper structure
    Given resource data in frontmatter
    When validating resource structure
    Then type should be one of: slides|code|link|video
    And title should be present and ≤ 100 characters
    And URL should follow valid URL format
    And description should be optional but ≤ 200 characters when present

  # Maps to TS-090 through TS-093: Resource Validation
  Scenario: Resource URLs are properly validated and handled
    Given various resource URL formats
    When processing resources
    Then valid URLs should pass validation
    And invalid URLs should show clear error messages
    And broken links should not break page rendering
    And resources should group correctly by type
    And multiple resources of same type should be supported

  # Maps to TS-094 through TS-097: Social Information
  Scenario: Speaker social information validates and renders correctly
    Given speaker social information in frontmatter
    When rendering speaker section
    Then Twitter handles should validate @username format
    And GitHub usernames should validate platform rules
    And website URLs should validate as proper URLs
    And LinkedIn profiles should validate URL format
    And missing social fields should not show broken sections

  # Maps to TS-098 through TS-101: Page Navigation
  Scenario: Site navigation functions properly across pages
    Given site navigation structure
    When navigating between pages
    Then page hierarchy should be visually clear
    And breadcrumbs should show current location
    And browser back/forward buttons should function correctly
    And keyboard focus should be maintained during navigation

  # Maps to TS-102 through TS-105: Content Discovery
  Scenario: Content discovery features work as expected
    Given multiple talks in the system
    When accessing content discovery features
    Then talk listing page should show all talks
    And talks should be organized by date/conference
    And content organization should follow logical patterns
    And future search/recommendation features should have placeholders

  # Maps to TS-106 through TS-109: Design Consistency
  Scenario: Visual design remains consistent across all pages
    Given multiple pages of the site
    When comparing visual design elements
    Then heading styles should be consistent across pages
    And color scheme should follow defined palette
    And font choices and sizing should be consistent
    And interactive states should provide clear visual feedback

  # Maps to TS-110 through TS-113: Brand Customization
  Scenario: Site supports basic theming and customization
    Given customization requirements
    When applying theme changes
    Then CSS variables should allow color customization
    And logo replacement should work correctly
    And theme changes should maintain design consistency
    And design system principles should be preserved

  # Maps to TS-114 through TS-117: User-Facing Errors
  Scenario: Error conditions are handled gracefully with helpful messages
    Given various error conditions
    When users encounter errors
    Then 404 pages should provide helpful information
    And broken resource links should show appropriate messages
    And error messages should be user-friendly
    And recovery options should be suggested

  # Maps to TS-118 through TS-121: Graceful Degradation
  Scenario: Site handles incomplete or malformed content gracefully
    Given incomplete or malformed content
    When pages are rendered
    Then missing fields should not break layout
    And partial data should still show useful information
    And fallback content should appear where appropriate
    And core functionality should remain available