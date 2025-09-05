# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../../lib/talk_renderer'

# Unit tests for embed functionality based on Gherkin specifications
class EmbedFunctionalityTest < Minitest::Test
  def setup
    @renderer = TalkRenderer.new
  end

  # Test Google Slides URL detection and embedding
  def test_google_slides_url_detection_and_embedding
    # Given a resource with Google Slides URL
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'slides' => {
          'url' => 'https://docs.google.com/presentation/d/1ABC123/edit#slide=id.p1',
          'title' => 'My Slides'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then the URL should be detected as Google Slides and embedded
    assert_includes html, 'slides-embed', 'Should include slides-embed class'
    assert_includes html, 'responsive-iframe', 'Should include responsive-iframe class'
    assert_includes html, 'docs.google.com/presentation/d/e/1ABC123/pubembed', 'Should convert to embed URL'
    assert_includes html, 'frameborder="0"', 'Should have frameborder="0"'
    assert_includes html, 'allowfullscreen', 'Should have allowfullscreen attribute'
    assert_includes html, 'loading="lazy"', 'Should have loading="lazy" attribute'
  end

  # Test YouTube watch URL detection and embedding
  def test_youtube_watch_url_detection_and_embedding
    # Given a resource with YouTube watch URL
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title' => 'Demo Video'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then it should be detected as YouTube and embedded
    assert_includes html, 'video-embed', 'Should include video-embed class'
    assert_includes html, 'responsive-iframe', 'Should include responsive-iframe class'
    assert_includes html, 'youtube.com/embed/dQw4w9WgXcQ', 'Should convert to standard embed URL'
    assert_includes html, 'frameborder="0"', 'Should have frameborder="0"'
    assert_includes html, 'allowfullscreen', 'Should have allowfullscreen attribute'
  end

  # Test YouTube short URL detection and embedding
  def test_youtube_short_url_detection_and_embedding
    # Given a resource with YouTube short URL
    talk_data = {
      'title' => 'Test Talk', 
      'resources' => {
        'video' => {
          'url' => 'https://youtu.be/dQw4w9WgXcQ',
          'title' => 'Demo Video'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then it should be detected as YouTube and embedded
    assert_includes html, 'video-embed', 'Should detect youtu.be as YouTube'
    assert_includes html, 'youtube.com/embed/dQw4w9WgXcQ', 'Should convert short URL to embed'
  end

  # Test non-embeddable URL fallback to link
  def test_non_embeddable_url_fallback_to_link
    # Given a resource with non-embeddable URL
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'links' => {
          'url' => 'https://example.com/document.pdf',
          'title' => 'PDF Document'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then it should be rendered as a standard link
    refute_includes html, 'embed-container', 'Should not include embed container'
    refute_includes html, '<iframe', 'Should not include iframe'
    assert_includes html, '<a href="https://example.com/document.pdf"', 'Should include link'
    assert_includes html, 'target="_blank"', 'Should have target="_blank"'
    assert_includes html, 'rel="noopener noreferrer"', 'Should have rel attributes'
  end

  # Test malformed Google Slides URL fallback
  def test_malformed_google_slides_url_fallback
    # Given a resource with malformed Google Slides URL
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'slides' => {
          'url' => 'https://docs.google.com/presentation/invalid',
          'title' => 'Invalid Slides'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then it should fall back to displaying as standard link
    assert_includes html, '<a href=', 'Should fall back to link'
    refute_includes html, '<iframe', 'Should not include iframe for malformed URL'
  end

  # Test YouTube URL with parameters extraction
  def test_youtube_url_with_parameters_extraction
    # Given a resource with YouTube URL containing parameters
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s&list=PLtest',
          'title' => 'Video with params'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then the video ID should be extracted correctly
    assert_includes html, 'youtube.com/embed/dQw4w9WgXcQ', 'Should extract clean video ID'
    refute_includes html, '&t=30s', 'Should not include timestamp parameter'
    refute_includes html, '&list=', 'Should not include playlist parameter'
  end

  # Test responsive iframe attributes
  def test_responsive_iframe_attributes
    # Given a resource with embeddable URL
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title' => 'Test Video'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then the iframe should have proper attributes
    assert_includes html, 'frameborder="0"', 'Should have frameborder="0"'
    assert_includes html, 'allowfullscreen', 'Should have allowfullscreen'
    assert_includes html, 'loading="lazy"', 'Should have loading="lazy"'
    assert_includes html, 'embed-container', 'Should be wrapped in responsive container'
  end

  # Test mixed resource types in same group - array format
  def test_mixed_resource_types_array_format
    # Given a resource group containing mixed types in array format
    talk_data = {
      'title' => 'Test Talk',
      'resources' => [
        {
          'type' => 'slides',
          'url' => 'https://docs.google.com/presentation/d/1ABC123/edit',
          'title' => 'My Slides'
        },
        {
          'type' => 'video',
          'url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title' => 'Demo Video'
        },
        {
          'type' => 'links',
          'url' => 'https://example.com/article',
          'title' => 'Related Link'
        }
      ]
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then mixed rendering should work correctly
    assert_includes html, 'slides-embed', 'Slides should be embedded'
    assert_includes html, 'video-embed', 'Video should be embedded'
    assert_includes html, '<a href="https://example.com/article"', 'Link should remain as link'
    assert_includes html, 'docs.google.com/presentation/d/e/1ABC123/pubembed', 'Slides should use embed URL'
    assert_includes html, 'youtube.com/embed/dQw4w9WgXcQ', 'Video should use embed URL'
  end

  # Test HTML escaping for security
  def test_html_escaping_for_security
    # Given a resource with potentially dangerous HTML in title
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title' => 'Test <script>alert(\'xss\')</script> Resource'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then the title should be HTML escaped
    refute_includes html, '<script>', 'Should not include unescaped script tags'
    refute_includes html, 'alert(\'xss\')', 'Should not include script content'
    assert_includes html, '&lt;script&gt;', 'Should escape HTML entities'
  end

  # Test hash format resource compatibility
  def test_hash_format_resource_compatibility
    # Given resources in hash format with embeddable URLs
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'slides' => {
          'url' => 'https://docs.google.com/presentation/d/1ABC123/edit',
          'title' => 'Presentation'
        },
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title' => 'Demo'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then both resources should be embedded and structure preserved
    assert_includes html, 'slides-embed', 'Slides should be embedded'
    assert_includes html, 'video-embed', 'Video should be embedded'
    assert_includes html, '<h3>Slides</h3>', 'Should preserve hash grouping'
    assert_includes html, '<h3>Video</h3>', 'Should preserve hash grouping'
  end

  # Test performance requirement validation
  def test_performance_requirement_validation
    # Given a talk with multiple embeddable resources
    talk_data = {
      'title' => 'Test Talk',
      'resources' => (1..5).map do |i|
        {
          'type' => 'video',
          'url' => "https://www.youtube.com/watch?v=dQw4w9WgX#{i}",
          'title' => "Video #{i}"
        }
      end
    }

    # When I generate the resource HTML with timing
    start_time = Time.now
    html = @renderer.generate_talk_page(talk_data)
    end_time = Time.now
    generation_time = (end_time - start_time) * 1000 # Convert to milliseconds

    # Then the generation should meet performance requirements
    assert generation_time < 50, "Generation should be under 50ms, took #{generation_time}ms"
    iframe_count = html.scan(/<iframe/).length
    assert_equal 5, iframe_count, 'Should generate 5 embedded iframes'
    refute_includes html, 'http://', 'Should not make external HTTP calls during generation'
  end

  # Test empty URL handling
  def test_empty_url_handling
    # Given a resource with empty URL
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'slides' => {
          'url' => '',
          'title' => 'Empty URL Resource'
        }
      }
    }

    # When I generate the resource HTML
    html = nil
    begin
      html = @renderer.generate_talk_page(talk_data)
      # Should not raise any exceptions
    rescue => e
      flunk("Should handle empty URL gracefully but got: #{e.message}")
    end
    
    # Then it should be handled gracefully
    assert html, 'Should generate some HTML'
    refute_includes html, '<iframe', 'Should not include iframe for empty URL'
    # Should either skip resource or show fallback (implementation dependent)
  end

  # Test very long URL handling
  def test_very_long_url_handling
    # Given a resource with very long but valid Google Slides URL
    long_url_suffix = 'A' * 400 # Create 400-character suffix
    talk_data = {
      'title' => 'Test Talk',
      'resources' => {
        'slides' => {
          'url' => "https://docs.google.com/presentation/d/1#{long_url_suffix}/edit",
          'title' => 'Very Long URL'
        }
      }
    }

    # When I generate the resource HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then it should be processed correctly
    assert_includes html, 'slides-embed', 'Should detect long URL as slides'
    assert_includes html, 'docs.google.com/presentation/d/e/1', 'Should process long URL correctly'
    iframe_match = html.match(/src="([^"]*)"/)
    assert iframe_match, 'Should generate valid iframe src'
    assert iframe_match[1].start_with?('https://'), 'Should generate valid HTTPS URL'
  end

  # Test URL validation and security
  def test_url_validation_and_security
    # Given potentially malicious URLs
    malicious_urls = [
      'javascript:alert("xss")',
      'data:text/html,<script>alert("xss")</script>',
      'https://docs.google.com/presentation/"><script>alert("xss")</script>',
      'ftp://malicious.com/presentation'
    ]

    malicious_urls.each do |malicious_url|
      talk_data = {
        'title' => 'Test Talk',
        'resources' => {
          'slides' => {
            'url' => malicious_url,
            'title' => 'Malicious Resource'
          }
        }
      }

      # When I generate the resource HTML
      html = @renderer.generate_talk_page(talk_data)

      # Then malicious URLs should be rejected or escaped
      refute_includes html, 'javascript:', "Should reject javascript: URL: #{malicious_url}"
      refute_includes html, 'data:', "Should reject data: URL: #{malicious_url}"  
      refute_includes html, '<script>', "Should escape script tags: #{malicious_url}"
      # Should either fall back to link or reject entirely
    end
  end
end