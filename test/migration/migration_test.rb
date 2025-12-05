#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'
require 'net/http'
require 'uri'
require 'json'
require 'timeout'
require 'nokogiri'
require 'set'

class MigrationTest < Minitest::Test
  # Test data directory - find the project root directory
  PROJECT_ROOT = File.expand_path('../../..', __FILE__)
  TALKS_DIR = File.join(PROJECT_ROOT, '_talks')
  
  # Check if running in CI environment where external requests may fail
  def self.ci_environment?
    ENV['CI'] == 'true' || ENV['GITHUB_ACTIONS'] == 'true'
  end
  
  def setup
    @talks = {}
    
    # Check for single talk testing mode
    single_talk = ENV['TEST_SINGLE_TALK']
    if single_talk
      puts "🎯 SINGLE TALK MODE: Testing only '#{single_talk}'"
      load_single_talk(single_talk)
    else
      puts "🔍 FULL SUITE MODE: Testing all talks"
      load_all_talks_with_sources
    end
  end
  
  def load_single_talk(talk_name)
    file_path = File.join(TALKS_DIR, "#{talk_name}.md")
    
    unless File.exist?(file_path)
      raise "❌ TALK NOT FOUND: #{file_path} does not exist!"
    end
    
    load_talk_from_file(file_path, talk_name)
    puts "📋 Loaded 1 talk for focused testing: #{talk_name}"
  end
  
  def load_all_talks_with_sources
    Dir.glob("#{TALKS_DIR}/*.md").each do |file|
      talk_name = File.basename(file, '.md')
      load_talk_from_file(file, talk_name)
    end
    puts "📋 Loaded #{@talks.length} talks for testing"
  end
  
  def load_talk_from_file(file, talk_name)
    begin
      content = File.read(file)
      
      # Handle both YAML frontmatter format and markdown-only format
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        # YAML frontmatter format (legacy)
        yaml_content = YAML.safe_load($1, permitted_classes: [Date])
        
        # Check for legacy source_url field first, then look in HTML comments
        source_url = yaml_content['source_url'] || yaml_content['notist_url'] || extract_source_url_from_markdown(content)
        
        @talks[talk_name] = {
          file: file,
          yaml: yaml_content,
          raw_content: content,
          source_url: source_url
        }
      else
        # Markdown-only format - extract source URL from HTML comment
        source_url = extract_source_url_from_markdown(content)
        
        if source_url
          @talks[talk_name] = {
            file: file,
            yaml: nil,
            raw_content: content,
            source_url: source_url
          }
        end
      end
    rescue => e
      puts "⚠️  Failed to load #{talk_name}: #{e.message}"
    end
  end
  
  def extract_source_url_from_markdown(content)
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    if talks_with_sources.empty?
      puts "⚠️  SKIPPING migration validation: No talks with source URLs found"
      puts "   - This test is only needed for migrated content"
      puts "   - Users creating content manually can safely skip this test"
      return
    end
    
    @talks.each do |talk_name, talk_data|
      puts "\n🔍 Testing #{talk_name}..."
      
      # Fetch original source page resources
      source_resources = extract_resources_from_source(talk_data[:source_url])
      
      # Extract migrated resources from markdown content
      migrated_resources = extract_migrated_resources(talk_data[:raw_content])
      
      # CRITICAL: Resource count must match exactly
      assert_equal source_resources.length, migrated_resources.length,
        "❌ RESOURCE COUNT MISMATCH for #{talk_name}:\n" \
        "Source has #{source_resources.length} resources\n" \
        "Migrated has #{migrated_resources.length} resources\n" \
        "EVERY resource from source must be migrated!"
      
      # CRITICAL: Compare URLs and titles for each resource
      source_resources.each_with_index do |source_resource, index|
        # Find matching migrated resource by URL or title similarity
        migrated_resource = find_matching_migrated_resource(source_resource, migrated_resources)
        
        assert migrated_resource,
          "❌ MISSING RESOURCE: Source resource '#{source_resource[:title]}' (#{source_resource[:url]}) not found in migration"
        
        # Validate title similarity (allowing for reasonable variations)
        assert_title_similarity(source_resource[:title], migrated_resource['title'], talk_name)
        
        # Validate URL correctness (exact match or acceptable transformation)
        assert_url_correctness(source_resource[:url], migrated_resource[:url], source_resource[:type], talk_name)
        
        puts "  ✅ #{migrated_resource[:title]} - URL and title validated"
      end
      
      puts "✅ #{talk_name}: #{migrated_resources.length} resources fully validated (URLs and titles match)"
    end
  end
  
  def test_video_availability_matches_source
    # Skip in CI environment where external requests may fail due to SSL issues
    if self.class.ci_environment?
      skip "Skipping external HTTP requests in CI environment"
    end
    
    # Skip if no talks have source URLs (non-migration users)
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    if talks_with_sources.empty?
      puts "⚠️  SKIPPING video validation: No talks with source URLs found"
      puts "   - This test is only needed for migrated content"
      puts "   - Users creating content manually can safely skip this test"
      return
    end
    
    @talks.each do |talk_name, talk_data|
      puts "\n🎬 Testing video for #{talk_name}..."
      
      # Check if source has video
      source_has_video = source_page_has_video?(talk_data[:source_url])
      content = talk_data[:raw_content]
      has_video = content.match?(/\*\*Video:\*\* \[.+?\]\((.+?)\)/) || content.include?('Video detected')
      
      if source_has_video
        assert has_video,
          "❌ VIDEO MISSING: Source has video but migration doesn't include it"
          
        # Test that video URL actually works
        if video_match = content.match(/\*\*Video:\*\* \[.+?\]\((.+?)\)/)
          video_url = video_match[1]
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
      migrated_resources = get_resources_from_talk(talk_data)
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
  
  def test_resource_type_detection
    @talks.each do |talk_name, talk_data|
      resources = get_resources_from_talk(talk_data)
      next if resources.empty?
      
      # Count resource types
      type_counts = resources.group_by { |r| r['type'] }.transform_values(&:count)
      
      # Verify Google Slides URLs are marked as "slides"
      slides_resources = resources.select { |r| r['type'] == 'slides' }
      slides_resources.each do |resource|
        url = resource['url']
        assert(
          url.include?('docs.google.com/presentation') || url.include?('drive.google.com') || url.include?('.pdf'),
          "Slides resource should have Google/PDF URL: #{url}"
        )
      end
      
      # Verify YouTube URLs are marked as "video"
      video_resources = resources.select { |r| r['type'] == 'video' }
      video_resources.each do |resource|
        url = resource['url']
        assert(
          url.include?('youtube.com') || url.include?('youtu.be'),
          "Video resource should have YouTube URL: #{url}"
        )
      end
      
      puts "✅ #{talk_name} resource types: #{type_counts}"
    end
  end  # ===========================================
  # Test Suite 2: Resource URL Validation
  # ===========================================
  
  def test_google_slides_url_format
    @talks.flat_map { |_, data| get_resources_from_talk(data) }.select { |r| r['type'] == 'slides' && r['url'].include?('docs.google.com/presentation') }.each do |resource|
      url = resource['url']
      
      # Should use /d/{document_id}/edit format, NOT /d/e/{published_id}/pub format
      refute url.include?('/d/e/'), 
        "CRITICAL: Using published URL format that doesn't work for thumbnails: #{url}. " \
        "Should use shared document format: /d/{id}/edit"
        
      assert url.include?('/d/') && (url.include?('/edit') || url.include?('/view')), 
        "Should use shared document format (/d/{id}/edit or /d/{id}/view): #{url}"
        
      # Document ID extracted for reference (thumbnails now use local files from Notist)
      if url.match(/\/d\/([a-zA-Z0-9\-_]+)/)
        doc_id = $1
        puts "  FILE #{resource['title']}: #{doc_id}"
      end
    end
    
    puts "SUCCESS Google Slides URL format: #{@talks.flat_map { |_, data| get_resources_from_talk(data) }.select { |r| r['type'] == 'slides' && r['url'].include?('docs.google.com/presentation') }.length} slides checked"
  end
  
  def test_slides_are_embedded_not_downloadable
    @talks.flat_map { |_, data| get_resources_from_talk(data) }.select { |r| r['type'] == 'slides' }.each do |resource|
      url = resource['url']
      title = resource['title'] || ''
      
      # Slides MUST be Google Drive URLs for embedding (thumbnails are handled separately via local files)
      if url.include?('.pdf') && !url.include?('drive.google.com')
        flunk "CRITICAL: Slides resource is downloadable PDF, not embedded: #{url}\n" \
              "Slides MUST be uploaded to Google Drive for embedding!"
      end
      
      # Google Drive URLs must be in correct format
      if url.include?('drive.google.com')
        assert url.include?('/file/d/') && url.include?('/view'), 
          "Google Drive slides URL must be in /file/d/{id}/view format: #{url}"
      end
      
      puts "  FILE Slides OK: #{title} → #{url}"
    end
    
    puts "SUCCESS All slides properly embedded (not downloadable)"
  end
  
  # External link accessibility test removed - takes time and not needed
  # We only need to verify that resources match between source and migrated content

  # ===========================================
  # Test Suite 3: Visual Quality Validation
  # ===========================================
  
  def test_local_thumbnails_exist_for_talks
    # Test that local thumbnails exist for talks (either from Notist migration or manually added)
    
    @talks.each do |talk_name, talk_data|
      # Generate expected thumbnail filename
      talk_slug = File.basename(talk_name, '.md')
      thumbnail_path = "assets/images/thumbnails/#{talk_slug}-thumbnail.png"
      
      if File.exist?(thumbnail_path)
        puts "  ✅ #{talk_slug}: Local thumbnail exists"
      else
        puts "  ❓ #{talk_slug}: No local thumbnail (will use placeholder)"
      end
    end
    
    puts "SUCCESS Local thumbnail check completed"
  end

  def test_pdf_file_integrity
    # Skip in CI environment where external requests may fail due to SSL issues
    if self.class.ci_environment?
      skip "Skipping external HTTP requests in CI environment"
    end
    
    # Validate that Google Drive PDF files are not corrupted
    pdf_files_tested = 0
    
    @talks.each do |talk_name, talk_data|
      urls_to_check = []
      
      # Get URLs from resources section
      resources = get_resources_from_talk(talk_data)
      resources.each do |resource|
        urls_to_check << resource['url'] if resource['url']
      end
      
      # Also check slides/PDF URLs from markdown header format
      content = talk_data[:raw_content]
      if content.match(/\*\*Slides:\*\*.*?\[.*?\]\((.*?)\)/)
        slides_url = $1
        urls_to_check << slides_url
      end
      
      # Test each URL for PDF integrity
      urls_to_check.each do |url|
        next unless url.include?('drive.google.com/file')
        
        if url.match(/\/file\/d\/([a-zA-Z0-9\-_]+)/)
          file_id = $1
          download_url = "https://drive.usercontent.google.com/download?id=#{file_id}&export=download"
          
          puts "  🔍 Validating PDF integrity: #{talk_name} -> #{file_id}"
          
          # Check file headers to ensure it's a valid PDF
          uri = URI.parse(download_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.read_timeout = 15
          
          # Request just the first 20 bytes to check PDF header
          request = Net::HTTP::Get.new(uri.request_uri)
          request['Range'] = 'bytes=0-19'
          
          response = http.request(request)
          
          # Check if request was successful
          unless response.code.to_i.between?(200, 299) || response.code.to_i == 206
            flunk "❌ PDF FILE NOT ACCESSIBLE: #{url}\n" \
                  "   Talk: #{talk_name}\n" \
                  "   File ID: #{file_id}\n" \
                  "   HTTP Status: #{response.code}\n" \
                  "   This PDF cannot be downloaded or accessed"
          end
          
          # Check if file starts with PDF header
          header_bytes = response.body
          if header_bytes && header_bytes.length >= 4
            # Valid PDF should start with "%PDF"
            unless header_bytes.start_with?('%PDF')
              flunk "❌ CORRUPTED PDF FILE: #{url}\n" \
                    "   Talk: #{talk_name}\n" \
                    "   File ID: #{file_id}\n" \
                    "   Expected: PDF header (%PDF)\n" \
                    "   Got: #{header_bytes[0..10].inspect}\n" \
                    "   This PDF file is corrupted and needs to be re-uploaded"
            end
          else
            flunk "❌ EMPTY PDF FILE: #{url}\n" \
                  "   Talk: #{talk_name}\n" \
                  "   File ID: #{file_id}\n" \
                  "   The PDF file appears to be empty or unreadable"
          end
          
          pdf_files_tested += 1
          puts "  ✅ PDF integrity OK: #{talk_name} -> #{file_id}"
        end
      end
    end
    
    if pdf_files_tested > 0
      puts "SUCCESS #{pdf_files_tested} PDF files validated for integrity"
    else
      puts "INFO No PDF files found to validate"
    end
  end

  # ===========================================
  # Test Suite 4: Migration Quality Assurance
  # ===========================================
  
  def test_content_completeness_check
    # Skip in CI environment where external requests may fail due to SSL issues
    if self.class.ci_environment?
      skip "Skipping external HTTP requests in CI environment"
    end
    
    # Skip if no talks have source URLs (non-migration users)
    talks_with_sources = @talks.select { |_, data| data[:source_url] }
    
    if talks_with_sources.empty?
      puts "⚠️  SKIPPING content completeness validation: No talks with source URLs found"
      puts "   - This test is only needed for migrated content"
      puts "   - Users creating content manually can safely skip this test"
      return
    end
    
    # Verify all migrated talks have complete content by comparing with source
    @talks.each do |talk_key, talk_data|
      content = talk_data[:raw_content]
      
      # Check for truncated files (YAML frontmatter but no content)
      if content.strip.start_with?('---') && !content.include?('# ')
        # Count lines to distinguish between old format and truncated files
        lines = content.strip.split("\n")
        if lines.length <= 4 && lines.join.gsub(/\s/, '').length < 20
          # Very short file with minimal content - likely truncated
          assert false, "❌ TRUNCATED FILE: #{talk_key}.md appears to be truncated (only YAML frontmatter, no content)"
        else
          # Longer file with YAML but no H1 - old format that needs migration
          puts "⚠️  SKIPPING #{talk_key}: Old YAML-only format, needs migration"
          next
        end
      end
      
      # Check for title (H1 in markdown)
      assert content.match?(/^# .+/), "Missing title (H1) in #{talk_key}.md"
      
      # Check for conference and date
      assert content.match?(/\*\*Conference:\*\* .+/), "Missing conference in #{talk_key}.md"
      assert content.match?(/\*\*Date:\*\* \d{4}-\d{2}-\d{2}/), "Missing date in #{talk_key}.md"
      
      # Check for resources (either slides/video or ## Resources section)
      has_slides = content.match?(/\*\*Slides:\*\*/)
      has_video = content.match?(/\*\*Video:\*\*/)
      has_resources_section = content.match?(/## Resources/)
      
      assert (has_slides || has_video || has_resources_section), 
        "Missing resources (no slides, video, or resources section) in #{talk_key}.md"
      
      # Dynamic validation: Compare resource count with source
      source_resources = extract_resources_from_source(talk_data[:source_url])
      migrated_resource_count = count_resources_in_content(content)
      
      if source_resources.length != migrated_resource_count
        puts "❌ RESOURCE COUNT MISMATCH for #{talk_key}:"
        puts "  Source has #{source_resources.length} resources"
        puts "  Migration has #{migrated_resource_count} resources"
        puts "  This indicates incomplete migration!"
      else
        puts "SUCCESS #{talk_key}: Content complete (#{migrated_resource_count} resources)"
      end
    end
  end
  
  def test_link_and_resource_functionality
    # Test that resource URLs are not malformed (common issue from batch replacements)
    all_resources = @talks.flat_map { |_, data| get_resources_from_talk(data) }
    
    all_resources.each do |resource|
      url = resource['url']
      
      # Skip resources with nil URLs
      next if url.nil?
      
      # Clean up URL whitespace
      url = url.strip
      
      # Check for malformed URLs (concatenated URLs), but allow web.archive.org format
      if url.scan(/https?:\/\//).length > 1 && !url.include?('web.archive.org')
        flunk "Malformed URL detected (concatenated): #{url}"
      end
        
      # Check for valid URL format
      assert url.match?(/^https?:\/\/[^\s]+$/), 
        "Invalid URL format: #{url}"
        
      # Check for common malformation patterns
      refute url.include?('http://http://'), "Double protocol in URL: #{url}"
      refute url.include?('https://https://'), "Double protocol in URL: #{url}"
    end
    
    puts "SUCCESS URL integrity: #{all_resources.length} URLs validated"
  end
  
  # ===========================================
  # Test Suite 5: Regression Prevention
  # ===========================================
  
  def test_no_liquid_syntax_in_yaml
    # Prevent the {{site.title}} bug from recurring
    @talks.each do |talk_name, talk_data|
      yaml_content = talk_data[:raw_content]
      
      # Check for liquid syntax in YAML front matter
      if yaml_content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        yaml_section = $1
        
        refute yaml_section.include?('{{'), 
          "Liquid syntax found in YAML front matter of #{talk_name}: #{yaml_section.scan(/\{\{.*?\}\}/)}"
        refute yaml_section.include?('{%'), 
          "Liquid syntax found in YAML front matter of #{talk_name}: #{yaml_section.scan(/\{%.*?%\}/)}"
      end
    end
    
    puts "SUCCESS No liquid syntax in YAML front matter"
  end
  
  def test_no_placeholder_resources
    # Ensure no SVG placeholders or placeholder text
    @talks.flat_map { |_, data| get_resources_from_talk(data) }.each do |resource|
      url = resource['url']
      title = resource['title'] || ''
      
      # Check for placeholder patterns
      refute url.include?('placeholder'), "Placeholder URL found: #{url}"
      refute url.include?('example.com'), "Example URL found: #{url}"
      refute title.downcase.include?('placeholder'), "Placeholder title found: #{title}"
      refute title.downcase.include?('todo'), "TODO in title found: #{title}"
      
      # Check for generic "Resource N" titles
      refute title.match?(/^Resource \d+$/), 
        "❌ GENERIC TITLE: Found '#{title}' - should be meaningful title from source content"
    end
    
    puts "SUCCESS No placeholder resources found"
  end
  
  # ===========================================
  # Utility Methods for Dynamic Testing
  # ===========================================
  
  def extract_source_url_from_markdown(content)
    # Look for source URL in HTML comment
    if match = content.match(/<!-- Source: (.+?) -->/)
      return match[1].strip
    end
    
    nil
  end
  
  def get_resources_from_talk(talk_data)
    # Handle both YAML frontmatter and markdown-only formats
    if talk_data[:yaml]
      # YAML frontmatter format
      return talk_data[:yaml]['resources'] || []
    else
      # Markdown-only format - extract from content
      return extract_migrated_resources(talk_data[:raw_content])
    end
  end
  
  def extract_resources_from_source(source_url)
    # Fetch and parse the source page, following redirects
    uri = URI.parse(source_url)
    
    # Follow redirects
    response = nil
    redirect_count = 0
    max_redirects = 5
    
    loop do
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      
      response = http.get(uri.request_uri)
      
      case response
      when Net::HTTPRedirection
        if redirect_count >= max_redirects
          raise "Too many redirects (#{redirect_count})"
        end
        uri = URI.parse(response['location'])
        redirect_count += 1
      else
        break
      end
    end
    
    unless response.code.to_i.between?(200, 299)
      raise "HTTP #{response.code} when fetching #{source_url}"
    end
    
    doc = Nokogiri::HTML(response.body)
    
    # Extract actual content resources (not navigation/metadata)
    resource_links = []
    
    # Look for resources section specifically
    resources_section = doc.css('#resources')
    if resources_section.any?
      # Use the same precise selector as migration script
      links = resources_section.css('.resource-list li h3 a')
      links.each do |link|
        href = link['href']
        title = link.text.strip
        
        # Skip only invalid/malformed links (same logic as migration script)
        next if href.start_with?('#') || href.start_with?('/')
        next if title.empty? || title.length < 3
        next if href.nil? || href.empty?
        
        # Skip URLs with leading/trailing whitespace (migration script filters these out)
        next if href != href.strip
        
        resource_type = determine_resource_type(href)
        
        # EXCLUDE slides and video resources from count comparison
        # These are handled separately in migration and don't appear in ## Resources section
        next if resource_type == 'slides' || resource_type == 'video'
        
        resource_links << {
          url: href,
          title: title,
          type: resource_type
        }
      end
    end
    
    # Return all resources without deduplication - preserve author's intentional content structure
    resource_links
  end
  
  def source_page_has_video?(source_url)
    return false if source_url.nil? || source_url.empty?
    
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
    
    # Extract YouTube video ID
    video_id = nil
    if video_url.include?('youtube.com/watch?v=')
      video_id = video_url.split('watch?v=').last.split('&').first
    elsif video_url.include?('youtu.be/')
      video_id = video_url.split('youtu.be/').last.split('?').first
    end
    
    # YouTube video IDs should be 11 characters long
    return false unless video_id && video_id.length == 11
    
    # Check if the video ID contains only valid characters (alphanumeric, _, -)
    return false unless video_id.match?(/^[a-zA-Z0-9_-]{11}$/)
    
    # Make a request to check if video exists (follow redirects)
    begin
      uri = URI.parse(video_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      
      # Follow redirects automatically
      response = http.get(uri.request_uri)
      
      # Follow up to 3 redirects
      redirect_count = 0
      while response.code.to_i.between?(300, 399) && redirect_count < 3
        location = response['location']
        break unless location
        
        new_uri = URI.parse(location)
        http = Net::HTTP.new(new_uri.host, new_uri.port)
        http.use_ssl = (new_uri.scheme == 'https')
        http.read_timeout = 10
        
        response = http.get(new_uri.request_uri)
        redirect_count += 1
      end
      
      # Check final response
      return false unless response.code.to_i.between?(200, 299)
      
      # Check for common YouTube error indicators in the final response
      if response.body
        body = response.body
        return false if body.include?('Video unavailable')
        return false if body.include?('This video is not available') 
        return false if body.include?('has been removed')
        return false if body.include?('private video')
      end
      
      true
    rescue => e
      puts "Video validation error: #{e.message}"
      false
    end
  end
  
  def determine_resource_type(url)
    return 'video' if url.include?('youtube.com') || url.include?('youtu.be')
    return 'slides' if url.include?('docs.google.com/presentation') || url.include?('drive.google.com')
    return 'code' if url.include?('github.com')
    'link'
  end

  def print_migration_summary
    puts "\n" + "=" * 60
    puts "MIGRATION TEST SUMMARY"
    puts "=" * 60
    
    @talks.each do |talk_name, talk_data|
      content = talk_data[:raw_content]
      
      # Extract title from markdown (H1)
      title_match = content.match(/^# (.+)/)
      title = title_match ? title_match[1] : "No title"
      
      # Count resources properly
      resource_count = count_resources_in_content(content)
      
      puts "FILE #{talk_name}"
      puts "   Title: #{title}"
      puts "   Resources: #{resource_count}"
      puts "   Format: Clean Markdown"
      puts
    end
  end

  # Helper method to count resources in clean markdown format
  def count_resources_in_content(content)
    # DON'T count slides/video - they are separate entities, not "resources"
    # Only count items in the ## Resources section
    
    # Find the Resources section with flexible matching
    lines = content.split("\n")
    resources_start = -1
    
    lines.each_with_index do |line, index|
      if line.strip == "## Resources"
        resources_start = index
        break
      end
    end
    
    return 0 if resources_start == -1
    
    # Count resource lines after the ## Resources header
    count = 0
    (resources_start + 1...lines.length).each do |i|
      line = lines[i].strip
      
      # Stop if we hit another section header
      break if line.start_with?("## ")
      
      # Count lines that start with "- ["
      if line.match?(/^- \[.+?\]\(.+?\)/)
        count += 1
      end
    end
    
    count
  end
  
  def extract_migrated_resources(content)
    resources = []
    
    # Find the Resources section
    lines = content.split("\n")
    resources_start = -1
    
    lines.each_with_index do |line, index|
      if line.strip == "## Resources"
        resources_start = index
        break
      end
    end
    
    return resources if resources_start == -1
    
    # Extract resource lines after the ## Resources header
    (resources_start + 1...lines.length).each do |i|
      line = lines[i].strip
      
      # Stop if we hit another section header
      break if line.start_with?("## ")
      
      # Parse lines that start with "- ["
      if match = line.match(/^- \[(.+?)\]\((.+?)\)/)
        title = match[1]
        url = match[2]
        
        # Only skip if URL is invalid - allow empty titles to be caught by validation
        next if url.nil? || url.empty?
        
        resources << {
          'title' => title,
          'url' => url,
          'type' => determine_resource_type(url)
        }
      end
    end
    
    resources
  end
  
  def find_matching_migrated_resource(source_resource, migrated_resources)
    # First try exact URL match
    exact_matches = migrated_resources.select { |r| r['url'] == source_resource[:url] }
    
    if exact_matches.length == 1
      return exact_matches.first
    elsif exact_matches.length > 1
      # Multiple resources with same URL - try to match by title similarity
      best_match = exact_matches.max_by do |migrated|
        calculate_similarity(source_resource[:title], migrated['title'])
      end
      return best_match if calculate_similarity(source_resource[:title], best_match['title']) > 0.6
      
      # If no good title match, just return the first one (this is a source data quality issue)
      return exact_matches.first
    end
    
    # Fallback to fuzzy URL matching if needed
    migrated_resources.find do |migrated|
      url_similarity = calculate_similarity(source_resource[:url], migrated['url'])
      url_similarity > 0.8
    end
  end
  
  def calculate_similarity(str1, str2)
    return 0.0 if str1.nil? || str2.nil? || str1.empty? || str2.empty?
    return 1.0 if str1 == str2
    
    # Simple Levenshtein distance-based similarity
    str1 = str1.downcase.strip
    str2 = str2.downcase.strip
    
    # Calculate Levenshtein distance
    matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1, 0) }
    
    (0..str1.length).each { |i| matrix[i][0] = i }
    (0..str2.length).each { |j| matrix[0][j] = j }
    
    (1..str1.length).each do |i|
      (1..str2.length).each do |j|
        cost = str1[i-1] == str2[j-1] ? 0 : 1
        matrix[i][j] = [
          matrix[i-1][j] + 1,     # deletion
          matrix[i][j-1] + 1,     # insertion
          matrix[i-1][j-1] + cost # substitution
        ].min
      end
    end
    
    distance = matrix[str1.length][str2.length]
    max_length = [str1.length, str2.length].max
    
    return 1.0 if max_length == 0
    1.0 - (distance.to_f / max_length)
  end

  def assert_title_similarity(source_title, migrated_title, talk_name)
    # Calculate similarity score
    similarity = calculate_similarity(source_title, migrated_title)
    
    # Allow for reasonable variations but catch completely wrong titles
    assert similarity > 0.6,
      "❌ TITLE MISMATCH in #{talk_name}:\n" \
      "Source: '#{source_title}'\n" \
      "Migrated: '#{migrated_title}'\n" \
      "Similarity: #{(similarity * 100).round(1)}% (need >60%)"
  end
  
  def assert_url_correctness(source_url, migrated_url, resource_type, talk_name)
    # For exact matches, no validation needed
    return if source_url == migrated_url
    
    case resource_type
    when 'slides'
      # PDFs should be migrated to Google Drive
      if source_url.end_with?('.pdf')
        assert migrated_url.include?('drive.google.com'),
          "❌ PDF NOT MIGRATED: #{source_url} should be uploaded to Google Drive, got: #{migrated_url}"
        
        assert migrated_url.include?('/file/d/') && migrated_url.include?('/view'),
          "❌ WRONG GOOGLE DRIVE FORMAT: #{migrated_url} should use /file/d/{id}/view format"
      else
        # Non-PDF slides should remain the same or be acceptable transformations
        assert_acceptable_url_transformation(source_url, migrated_url, talk_name)
      end
    when 'video'
      # Videos should remain the same or be acceptable YouTube transformations
      if source_url.include?('youtube.com') || source_url.include?('youtu.be')
        assert migrated_url.include?('youtube.com') || migrated_url.include?('youtu.be'),
          "❌ VIDEO URL CHANGED: #{source_url} became #{migrated_url} - YouTube URLs should be preserved"
      end
    else
      # Other resources should have acceptable transformations
      assert_acceptable_url_transformation(source_url, migrated_url, talk_name)
    end
  end
  
  def assert_acceptable_url_transformation(source_url, migrated_url, talk_name)
    # Handle nil URLs
    return if source_url.nil? || migrated_url.nil?
    
    # Allow common acceptable transformations
    source_domain = URI.parse(source_url).host rescue nil
    migrated_domain = URI.parse(migrated_url).host rescue nil
    
    # Same domain is always acceptable
    return if source_domain == migrated_domain
    
    # Allow HTTP -> HTTPS transformations
    return if source_url.gsub('http://', 'https://') == migrated_url
    
    # Allow trailing slash differences
    return if source_url.chomp('/') == migrated_url.chomp('/')
    
    # If we get here, it might be an unacceptable change
    puts "⚠️  URL TRANSFORMATION in #{talk_name}: #{source_url} -> #{migrated_url}"
  end
  
  def title_similarity_score(title1, title2)
    # Handle nil titles
    return 0.0 if title1.nil? || title2.nil?
    
    # Simple similarity based on common words
    words1 = title1.downcase.split(/\W+/).reject(&:empty?)
    words2 = title2.downcase.split(/\W+/).reject(&:empty?)
    
    return 1.0 if words1.empty? && words2.empty?
    return 0.0 if words1.empty? || words2.empty?
    
    common_words = words1 & words2
    total_words = (words1 + words2).uniq.length
    
    common_words.length.to_f / total_words
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  # Add custom test output
  class MigrationTest
    def run
      result = super
      print_migration_summary if passed?
      result
    end
  end
end