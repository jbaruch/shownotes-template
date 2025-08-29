#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'

class SpeakerConfigurationVisualTest < Minitest::Test
  def setup
    @site_path = File.join(File.dirname(__FILE__), '..', '..', '..', '_site', 'index.html')
    @config_path = File.join(File.dirname(__FILE__), '..', '..', '..', '_config.yml')
    @screenshots_dir = File.join(File.dirname(__FILE__), '..', '..', 'screenshots', 'speaker_config')
    
    FileUtils.mkdir_p(@screenshots_dir)
    
    # Ensure the site is built
    unless File.exist?(@site_path)
      system('bundle', 'exec', 'jekyll', 'build', '--quiet', chdir: File.join(File.dirname(__FILE__), '..', '..', '..'))
    end
    
    # Load the real configuration
    @config = YAML.load_file(@config_path)
  end

  def test_homepage_visual_elements_present
    # Test that visual elements are present in the real built site
    index_content = File.read(@site_path)
    
    # Visual structure elements should be present
    assert_includes index_content, 'class="hero-section"', "Hero section should be visually present"
    assert_includes index_content, 'class="hero-content"', "Hero content should be visually present"
    
    # Speaker info should be visually displayed
    speaker_config = @config['speaker']
    if speaker_config
      if speaker_config['display_name'] || speaker_config['name']
        assert_includes index_content, '<h1>', "Speaker name should be visually prominent with h1 tag"
      end
      
      if speaker_config['bio']
        assert_includes index_content, 'class="hero-description"', "Bio should be visually styled"
      end
    end
  end

  def test_avatar_visual_display
    # Test avatar visual presence in real site
    index_content = File.read(@site_path)
    
    speaker_config = @config['speaker']
    if speaker_config
      # Check if avatar should be displayed
      has_github = speaker_config['social'] && speaker_config['social']['github'] && !speaker_config['social']['github'].empty?
      has_custom = speaker_config['avatar_url'] && !speaker_config['avatar_url'].empty?
      
      if has_github || has_custom
        assert_includes index_content, 'class="author-avatar"', "Avatar should be visually displayed when configured"
        assert_includes index_content, 'class="hero-image"', "Avatar should be in hero image container for proper visual layout"
      end
    end
  end

  def test_social_links_visual_display
    # Test social media links visual presence in real site
    index_content = File.read(@site_path)
    
    speaker_config = @config['speaker']
    if speaker_config && speaker_config['social']
      social_config = speaker_config['social']
      configured_platforms = social_config.select { |_, username| username && !username.empty? }
      
      if configured_platforms.any?
        assert_includes index_content, 'class="speaker-social-links"', "Social links container should be visually present"
        
        # Check each configured platform has visual elements
        configured_platforms.each do |platform, _|
          assert_includes index_content, "class=\"social-link #{platform}\"", "#{platform} should be visually represented"
          assert_includes index_content, 'class="social-icon"', "Social icons should be visually present"
        end
      end
    end
  end

  def test_responsive_visual_structure
    # Test that responsive design elements are present in real site
    index_content = File.read(@site_path)
    
    # Should have responsive viewport meta tag
    assert_includes index_content, 'name="viewport"', "Should have responsive viewport meta tag"
    assert_includes index_content, 'width=device-width', "Should be configured for mobile devices"
    
    # Should have responsive wrapper elements
    assert_includes index_content, 'class="wrapper"', "Should have wrapper elements for responsive layout"
  end

  def test_accessibility_visual_elements
    # Test accessibility visual elements in real site
    index_content = File.read(@site_path)
    
    # Should have skip navigation for screen readers
    assert_includes index_content, 'class="skip-link"', "Should have skip navigation link"
    
    # Social links should have aria labels for accessibility
    if index_content.include?('class="social-link')
      assert_includes index_content, 'aria-label=', "Social links should have aria labels for accessibility"
    end
    
    # Should have proper heading structure
    assert_includes index_content, '<h1>', "Should have h1 for main heading"
    
    # Should have proper alt attributes for images
    if index_content.include?('class="author-avatar"')
      assert_includes index_content, 'alt=', "Avatar image should have alt attribute"
    end
  end

  def test_no_hardcoded_test_values_visual
    # Ensure no test-specific values appear in visual output
    index_content = File.read(@site_path)
    
    # Should not contain any test placeholders
    refute_includes index_content, 'Test Speaker', "Should not contain hardcoded test speaker names"
    refute_includes index_content, 'testing GitHub avatar', "Should not contain test-specific bio content"
    refute_includes index_content, 'githubuser', "Should not contain test social media usernames"
    refute_includes index_content, 'octocat', "Should not contain hardcoded test GitHub usernames"
  end

  private

  def take_screenshot_note
    # Note: Screenshot functionality would require Playwright or similar
    # For now, we're testing the HTML structure for visual elements
    puts "Note: To enable visual screenshots, install Playwright"
  end
end
