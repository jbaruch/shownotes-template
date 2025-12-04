# frozen_string_literal: true

# HtmlSanitizer provides utilities for HTML escaping and sanitization
# to prevent XSS attacks and ensure safe HTML output.
#
# This module extracts common HTML sanitization logic used across
# TalkRenderer and SimpleTalkRenderer to provide a single source of truth
# for HTML security.
#
# Usage:
#   include HtmlSanitizer
#   
#   safe_text = escape_html(user_input)
#   safe_html = sanitize_html(html_content)
module HtmlSanitizer
  # Escapes HTML special characters to prevent XSS attacks.
  #
  # This method converts potentially dangerous characters into their
  # HTML entity equivalents, making them safe to display in HTML context.
  #
  # @param text [String, nil] The text to escape
  # @return [String] The escaped text, or empty string if input is nil
  #
  # @example
  #   escape_html('<script>alert("XSS")</script>')
  #   # => '&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;'
  #
  # @example
  #   escape_html(nil)
  #   # => ''
  def escape_html(text)
    return '' if text.nil?
    
    # Convert to string to handle non-string inputs
    text = text.to_s
    return '' if text.empty?
    
    # Escape HTML special characters
    # Order matters: & must be escaped first to avoid double-escaping
    text.gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
        .gsub('"', '&quot;')
        .gsub("'", '&#x27;')
  end

  # Sanitizes HTML content by removing dangerous script tags.
  #
  # This method removes <script> tags and their content to prevent
  # JavaScript execution. It's designed to work with HTML that may
  # contain legitimate tags (like <p>, <strong>, etc.) but needs
  # script tags removed for security.
  #
  # @param html [String, nil] The HTML content to sanitize
  # @return [String] The sanitized HTML, or empty string if input is nil
  #
  # @example
  #   sanitize_html('<p>Hello</p><script>alert("XSS")</script>')
  #   # => '<p>Hello</p>&lt;script&gt;[removed]&lt;/script&gt;'
  #
  # @example
  #   sanitize_html('<p>Safe <strong>content</strong></p>')
  #   # => '<p>Safe <strong>content</strong></p>'
  #
  # @note This method uses a simple regex-based approach. For more
  #   comprehensive HTML sanitization, consider using a dedicated
  #   library like Sanitize or Loofah.
  def sanitize_html(html)
    return '' if html.nil?
    
    html = html.to_s
    return '' if html.empty?
    
    # Remove script tags and their content (case-insensitive, multiline)
    # Replace with escaped version to make the attempt visible but safe
    html.gsub(/<script[^>]*>.*?<\/script>/mi, '&lt;script&gt;[removed]&lt;/script&gt;')
  end
end
