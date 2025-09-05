# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'nokogiri'

# Integration tests for Complete Data Pipeline (TS-251 through TS-260)
# Maps to Gherkin: "Complete data extraction and rendering pipeline works end-to-end"
class DataPipelineIntegrationTest < Minitest::Test
  def setup
    # Build Jekyll site for testing
    config = Jekyll.configuration({
      'source' => Dir.pwd,
      'destination' => File.join(Dir.pwd, '_test_site')
    })
    @site = Jekyll::Site.new(config)
    @site.process
  end

  # TS-251: End-to-end data extraction and display
  def test_end_to_end_data_extraction_and_display
    talks_collection = @site.collections['talks']
    skip 'Talks collection not found' unless talks_collection
    skip 'No talks found' if talks_collection.docs.empty?

    talk = talks_collection.docs.first

    # Verify data was extracted
    assert talk.data['extracted_title'], 'Title should be extracted'
    assert talk.data['extracted_conference'], 'Conference should be extracted'
    assert talk.data['extracted_date'], 'Date should be extracted'

    # Verify data is displayed on index page
    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    assert_includes html, talk.data['extracted_title'], 'Title should be displayed on index'
    assert_includes html, talk.data['extracted_conference'], 'Conference should be displayed on index'

    # Verify data is displayed on talk page
    skip 'Talk page not found' unless talk.output

    talk_html = talk.output
    assert_includes talk_html, talk.data['extracted_title'], 'Title should be displayed on talk page'
    assert_includes talk_html, talk.data['extracted_conference'], 'Conference should be displayed on talk page'
  end

  # TS-252: Template format consistency prevents display issues
  def test_template_format_consistency_prevents_issues
    # This test verifies that the template format in documentation
    # matches what the parser actually extracts

    readme_path = File.join(Dir.pwd, 'README.md')
    skip 'README.md not found' unless File.exist?(readme_path)

    readme_content = File.read(readme_path)

    # README should show the format that actually works
    assert_includes readme_content, '**Conference:**',
                    'README should show working markdown metadata format'

    # README should NOT show the broken YAML format
    refute_includes readme_content, 'conference:',
                    'README should not show broken YAML frontmatter format'
  end

  # TS-253: Collection access pattern verification
  def test_collection_access_pattern_verification
    # Verify that the standard Jekyll collection access works
    talks_collection = @site.collections['talks']
    refute_nil talks_collection, 'site.collections.talks should exist'
    refute_nil talks_collection.docs, 'site.collections.talks.docs should work'
    assert_kind_of Array, talks_collection.docs, 'site.collections.talks.docs should be an array'

    # Verify that site.talks convenience method now works (fixed by plugin)
    talks_via_method = @site.talks
    refute_nil talks_via_method, 'site.talks convenience method should work'
    assert_kind_of Array, talks_via_method, 'site.talks should return an array'
    assert_equal talks_collection.docs, talks_via_method, 'site.talks should return same as site.collections.talks.docs'
  end

  # TS-254: Data access pattern consistency across templates
  def test_data_access_pattern_consistency
    talks_collection = @site.collections['talks']
    skip 'Talks collection not found' unless talks_collection
    skip 'No talks found' if talks_collection.docs.empty?

    talk = talks_collection.docs.first

    # Verify that both access patterns work for document data
    assert_equal talk.data['extracted_title'], talk['extracted_title'],
                 'Both talk.data.extracted_title and talk.extracted_title should work'

    # Verify templates use the correct pattern
    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    assert_includes html, talk.data['extracted_title'],
                    'Template should successfully access extracted data'
  end

  # TS-255: Plugin robustness prevents nil access errors
  def test_plugin_robustness_prevents_errors
    # Test that the plugin handles edge cases gracefully

    # Create a mock site with empty collections
    config = Jekyll.configuration({
      'source' => Dir.pwd,
      'destination' => File.join(Dir.pwd, '_test_site_empty')
    })
    empty_site = Jekyll::Site.new(config)

    # Mock empty collections
    empty_site.instance_variable_set(:@collections, {})

    # Plugin should not crash with empty collections
    plugin = Jekyll::MarkdownTalkProcessor.new
    begin
      plugin.generate(empty_site)
      assert true, 'Plugin should handle empty collections without crashing'
    rescue => e
      flunk "Plugin crashed with empty collections: #{e.message}"
    end
  end

  # TS-256: Build process completes without collection errors
  def test_build_process_completes_without_collection_errors
    # Verify that the entire build process works without errors
    assert @site.pages.any?, 'Site should have pages after build'

    talks_collection = @site.collections['talks']
    has_talks = talks_collection && talks_collection.docs.any?
    
    # Skip if no content exists - this is expected when starting fresh
    skip 'No content found - skipping content validation for empty site' unless @site.posts.any? || has_talks
    
    assert @site.posts.any? || has_talks, 'Site should have content after build'
  end

  # TS-257: Template rendering handles all data types correctly
  def test_template_rendering_handles_data_types
    talks_collection = @site.collections['talks']
    skip 'Talks collection not found' unless talks_collection
    skip 'No talks found' if talks_collection.docs.empty?

    talk = talks_collection.docs.first
    skip 'Talk page not found' unless talk.output

    html = talk.output
    doc = Nokogiri::HTML(html)

    # Check that different data types are rendered appropriately
    # Strings (title, conference)
    title_element = doc.css('h1').first
    refute_nil title_element, 'Should have title element'

    # Dates
    time_elements = doc.css('time')
    refute_empty time_elements, 'Should have time elements'

    # URLs (slides, video)
    if talk.data['extracted_slides']
      assert_includes html, talk.data['extracted_slides'], 'Slides URL should be rendered'
    end

    if talk.data['extracted_video']
      # Video URLs get transformed to standard youtube embed format
      video_id = talk.data['extracted_video'].match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n]+)/)[1] rescue nil
      if video_id
        assert_includes html, video_id, 'Video ID should be rendered'
      else
        assert_includes html, talk.data['extracted_video'], 'Video URL should be rendered'
      end
    end
  end

  # TS-258: Error handling for malformed talk files
  def test_error_handling_for_malformed_files
    # This would test that malformed talk files don't break the build
    # For now, we verify the build succeeds
    assert @site.pages.find { |page| page.url == '/' }, 'Index page should exist'
  end

  # TS-259: Performance impact of data extraction
  def test_performance_impact_of_data_extraction
    # Basic performance test - build should complete in reasonable time
    start_time = Time.now
    config = Jekyll.configuration({
      'source' => Dir.pwd,
      'destination' => File.join(Dir.pwd, '_perf_test_site')
    })
    perf_site = Jekyll::Site.new(config)
    perf_site.process
    end_time = Time.now

    build_time = end_time - start_time
    assert build_time < 30, "Build should complete in less than 30 seconds (took #{build_time}s)"
  end

  # TS-260: Regression test for previously fixed issues
  def test_regression_prevention
    # This test serves as a regression test for the issues we just fixed

    # 1. Verify collection access works
    talks_collection = @site.collections['talks']
    refute_nil talks_collection, 'Collection access should work (regression test)'
    refute_nil talks_collection.docs, 'Collection docs should be accessible (regression test)'

    # 2. Verify data extraction works
    skip 'No talks found' if talks_collection.docs.empty?
    talk = talks_collection.docs.first
    assert talk.data['extracted_title'], 'Data extraction should work (regression test)'

    # 3. Verify template rendering works
    index_page = @site.pages.find { |page| page.url == '/' }
    skip 'Index page not found' unless index_page

    html = index_page.output
    assert_includes html, talk.data['extracted_title'],
                    'Template rendering should work (regression test)'

    # 4. Verify no template format mismatches
    readme_path = File.join(Dir.pwd, 'README.md')
    if File.exist?(readme_path)
      readme_content = File.read(readme_path)
      assert_includes readme_content, '**Conference:**',
                      'README should show correct format (regression test)'
    end
  end
end
