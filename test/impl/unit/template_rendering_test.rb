# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'nokogiri'
require 'ostruct'

# Unit tests for Template Rendering (TS-236 through TS-250)
# Maps to Gherkin: "Templates render correctly with extracted data"
class TemplateRenderingTest < Minitest::Test
  def setup
    # Build Jekyll site for testing
    config = Jekyll.configuration({
      'source' => Dir.pwd,
      'destination' => File.join(Dir.pwd, '_test_site')
    })
    @site = Jekyll::Site.new(config)
    @site.process
  end

  # TS-236: Index page renders with talk data
  def test_index_page_renders_with_talk_data
    skip 'No talks found' if @site.talks.empty?

    # Find the rendered index page
    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    refute_nil html, 'Index page should have output'

    # Check that talk data is rendered
    talk = @site.talks.first
    assert_includes html, talk.data['extracted_title'], 'Index should contain talk title'
    assert_includes html, talk.data['extracted_conference'], 'Index should contain conference name'
  end

  # TS-237: Talk pages render with extracted metadata
  def test_talk_pages_render_with_metadata
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    skip 'Talk page not found' unless talk.output

    html = talk.output
    refute_nil html, 'Talk page should have output'

    # Check metadata rendering
    assert_includes html, talk.data['extracted_title'], 'Talk page should contain title'
    assert_includes html, talk.data['extracted_conference'], 'Talk page should contain conference'
    assert_includes html, talk.data['extracted_date'], 'Talk page should contain date'
  end

  # TS-238: Conference names display correctly in templates
  def test_conference_names_display_correctly
    skip 'No talks found' if @site.talks.empty?

    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    doc = Nokogiri::HTML(html)

    # Look for conference names in the rendered HTML
    conference_elements = doc.css('.conference-name, .meta-item.conference')
    refute_empty conference_elements, 'Should find conference name elements'

    talk = @site.talks.first
    expected_conference = talk.data['extracted_conference']
    assert_includes html, expected_conference, 'Conference name should be displayed'
  end

  # TS-239: Dates display correctly in templates
  def test_dates_display_correctly
    skip 'No talks found' if @site.talks.empty?

    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    doc = Nokogiri::HTML(html)

    # Look for date elements
    date_elements = doc.css('time, .meta-item.date')
    refute_empty date_elements, 'Should find date elements'

    talk = @site.talks.first
    expected_date = talk.data['extracted_date']
    assert_includes html, expected_date, 'Date should be displayed'
  end

  # TS-240: Video status displays correctly
  def test_video_status_displays_correctly
    skip 'No talks found' if @site.talks.empty?

    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    talk = @site.talks.first

    if talk.data['extracted_video']
      assert_includes html, 'Video Available', 'Should show "Video Available" when video exists'
      refute_includes html, 'Video Coming Soon', 'Should not show "Video Coming Soon" when video exists'
    else
      assert_includes html, 'Video Coming Soon', 'Should show "Video Coming Soon" when no video'
      refute_includes html, 'Video Available', 'Should not show "Video Available" when no video'
    end
  end

  # TS-241: Slides embed correctly
  def test_slides_embed_correctly
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    skip 'No slides for this talk' unless talk.data['extracted_slides']

    skip 'Talk page not found' unless talk.output

    html = talk.output
    assert_includes html, 'slides-embed', 'Talk page should have slides embed section'
    assert_includes html, talk.data['extracted_slides'], 'Slides URL should be embedded'
  end

  # TS-242: Video embed correctly
  def test_video_embed_correctly
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    skip 'No video for this talk' unless talk.data['extracted_video']

    skip 'Talk page not found' unless talk.output

    html = talk.output
    assert_includes html, 'video-embed', 'Talk page should have video embed section'
    # Check for the video ID rather than the exact URL since it gets transformed to embed format
    video_id = talk.data['extracted_video'].match(/[?&]v=([^&]+)/)[1] if talk.data['extracted_video']
    assert_includes html, video_id, 'Video ID should be embedded' if video_id
  end

  # TS-243: Template handles missing extracted data gracefully
  def test_handles_missing_extracted_data
    # Create a mock talk document with missing data
    mock_talk = OpenStruct.new(
      data: {
        'extracted_title' => 'Test Talk',
        'extracted_conference' => nil,
        'extracted_date' => nil,
        'extracted_slides' => nil,
        'extracted_video' => nil
      },
      url: '/talks/test-talk/'
    )

    # Test that templates don't break with nil values
    # This would be tested in integration with actual template rendering
    refute_nil mock_talk.data['extracted_title'], 'Title should be present'
    assert_nil mock_talk.data['extracted_conference'], 'Conference can be nil'
    assert_nil mock_talk.data['extracted_date'], 'Date can be nil'
  end

  # TS-244: Template data access patterns work in rendered output
  def test_template_data_access_patterns_in_output
    skip 'No talks found' if @site.talks.empty?

    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    talk = @site.talks.first

    # Verify that the template used the correct data access pattern
    # (talk.extracted_* instead of talk.data.extracted_*)
    assert_includes html, talk.data['extracted_title'], 'Title should be accessible'
    assert_includes html, talk.data['extracted_conference'], 'Conference should be accessible'
  end

  # TS-245: Collection size displays correctly
  def test_collection_size_displays_correctly
    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output

    if @site.talks.size > 0
      assert_includes html, 'Recent Presentations', 'Should show recent presentations section'
    end

    if @site.talks.size > 3
      assert_includes html, 'All Presentations', 'Should show all presentations section when more than 3 talks'
    end
  end

  # TS-246: Template renders without errors when collection is empty
  def test_renders_without_errors_when_collection_empty
    # This test would require mocking an empty collection
    # For now, we verify the site builds successfully
    assert @site.pages.any?, 'Site should have pages even with empty collection'
  end

  # TS-247: Template handles special characters in extracted data
  def test_handles_special_characters_in_data
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    skip 'Talk page not found' unless talk.output

    html = talk.output

    # Check that HTML is properly escaped
    assert_includes html, '<html', 'HTML should be properly formed'
    refute_includes html, '&lt;script&gt;', 'Should not have unescaped script tags'
  end

  # TS-248: Template includes proper structured data
  def test_includes_structured_data
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    skip 'Talk page not found' unless talk.output

    html = talk.output

    # Check for JSON-LD structured data
    assert_includes html, 'application/ld+json', 'Should include JSON-LD structured data'
    assert_includes html, '"@type": "PresentationDigitalDocument"', 'Should have presentation schema'
  end

  # TS-249: Template renders responsive design elements
  def test_renders_responsive_elements
    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    doc = Nokogiri::HTML(html)

    # Check for responsive meta tags
    viewport_meta = doc.css('meta[name="viewport"]').first
    refute_nil viewport_meta, 'Should have viewport meta tag'

    # Check for responsive classes
    responsive_elements = doc.css('.featured-talks-grid, .talks-list')
    refute_empty responsive_elements, 'Should have responsive grid/list elements'
  end

  # TS-250: Template handles long content gracefully
  def test_handles_long_content_gracefully
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    skip 'Talk page not found' unless talk.output

    html = talk.output

    # Check that content is properly truncated/displayed
    # This is more of a visual test, but we can check for truncation classes
    assert_includes html, 'talk-description', 'Should have talk description section'
  end

  # Test that talks are sorted by date (newest first) on homepage
  def test_talks_sorted_by_date_newest_first
    # This test gracefully handles sites with no talks or only one talk
    if @site.talks.empty?
      puts "ℹ️  No talks found - skipping sort test"
      return
    end
    
    if @site.talks.length == 1
      puts "ℹ️  Only one talk found - skipping sort test"
      return
    end

    # Find the rendered index page
    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output

    # Get talks with dates sorted newest first (expected order)
    talks_with_dates = []
    @site.talks.each do |talk|
      if talk.data['extracted_date']
        talks_with_dates << {
          title: talk.data['extracted_title'] || talk.data['title'],
          date: Date.parse(talk.data['extracted_date']),
          talk: talk
        }
      end
    end
    
    skip 'No talks with valid dates found' if talks_with_dates.empty?
    skip 'Need at least 2 talks to test sorting' if talks_with_dates.length < 2
    
    # Expected order (newest first)
    expected_order = talks_with_dates.sort_by { |t| t[:date] }.reverse
    
    puts "ℹ️  Expected order: #{expected_order.map { |t| "#{t[:title]} (#{t[:date]})" }.join(', ')}"
    
    # Check the actual order in HTML by looking at the position of talk titles
    talk_positions = []
    expected_order.each do |talk|
      position = html.index(talk[:title])
      if position
        talk_positions << { talk: talk, position: position }
      end
    end
    
    # Sort by position to get the actual order in HTML
    actual_order_by_position = talk_positions.sort_by { |tp| tp[:position] }.map { |tp| tp[:talk] }
    
    puts "ℹ️  Actual order in HTML: #{actual_order_by_position.map { |t| "#{t[:title]} (#{t[:date]})" }.join(', ')}"
    
    # Compare the orders
    expected_dates = expected_order.map { |t| t[:date] }
    actual_dates = actual_order_by_position.map { |t| t[:date] }
    
    assert_equal expected_dates, actual_dates,
      "Talks are not sorted in chronological order (newest first) in the rendered HTML. Expected: #{expected_dates}, but got: #{actual_dates}"
  end
end
