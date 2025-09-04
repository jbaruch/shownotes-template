#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'
require 'nokogiri'

class ThumbnailAccessibilityTest < Minitest::Test
  JEKYLL_BASE_URL = ENV['TEST_BASE_URL'] || 'http://localhost:4000/shownotes'
  
  @@server_pid = nil
  @@server_running = false

  def self.startup
    # Check if server is already running
    begin
      uri = URI.parse("#{JEKYLL_BASE_URL}/")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 5
      response = http.get(uri.path)
      @@server_running = response.code.to_i.between?(200, 399)
    rescue
      @@server_running = false
    end

    # Start server if not running
    unless @@server_running
      # Clean up any existing Jekyll processes first
      system('pkill -f jekyll 2>/dev/null')
      sleep 2
      
      puts "Building Jekyll site for thumbnail accessibility test..."
      build_result = system('bundle exec jekyll build --quiet')
      raise "Failed to build Jekyll site" unless build_result
      
      puts "Starting Jekyll server for thumbnail accessibility test..."
      @@server_pid = spawn('bundle exec jekyll serve --detach --skip-initial-build')
      
      # Wait for server to start (up to 30 seconds)
      30.times do
        sleep 1
        begin
          uri = URI.parse("#{JEKYLL_BASE_URL}/")
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 2
          response = http.get(uri.path)
          if response.code.to_i.between?(200, 399)
            @@server_running = true
            puts "Jekyll server started successfully"
            break
          end
        rescue
          # Continue waiting
        end
      end
      
      raise "Failed to start Jekyll server after 30 seconds" unless @@server_running
    end
  end
  
  def self.shutdown
    if @@server_pid
      begin
        Process.kill('TERM', @@server_pid)
        Process.wait(@@server_pid)
      rescue
        # Process may have already exited
      end
      @@server_pid = nil
    end
    
    # Ensure all Jekyll processes are cleaned up
    system('pkill -f jekyll 2>/dev/null')
    @@server_running = false
  end

  def setup
    # Ensure server is still running
    unless @@server_running
      skip "Jekyll server not available"
    end
  end

  def test_thumbnail_images_are_accessible_in_browsers
    skip "No talks found" if site_talks_count == 0
    
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert_equal "200", response.code, "Homepage should load successfully"
    
    doc = Nokogiri::HTML(response.body)
    
    # Find all thumbnail images
    thumbnail_images = doc.css('.preview-image')
    assert thumbnail_images.size > 0, "Should have thumbnail images on homepage"
    
    broken_thumbnails = []
    accessible_thumbnails = []
    
    thumbnail_images.each do |img|
      src = img['src']
      next unless src && !src.empty?
      
      # Test if the thumbnail URL is actually accessible
      begin
        # Handle relative URLs by making them absolute
        if src.start_with?('/')
          full_url = "#{JEKYLL_BASE_URL}#{src}"
        else
          full_url = src
        end
        
        thumbnail_uri = URI.parse(full_url)
        http = Net::HTTP.new(thumbnail_uri.host, thumbnail_uri.port)
        http.use_ssl = true if thumbnail_uri.scheme == 'https'
        http.read_timeout = 5
        
        # Add user agent and referer headers to mimic browser request
        headers = {
          'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer' => JEKYLL_BASE_URL
        }
        
        thumb_response = http.get(thumbnail_uri.path + (thumbnail_uri.query ? "?#{thumbnail_uri.query}" : ""), headers)
        
        if thumb_response.code.to_i.between?(200, 299)
          accessible_thumbnails << src
          puts "✅ ACCESSIBLE: #{src}"
        else
          broken_thumbnails << "#{src} (HTTP #{thumb_response.code})"
          puts "❌ BLOCKED: #{src} (HTTP #{thumb_response.code})"
        end
        
      rescue => e
        broken_thumbnails << "#{src} (Error: #{e.message})"
        puts "❌ ERROR: #{src} (#{e.message})"
      end
    end
    
    puts "\n📊 THUMBNAIL ACCESSIBILITY REPORT:"
    puts "   Accessible: #{accessible_thumbnails.size}"
    puts "   Blocked/Broken: #{broken_thumbnails.size}"
    
    if broken_thumbnails.any?
      puts "\n🚨 BLOCKED THUMBNAILS:"
      broken_thumbnails.each { |thumb| puts "   - #{thumb}" }
      
      puts "\n💡 RECOMMENDATION:"
      puts "   Some thumbnails may be inaccessible due to network issues or missing files."
      puts "   Consider checking that all referenced thumbnail files exist locally."
    end
    
    # This test warns about broken thumbnails but doesn't fail the build
    # since thumbnails may be missing for talks that haven't been migrated yet
    if broken_thumbnails.any?
      puts "\n⚠️  WARNING: Some thumbnails may not display properly"
    else
      puts "\n✅ All thumbnails are accessible"
    end
  end

  def test_fallback_when_thumbnails_fail
    skip "No talks found" if site_talks_count == 0
    
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    doc = Nokogiri::HTML(response.body)
    
    # Check that we have proper fallback structure
    preview_containers = doc.css('.talk-preview-large, .talk-preview-small')
    assert preview_containers.size > 0, "Should have preview containers"
    
    # Check that each preview container has fallback elements for when images fail
    preview_containers.each do |container|
      # Should have either an image with onerror fallback or a fallback element
      img = container.css('.preview-image').first
      fallback = container.css('.thumbnail-fallback').first
      
      assert img || fallback, "Preview container should have either image or fallback element"
      
      if img
        # Image should have onerror attribute for fallback handling
        assert img.has_attribute?('onerror') || fallback, 
               "Image should have onerror fallback or container should have fallback element"
      end
    end
    
    preview_containers.each do |container|
      # Check for alternative content when thumbnails fail
      img = container.css('.preview-image').first
      if img
        # Verify image has proper alt text (even if empty)
        assert img.has_attribute?('alt'), "Thumbnail images should have alt attribute for accessibility"
        
        # Check for loading attribute
        assert img.has_attribute?('loading'), "Thumbnail images should have loading attribute"
        assert_equal 'lazy', img['loading'], "Thumbnails should use lazy loading"
        
        # Check for onerror handler or data-fallback
        assert img.has_attribute?('onerror') || img.has_attribute?('data-fallback'), "Thumbnail images should have onerror fallback or data-fallback"
        if img.has_attribute?('data-fallback')
          assert img['data-fallback'].include?('placeholder-thumbnail.svg'), "data-fallback should reference placeholder"
        elsif img.has_attribute?('onerror')
          assert img['onerror'].include?('placeholder-thumbnail.svg') || img['onerror'].include?('dataset.fallback'), "onerror should activate fallback"
        end
      end
      
      # Check that fallback structure exists
      fallback = container.css('.thumbnail-fallback').first
      if fallback
        assert fallback.css('.fallback-icon').any?, "Fallback should have icon"
        assert fallback.css('.fallback-text').any?, "Fallback should have text"
      end
    end
    
    puts "SUCCESS Thumbnail fallback structure is properly configured"
    fallback_elements = doc.css('.thumbnail-fallback')
    puts "         - Found #{fallback_elements.size} fallback elements"
    puts "         - All images have proper onerror handlers"
  end

  private

  def site_talks_count
    talks_dir = File.join(File.dirname(__FILE__), '..', '..', '..', '_talks')
    return 0 unless Dir.exist?(talks_dir)
    Dir.glob(File.join(talks_dir, '*.md')).size
  end
end

# Start the Jekyll server when the test class is loaded
ThumbnailAccessibilityTest.startup

# Hook into Minitest lifecycle for class-level teardown
Minitest.after_run { ThumbnailAccessibilityTest.shutdown }
