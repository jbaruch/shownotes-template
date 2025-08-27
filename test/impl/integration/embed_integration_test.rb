# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../../lib/talk_renderer'

# Integration tests for embed functionality with real-world scenarios
class EmbedIntegrationTest < Minitest::Test
  def setup
    @renderer = TalkRenderer.new
  end

  # Test complete talk page with embedded resources
  def test_complete_talk_page_with_embedded_resources
    # Given a complete talk with mixed resource types
    talk_data = {
      'title' => 'Modern JavaScript Patterns',
      'speaker' => 'John Doe',
      'conference' => 'JSConf 2024',
      'date' => '2024-08-26',
      'description' => 'A comprehensive overview of modern JavaScript patterns',
      'resources' => {
        'slides' => {
          'url' => 'https://docs.google.com/presentation/d/1vQtLbueXXLmtdrkOsEFqtDlhM-rzaoaEFacQ8fMrmn4w9qFptjZe0RlsaUcUjMwyg/edit#slide=id.p1',
          'title' => 'Conference Slides'
        },
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=Yh_hs4mZTiY',
          'title' => 'Full Presentation Video'
        },
        'code' => {
          'url' => 'https://github.com/example/modern-js-patterns',
          'title' => 'Source Code Repository'
        },
        'links' => [
          {
            'url' => 'https://developer.mozilla.org/en-US/docs/Web/JavaScript',
            'title' => 'JavaScript Documentation'
          },
          {
            'url' => 'https://tc39.es/ecma262/',
            'title' => 'ECMAScript Specification'
          }
        ]
      }
    }

    # When I generate the complete talk page
    html = @renderer.generate_talk_page(talk_data)

    # Then the page should contain embedded content and fallback links
    assert_includes html, '<h1 class="talk-title">Modern JavaScript Patterns</h1>', 'Should include talk title'
    assert_includes html, 'John Doe', 'Should include speaker name'
    
    # Embedded content
    assert_includes html, 'slides-embed', 'Should embed Google Slides'
    assert_includes html, 'video-embed', 'Should embed YouTube video'
    assert_includes html, 'docs.google.com/presentation/d/e/', 'Should convert slides URL'
    assert_includes html, 'youtube-nocookie.com/embed/Yh_hs4mZTiY', 'Should convert video URL'
    
    # Fallback links
    assert_includes html, 'github.com/example/modern-js-patterns', 'Should keep code link'
    assert_includes html, 'developer.mozilla.org', 'Should keep doc links'
    assert_includes html, 'tc39.es', 'Should keep spec links'
    
    # Structure preservation
    assert_includes html, '<h3>Slides</h3>', 'Should preserve resource grouping'
    assert_includes html, '<h3>Video</h3>', 'Should preserve resource grouping'
    assert_includes html, '<h3>Code</h3>', 'Should preserve resource grouping'
    assert_includes html, '<h3>Links</h3>', 'Should preserve resource grouping'
  end

  # Test responsive CSS and mobile optimization
  def test_responsive_css_and_mobile_optimization
    # Given a talk with embeddable content
    talk_data = {
      'title' => 'Mobile Test Talk',
      'resources' => {
        'slides' => {
          'url' => 'https://docs.google.com/presentation/d/1ABC123/edit',
          'title' => 'Test Slides'
        },
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title' => 'Test Video'
        }
      }
    }

    # When I generate the page HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then it should include responsive design elements
    assert_includes html, 'embed-container', 'Should include responsive containers'
    assert_includes html, 'responsive-iframe', 'Should include responsive iframe class'
    assert_includes html, 'video-embed', 'Should include video-specific responsive class'
    assert_includes html, 'slides-embed', 'Should include slides-specific responsive class'
    
    # Verify iframe attributes for mobile
    iframe_matches = html.scan(/<iframe[^>]*>/)
    iframe_matches.each do |iframe|
      assert_includes iframe, 'loading="lazy"', 'All iframes should have lazy loading'
      assert_includes iframe, 'frameborder="0"', 'All iframes should have no frame border'
    end
  end

  # Test SEO and accessibility features with embedded content
  def test_seo_and_accessibility_with_embedded_content
    # Given a talk with embedded resources
    talk_data = {
      'title' => 'Accessibility in Web Apps',
      'speaker' => 'Jane Smith',
      'description' => 'Learn how to build accessible web applications',
      'resources' => {
        'slides' => {
          'url' => 'https://docs.google.com/presentation/d/1ABC123/edit',
          'title' => 'Accessibility Guidelines Slides'
        },
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=accessibility123',
          'title' => 'Accessibility Demo Video'
        }
      }
    }

    # When I generate the page HTML
    html = @renderer.generate_talk_page(talk_data)

    # Then it should maintain SEO and accessibility features
    assert_includes html, '<title>Accessibility in Web Apps - Talk</title>', 'Should include page title'
    assert_includes html, 'name="description"', 'Should include meta description'
    assert_includes html, 'application/ld+json', 'Should include structured data'
    assert_includes html, '"@type": "PresentationDigitalDocument"', 'Should include structured data type'
    
    # Accessibility for embedded content
    iframe_matches = html.scan(/<iframe[^>]*allowfullscreen[^>]*>/)
    refute_empty iframe_matches, 'Embedded iframes should support fullscreen for accessibility'
  end

  # Test error handling and graceful degradation
  def test_error_handling_and_graceful_degradation
    # Given a talk with mixed valid and invalid resources
    talk_data = {
      'title' => 'Error Handling Test',
      'resources' => {
        'slides' => nil, # Invalid: nil resource
        'video' => {
          'url' => 'https://www.youtube.com/watch?v=validVideo123',
          'title' => 'Valid Video'
        },
        'invalid' => {
          'url' => 'not-a-valid-url',
          'title' => 'Invalid URL'
        },
        'empty' => {
          'url' => '',
          'title' => 'Empty URL'
        }
      }
    }

    # When I generate the page HTML
    html = nil
    begin
      html = @renderer.generate_talk_page(talk_data)
    rescue => e
      flunk("Should handle mixed valid/invalid resources gracefully but got: #{e.message}")
    end

    # Then it should handle errors gracefully
    assert html, 'Should generate HTML despite errors'
    assert_includes html, '<h1 class="talk-title">Error Handling Test</h1>', 'Should still generate page structure'
    
    # Valid content should still work
    assert_includes html, 'youtube-nocookie.com/embed/validVideo123', 'Valid video should still embed'
    
    # Invalid content should not break the page
    refute_includes html, 'not-a-valid-url', 'Invalid URLs should be handled gracefully'
  end

  # Test real-world Google Slides URL patterns
  def test_real_world_google_slides_url_patterns
    # Test various real Google Slides URL formats
    test_cases = [
      {
        'input' => 'https://docs.google.com/presentation/d/1vQtLbueXXLmtdrkOsEFqtDlhM-rzaoaEFacQ8fMrmn4w9qFptjZe0RlsaUcUjMwyg/edit#slide=id.p1',
        'expected_id' => '1vQtLbueXXLmtdrkOsEFqtDlhM-rzaoaEFacQ8fMrmn4w9qFptjZe0RlsaUcUjMwyg'
      },
      {
        'input' => 'https://docs.google.com/presentation/d/1ABC-123_DEF/edit?usp=sharing',
        'expected_id' => '1ABC-123_DEF'
      },
      {
        'input' => 'https://docs.google.com/presentation/d/1SimpleID/present',
        'expected_id' => '1SimpleID'
      }
    ]

    test_cases.each do |test_case|
      # Given a talk with specific Google Slides URL format
      talk_data = {
        'title' => 'Slides Format Test',
        'resources' => {
          'slides' => {
            'url' => test_case['input'],
            'title' => 'Test Slides'
          }
        }
      }

      # When I generate the resource HTML
      html = @renderer.generate_talk_page(talk_data)

      # Then it should convert to proper embed URL
      assert_includes html, 'slides-embed', "Should detect slides URL: #{test_case['input']}"
      assert_includes html, "docs.google.com/presentation/d/e/#{test_case['expected_id']}/pubembed", 
                      "Should extract correct ID: #{test_case['expected_id']}"
      assert_includes html, 'start=false&loop=false&delayms=3000', 
                      'Should include proper embed parameters'
    end
  end

  # Test real-world YouTube URL patterns
  def test_real_world_youtube_url_patterns
    # Test various real YouTube URL formats
    test_cases = [
      {
        'input' => 'https://www.youtube.com/watch?v=Yh_hs4mZTiY&si=poyYPMMOOhiiTSZt',
        'expected_id' => 'Yh_hs4mZTiY'
      },
      {
        'input' => 'https://youtu.be/dQw4w9WgXcQ?t=42',
        'expected_id' => 'dQw4w9WgXcQ'
      },
      {
        'input' => 'https://www.youtube.com/watch?v=abc123XYZ&list=PLrAXtmRdnEQy&index=1',
        'expected_id' => 'abc123XYZ'
      },
      {
        'input' => 'https://m.youtube.com/watch?v=mobile123',
        'expected_id' => 'mobile123'
      }
    ]

    test_cases.each do |test_case|
      # Given a talk with specific YouTube URL format
      talk_data = {
        'title' => 'Video Format Test',
        'resources' => {
          'video' => {
            'url' => test_case['input'],
            'title' => 'Test Video'
          }
        }
      }

      # When I generate the resource HTML
      html = @renderer.generate_talk_page(talk_data)

      # Then it should convert to proper embed URL
      assert_includes html, 'video-embed', "Should detect video URL: #{test_case['input']}"
      assert_includes html, "youtube-nocookie.com/embed/#{test_case['expected_id']}", 
                      "Should extract correct video ID: #{test_case['expected_id']}"
      refute_includes html, '&t=', 'Should not include timestamp parameters'
      refute_includes html, '&list=', 'Should not include playlist parameters'
      refute_includes html, '&si=', 'Should not include tracking parameters'
    end
  end

  # Test performance with large number of embedded resources
  def test_performance_with_large_number_of_embedded_resources
    # Given a talk with many embedded resources
    large_resources = {}
    (1..20).each do |i|
      large_resources["video_#{i}"] = {
        'url' => "https://www.youtube.com/watch?v=video#{i}",
        'title' => "Video #{i}"
      }
      large_resources["slides_#{i}"] = {
        'url' => "https://docs.google.com/presentation/d/1slides#{i}/edit",
        'title' => "Slides #{i}"
      }
    end

    talk_data = {
      'title' => 'Performance Test Talk',
      'resources' => large_resources
    }

    # When I generate the page HTML with timing
    start_time = Time.now
    html = @renderer.generate_talk_page(talk_data)
    end_time = Time.now
    generation_time = (end_time - start_time) * 1000

    # Then it should handle many embeds efficiently
    assert generation_time < 100, "Large page generation should be under 100ms, took #{generation_time}ms"
    
    video_embeds = html.scan(/video-embed/).length
    slides_embeds = html.scan(/slides-embed/).length
    
    assert_equal 20, video_embeds, 'Should generate 20 video embeds'
    assert_equal 20, slides_embeds, 'Should generate 20 slides embeds'
    assert html.length > 10000, 'Should generate substantial HTML content'
  end

  # Test security validation with edge cases
  def test_security_validation_with_edge_cases
    # Test various potentially problematic URLs
    security_test_cases = [
      'https://docs.google.com/presentation/d/"><script>alert("xss")</script>/edit',
      'https://www.youtube.com/watch?v=valid&"><script>alert("xss")</script>',
      "https://docs.google.com/presentation/d/1ABC123/edit'><img src=x onerror=alert('xss')>",
      'https://www.youtube.com/watch?v=test&callback=alert(document.cookie)'
    ]

    security_test_cases.each do |malicious_url|
      talk_data = {
        'title' => 'Security Test',
        'resources' => {
          'test' => {
            'url' => malicious_url,
            'title' => 'Security Test Resource'
          }
        }
      }

      # When I generate the resource HTML
      html = @renderer.generate_talk_page(talk_data)

      # Then it should prevent XSS attacks
      refute_includes html, '<script>', "Should prevent script injection: #{malicious_url}"
      refute_includes html, 'alert(', "Should prevent alert injection: #{malicious_url}"
      refute_includes html, 'onerror=', "Should prevent event handler injection: #{malicious_url}"
      refute_includes html, 'document.cookie', "Should prevent cookie access: #{malicious_url}"
      
      # Should either sanitize or fall back to safe link
      if html.include?('<iframe')
        # If iframe is generated, ensure the src is safe
        iframe_src_match = html.match(/src="([^"]*)"/)
        if iframe_src_match
          src_url = iframe_src_match[1]
          assert src_url.start_with?('https://'), "Iframe src should be HTTPS: #{src_url}"
          refute_includes src_url, '<', "Iframe src should not contain HTML: #{src_url}"
          refute_includes src_url, '>', "Iframe src should not contain HTML: #{src_url}"
          refute_includes src_url, '"', "Iframe src should not contain quotes: #{src_url}"
        end
      end
    end
  end
end