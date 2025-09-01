#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'
require 'net/http'
require 'uri'
require 'nokogiri'

class DynamicMigrationTest < Minitest::Test
  # Test data directory
  TALKS_DIR = File.join(File.dirname(__FILE__), '..', '_talks')
  
  # Dynamic talk discovery - find talks with notist_url in front matter
  def setup
    @talks = {}
    load_all_talks_with_sources
  end
  
  def load_all_talks_with_sources
    Dir.glob("#{TALKS_DIR}/*.md").each do |file|
      content = File.read(file)
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        yaml_content = YAML.safe_load($1)
        
        # Only include talks that have a source URL (notist_url or similar)
        if yaml_content['notist_url'] || yaml_content['source_url']
          source_url = yaml_content['notist_url'] || yaml_content['source_url']
          
          @talks[File.basename(file, '.md')] = {
            file: file,
            yaml: yaml_content,
            raw_content: content,
            source_url: source_url
          }
        end
      end
    end
    
    puts "Found #{@talks.length} talks with source URLs for dynamic testing"
  end

  # ==========================================
  # Dynamic Source-vs-Migrated Comparison
  # ==========================================
  
  def test_migrated_resources_match_source_exactly
    @talks.each do |talk_name, talk_data|
      puts "\n🔍 Testing #{talk_name}..."
      
      # Fetch original source page
      source_resources = extract_resources_from_source(talk_data[:source_url])
      migrated_resources = talk_data[:yaml]['resources'] || []
      
      # CRITICAL: Resource count must match exactly
      assert_equal source_resources.length, migrated_resources.length,
        "❌ RESOURCE COUNT MISMATCH for #{talk_name}:\n" \
        "Source has #{source_resources.length} resources\n" \
        "Migrated has #{migrated_resources.length} resources\n" \
        "EVERY resource from source must be migrated!"
      
      # Validate each migrated resource has meaningful title
      migrated_resources.each_with_index do |resource, index|
        title = resource['title']
        
        refute title.match?(/^Resource \d+$/), 
          "❌ GENERIC TITLE: '#{title}' should be actual content title from source"
        
        refute title.empty?, 
          "❌ EMPTY TITLE: Resource #{index + 1} has no title"
          
        assert title.length > 5,
          "❌ TOO SHORT TITLE: '#{title}' is too short to be meaningful"
      end
      
      puts "✅ #{talk_name}: #{migrated_resources.length} resources with meaningful titles"
    end
  end
  
  def test_video_availability_matches_source
    @talks.each do |talk_name, talk_data|
      puts "\n🎬 Testing video for #{talk_name}..."
      
      # Check if source has video
      source_has_video = source_page_has_video?(talk_data[:source_url])
      migrated_resources = talk_data[:yaml]['resources'] || []
      migrated_videos = migrated_resources.select { |r| r['type'] == 'video' }
      
      if source_has_video
        assert migrated_videos.length > 0,
          "❌ VIDEO MISSING: Source has video but migration doesn't include it"
          
        # Test that video URL actually works
        migrated_videos.each do |video|
          video_url = video['url']
          assert video_works?(video_url),
            "❌ VIDEO BROKEN: #{video_url} doesn't work or video doesn't exist"
        end
        
        puts "✅ #{talk_name}: Video present and working"
      else
        puts "ℹ️  #{talk_name}: No video in source (as expected)"
      end
    end
  end
  
  def test_slides_are_google_drive_embedded
    @talks.each do |talk_name, talk_data|
      migrated_resources = talk_data[:yaml]['resources'] || []
      slides_resources = migrated_resources.select { |r| r['type'] == 'slides' }
      
      slides_resources.each do |slides|
        url = slides['url']
        
        # CRITICAL: Must be Google Drive, not direct PDF downloads
        if url.include?('.pdf') && !url.include?('drive.google.com')
          flunk "❌ WRONG PDF SOURCE: #{url}\n" \
                "Slides must be uploaded to Google Drive, not linked to external PDFs!\n" \
                "This prevents thumbnail generation and proper embedding."
        end
        
        if url.include?('drive.google.com')
          assert url.include?('/file/d/') && url.include?('/view'),
            "❌ WRONG GOOGLE DRIVE FORMAT: #{url}\n" \
            "Must use /file/d/{id}/view format for proper embedding"
        end
      end
      
      if slides_resources.length > 0
        puts "✅ #{talk_name}: Slides properly hosted on Google Drive"
      end
    end
  end

  private
  
  def extract_resources_from_source(source_url)
    # Fetch and parse the source page
    uri = URI.parse(source_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.request_uri)
    doc = Nokogiri::HTML(response.body)
    
    # Extract actual content resources (not navigation/metadata)
    resource_links = []
    
    # Look for resources section specifically
    resources_section = doc.css('#resources, .resources, *:contains("Resources")').first
    if resources_section
      # Get links that are actual content resources
      links = resources_section.css('a[href]')
      links.each do |link|
        href = link['href']
        title = link.text.strip
        
        # Skip navigation/metadata links
        next if href.include?('notist.st') || href.include?('noti.st')
        next if href.include?('twitter.com/intent') 
        next if href.start_with?('#') || href.start_with?('/')
        next if title.empty? || title.length < 3
        
        resource_links << {
          url: href,
          title: title,
          type: determine_resource_type(href)
        }
      end
    end
    
    resource_links
  end
  
  def source_page_has_video?(source_url)
    uri = URI.parse(source_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.request_uri)
    content = response.body
    
    # Check for video indicators
    content.include?('youtube.com') || 
    content.include?('youtu.be') || 
    content.include?('notist.ninja/embed') ||
    content.include?('id="video"')
  end
  
  def video_works?(video_url)
    return false unless video_url.include?('youtube.com') || video_url.include?('youtu.be')
    
    # For YouTube, check if video page loads successfully
    uri = URI.parse(video_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    response = http.get(uri.request_uri)
    
    # YouTube returns 200 even for non-existent videos, so check content
    !response.body.include?('Video unavailable') && 
    !response.body.include?('This video is not available')
  end
  
  def determine_resource_type(url)
    return 'video' if url.include?('youtube.com') || url.include?('youtu.be')
    return 'slides' if url.include?('docs.google.com/presentation') || url.include?('drive.google.com')
    return 'code' if url.include?('github.com')
    'link'
  end
end
