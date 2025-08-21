# frozen_string_literal: true

require 'minitest/autorun'

# Unit tests for Resource Management (TS-006 through TS-010)
# Maps to Gherkin: "Talk page displays resources correctly" + "Talk page handles missing resources gracefully"
class ResourceManagementTest < Minitest::Test
  def setup
    @talk_with_resources = {
      'title' => 'Test Talk',
      'resources' => {
        'slides' => {
          'title' => 'Presentation Slides',
          'url' => 'https://slides.example.com/js-patterns'
        },
        'code' => {
          'title' => 'Demo Repository',
          'url' => 'https://github.com/jane/js-patterns-demo'
        },
        'links' => [
          {
            'title' => 'MDN Guide',
            'url' => 'https://developer.mozilla.org/guide',
            'description' => 'Comprehensive reference'
          }
        ]
      }
    }

    @talk_without_resources = {
      'title' => 'Test Talk No Resources'
    }
  end

  # TS-006: Slides resource displays with clear labeling
  def test_slides_resource_displays_with_label
    page_html = generate_talk_page(@talk_with_resources)
    
    assert_includes page_html, 'href="https://slides.example.com/js-patterns"',
                    'Slides URL should be present in href attribute'
    
    assert_includes page_html, 'Slides',
                    'Slides should have clear label'
    
    slides_section = extract_resource_section(page_html, 'slides')
    assert_includes slides_section, 'Presentation Slides',
                    'Slides section should contain resource title'
  end

  # TS-007: Code repository links render when present in frontmatter
  def test_code_repository_links_render
    page_html = generate_talk_page(@talk_with_resources)
    
    assert_includes page_html, 'href="https://github.com/jane/js-patterns-demo"',
                    'Code repository URL should be present'
    
    assert_includes page_html, 'Code',
                    'Code repository should have clear label'
    
    code_section = extract_resource_section(page_html, 'code')
    assert_includes code_section, 'Demo Repository',
                    'Code section should contain resource title'
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
    
    # Should not contain broken resource sections
    assert_no_broken_resource_sections(page_html)
    
    # Should not display empty resource containers
    refute_includes page_html, '<div class="resource-item resource-slides"></div>',
                    'Empty slides section should not appear'
  end

  # TS-010: External links open in new tabs/windows
  def test_external_links_open_in_new_tabs
    page_html = generate_talk_page(@talk_with_resources)
    
    # All external resource links should have target="_blank"
    slides_link = extract_link(page_html, 'slides.example.com')
    assert_includes slides_link, 'target="_blank"',
                    'Slides link should open in new tab'
    
    code_link = extract_link(page_html, 'github.com')
    assert_includes code_link, 'target="_blank"',
                    'Code repository link should open in new tab'
    
    additional_link = extract_link(page_html, 'developer.mozilla.org')
    assert_includes additional_link, 'target="_blank"',
                    'Additional link should open in new tab'
    
    # All external links should have rel="noopener" for security
    assert_includes slides_link, 'rel="noopener"',
                    'Slides link should have rel="noopener"'
    assert_includes code_link, 'rel="noopener"',
                    'Code link should have rel="noopener"'
    assert_includes additional_link, 'rel="noopener"',
                    'Additional link should have rel="noopener"'
  end

  private

  # Interface methods - implementations will be created later
  def generate_talk_page(talk_data)
    fail 'generate_talk_page method not implemented yet'
  end

  def extract_resource_section(html, resource_type)
    fail 'extract_resource_section method not implemented yet'
  end

  def extract_link(html, domain)
    fail 'extract_link method not implemented yet'
  end

  def assert_no_broken_resource_sections(html)
    fail 'assert_no_broken_resource_sections method not implemented yet'
  end
end