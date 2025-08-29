#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'

class VisualTestSimple < Minitest::Test
  JEKYLL_BASE_URL = 'http://localhost:4000'
  
  def setup
    # Test if Jekyll server is running
    begin
      uri = URI.parse(JEKYLL_BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 5
      response = http.get('/')
      @server_running = response.code.to_i.between?(200, 399)
    rescue
      @server_running = false
    end
    
    skip "Jekyll server not running on #{JEKYLL_BASE_URL}. Start with: bundle exec jekyll serve" unless @server_running
  end

  # ===========================================
  # Test Suite 1: Homepage Accessibility
  # ===========================================
  
  def test_homepage_loads_successfully
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    assert response.code.to_i.between?(200, 399), 
      "Homepage failed to load: HTTP #{response.code}"
      
    # Check that the response contains expected content
    refute response.body.include?('{{site.title}}'), 
      "CRITICAL: Literal liquid syntax found in homepage HTML"
    refute response.body.include?('{{'), 
      "Unprocessed liquid syntax found in homepage"
      
    puts "SUCCESS Homepage loads successfully (HTTP #{response.code})"
  end
  
  def test_luxembourg_talk_page_loads
    uri = URI.parse("#{JEKYLL_BASE_URL}/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert response.code.to_i.between?(200, 399), 
      "Luxembourg talk page failed to load: HTTP #{response.code}"
      
    # Check for expected content
    assert response.body.include?('Technical Enshittification'), 
      "Talk page missing expected title"
    assert response.body.include?('resources'), 
      "Talk page missing resources section"
      
    puts "SUCCESS Luxembourg talk page loads successfully (HTTP #{response.code})"
  end

  # ===========================================
  # Test Suite 2: Resource Links Work
  # ===========================================
  
  def test_talk_list_page_loads
    uri = URI.parse("#{JEKYLL_BASE_URL}/talks/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert response.code.to_i.between?(200, 399), 
      "Talks list page failed to load: HTTP #{response.code}"
      
    puts "SUCCESS Talks list page loads successfully (HTTP #{response.code})"
  end

  # ===========================================
  # Test Suite 3: Content Quality Checks
  # ===========================================
  
  def test_no_error_pages
    test_pages = [
      '/',
      '/talks/',
      '/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/',
    ]
    
    test_pages.each do |page_path|
      uri = URI.parse("#{JEKYLL_BASE_URL}#{page_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.path)
      
      refute response.code.to_i.between?(400, 599), 
        "Error page found: #{page_path} returned HTTP #{response.code}"
        
      puts "  SUCCESS #{page_path}: HTTP #{response.code}"
    end
    
    puts "SUCCESS All test pages load without errors"
  end
  
  def test_html_structure_validity
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    # Basic HTML structure checks
    assert response.body.include?('<!DOCTYPE html>'), 
      "Missing HTML5 doctype"
    assert response.body.include?('<html'), 
      "Missing html tag"
    assert response.body.include?('<head>'), 
      "Missing head section"
    assert response.body.include?('<body>'), 
      "Missing body section"
      
    puts "SUCCESS HTML structure is valid"
  end

  # ===========================================
  # Test Suite 4: Resource Integration
  # ===========================================
  
  def test_no_liquid_template_errors_in_html
    test_pages = [
      '/',
      '/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/',
    ]
    
    test_pages.each do |page_path|
      uri = URI.parse("#{JEKYLL_BASE_URL}#{page_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.path)
      
      # Check for unprocessed liquid syntax in HTML
      liquid_errors = response.body.scan(/\{\{[^}]+\}\}|\{%[^%]+%\}/)
      
      assert_empty liquid_errors, 
        "Unprocessed liquid syntax found in #{page_path}: #{liquid_errors}"
        
      puts "  SUCCESS #{page_path}: No liquid template errors"
    end
    
    puts "SUCCESS No liquid template errors in generated HTML"
  end
  
  def test_google_drive_thumbnail_urls_present
    # Check homepage for thumbnails (where previews are shown)
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    # Look for Google Drive thumbnail URLs in the HTML
    drive_thumbnails = response.body.scan(/https:\/\/drive\.google\.com\/thumbnail\?id=/)
    slides_thumbnails = response.body.scan(/https:\/\/lh3\.googleusercontent\.com\/d\//)
    
    thumbnail_count = drive_thumbnails.length + slides_thumbnails.length
    
    # If no thumbnails on homepage, check talk page
    if thumbnail_count == 0
      uri = URI.parse("#{JEKYLL_BASE_URL}/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/")
      response = http.get(uri.path)
      drive_thumbnails = response.body.scan(/https:\/\/drive\.google\.com\/thumbnail\?id=/)
      slides_thumbnails = response.body.scan(/https:\/\/lh3\.googleusercontent\.com\/d\//)
      thumbnail_count = drive_thumbnails.length + slides_thumbnails.length
    end
    
    assert thumbnail_count > 0, 
      "No Google Drive/Slides thumbnail URLs found in homepage or Luxembourg talk page HTML"
      
    puts "SUCCESS Found #{thumbnail_count} thumbnail URLs in generated HTML"
  end

  # ===========================================
  # Performance and Basic Quality
  # ===========================================
  
  def test_reasonable_page_size
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    page_size_kb = response.body.length / 1024.0
    
    # Homepage should be reasonably sized (not bloated)
    assert page_size_kb < 500, 
      "Homepage too large: #{page_size_kb.round(1)}KB (should be < 500KB)"
      
    puts "SUCCESS Homepage size reasonable: #{page_size_kb.round(1)}KB"
  end
  
  def test_no_common_broken_links
    uri = URI.parse("#{JEKYLL_BASE_URL}/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    # Check for common broken link patterns in HTML
    broken_patterns = [
      'href="http://http://',
      'href="https://https://',
      'src="http://http://',
      'src="https://https://',
      'href="#"',
      'href="javascript:void(0)"'
    ]
    
    broken_patterns.each do |pattern|
      refute response.body.include?(pattern), 
        "Broken link pattern found: #{pattern}"
    end
    
    puts "SUCCESS No common broken link patterns found"
  end
end