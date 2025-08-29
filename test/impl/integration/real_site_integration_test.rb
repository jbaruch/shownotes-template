#!/usr/bin/env ruby

require 'minitest/autorun'

class RealSiteIntegrationTest < Minitest::Test
  def setup
    @site_path = File.join(File.dirname(__FILE__), '..', '..', '..', '_site', 'index.html')
    
    # Ensure the site is built
    unless File.exist?(@site_path)
      # Build the site if it doesn't exist
      system('bundle', 'exec', 'jekyll', 'build', '--quiet', chdir: File.join(File.dirname(__FILE__), '..', '..', '..'))
    end
  end

  def test_github_avatar_integration
    # Test the real built site
    index_content = File.read(@site_path)
    
    # Should use GitHub avatar for the real configured user
    assert_includes index_content, 'github.com/', "GitHub avatar URL should be present"
    assert_includes index_content, '.png?size=200', "Avatar should have size parameter"
    assert_includes index_content, 'class="author-avatar"', "Avatar should have correct CSS class"
  end

  def test_social_media_links_integration
    # Test the real built site
    index_content = File.read(@site_path)
    
    # Check social links are properly generated with correct CSS classes
    assert_includes index_content, 'class="social-link linkedin"', "LinkedIn link should be present"
    assert_includes index_content, 'class="social-link x"', "X/Twitter link should be present"
    assert_includes index_content, 'class="social-link github"', "GitHub link should be present"
    assert_includes index_content, 'class="social-link bluesky"', "Bluesky link should be present"
    
    # Should have the social links container
    assert_includes index_content, 'class="speaker-social-links"', "Social links container should be present"
  end

  def test_speaker_information_display
    index_content = File.read(@site_path)
    
    # Should have speaker name/title
    assert_includes index_content, 'Presentations by', "Should have presentations title"
    
    # Should have bio description
    assert_includes index_content, 'class="hero-description"', "Should have hero description"
  end

  def test_site_structure
    index_content = File.read(@site_path)
    
    # Basic site structure
    assert_includes index_content, 'class="hero-section"', "Should have hero section"
    assert_includes index_content, 'class="hero-content"', "Should have hero content"
    assert_includes index_content, 'id="main-content"', "Should have main content area"
  end
end
