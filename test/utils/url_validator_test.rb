# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/utils/url_validator'

class UrlValidatorTest < Minitest::Test
  include UrlValidator
  
  # Test valid_url? method
  
  def test_valid_url_with_https
    assert valid_url?('https://example.com')
    assert valid_url?('https://www.example.com/path')
    assert valid_url?('https://example.com/path?query=value')
  end
  
  def test_valid_url_with_http
    assert valid_url?('http://example.com')
    assert valid_url?('http://www.example.com/path')
  end
  
  def test_valid_url_with_complex_paths
    assert valid_url?('https://docs.google.com/presentation/d/abc123/edit')
    assert valid_url?('https://youtube.com/watch?v=abc123')
    assert valid_url?('https://github.com/user/repo/blob/main/file.rb')
  end
  
  def test_invalid_url_without_protocol
    refute valid_url?('example.com')
    refute valid_url?('www.example.com')
  end
  
  def test_invalid_url_with_malicious_protocol
    refute valid_url?('javascript:alert(1)')
    refute valid_url?('data:text/html,<script>alert(1)</script>')
    refute valid_url?('file:///etc/passwd')
  end
  
  def test_invalid_url_empty_or_nil
    refute valid_url?(nil)
    refute valid_url?('')
    refute valid_url?('   ')
  end
  
  def test_invalid_url_with_special_characters
    refute valid_url?('https://example.com/<script>')
    refute valid_url?('https://example.com/alert(')
  end
  
  # Test safe_url? method
  
  def test_safe_url_with_https
    assert safe_url?('https://example.com')
    assert safe_url?('https://www.example.com/path')
  end
  
  def test_safe_url_with_http
    assert safe_url?('http://example.com')
  end
  
  def test_unsafe_url_with_javascript_protocol
    refute safe_url?('javascript:alert(1)')
    refute safe_url?('JavaScript:alert(1)')
    refute safe_url?('JAVASCRIPT:alert(1)')
  end
  
  def test_unsafe_url_with_data_protocol
    refute safe_url?('data:text/html,<script>alert(1)</script>')
    refute safe_url?('data:image/png;base64,abc123')
  end
  
  def test_unsafe_url_with_file_protocol
    refute safe_url?('file:///etc/passwd')
    refute safe_url?('file://C:/Windows/System32')
  end
  
  def test_unsafe_url_with_script_tags
    refute safe_url?('https://example.com/<script>alert(1)</script>')
    refute safe_url?('https://example.com/<SCRIPT>alert(1)</SCRIPT>')
  end
  
  def test_unsafe_url_with_javascript_in_path
    refute safe_url?('https://example.com/javascript:alert(1)')
    refute safe_url?('https://example.com/path?redirect=javascript:alert(1)')
  end
  
  def test_unsafe_url_with_alert_function
    refute safe_url?('https://example.com/alert(')
    refute safe_url?('https://example.com/?q=alert(1)')
  end
  
  def test_safe_url_empty_or_nil
    refute safe_url?(nil)
    refute safe_url?('')
    refute safe_url?('   ')
  end
  
  # Test http_or_https? method
  
  def test_http_or_https_with_https
    assert http_or_https?('https://example.com')
  end
  
  def test_http_or_https_with_http
    assert http_or_https?('http://example.com')
  end
  
  def test_http_or_https_with_other_protocols
    refute http_or_https?('ftp://example.com')
    refute http_or_https?('javascript:alert(1)')
    refute http_or_https?('data:text/html')
  end
  
  def test_http_or_https_without_protocol
    refute http_or_https?('example.com')
    refute http_or_https?('www.example.com')
  end
  
  def test_http_or_https_empty_or_nil
    refute http_or_https?(nil)
    refute http_or_https?('')
  end
  
  # Test normalize_url method
  
  def test_normalize_url_removes_protocol_difference
    assert_equal 'http://example.com', normalize_url('https://example.com')
    assert_equal 'http://example.com', normalize_url('http://example.com')
  end
  
  def test_normalize_url_removes_trailing_slash
    assert_equal 'http://example.com', normalize_url('https://example.com/')
    assert_equal 'http://example.com/path', normalize_url('https://example.com/path/')
  end
  
  def test_normalize_url_strips_whitespace
    assert_equal 'http://example.com', normalize_url('  https://example.com  ')
  end
  
  def test_normalize_url_handles_nil
    assert_nil normalize_url(nil)
  end
  
  def test_normalize_url_preserves_path_and_query
    assert_equal 'http://example.com/path?query=value', 
                 normalize_url('https://example.com/path?query=value')
  end
  
  # Test extract_domain method
  
  def test_extract_domain_from_https_url
    assert_equal 'example.com', extract_domain('https://example.com')
    assert_equal 'www.example.com', extract_domain('https://www.example.com')
  end
  
  def test_extract_domain_from_http_url
    assert_equal 'example.com', extract_domain('http://example.com')
  end
  
  def test_extract_domain_with_path
    assert_equal 'example.com', extract_domain('https://example.com/path')
    assert_equal 'example.com', extract_domain('https://example.com/path?query=value')
  end
  
  def test_extract_domain_with_subdomain
    assert_equal 'docs.google.com', extract_domain('https://docs.google.com/presentation')
    assert_equal 'drive.google.com', extract_domain('https://drive.google.com/file/d/123')
  end
  
  def test_extract_domain_from_invalid_url
    assert_nil extract_domain('not a url')
    assert_nil extract_domain('javascript:alert(1)')
  end
  
  def test_extract_domain_from_nil
    assert_nil extract_domain(nil)
  end
  
  # Test google_drive_url? method
  
  def test_google_drive_url_with_drive_domain
    assert google_drive_url?('https://drive.google.com/file/d/abc123')
    assert google_drive_url?('https://drive.google.com/open?id=abc123')
  end
  
  def test_google_drive_url_with_docs_domain
    assert google_drive_url?('https://docs.google.com/presentation/d/abc123')
    assert google_drive_url?('https://docs.google.com/document/d/abc123')
  end
  
  def test_not_google_drive_url
    refute google_drive_url?('https://example.com')
    refute google_drive_url?('https://youtube.com')
    refute google_drive_url?('https://github.com')
  end
  
  def test_google_drive_url_with_nil
    refute google_drive_url?(nil)
  end
  
  # Test youtube_url? method
  
  def test_youtube_url_with_watch_format
    assert youtube_url?('https://youtube.com/watch?v=abc123')
    assert youtube_url?('https://www.youtube.com/watch?v=abc123')
    assert youtube_url?('https://m.youtube.com/watch?v=abc123')
  end
  
  def test_youtube_url_with_short_format
    assert youtube_url?('https://youtu.be/abc123')
  end
  
  def test_youtube_url_with_embed_format
    assert youtube_url?('https://youtube.com/embed/abc123')
  end
  
  def test_not_youtube_url
    refute youtube_url?('https://example.com')
    refute youtube_url?('https://vimeo.com/123456')
  end
  
  def test_youtube_url_with_nil
    refute youtube_url?(nil)
  end
  
  # Test notist_url? method
  
  def test_notist_url_with_notist_cloud
    assert notist_url?('https://on.notist.cloud/pdf/abc123.pdf')
    assert notist_url?('https://on.notist.cloud/slides/abc123')
  end
  
  def test_notist_url_with_speaking_domain
    assert notist_url?('https://example.com/abc123')
  end
  
  def test_notist_url_with_notist_ninja
    assert notist_url?('https://notist.ninja/embed/abc123')
  end
  
  def test_not_notist_url
    refute notist_url?('https://example.com')
    refute notist_url?('https://youtube.com')
  end
  
  def test_notist_url_with_nil
    refute notist_url?(nil)
  end
end
