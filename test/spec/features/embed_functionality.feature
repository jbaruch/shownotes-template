Feature: Embed functionality for slides and video content
  As a talk attendee
  I want to view embedded slides and videos directly on the page
  So that I don't need to navigate away to access content

  Background:
    Given a talk renderer is initialized
    And the talk has various resource types with URLs

  Scenario: Google Slides URL detection and embedding
    Given a resource with URL "https://docs.google.com/presentation/d/1ABC123/edit#slide=id.p1"
    When I generate the resource HTML
    Then the URL should be detected as Google Slides
    And it should be rendered as an embedded iframe
    And the iframe should use the converted embed URL "https://docs.google.com/presentation/d/e/1ABC123/pubembed?start=false&loop=false&delayms=3000"
    And the iframe should have class "responsive-iframe"
    And the container should have class "slides-embed"

  Scenario: YouTube watch URL detection and embedding
    Given a resource with URL "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    When I generate the resource HTML
    Then the URL should be detected as YouTube
    And it should be rendered as an embedded iframe
    And the iframe should use the converted embed URL "https://www.youtube.com/embed/dQw4w9WgXcQ"
    And the iframe should have class "responsive-iframe"
    And the container should have class "video-embed"

  Scenario: YouTube short URL detection and embedding
    Given a resource with URL "https://youtu.be/dQw4w9WgXcQ"
    When I generate the resource HTML
    Then the URL should be detected as YouTube
    And it should be rendered as an embedded iframe
    And the iframe should use the converted embed URL "https://www.youtube.com/embed/dQw4w9WgXcQ"

  Scenario: Non-embeddable URL fallback to link
    Given a resource with URL "https://example.com/document.pdf"
    When I generate the resource HTML
    Then it should not be detected as embeddable
    And it should be rendered as a standard link
    And the link should have target="_blank" attribute
    And the link should have rel="noopener noreferrer" attribute

  Scenario: Malformed Google Slides URL fallback
    Given a resource with URL "https://docs.google.com/presentation/invalid"
    When I generate the resource HTML
    Then it should fall back to displaying as a standard link
    And no errors should be raised

  Scenario: YouTube URL with parameters extraction
    Given a resource with URL "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s&list=PLtest"
    When I generate the resource HTML
    Then the video ID should be extracted correctly
    And the iframe should use the clean embed URL "https://www.youtube.com/embed/dQw4w9WgXcQ"

  Scenario: Responsive iframe attributes
    Given a resource with an embeddable URL
    When I generate the resource HTML
    Then the iframe should have frameborder="0"
    And the iframe should have allowfullscreen attribute
    And the iframe should have loading="lazy"
    And the iframe should be wrapped in a responsive container

  Scenario: Mixed resource types in same group
    Given a resource group containing:
      | type   | url                                                                    | title        |
      | slides | https://docs.google.com/presentation/d/1ABC123/edit                   | My Slides    |
      | video  | https://www.youtube.com/watch?v=dQw4w9WgXcQ                           | Demo Video   |
      | links  | https://example.com/article                                           | Related Link |
    When I generate the resource HTML
    Then the slides should be embedded as iframe
    And the video should be embedded as iframe  
    And the link should remain as clickable link
    And all resources should be grouped under the same section

  Scenario: HTML escaping for security
    Given a resource with title "Test <script>alert('xss')</script> Resource"
    And the resource has a valid embeddable URL
    When I generate the resource HTML
    Then the title should be HTML escaped
    And no script execution should be possible
    And the iframe src should be properly validated

  Scenario: Hash format resource compatibility
    Given resources in hash format:
      """
      {
        "slides": {
          "url": "https://docs.google.com/presentation/d/1ABC123/edit",
          "title": "Presentation"
        },
        "video": {
          "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", 
          "title": "Demo"
        }
      }
      """
    When I generate the resource HTML
    Then both resources should be embedded as iframes
    And the existing hash structure should be preserved

  Scenario: Array format resource compatibility
    Given resources in array format:
      """
      [
        {
          "type": "slides",
          "url": "https://docs.google.com/presentation/d/1ABC123/edit",
          "title": "Presentation"
        },
        {
          "type": "video", 
          "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          "title": "Demo"
        }
      ]
      """
    When I generate the resource HTML
    Then both resources should be embedded as iframes
    And the resources should be grouped by type
    And the existing array structure should be preserved

  Scenario: Performance requirement validation
    Given a talk with 5 embeddable resources
    When I generate the resource HTML
    Then the generation should complete in under 50ms
    And the output should contain 5 embedded iframes
    And no external API calls should be made

  Scenario: Empty or missing URL handling  
    Given a resource with empty URL ""
    When I generate the resource HTML
    Then it should be handled gracefully
    And no errors should be raised
    And the resource should be skipped or show fallback

  Scenario: Very long URL handling
    Given a resource with a 500-character valid Google Slides URL
    When I generate the resource HTML  
    Then it should be processed correctly
    And generate proper embed HTML
    And the iframe src should be valid