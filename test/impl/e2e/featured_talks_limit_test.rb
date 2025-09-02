#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'
require 'nokogiri'

class FeaturedTalksLimitTest < Minitest::Test
  JEKYLL_BASE_URL = 'http://localhost:4000'
  EXPECTED_FEATURED_LIMIT = 4
  
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
      puts "Building Jekyll site for featured talks limit test..."
      build_result = system('bundle exec jekyll build --quiet')
      assert build_result, "Failed to build Jekyll site"
      
      puts "Starting Jekyll server for featured talks limit test..."
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
    
    puts "🔍 Found #{featured_count} featured talk cards (expected: #{EXPECTED_FEATURED_LIMIT})"
    
    assert_equal EXPECTED_FEATURED_LIMIT, featured_count,
                 "Featured talks should be limited to #{EXPECTED_FEATURED_LIMIT}, but found #{featured_count}"
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
    
    # Verify the compact list has significantly more items than featured
    # (since we have 30+ talks total)
    assert compact_count > EXPECTED_FEATURED_LIMIT, 
           "Compact list should have more talks (#{compact_count}) than featured section (#{EXPECTED_FEATURED_LIMIT})"
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
    
    # Sanity check: should have a reasonable total
    assert total_on_homepage > 10, "Should have a reasonable number of talks total"
    assert featured_cards.length <= compact_items.length, 
           "Featured talks (#{featured_cards.length}) should not outnumber compact list (#{compact_items.length})"
  end
end
