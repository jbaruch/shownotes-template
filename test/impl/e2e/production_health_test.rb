require 'minitest/autorun'
require 'net/http'
require 'uri'

class ProductionHealthTest < Minitest::Test
  PRODUCTION_URL = 'https://speaking.jbaru.ch'
  
  # Helper method to fetch HTML from production
  def fetch_production_html(path = '/')
    uri = URI.join(PRODUCTION_URL, path)
    response = Net::HTTP.get_response(uri)
    
    unless response.is_a?(Net::HTTPSuccess)
      flunk "Failed to fetch #{uri}: #{response.code} #{response.message}"
    end
    
    response.body
  end
  
  # Helper method to check if running in CI environment
  def ci_environment?
    ENV['CI'] == 'true' || ENV['GITHUB_ACTIONS'] == 'true'
  end
  
  # Homepage Health Tests
  
  def test_production_homepage_loads_successfully
    skip "Skipping production test in CI" if ci_environment?
    
    uri = URI(PRODUCTION_URL)
    response = Net::HTTP.get_response(uri)
    
    assert_equal '200', response.code, "Homepage should return HTTP 200"
  end
  
  def test_production_homepage_has_css_loaded
    skip "Skipping production test in CI" if ci_environment?
    
    html = fetch_production_html('/')
    
    # Check for stylesheet link in HTML
    assert_match %r{<link[^>]*rel=["']stylesheet["'][^>]*>}, html,
                 "Homepage should have CSS stylesheet link"
  end
  
  def test_production_homepage_has_highlighted_presentations_section
    skip "Skipping production test in CI" if ci_environment?
    
    html = fetch_production_html('/')
    
    assert_includes html, 'Highlighted Presentations',
                    "Homepage should have 'Highlighted Presentations' section"
  end
  
  def test_production_homepage_displays_at_least_three_highlighted_talks
    skip "Skipping production test in CI" if ci_environment?
    
    html = fetch_production_html('/')
    
    # Count featured talk cards
    featured_count = html.scan(/<article[^>]*class=["'][^"']*featured-talk-card[^"']*["']/).length
    
    assert_operator featured_count, :>=, 3,
                    "Homepage should display at least 3 talks in highlighted section (found #{featured_count})"
  end
  
  # Talk Page Health Tests
  
  def test_production_talk_page_loads_successfully
    skip "Skipping production test in CI" if ci_environment?
    
    # Test with the Dev2Next 2025 RoboCoders talk
    talk_path = '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'
    uri = URI.join(PRODUCTION_URL, talk_path)
    response = Net::HTTP.get_response(uri)
    
    assert_equal '200', response.code, "Talk page should return HTTP 200"
  end
  
  def test_production_talk_page_has_proper_title_not_slugified
    skip "Skipping production test in CI" if ci_environment?
    
    talk_path = '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'
    html = fetch_production_html(talk_path)
    
    # Should have the proper title from H1
    assert_includes html, 'RoboCoders: Judgment Day',
                    "Talk page should have proper title extracted from H1"
    
    # Should NOT have the slugified filename as title
    refute_includes html, 'Dev2next 2025 Robocoders Judgment Day',
                    "Talk page should not show slugified filename as title"
  end
  
  def test_production_talk_page_has_conference_name
    skip "Skipping production test in CI" if ci_environment?
    
    talk_path = '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'
    html = fetch_production_html(talk_path)
    
    # Check for conference name with emoji
    assert_includes html, '📍 Dev2Next 2025',
                    "Talk page should display conference name"
  end
  
  def test_production_talk_page_has_date
    skip "Skipping production test in CI" if ci_environment?
    
    talk_path = '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'
    html = fetch_production_html(talk_path)
    
    # Check for date with emoji
    assert_includes html, '📅 October 01, 2025',
                    "Talk page should display formatted date"
  end
  
  def test_production_talk_page_has_video_status
    skip "Skipping production test in CI" if ci_environment?
    
    talk_path = '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'
    html = fetch_production_html(talk_path)
    
    # Check for video status (either available or coming soon)
    has_video_status = html.include?('🎥 Video Available') || html.include?('⏳ Video Coming Soon')
    
    assert has_video_status, "Talk page should display video status"
  end
  
  def test_production_talk_page_has_abstract_section
    skip "Skipping production test in CI" if ci_environment?
    
    talk_path = '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'
    html = fetch_production_html(talk_path)
    
    # Check for Abstract heading
    assert_match %r{<h2[^>]*>Abstract</h2>}, html,
                 "Talk page should have Abstract section"
  end
  
  def test_production_talk_page_has_resources_section
    skip "Skipping production test in CI" if ci_environment?
    
    talk_path = '/talks/2025-10-01-dev2next-2025-robocoders-judgment-day/'
    html = fetch_production_html(talk_path)
    
    # Check for Resources heading
    assert_match %r{<h2[^>]*>Resources</h2>}, html,
                 "Talk page should have Resources section"
  end
  
  # Sample Talk Exclusion Tests
  
  def test_production_homepage_does_not_show_sample_talk
    skip "Skipping production test in CI" if ci_environment?
    
    html = fetch_production_html('/')
    
    # Check that sample talk title doesn't appear
    refute_includes html, 'Your Amazing Talk Title',
                    "Homepage should not contain sample talk title"
    
    # Check that sample talk doesn't appear in any talk list
    refute_includes html, 'Sample Talk',
                    "Homepage should not contain 'Sample Talk' in talks list"
  end
  
  def test_production_sample_talk_url_returns_404_or_not_found
    skip "Skipping production test in CI" if ci_environment?
    
    sample_talk_path = '/talks/sample-talk/'
    uri = URI.join(PRODUCTION_URL, sample_talk_path)
    response = Net::HTTP.get_response(uri)
    
    # Should return 404 or redirect (not 200)
    refute_equal '200', response.code,
                 "Sample talk URL should not return 200 (found #{response.code})"
  end
  
  def test_production_homepage_does_not_link_to_sample_talk
    skip "Skipping production test in CI" if ci_environment?
    
    html = fetch_production_html('/')
    
    # Check that there's no link to sample talk
    refute_match %r{href=["'][^"']*\/talks\/sample-talk\/["']}, html,
                 "Homepage should not contain links to sample talk"
  end
  
  # Production Parity Tests
  
  def test_production_has_similar_talk_count_to_local
    skip "Skipping production test in CI" if ci_environment?
    
    # Fetch production homepage
    prod_html = fetch_production_html('/')
    
    # Count talk items on production
    prod_talk_count = prod_html.scan(/<article[^>]*class=["'][^"']*talk-list-item[^"']*["']/).length
    
    # Count local talks (excluding sample talk)
    local_talk_count = Dir.glob('_talks/*.md').reject { |f| f.include?('sample-talk') }.length
    
    # Allow for small differences (e.g., draft talks not deployed)
    difference = (prod_talk_count - local_talk_count).abs
    
    assert_operator difference, :<=, 2,
                    "Production talk count (#{prod_talk_count}) should be similar to local (#{local_talk_count})"
  end
  
  def test_production_talks_have_proper_titles_not_slugified
    skip "Skipping production test in CI" if ci_environment?
    
    html = fetch_production_html('/')
    
    # Extract all talk titles from the page
    talk_titles = html.scan(/<h3[^>]*>([^<]+)<\/h3>/).flatten
    
    # Check that titles don't look like slugified filenames
    # Slugified titles typically have patterns like "Word1 Word2 Word3" with no punctuation
    slugified_pattern = /^[A-Z][a-z]+(\s+[A-Z][a-z]+){3,}$/
    
    slugified_titles = talk_titles.select { |title| title.match?(slugified_pattern) }
    
    assert_empty slugified_titles,
                 "Found slugified titles on production: #{slugified_titles.join(', ')}"
  end
  
  def test_production_talks_have_consistent_metadata_format
    skip "Skipping production test in CI" if ci_environment?
    
    html = fetch_production_html('/')
    
    # Check that talks have conference names (📍 emoji)
    conference_count = html.scan(/📍/).length
    
    # Check that talks have dates (📅 emoji)
    date_count = html.scan(/📅/).length
    
    # Check that talks have video status (🎥 or ⏳ emoji)
    video_status_count = html.scan(/🎥|⏳/).length
    
    # All counts should be similar (allowing for some variation in featured vs all talks)
    assert_operator conference_count, :>, 0, "Should have conference names on production"
    assert_operator date_count, :>, 0, "Should have dates on production"
    assert_operator video_status_count, :>, 0, "Should have video status on production"
    
    # Conference and date counts should be similar
    difference = (conference_count - date_count).abs
    assert_operator difference, :<=, 3,
                    "Conference count (#{conference_count}) and date count (#{date_count}) should be similar"
  end
end
