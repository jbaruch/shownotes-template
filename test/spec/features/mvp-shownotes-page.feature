Feature: MVP Shownotes Page
  As a conference attendee
  I want to access a simple shownotes page for a talk
  So that I can bookmark resources, verify QR codes work, and return later for content

  Background:
    Given a Jekyll-generated shownotes site is deployed on GitHub Pages
    And a talk page exists with basic metadata and resources

  Scenario: Quick QR code verification during talk
    Given I am attending a conference talk
    When I scan the QR code displayed by the speaker
    Then I should see the shownotes page load within reasonable time
    And the page should display the talk title and speaker name
    And I should be able to bookmark the page for later reference
    And the URL should be clean and shareable

  Scenario: Mobile-responsive page display
    Given I access the shownotes page on a mobile device
    When the page loads
    Then the layout should be mobile-optimized
    And text should be readable without zooming
    And interactive elements should be touch-friendly
    And the page should work with or without JavaScript

  Scenario: Talk metadata display
    Given I visit a shownotes page
    When the page loads
    Then I should see the talk title prominently displayed
    And I should see the speaker name
    And I should see the conference name and date
    And I should see a brief talk description
    And I should see the talk status (upcoming/completed)

  Scenario: Resource access and display
    Given a shownotes page has associated resources
    When I visit the page
    Then I should see a list of available resources
    And each resource should have a clear title and description
    And resource links should open appropriately (new tab for external links)
    And slide links should be clearly marked
    And code repository links should be distinguishable

  Scenario: Post-talk resource exploration
    Given I return to a shownotes page after the talk
    When I explore the available resources
    Then I should easily find slides and presentation materials
    And I should see any code repositories or demos
    And I should find relevant links mentioned during the talk
    And resources should be organized in a logical order

  Scenario: Page sharing capabilities
    Given I want to share a shownotes page with colleagues
    When I copy the page URL
    Then the URL should be clean and meaningful
    And the page should display well when shared on social platforms
    And meta tags should provide appropriate preview information
    And the page should be accessible without authentication

  Scenario: Bookmark and return workflow
    Given I bookmarked a shownotes page during a talk
    When I return to the bookmarked page later
    Then the page should load reliably
    And all content should remain accessible
    And any updated resources should be visible
    And the page structure should be consistent

  Scenario: Future notification signup placeholder
    Given I am on a shownotes page
    When I look for notification options
    Then I should see a placeholder or coming soon message for email notifications
    And the design should accommodate future notification signup
    But no functional email signup should be present in MVP

  Scenario: Accessibility and performance
    Given I access a shownotes page
    When the page loads
    Then it should meet basic accessibility standards
    And it should work with screen readers
    And it should have appropriate heading structure
    And it should load reasonably fast on conference Wi-Fi
    And it should work across modern browsers

  Scenario: Jekyll and GitHub Pages integration
    Given the site is built with Jekyll
    When content is updated in the repository
    Then the site should rebuild automatically via GitHub Actions
    And changes should be reflected on the live site
    And the build process should complete successfully
    And static assets should be served efficiently