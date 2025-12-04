# frozen_string_literal: true

require 'uri'

# URL validation utilities for security and consistency
module UrlValidator
  # Check if URL is valid (has http/https protocol and proper format)
  def valid_url?(url)
    return false if url.nil? || url.to_s.strip.empty?
    
    # Must start with http:// or https://
    return false unless url.match?(/^https?:\/\//)
    
    # Reject URLs with dangerous content
    return false if url.include?('<script>') || url.include?('alert(')
    
    true
  end
  
  # Check if URL is safe (no malicious protocols or content)
  def safe_url?(url)
    return false if url.nil? || url.to_s.strip.empty?
    
    # Reject dangerous protocols
    return false if url.match?(/^javascript:/i)
    return false if url.match?(/^data:/i)
    return false if url.match?(/^file:/i)
    
    # Reject URLs with script tags
    return false if url.match?(/<script>/i)
    
    # Reject URLs with javascript: in the path
    return false if url.include?('javascript:')
    
    # Reject URLs with alert( function calls
    return false if url.include?('alert(')
    
    true
  end
  
  # Check if URL uses http or https protocol
  def http_or_https?(url)
    return false if url.nil? || url.to_s.strip.empty?
    url.match?(/^https?:\/\//)
  end
  
  # Normalize URL for comparison (remove protocol differences, trailing slashes)
  def normalize_url(url)
    return nil if url.nil?
    
    normalized = url.strip
    # Convert https to http for consistent comparison
    normalized = normalized.sub(/^https:\/\//, 'http://')
    # Remove trailing slash
    normalized = normalized.chomp('/')
    
    normalized
  end
  
  # Extract domain from URL
  def extract_domain(url)
    return nil if url.nil? || url.to_s.strip.empty?
    
    begin
      uri = URI.parse(url)
      uri.host
    rescue URI::InvalidURIError
      nil
    end
  end
  
  # Check if URL is from Google Drive
  def google_drive_url?(url)
    return false if url.nil? || url.to_s.strip.empty?
    url.include?('drive.google.com') || url.include?('docs.google.com')
  end
  
  # Check if URL is from YouTube
  def youtube_url?(url)
    return false if url.nil? || url.to_s.strip.empty?
    url.match?(/(?:youtube\.com\/watch\?v=|youtu\.be\/|m\.youtube\.com\/watch\?v=|youtube\.com\/embed\/)/)
  end
  
  # Check if URL is from Notist
  def notist_url?(url)
    return false if url.nil? || url.to_s.strip.empty?
    url.include?('notist.cloud') || url.include?('speaking.jbaru.ch') || url.include?('notist.ninja')
  end
end
