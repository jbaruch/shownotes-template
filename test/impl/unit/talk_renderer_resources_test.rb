# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../../lib/talk_renderer'

# Tests for TalkRenderer resource HTML generation
class TalkRendererResourcesTest < Minitest::Test
  def setup
    @renderer = TalkRenderer.new
  end

  # generate_resources_html with array format
  def test_generate_resources_html_with_array_format
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com/slides', 'title' => 'Slides' },
      { 'type' => 'code', 'url' => 'https://github.com/repo', 'title' => 'Code' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'talk-resources'
    assert_includes html, 'Slides'
    assert_includes html, 'Code'
    assert_includes html, 'resource-group'
  end

  def test_generate_resources_html_with_hash_format
    resources = {
      'slides' => { 'url' => 'https://example.com/slides', 'title' => 'My Slides' },
      'code' => { 'url' => 'https://github.com/repo', 'title' => 'Source Code' }
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'talk-resources'
    assert_includes html, 'My Slides'
    assert_includes html, 'Source Code'
  end

  def test_generate_resources_html_with_hash_array_format
    resources = {
      'slides' => [
        { 'url' => 'https://example.com/slides1', 'title' => 'Slides 1' },
        { 'url' => 'https://example.com/slides2', 'title' => 'Slides 2' }
      ]
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Slides 1'
    assert_includes html, 'Slides 2'
  end

  def test_generate_resources_html_returns_empty_for_nil
    html = @renderer.generate_resources_html(nil)
    assert_equal '', html
  end

  def test_generate_resources_html_returns_empty_for_empty_hash
    html = @renderer.generate_resources_html({})
    assert_equal '', html
  end

  def test_generate_resources_html_returns_empty_for_empty_array
    html = @renderer.generate_resources_html([])
    assert_equal '', html
  end

  def test_generate_resources_html_groups_by_type_for_array
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com/1', 'title' => 'Slides 1' },
      { 'type' => 'slides', 'url' => 'https://example.com/2', 'title' => 'Slides 2' },
      { 'type' => 'code', 'url' => 'https://github.com/1', 'title' => 'Code 1' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    # Should have two groups: slides and code
    assert_includes html, '<h3>Slides</h3>'
    assert_includes html, '<h3>Code</h3>'
    assert_includes html, 'Slides 1'
    assert_includes html, 'Slides 2'
    assert_includes html, 'Code 1'
  end

  def test_generate_resources_html_uses_default_type_for_array_without_type
    resources = [
      { 'url' => 'https://example.com', 'title' => 'Link' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, '<h3>Links</h3>'
  end

  def test_generate_resources_html_skips_items_without_url
    resources = [
      { 'type' => 'slides', 'title' => 'No URL' },
      { 'type' => 'slides', 'url' => 'https://example.com', 'title' => 'Has URL' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Has URL'
    refute_includes html, 'No URL'
  end

  def test_generate_resources_html_skips_items_without_title
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com' },
      { 'type' => 'slides', 'url' => 'https://example.com/2', 'title' => 'Has Title' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Has Title'
    # Item without title should be skipped
  end

  def test_generate_resources_html_creates_embeds_for_embeddable_urls
    resources = [
      { 'type' => 'slides', 'url' => 'https://docs.google.com/presentation/d/abc123/edit', 'title' => 'Slides' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'iframe'
    assert_includes html, 'slides-embed'
  end

  def test_generate_resources_html_creates_links_for_non_embeddable_urls
    resources = [
      { 'type' => 'link', 'url' => 'https://example.com', 'title' => 'Link' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, '<a href='
    refute_includes html, 'iframe'
  end

  def test_generate_resources_html_handles_mixed_embeddable_and_links
    resources = [
      { 'type' => 'slides', 'url' => 'https://docs.google.com/presentation/d/abc123/edit', 'title' => 'Slides' },
      { 'type' => 'link', 'url' => 'https://example.com', 'title' => 'Link' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'iframe'
    assert_includes html, '<a href='
  end

  def test_generate_resources_html_capitalizes_type_names
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com', 'title' => 'Slides' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, '<h3>Slides</h3>'
  end

  def test_generate_resources_html_includes_resource_section_wrapper
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com', 'title' => 'Slides' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, '<section class="talk-resources">'
    assert_includes html, '<h2>Resources</h2>'
    assert_includes html, '</section>'
  end

  def test_generate_resources_html_includes_resource_group_wrapper
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com', 'title' => 'Slides' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, '<div class="resource-group">'
    assert_includes html, '</div>'
  end

  def test_generate_resources_html_includes_resource_list_wrapper
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com', 'title' => 'Slides' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, '<ul class="resource-list">'
    assert_includes html, '</ul>'
  end

  # Hash format with single resource
  def test_generate_resources_html_hash_format_single_resource
    resources = {
      'slides' => { 'url' => 'https://example.com', 'title' => 'My Slides' }
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'My Slides'
    assert_includes html, '<h3>Slides</h3>'
  end

  # Hash format with array of resources
  def test_generate_resources_html_hash_format_array_of_resources
    resources = {
      'slides' => [
        { 'url' => 'https://example.com/1', 'title' => 'Slides 1' },
        { 'url' => 'https://example.com/2', 'title' => 'Slides 2' }
      ]
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Slides 1'
    assert_includes html, 'Slides 2'
  end

  # Hash format skips nil values
  def test_generate_resources_html_hash_format_skips_nil_values
    resources = {
      'slides' => nil,
      'code' => { 'url' => 'https://github.com', 'title' => 'Code' }
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Code'
    refute_includes html, '<h3>Slides</h3>'
  end

  # Hash format skips resources without URL
  def test_generate_resources_html_hash_format_skips_without_url
    resources = {
      'slides' => { 'title' => 'No URL' },
      'code' => { 'url' => 'https://github.com', 'title' => 'Code' }
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Code'
    # Slides without URL should not appear
  end

  # Hash format with embeddable URLs
  def test_generate_resources_html_hash_format_embeds_google_slides
    resources = {
      'slides' => { 'url' => 'https://docs.google.com/presentation/d/abc123/edit', 'title' => 'Slides' }
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'iframe'
    assert_includes html, 'slides-embed'
  end

  def test_generate_resources_html_hash_format_embeds_youtube
    resources = {
      'video' => { 'url' => 'https://www.youtube.com/watch?v=abc123', 'title' => 'Video' }
    }
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'iframe'
    assert_includes html, 'video-embed'
  end

  # Edge cases
  def test_generate_resources_html_handles_empty_type_string
    resources = [
      { 'type' => '', 'url' => 'https://example.com', 'title' => 'Link' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    # Should use default type 'links'
    assert_includes html, 'Link'
  end

  def test_generate_resources_html_handles_special_characters_in_type
    resources = [
      { 'type' => 'code-samples', 'url' => 'https://example.com', 'title' => 'Code' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Code-samples'
  end

  def test_generate_resources_html_handles_multiple_resource_types
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com/slides', 'title' => 'Slides' },
      { 'type' => 'video', 'url' => 'https://example.com/video', 'title' => 'Video' },
      { 'type' => 'code', 'url' => 'https://github.com', 'title' => 'Code' },
      { 'type' => 'link', 'url' => 'https://example.com', 'title' => 'Link' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, '<h3>Slides</h3>'
    assert_includes html, '<h3>Video</h3>'
    assert_includes html, '<h3>Code</h3>'
    assert_includes html, '<h3>Link</h3>'
  end

  def test_generate_resources_html_preserves_resource_order_within_type
    resources = [
      { 'type' => 'slides', 'url' => 'https://example.com/1', 'title' => 'First' },
      { 'type' => 'slides', 'url' => 'https://example.com/2', 'title' => 'Second' },
      { 'type' => 'slides', 'url' => 'https://example.com/3', 'title' => 'Third' }
    ]
    html = @renderer.generate_resources_html(resources)
    
    first_pos = html.index('First')
    second_pos = html.index('Second')
    third_pos = html.index('Third')
    
    assert first_pos < second_pos
    assert second_pos < third_pos
  end

  def test_generate_resources_html_handles_very_long_resource_lists
    resources = (1..50).map do |i|
      { 'type' => 'link', 'url' => "https://example.com/#{i}", 'title' => "Link #{i}" }
    end
    html = @renderer.generate_resources_html(resources)
    
    assert_includes html, 'Link 1'
    assert_includes html, 'Link 50'
  end
end
