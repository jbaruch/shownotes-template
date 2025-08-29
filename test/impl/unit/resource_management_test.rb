# frozen_string_literal: true

require 'minitest/autorun'

# Unit tests for Resource Management (TS-006 through TS-010)
# Maps to Gherkin: "Talk page displays resources correctly" + "Talk page handles missing resources gracefully"
class ResourceManagementTest < Minitest::Test
  def setup
    @talk_with_resources = {
      'title' => 'Test Talk',
      'conference' => 'Test Conference', 
      'date' => '2025-01-01',
      'slides' => 'https://slides.example.com/js-patterns',
      'video' => 'https://youtube.com/watch?v=example',
      'content' => "Talk content with resources:\n\n* [GitHub Repository](https://github.com/jane/js-patterns-demo) - Demo code for the talk\n* [MDN Guide](https://developer.mozilla.org/guide) - Comprehensive reference\n"
    }

    @talk_without_resources = {
      'title' => 'Test Talk No Resources',
      'conference' => 'Test Conference',
      'date' => '2025-01-01'
    }
  end

  # TS-006: Slides resource displays with clear labeling
  def test_slides_resource_displays_with_label
    page_html = generate_talk_page(@talk_with_resources)
    
    assert_includes page_html, 'https://slides.example.com/js-patterns',
                    'Slides URL should be present in embedded iframe'
    
    assert_includes page_html, '<h2>Slides</h2>',
                    'Slides should have clear label'
  end

  # TS-007: Code repository links render when present in content
  def test_code_repository_links_render
    page_html = generate_talk_page(@talk_with_resources)
    
    assert_includes page_html, 'href="https://github.com/jane/js-patterns-demo"',
                    'Code repository URL should be present'
    
    assert_includes page_html, 'GitHub Repository',
                    'Code repository should have clear label'
  end

  # TS-008: Additional reference links show with descriptions
  def test_additional_links_with_descriptions
    page_html = generate_talk_page(@talk_with_resources)
    
    assert_includes page_html, 'href="https://developer.mozilla.org/guide"',
                    'Additional link URL should be present'
    
    assert_includes page_html, 'MDN Guide',
                    'Additional link title should be displayed'
    
    assert_includes page_html, 'Comprehensive reference',
                    'Additional link description should be displayed'
  end

  # TS-009: Missing resources don't break page layout
  def test_missing_resources_handled_gracefully
    page_html = generate_talk_page(@talk_without_resources)
    
    # Page should still render without errors
    refute_nil page_html, 'Page should render even without resources'
    
    # Should contain basic page structure
    assert_includes page_html, '<h1 class="talk-title">Test Talk No Resources</h1>',
                    'Page should contain talk title'
    
    # Should not display empty resource containers
    refute_includes page_html, '<div class="resource-item resource-slides"></div>',
                    'Empty slides section should not appear'
  end

  # TS-010: External links open in new tabs/windows
  def test_external_links_open_in_new_tabs
    page_html = generate_talk_page(@talk_with_resources)
    
    # All external resource links should have target="_blank"
    github_match = page_html.match(/<a[^>]*href="https:\/\/github\.com\/jane\/js-patterns-demo"[^>]*>/)
    assert github_match, 'GitHub link should be present'
    assert_includes github_match[0], 'target="_blank"', 'GitHub link should open in new tab'
    
    mdn_match = page_html.match(/<a[^>]*href="https:\/\/developer\.mozilla\.org\/guide"[^>]*>/)
    assert mdn_match, 'MDN link should be present'
    assert_includes mdn_match[0], 'target="_blank"', 'MDN link should open in new tab'
  end
  private

  # Interface methods - connected to implementation
  def generate_talk_page(talk_data)
    require_relative '../../../lib/simple_talk_renderer'
    renderer = SimpleTalkRenderer.new
    renderer.generate_talk_page(talk_data)
  end
end