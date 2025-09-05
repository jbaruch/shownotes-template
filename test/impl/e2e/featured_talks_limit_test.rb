#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'yaml'

class FeaturedTalksLimitTest < Minitest::Test
  JEKYLL_BASE_URL = 'http://localhost:4000'
  
  @@jekyll_pid = nil
  @@server_running = false
  
  def self.startup
    # Load expected count from config
    config = YAML.load_file('_config.yml')
    @@expected_featured_limit = config['featured_talks_count'] || 4
    
    # Check if we have enough talks to run the test
    talks_dir = '_talks'
    talk_files = Dir.glob(File.join(talks_dir, '*.md'))
    @@total_talks_count = talk_files.length
    
    # Skip if insufficient talks
    if @@total_talks_count < @@expected_featured_limit
      puts "Insufficient talks (#{@@total_talks_count}) for featured talks test (requires #{@@expected_featured_limit})"
      return
    end
    
    # Clean up any existing Jekyll processes first
    system('pkill -f jekyll 2>/dev/null')
    sleep 2
    
    # Test if Jekyll server is running, start it if not
    begin
      uri = URI.parse("#{JEKYLL_BASE_URL}/")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 5
      response = http.get(uri.path)
      @@server_running = response.code.to_i.between?(200, 399)
    rescue
      @@server_running = false
    end
    
    # Start Jekyll server if not running
    unless @@server_running
      puts "Building Jekyll site for featured talks limit test..."
      build_result = system('bundle exec jekyll build --config _config_test.yml --quiet')
      raise "Failed to build Jekyll site" unless build_result
      
      puts "Starting Jekyll server for featured talks limit test..."
      @@jekyll_pid = spawn('bundle exec jekyll serve --config _config_test.yml --detach --skip-initial-build')
      
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
    # Clean up Jekyll server
    if @@jekyll_pid
      begin
        Process.kill('TERM', @@jekyll_pid)
        Process.wait(@@jekyll_pid)
      rescue
        # Process may have already exited
      end
      @@jekyll_pid = nil
    end
    
    # Ensure all Jekyll processes are cleaned up
    system('pkill -f jekyll 2>/dev/null')
    @@server_running = false
  end
  
  def setup
    # Skip if insufficient talks
    if @@total_talks_count < @@expected_featured_limit
      skip "Insufficient talks (#{@@total_talks_count}) for featured talks test (requires #{@@expected_featured_limit})"
    end
    
    # Ensure server is still running
    unless @@server_running
      skip "Jekyll server not available"
    end
    
    @expected_featured_limit = @@expected_featured_limit
  end

  def test_featured_talks_limited_to_four
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert response.code.to_i.between?(200, 399), 
           "Homepage should be accessible (HTTP #{response.code})"
    
    doc = Nokogiri::HTML(response.body)
    
    # Find the featured talks section
    featured_section = doc.css('section.featured-talks').first
    assert featured_section, "Should have a featured talks section"
    
    # Count featured talk cards (large panels)
    featured_cards = featured_section.css('article.featured-talk-card')
    featured_count = featured_cards.length
    
    puts "🔍 Found #{featured_count} featured talk cards (expected: #{@expected_featured_limit})"
    
    assert_equal @expected_featured_limit, featured_count,
                 "Featured talks should be limited to #{@expected_featured_limit}, but found #{featured_count}"
  end

  def test_remaining_talks_in_compact_list
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert response.code.to_i.between?(200, 399), 
           "Homepage should be accessible (HTTP #{response.code})"
    
    doc = Nokogiri::HTML(response.body)
    
    # Find the all talks section
    all_talks_section = doc.css('section.all-talks').first
    assert all_talks_section, "Should have an 'all talks' section for remaining talks"
    
    # Count small list items
    talk_list_items = all_talks_section.css('article.talk-list-item')
    compact_count = talk_list_items.length
    
    puts "🔍 Found #{compact_count} talks in compact list"
    
    # Should have some talks in the compact list (total talks - featured talks)
    assert compact_count > 0, "Should have talks in the compact 'All Presentations' list"
    
    # Verify the compact list has at least as many items as featured
    # (with small numbers of talks, they can be equal)
    assert compact_count >= @expected_featured_limit, 
           "Compact list should have at least as many talks (#{compact_count}) as featured section (#{@expected_featured_limit})"
  end

  def test_homepage_structure_makes_sense
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    doc = Nokogiri::HTML(response.body)
    
    # Count total talks on homepage
    featured_cards = doc.css('section.featured-talks article.featured-talk-card')
    compact_items = doc.css('section.all-talks article.talk-list-item')
    
    total_on_homepage = featured_cards.length + compact_items.length
    
    puts "📊 Homepage structure:"
    puts "  - Featured (large): #{featured_cards.length}"
    puts "  - Compact (small): #{compact_items.length}"
    puts "  - Total: #{total_on_homepage}"
    
    # Sanity check: should have a reasonable total (at least some talks)
    assert total_on_homepage > 0, "Should have at least some talks"
    assert featured_cards.length <= compact_items.length, 
           "Featured talks (#{featured_cards.length}) should not outnumber compact list (#{compact_items.length})"
  end
end

# Start the Jekyll server when the test class is loaded
FeaturedTalksLimitTest.startup

# Hook into Minitest lifecycle for class-level teardown
Minitest.after_run { FeaturedTalksLimitTest.shutdown }
