# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../../lib/simple_talk_renderer'

# Unit tests for Content Rendering (TS-011 through TS-014)
# Maps to Gherkin: "Talk page processes Markdown and frontmatter correctly"
class ContentRenderingTest < Minitest::Test
  def setup
    @renderer = SimpleTalkRenderer.new
    @markdown_content = <<~MARKDOWN
      ---
      title: "Test Talk"
      speaker: "Test Speaker"
      ---

      ## Talk Abstract

      This is a test talk about **important topics**.

      ### Key Points

      - First point
      - Second point with [link](https://example.com)

      ```javascript
      function example() {
        return "Hello World";
      }
      ```

      Special characters: <script>alert('xss')</script>
    MARKDOWN

    @malformed_frontmatter = <<~MARKDOWN
      ---
      title: "Test Talk
      speaker: Invalid YAML
      date: 2024-01-01
      --
      
      Content here.
    MARKDOWN
  end

  # TS-011: Markdown content processes into HTML correctly
  def test_markdown_processes_to_html
    processed_html = process_markdown_content(@markdown_content)
    
    # Headers should convert to HTML
    assert_includes processed_html, '<h2>Talk Abstract</h2>',
                    'H2 markdown should convert to HTML h2 element'
    
    assert_includes processed_html, '<h3>Key Points</h3>',
                    'H3 markdown should convert to HTML h3 element'
    
    # Bold text should convert
    assert_includes processed_html, '<strong>important topics</strong>',
                    'Bold markdown should convert to strong element'
    
    # Lists should convert
    assert_includes processed_html, '<ul>',
                    'Markdown list should convert to HTML ul'
    assert_includes processed_html, '<li>First point</li>',
                    'List items should convert to HTML li elements'
    
    # Links should convert
    assert_includes processed_html, '<a href="https://example.com">link</a>',
                    'Markdown links should convert to HTML a elements'
  end

  # TS-012: YAML frontmatter parses into page variables
  def test_frontmatter_parses_to_variables
    page_data = parse_frontmatter(@markdown_content)
    
    assert_equal 'Test Talk', page_data['title'],
                 'Title should parse from frontmatter'
    
    assert_equal 'Test Speaker', page_data['speaker'],
                 'Speaker should parse from frontmatter'
    
    # Verify frontmatter is accessible in template context
    template_variables = extract_template_variables(@markdown_content)
    assert_includes template_variables, 'page.title',
                    'Page title should be available as template variable'
    assert_includes template_variables, 'page.speaker',
                    'Page speaker should be available as template variable'
  end

  # TS-013: Special characters render safely (no XSS)
  def test_special_characters_escaped_safely
    processed_html = process_markdown_content(@markdown_content)
    
    # Script tags should be escaped, not executed
    refute_includes processed_html, '<script>alert(\'xss\')</script>',
                    'Script tags should not appear unescaped in output'
    
    assert_includes processed_html, '&lt;script&gt;alert(\'xss\')&lt;/script&gt;',
                    'Script tags should be HTML-escaped'
    
    # Verify no executable JavaScript is present
    assert_no_executable_javascript(processed_html)
  end

  # TS-014: Code blocks render with syntax highlighting
  def test_code_blocks_with_syntax_highlighting
    processed_html = process_markdown_content(@markdown_content)
    
    # Code block should be wrapped in appropriate tags
    assert_includes processed_html, '<pre',
                    'Code blocks should be wrapped in pre element'
    
    assert_includes processed_html, '<code',
                    'Code blocks should contain code element'
    
    # JavaScript syntax should be highlighted
    assert_includes processed_html, 'class="language-javascript"',
                    'Code block should have language class for syntax highlighting'
    
    # Code content should be preserved (may be syntax highlighted)
    assert(processed_html.include?('function') && processed_html.include?('example'),
           'Code content should be preserved in code block')
    
    # Verify syntax highlighting classes are applied
    assert_syntax_highlighting_applied(processed_html, 'javascript')
  end

  # Test malformed frontmatter handling
  def test_malformed_frontmatter_handled_gracefully
    # Interface method will fail with "not implemented"
    result = parse_frontmatter(@malformed_frontmatter)
    
    # Test will fail on interface method call
    assert result.is_a?(Hash), 'Should return hash even with malformed frontmatter'
    assert result.key?('error'), 'Should include error information'
    
    # Also test safe parsing method
    safe_result = safe_parse_frontmatter(@malformed_frontmatter)
    assert safe_result.is_a?(Hash), 'Safe parse should return hash'
  end

  private

  # Interface methods - now implemented
  def process_markdown_content(content)
    @renderer.process_markdown_content(content)
  end

  def parse_frontmatter(content)
    @renderer.parse_frontmatter(content)
  end

  def safe_parse_frontmatter(content)
    @renderer.safe_parse_frontmatter(content)
  end

  def extract_template_variables(content)
    @renderer.extract_template_variables(content)
  end

  def assert_no_executable_javascript(html)
    @renderer.assert_no_executable_javascript(html)
  end

  def assert_syntax_highlighting_applied(html, language)
    @renderer.assert_syntax_highlighting_applied(html, language)
  end

  # Custom error class for frontmatter parsing
  class FrontmatterParsingError < StandardError; end
end