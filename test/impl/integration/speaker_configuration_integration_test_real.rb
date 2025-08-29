#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'

class SpeakerConfigurationIntegrationTest < Minitest::Test
  def setup
    @site_path = File.join(File.dirname(__FILE__), '..', '..', '..', '_site', 'index.html')
    @config_path = File.join(File.dirname(__FILE__), '..', '..', '..', '_config.yml')
    
    # Ensure the site is built
    unless File.exist?(@site_path)
      system('bundle', 'exec', 'jekyll', 'build', '--quiet', chdir: File.join(File.dirname(__FILE__), '..', '..', '..'))
    end
    
    # Load the real configuration
    @config = YAML.load_file(@config_path)
  end

  def test_github_avatar_integration
    # Test the real built site with real configuration
    index_content = File.read(@site_path)
    
    # Should use GitHub avatar if github social is configured
    if @config['speaker'] && @config['speaker']['social'] && @config['speaker']['social']['github']
      assert_includes index_content, 'github.com/', "GitHub avatar URL should be present when GitHub social is configured"
      assert_includes index_content, '.png?size=200', "Avatar should have size parameter"
      assert_includes index_content, 'class="author-avatar"', "Avatar should have correct CSS class"
    end
  end

  def test_custom_avatar_fallback_integration
    # Test the real built site
    index_content = File.read(@site_path)
    
    # Should have avatar from either GitHub or custom URL
    speaker_config = @config['speaker']
    if speaker_config
      if speaker_config['avatar_url'] && !speaker_config['avatar_url'].empty?
        # Custom avatar should be present
        assert_includes index_content, 'class="author-avatar"', "Custom avatar should have correct CSS class"
      elsif speaker_config['social'] && speaker_config['social']['github'] && !speaker_config['social']['github'].empty?
        # GitHub avatar should be present
        assert_includes index_content, 'github.com/', "GitHub avatar should be used as fallback"
        assert_includes index_content, 'class="author-avatar"', "GitHub avatar should have correct CSS class"
      end
    end
  end

  def test_social_media_links_integration
    # Test the real built site with real configuration
    index_content = File.read(@site_path)
    
    # Check each configured social media platform
    if @config['speaker'] && @config['speaker']['social']
      social_config = @config['speaker']['social']
      
      # Only check for platforms that are actually configured
      social_config.each do |platform, username|
        next if username.nil? || username.empty?
        
        assert_includes index_content, "class=\"social-link #{platform}\"", 
          "#{platform.capitalize} link should be present when configured in _config.yml"
      end
      
      # Should have the social links container if any social media is configured
      if social_config.any? { |_, username| username && !username.empty? }
        assert_includes index_content, 'class="speaker-social-links"', 
          "Social links container should be present when social media is configured"
      end
    end
  end

  def test_speaker_information_display_integration
    # Test the real built site
    index_content = File.read(@site_path)
    
    speaker_config = @config['speaker']
    if speaker_config
      # Should have speaker name/title
      if speaker_config['display_name'] && !speaker_config['display_name'].empty?
        assert_includes index_content, speaker_config['display_name'], "Display name should be present in site"
      elsif speaker_config['name'] && !speaker_config['name'].empty?
        assert_includes index_content, speaker_config['name'], "Speaker name should be present in site"
      end
      
      # Should have bio if configured
      if speaker_config['bio'] && !speaker_config['bio'].empty?
        assert_includes index_content, 'class="hero-description"', "Bio should be displayed with correct CSS class"
      end
    end
    
    # Should have presentations title
    assert_includes index_content, 'Presentations by', "Should have presentations title"
  end

  def test_site_structure_integration
    # Test the real built site structure
    index_content = File.read(@site_path)
    
    # Basic site structure should be present
    assert_includes index_content, 'class="hero-section"', "Should have hero section"
    assert_includes index_content, 'class="hero-content"', "Should have hero content"
    assert_includes index_content, 'id="main-content"', "Should have main content area"
    assert_includes index_content, 'class="site-header"', "Should have site header"
    assert_includes index_content, 'class="site-footer"', "Should have site footer"
  end

  def test_no_hardcoded_values
    # Ensure no test-specific hardcoded values are in the real site
    index_content = File.read(@site_path)
    
    # Should not contain any test-specific hardcoded values
    refute_includes index_content, 'Test Display Name', "Should not contain hardcoded test values"
    refute_includes index_content, 'testlinkedin', "Should not contain hardcoded test social media usernames"
    refute_includes index_content, 'testtwitter', "Should not contain hardcoded test social media usernames"
    refute_includes index_content, 'testgithub', "Should not contain hardcoded test social media usernames"
    refute_includes index_content, 'example.com/custom.jpg', "Should not contain hardcoded test URLs"
  end
end
