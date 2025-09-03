#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'
require 'nokogiri'

class HomepageThumbnailsTest < Minitest::Test
  JEKYLL_BASE_URL = ENV['TEST_BASE_URL'] || 'http://localhost:4000'

  def setup
    # We need a site running
    start_test_server
  end

  def teardown
    stop_test_server
  end

  def test_homepage_has_thumbnails_when_talks_exist
    skip "No talks found" if site_talks_count == 0
    
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert_equal "200", response.code, "Homepage should load successfully"
    
    doc = Nokogiri::HTML(response.body)
    
    # Check for thumbnails in featured talks section
    featured_thumbnails = doc.css('.featured-talks .preview-image')
    assert featured_thumbnails.size > 0, "Homepage should have thumbnails in featured talks section"
    
    # Check that thumbnail images have proper src attributes
    featured_thumbnails.each do |img|
      src = img['src']
      assert src && !src.empty?, "Thumbnail image should have src attribute"
      assert src.include?('thumbnail') || src.include?('img') || src.include?('drive.google.com') || src.include?('googleusercontent.com') || src.start_with?('data:'), 
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
    
    # Check for thumbnails in all talks section
    all_talks_thumbnails = doc.css('.all-talks .preview-image')
    assert all_talks_thumbnails.size > 0, "Homepage should have thumbnails in all talks section"
    
    # Check that thumbnail images have proper src attributes
    all_talks_thumbnails.each do |img|
      src = img['src']
      assert src && !src.empty?, "Thumbnail image should have src attribute"
      assert src.include?('thumbnail') || src.include?('img') || src.include?('drive.google.com') || src.include?('googleusercontent.com') || src.start_with?('data:'), 
             "Thumbnail src should be a valid image URL: #{src}"
    end
    
    puts "SUCCESS Found #{all_talks_thumbnails.size} thumbnail(s) in all talks section"
  end

  private

  def start_test_server
    # Check if server is already running
    begin
      uri = URI.parse(JEKYLL_BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 1
      response = http.get('/')
      return if response.code.to_i.between?(200, 399)
    rescue
      # Server not running, we'll start it
    end

    # Build and start server
    puts "Building Jekyll site for tests..."
    build_result = system('bundle exec jekyll build --quiet')
    raise "Failed to build Jekyll site" unless build_result
    
    puts "Starting Jekyll server for tests..."
    @server_pid = spawn("bundle exec jekyll serve --port #{URI.parse(JEKYLL_BASE_URL).port} --detach --skip-initial-build", 
                       :out => '/dev/null', :err => '/dev/null')
    sleep 3  # Give server time to start
  end

  def stop_test_server
    if @server_pid
      Process.kill('TERM', @server_pid) rescue nil
      Process.wait(@server_pid) rescue nil
    end
  end

  def site_talks_count
    # Count talks by checking if _talks directory has any .md files
    talks_dir = File.join(File.dirname(__FILE__), '..', '..', '..', '_talks')
    return 0 unless Dir.exist?(talks_dir)
    
    Dir.glob(File.join(talks_dir, '*.md')).size
  end
end
