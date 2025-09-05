#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'
require 'nokogiri'

class HomepageThumbnailsTest < Minitest::Test
  JEKYLL_BASE_URL = ENV['TEST_BASE_URL'] || 'http://localhost:4000'
  
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
      
      puts "Building Jekyll site for homepage thumbnails test..."
      build_result = system('bundle exec jekyll build --config _config_test.yml --quiet')
      raise "Failed to build Jekyll site" unless build_result
      
      puts "Starting Jekyll server for homepage thumbnails test..."
      @@server_pid = spawn('bundle exec jekyll serve --config _config_test.yml --detach --skip-initial-build')
      
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

  def test_homepage_has_thumbnails_when_talks_exist
    skip "No talks found" if site_talks_count == 0
    
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert_equal "200", response.code, "Homepage should load successfully"
    
    doc = Nokogiri::HTML(response.body)
    
    # Check for thumbnails in featured talks section (using current template class)
    featured_thumbnails = doc.css('.featured-talks .thumbnail-image, .featured-thumbnail .thumbnail-image')
    assert featured_thumbnails.size > 0, "Homepage should have thumbnails in featured talks section"
    
    # Check that thumbnail images have proper src attributes
    featured_thumbnails.each do |img|
      src = img['src']
      assert src && !src.empty?, "Thumbnail image should have src attribute"
      assert src.include?('thumbnail') || src.include?('img') || src.include?('/assets/images/') || src.start_with?('data:'), 
             "Thumbnail src should be a valid image URL: #{src}"
    end
    
    puts "SUCCESS Found #{featured_thumbnails.size} thumbnail(s) on homepage"
  end

  def test_homepage_has_thumbnails_in_all_talks_section_when_talks_exist
    skip "No talks found" if site_talks_count == 0
    
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert_equal "200", response.code, "Homepage should load successfully"
    
    doc = Nokogiri::HTML(response.body)
    
    # Check for thumbnails in all talks section (using current template class)
    all_talks_thumbnails = doc.css('.all-talks .thumbnail-image, .talk-thumbnail .thumbnail-image')
    assert all_talks_thumbnails.size > 0, "Homepage should have thumbnails in all talks section"
    
    # Check that thumbnail images have proper src attributes
    all_talks_thumbnails.each do |img|
      src = img['src']
      assert src && !src.empty?, "Thumbnail image should have src attribute"
      assert src.include?('thumbnail') || src.include?('img') || src.include?('/assets/images/') || src.start_with?('data:'), 
             "Thumbnail src should be a valid image URL: #{src}"
    end
    
    puts "SUCCESS Found #{all_talks_thumbnails.size} thumbnail(s) in all talks section"
  end

  private

  def site_talks_count
    # Count talks by checking if _talks directory has any .md files
    talks_dir = File.join(File.dirname(__FILE__), '..', '..', '..', '_talks')
    return 0 unless Dir.exist?(talks_dir)
    
    Dir.glob(File.join(talks_dir, '*.md')).size
  end
end

# Start the Jekyll server when the test class is loaded
HomepageThumbnailsTest.startup

# Hook into Minitest lifecycle for class-level teardown
Minitest.after_run { HomepageThumbnailsTest.shutdown }
