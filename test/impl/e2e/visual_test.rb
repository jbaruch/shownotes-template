#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'

class VisualTest < Minitest::Test
  JEKYLL_BASE_URL = 'http://localhost:4000'
  
  def setup
    # Test if Jekyll server is running, start it if not
    begin
      uri = URI.parse(JEKYLL_BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 5
      response = http.get('/')
      @server_running = response.code.to_i.between?(200, 399)
    rescue
      @server_running = false
    end
    
    # Start Jekyll server if not running
    unless @server_running
      puts "Building and starting Jekyll server for visual tests..."
      
      # First, build the site to ensure all content is generated
      puts "Building Jekyll site..."
      build_result = system('bundle exec jekyll build --quiet')
      assert build_result, "Failed to build Jekyll site"
      
      # Then start the server
      puts "Starting Jekyll server..."
      @jekyll_pid = spawn('bundle exec jekyll serve --detach --skip-initial-build')
      
      # Wait for server to start (up to 30 seconds)
      30.times do
        sleep 1
        begin
          uri = URI.parse(JEKYLL_BASE_URL)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 2
          response = http.get('/')
          if response.code.to_i.between?(200, 399)
            @server_running = true
            puts "Jekyll server started successfully"
            break
          end
        rescue
          # Continue waiting
        end
      end
      
      assert @server_running, "Failed to start Jekyll server after 30 seconds"
    end
  end
  
  def teardown
    # Clean up Jekyll server if we started it
    if @jekyll_pid
      begin
        Process.kill('TERM', @jekyll_pid)
        Process.wait(@jekyll_pid)
      rescue
        # Process may have already exited
      end
    end
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
  
  def test_any_talk_page_loads
    # Find any available talk page dynamically
    talk_url = find_any_talk_url
    
    if talk_url.nil?
      skip "❌ SKIPPED: No talk pages found - repository has no talks"
      return
    end
    
    uri = URI.parse("#{JEKYLL_BASE_URL}#{talk_url}")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert response.code.to_i.between?(200, 399), 
      "Talk page failed to load: HTTP #{response.code} for #{talk_url}"
      
    # Check for basic expected content structure
    assert response.body.include?('<title>'), 
      "Talk page missing title tag"
    assert response.body.length > 100, 
      "Talk page content seems too short"
      
    puts "SUCCESS Talk page loads successfully (HTTP #{response.code}) for #{talk_url}"
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
    # Base pages that should always exist
    base_test_pages = [
      '/',
      '/talks/',
    ]
    
    # Add any specific talk pages that exist
    specific_talk_pages = find_all_talk_urls
    
    test_pages = base_test_pages + specific_talk_pages
    
    test_pages.each do |page_path|
      uri = URI.parse("#{JEKYLL_BASE_URL}#{page_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.path)
      
      refute response.code.to_i.between?(400, 599), 
        "Error page found: #{page_path} returned HTTP #{response.code}"
        
      puts "  SUCCESS #{page_path}: HTTP #{response.code}"
    end
    
    if specific_talk_pages.empty?
      puts "  INFO: No talk pages found - tested base pages only"
    else
      puts "  INFO: Tested #{specific_talk_pages.length} talk page(s)"
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
    test_pages = ['/']
    
    # Add any available talk pages
    talk_urls = find_all_talk_urls
    test_pages += talk_urls
    
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
    
    # If no thumbnails on homepage, check if any talk page exists and check it
    if thumbnail_count == 0
      talk_url = find_any_talk_url
      
      if talk_url
        uri = URI.parse("#{JEKYLL_BASE_URL}#{talk_url}")
        response = http.get(uri.path)
        drive_thumbnails = response.body.scan(/https:\/\/drive\.google\.com\/thumbnail\?id=/)
        slides_thumbnails = response.body.scan(/https:\/\/lh3\.googleusercontent\.com\/d\//)
        thumbnail_count = drive_thumbnails.length + slides_thumbnails.length
      else
        # No talks exist, skip the test
        skip "❌ SKIPPED: No talks found - cannot test Google Drive thumbnails without content"
        return
      end
    end
    
    assert thumbnail_count > 0, 
      "No Google Drive/Slides thumbnail URLs found in homepage or talk page HTML"
      
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
    # Test the homepage for broken link patterns
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    # Also test any available talk page if one exists
    talk_url = find_any_talk_url
    if talk_url
      talk_uri = URI.parse("#{JEKYLL_BASE_URL}#{talk_url}")
      talk_response = http.get(talk_uri.path)
      response.body += "\n" + talk_response.body # Combine both for testing
    end
    
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

private

  def find_any_talk_url
    # /talks/ now has a meta redirect to homepage where talks are properly formatted
    # Look for talk links on the homepage since /talks/ redirects there
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    # Look for talk links in the homepage HTML
    talk_links = response.body.scan(/href="(\/talks\/[^"]+)"/).flatten
    talk_links.first # Return the first talk URL found, or nil if none
  end

  def find_all_talk_urls
    # /talks/ now has a meta redirect to homepage where talks are properly formatted
    # Look for talk links on the homepage since /talks/ redirects there
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    # Look for talk links in the homepage HTML
    talk_links = response.body.scan(/href="(\/talks\/[^"]+)"/).flatten
    talk_links.uniq # Return all unique talk URLs found
  end
end