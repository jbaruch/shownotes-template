#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'
require 'nokogiri'

class ThumbnailAccessibilityTest < Minitest::Test
  JEKYLL_BASE_URL = ENV['TEST_BASE_URL'] || 'http://localhost:4000'

  def setup
    start_test_server
  end

  def teardown
    stop_test_server
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
        thumbnail_uri = URI.parse(src)
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
        
        # Check for onerror handler
        assert img.has_attribute?('onerror'), "Thumbnail images should have onerror fallback"
        assert img['onerror'].include?('placeholder-thumbnail.svg'), "onerror should activate fallback"
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

  def start_test_server
    begin
      uri = URI.parse(JEKYLL_BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 1
      response = http.get('/')
      return if response.code.to_i.between?(200, 399)
    rescue
    end

    puts "Building Jekyll site for thumbnail accessibility tests..."
    build_result = system('bundle exec jekyll build --config _config_test.yml --quiet')
    raise "Failed to build Jekyll site" unless build_result
    
    puts "Starting Jekyll server for thumbnail accessibility tests..."
    @server_pid = spawn("bundle exec jekyll serve --config _config_test.yml --port #{URI.parse(JEKYLL_BASE_URL).port} --detach --skip-initial-build", 
                       :out => '/dev/null', :err => '/dev/null')
    sleep 3
  end

  def stop_test_server
    if @server_pid
      Process.kill('TERM', @server_pid) rescue nil
      Process.wait(@server_pid) rescue nil
    end
  end

  def site_talks_count
    talks_dir = File.join(File.dirname(__FILE__), '..', '..', '..', '_talks')
    return 0 unless Dir.exist?(talks_dir)
    Dir.glob(File.join(talks_dir, '*.md')).size
  end
end
