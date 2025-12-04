require_relative '../test_helper'
require_relative '../../lib/utils/html_sanitizer'

class HtmlSanitizerTest < Minitest::Test
  include HtmlSanitizer

  # Test escape_html method
  def test_escape_html_escapes_ampersands
    assert_equal '&amp;', escape_html('&')
  end

  def test_escape_html_escapes_less_than
    assert_equal '&lt;', escape_html('<')
  end

  def test_escape_html_escapes_greater_than
    assert_equal '&gt;', escape_html('>')
  end

  def test_escape_html_escapes_double_quotes
    assert_equal '&quot;', escape_html('"')
  end

  def test_escape_html_escapes_single_quotes
    assert_equal '&#x27;', escape_html("'")
  end

  def test_escape_html_escapes_combined_characters
    input = '<script>alert("XSS")</script>'
    expected = '&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;'
    assert_equal expected, escape_html(input)
  end

  def test_escape_html_handles_nil
    assert_equal '', escape_html(nil)
  end

  def test_escape_html_handles_empty_string
    assert_equal '', escape_html('')
  end

  def test_escape_html_converts_non_strings
    assert_equal '123', escape_html(123)
  end

  def test_escape_html_preserves_safe_text
    input = 'Hello World'
    assert_equal 'Hello World', escape_html(input)
  end

  def test_escape_html_escapes_multiple_special_chars
    input = '&<>"\'&<>"'
    expected = '&amp;&lt;&gt;&quot;&#x27;&amp;&lt;&gt;&quot;'
    assert_equal expected, escape_html(input)
  end

  # Test sanitize_html method
  def test_sanitize_html_removes_script_tags
    input = '<p>Hello</p><script>alert("XSS")</script><p>World</p>'
    result = sanitize_html(input)
    refute_includes result, '<script>'
    refute_includes result, 'alert'
  end

  def test_sanitize_html_removes_script_tags_with_attributes
    input = '<script type="text/javascript">alert("XSS")</script>'
    result = sanitize_html(input)
    refute_includes result, '<script'
    refute_includes result, 'alert'
  end

  def test_sanitize_html_removes_script_tags_case_insensitive
    input = '<SCRIPT>alert("XSS")</SCRIPT>'
    result = sanitize_html(input)
    refute_includes result.downcase, '<script'
  end

  def test_sanitize_html_removes_multiline_script_tags
    input = <<~HTML
      <p>Before</p>
      <script>
        var x = 1;
        alert(x);
      </script>
      <p>After</p>
    HTML
    result = sanitize_html(input)
    refute_includes result, '<script'
    refute_includes result, 'alert'
    assert_includes result, '<p>Before</p>'
    assert_includes result, '<p>After</p>'
  end

  def test_sanitize_html_preserves_safe_html
    input = '<p>Hello <strong>World</strong></p>'
    result = sanitize_html(input)
    assert_equal input, result
  end

  def test_sanitize_html_handles_empty_string
    assert_equal '', sanitize_html('')
  end

  def test_sanitize_html_handles_nil
    assert_equal '', sanitize_html(nil)
  end

  def test_sanitize_html_removes_multiple_script_tags
    input = '<script>alert(1)</script><p>Text</p><script>alert(2)</script>'
    result = sanitize_html(input)
    refute_includes result, '<script'
    refute_includes result, 'alert'
    assert_includes result, '<p>Text</p>'
  end

  # XSS Prevention Tests
  def test_prevents_xss_via_script_tag
    malicious = '<script>document.cookie</script>'
    result = sanitize_html(malicious)
    refute_includes result, '<script'
    refute_includes result, 'document.cookie'
  end

  def test_prevents_xss_via_img_onerror
    # escape_html escapes all HTML, including dangerous attributes
    malicious = '<img src=x onerror="alert(1)">'
    escaped = escape_html(malicious)
    # The entire tag is escaped, making it safe
    assert_includes escaped, '&lt;img'
    assert_includes escaped, '&gt;'
    # The dangerous attribute is now escaped text, not executable
    refute_match(/<img[^>]*onerror/, escaped)
  end

  def test_prevents_xss_via_javascript_protocol
    # escape_html escapes the entire tag, including javascript: URLs
    malicious = '<a href="javascript:alert(1)">Click</a>'
    escaped = escape_html(malicious)
    # The entire tag is escaped
    assert_includes escaped, '&lt;a'
    assert_includes escaped, '&gt;'
    # The javascript: protocol is now escaped text, not executable
    refute_match(/<a[^>]*href=["']javascript:/, escaped)
  end

  def test_prevents_xss_via_data_protocol
    # escape_html escapes all HTML tags
    malicious = '<a href="data:text/html,<script>alert(1)</script>">Click</a>'
    escaped = escape_html(malicious)
    # All tags are escaped
    assert_includes escaped, '&lt;a'
    assert_includes escaped, '&lt;script'
    # No executable HTML remains
    refute_match(/<(a|script)/, escaped)
  end

  # Edge Cases
  def test_escape_html_handles_unicode
    input = 'Hello 世界 🌍'
    result = escape_html(input)
    assert_equal input, result
  end

  def test_sanitize_html_handles_nested_tags
    input = '<div><p><span>Text</span></p></div>'
    result = sanitize_html(input)
    assert_equal input, result
  end

  def test_escape_html_escapes_in_correct_order
    # Ampersands must be escaped first to avoid double-escaping
    input = '&lt;'
    result = escape_html(input)
    assert_equal '&amp;lt;', result
  end

  def test_sanitize_html_handles_script_with_newlines_in_tag
    input = '<script
      type="text/javascript">alert(1)</script>'
    result = sanitize_html(input)
    refute_includes result, '<script'
    refute_includes result, 'alert'
  end

  def test_escape_html_handles_long_strings
    input = 'a' * 10000
    result = escape_html(input)
    assert_equal input, result
    assert_equal 10000, result.length
  end

  def test_sanitize_html_handles_script_tags_with_cdata
    input = '<script><![CDATA[alert(1)]]></script>'
    result = sanitize_html(input)
    refute_includes result, '<script'
    refute_includes result, 'alert'
  end
end
