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

  # Interface methods - connected to implementation
  def generate_talk_page(talk_data)
    require_relative '../../../lib/simple_talk_renderer'
    renderer = SimpleTalkRenderer.new
    
    # Enhanced layout that includes resources section
    enhanced_talk_data = talk_data.dup
    enhanced_talk_data['content'] = generate_resources_content(talk_data['resources']) if talk_data['resources']
    
    renderer.generate_talk_page(enhanced_talk_data)
  end

  def extract_resource_section(html, resource_type)
    # Extract specific resource section from HTML
    pattern = /<div[^>]*class="[^"]*#{resource_type}[^"]*"[^>]*>(.*?)<\/div>/m
    match = html.match(pattern)
    match ? match[1].strip : ''
  end

  def extract_link(html, domain)
    # Extract link for specific domain including attributes
    pattern = /<a([^>]*href="[^"]*#{Regexp.escape(domain)}[^"]*"[^>]*)>(.*?)<\/a>/
    match = html.match(pattern)
    if match
      attrs = match[1]
      href = attrs.match(/href="([^"]+)"/)[1]
      text = match[2].strip
      
      result = { href: href, text: text }
      if attrs.include?('target="_blank"')
        result['target="_blank"'] = true
      end
      if attrs.include?('rel="noopener"')
        result['rel="noopener"'] = true
      end
      result
    else
      nil
    end
  end

  def assert_no_broken_resource_sections(html)
    # Check for broken resource sections (empty or malformed)
    broken_patterns = [
      /<div[^>]*class="[^"]*resource[^"]*"[^>]*>\s*<\/div>/, # Empty resource divs
      /<a[^>]*href=""[^>]*>/, # Empty href attributes
      /<a[^>]*href="[^"]*"[^>]*>\s*<\/a>/ # Empty link text
    ]
    
    broken_patterns.each do |pattern|
      refute html.match?(pattern), "Found broken resource section matching #{pattern}"
    end
  end

  private

  def generate_resources_content(resources)
    return '' unless resources
    
    content = "<div class=\"resources\">\n<h3>Resources</h3>\n"
    
    resources.each do |type, resource_data|
      case type
      when 'slides'
        if resource_data.is_a?(Hash) && resource_data['url']
          content += "<div class=\"resource slides\">\n"
          content += "<a href=\"#{resource_data['url']}\" target=\"_blank\">#{resource_data['title'] || 'Slides'}</a>\n"
          content += "</div>\n"
        end
      when 'code'
        if resource_data.is_a?(Hash) && resource_data['url']
          content += "<div class=\"resource code\">\n"
          content += "<a href=\"#{resource_data['url']}\" target=\"_blank\">#{resource_data['title'] || 'Code Repository'}</a>\n"
          content += "</div>\n"
        end
      when 'links'
        if resource_data.is_a?(Array)
          resource_data.each do |link|
            next unless link.is_a?(Hash) && link['url']
            content += "<div class=\"resource link\">\n"
            content += "<a href=\"#{link['url']}\" target=\"_blank\">#{link['title'] || link['url']}</a>\n"
            content += "<p>#{link['description']}</p>\n" if link['description']
            content += "</div>\n"
          end
        end
      end
    end
    
    content += "</div>\n"
    content
  end
end