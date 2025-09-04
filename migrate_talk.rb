#!/usr/bin/env ruby
# frozen_string_literal: true

# Disable frozen string literal warnings that flood output from liquid 4.0.4
ENV['RUBYOPT'] = '--disable-frozen-string-literal'

# Suppress deprecation warnings from legacy gems like liquid 4.0.4
$VERBOSE = nil

require 'net/http'
require 'uri'
require 'nokogiri'
require 'yaml'
require 'json'
require 'date'
require 'google/apis/drive_v3'
require 'googleauth'
require 'optparse'

class TalkMigrator
  
  def initialize(talk_url, skip_tests: false)
    @talk_url = talk_url
    @talk_data = {}
    @resources = []
    @errors = []
    @skip_tests = skip_tests
  end
  
  def migrate
    puts "STARTING DETERMINISTIC TALK MIGRATION"
    puts "=" * 50
    puts "URL: #{@talk_url}"
    
    # Step 0: Check if talk already exists (source of truth: source URL)
    if talk_already_exists?
      puts "✅ SKIPPING: Talk already exists with this source URL"
      puts "   - Found existing talk with source: #{@talk_url}"
      puts "   - Migration not needed (source URL is source of truth)"
      return true
    end
    
    # Step 1: Fetch and parse talk page
    unless fetch_talk_page
      report_failure("Failed to fetch talk page")
      return false
    end
    
    # Step 2: Extract all metadata
    unless extract_metadata
      report_failure("Failed to extract metadata")
      return false
    end
    
    # Step 3: Extract ALL resources (MUST be complete)
    unless extract_all_resources
      report_failure("Failed to extract complete resources")
      return false
    end
    
    # Step 4: Download and upload PDF if exists
    unless handle_pdf
      report_failure("Failed to handle PDF")
      return false
    end
    
    # Step 5: Find video URL if exists
    unless find_video
      report_failure("Failed to find video")
      return false
    end
    
    # Step 6: Generate Jekyll file
    unless generate_jekyll_file
      report_failure("Failed to generate Jekyll file")
      return false
    end

    # Step 6.5: Validate resource sources (no Notist dependencies)
    unless validate_resource_sources
      report_failure("Resource source validation failed")
      return false
    end

    # Step 7: Validate migration
    unless validate_migration
      report_failure("Migration validation failed")
      return false
    end

    # Step 8: Rebuild Jekyll site (always do this after successful file generation)
    jekyll_success = rebuild_jekyll_site
    unless jekyll_success
      puts "⚠️  Jekyll rebuild failed, but migration file was created"
      puts "   You may need to rebuild manually with: bundle exec jekyll build"
      puts "   The talk file was created correctly at: #{@jekyll_file}"
      # Don't return false here - the migration technically succeeded
    end
    
    # Step 9: Run migration tests (unless skipped for batch processing)
    unless @skip_tests
      test_success = run_migration_tests
      unless test_success
        puts "❌ Migration tests FAILED"
        puts "   This indicates the migration may be incomplete"
        puts "   Check test output above for specific issues"
        puts "⚠️  Migration tests failed, but file was created and site rebuilt"
        puts "   This may indicate incomplete migration that needs manual review"
        return false
      end
    else
      puts "⏭️  Skipping individual migration tests (batch mode)"
    end
    
    # Step 10: Run site integration tests
    integration_success = run_site_integration_tests
    unless integration_success
      puts "⚠️  Site integration tests failed, but migration is technically complete"
      puts "   Check site integration test output for issues"
      puts "   The talk file was created correctly and site was rebuilt"
      # Don't return false here - the migration succeeded, just integration tests failed
    end

    puts "\n✅ MIGRATION SUCCESSFUL!"
    puts "Generated: #{@jekyll_file}"
    
    # Calculate resource breakdown
    slides_count = @resources.count { |r| r['type'] == 'slides' }
    video_count = @resources.count { |r| r['type'] == 'video' }
    other_count = @resources.count { |r| r['type'] != 'slides' && r['type'] != 'video' }
    
    puts "Resources: #{@resources.length} total extracted (#{other_count} in resources section + #{slides_count + video_count} moved to header)"
    puts "🎬 Video: #{@talk_data[:video_url] || 'None'}"
    puts "📄 PDF: #{@talk_data[:pdf_url] || 'None'}"
    puts "Next: Review generated file and commit to repository"
    true
  end
  
  private
  
  def talk_already_exists?
    # Normalize the talk URL for comparison (remove protocol differences)
    normalized_talk_url = normalize_url(@talk_url)
    
    # Check if any existing talk files have this source URL
    Dir.glob('_talks/*.md').each do |file|
      content = File.read(file)
      
      # Check for source URL in HTML comment (new format)
      if content.match(/<!-- Source: (.+?) -->/)
        existing_source_url = $1.strip
        normalized_existing_url = normalize_url(existing_source_url)
        return true if normalized_existing_url == normalized_talk_url
      end
      
      # Check legacy YAML frontmatter format for backward compatibility
      if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
        begin
          yaml_content = YAML.safe_load($1, permitted_classes: [Date])
          existing_source_url = yaml_content['source_url'] || yaml_content['notist_url']
          if existing_source_url
            normalized_existing_url = normalize_url(existing_source_url)
            return true if normalized_existing_url == normalized_talk_url
          end
        rescue => e
          # Continue if YAML parsing fails
        end
      end
    end
    
    false
  end
  
  def normalize_url(url)
    # Normalize URL for comparison: remove protocol difference, trailing slashes, etc.
    return url unless url
    
    normalized = url.strip
    # Convert https to http for consistent comparison
    normalized = normalized.sub(/^https:\/\//, 'http://')
    # Remove trailing slash
    normalized = normalized.chomp('/')
    
    normalized
  end
  
  def fetch_talk_page
    puts "\n1️⃣ Fetching talk page..."
    
    uri = URI.parse(@talk_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.path)
    
    # Handle redirects (HTTP 301, 302, 303, 307, 308)
    if [301, 302, 303, 307, 308].include?(response.code.to_i)
      location = response['location']
      if location
        puts "🔄 Following redirect to: #{location}"
        @talk_url = location
        return fetch_talk_page  # Recursive call with new URL
      else
        @errors << "HTTP #{response.code} redirect without location header"
        return false
      end
    end
    
    unless response.code.to_i.between?(200, 299)
      @errors << "HTTP #{response.code} when fetching #{@talk_url}"
      return false
    end
    
    begin
      @doc = Nokogiri::HTML(response.body)
      puts "SUCCESS Page fetched successfully"
      return true
    rescue => e
      @errors << "Failed to parse HTML: #{e.message}"
      return false
    end
  end
  
  def fetch_page(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.path)
    
    unless response.code.to_i.between?(200, 299)
      puts "⚠️  HTTP #{response.code} when fetching #{url}"
      return nil
    end
    
    Nokogiri::HTML(response.body)
  rescue => e
    puts "⚠️  Error fetching #{url}: #{e.message}"
    nil
  end
  
  def extract_metadata
    puts "\n2️⃣ Extracting metadata..."
    
    # Title (REQUIRED) - Use precise selector for Notist pages
    title_elem = @doc.css('.presentation-header h1 a').first
    unless title_elem
      @errors << "No title found (missing .presentation-header h1 a element)"
      return false
    end
    @talk_data[:title] = title_elem.text.strip
    
    # Date and Conference - Use precise datetime attribute and subhead structure
    # First extract from time[datetime] element which is most reliable
    time_elem = @doc.css('time[datetime]').first
    if time_elem && time_elem['datetime']
      begin
        @talk_data[:date] = Date.parse(time_elem['datetime']).strftime("%Y-%m-%d")
        puts "SUCCESS Date extracted from datetime attribute: #{@talk_data[:date]}"
      rescue => e
        puts "❌ Failed to parse datetime attribute: #{e.message}"
      end
    end
    
    # Extract conference from subhead structure
    subhead = @doc.css('.presentation-header .subhead').first
    if subhead
      # Look for "A presentation at [Conference Name]" pattern
      conf_link = subhead.css('a').first
      if conf_link && conf_link.text.strip.length > 0
        @talk_data[:conference] = conf_link.text.strip
        puts "SUCCESS Conference extracted from subhead: #{@talk_data[:conference]}"
      end
    end
    
    # Fallback to JSON-LD if direct extraction didn't work
    unless @talk_data[:date] && @talk_data[:conference]
      json_ld_scripts = @doc.css('script[type="application/ld+json"]')
      json_ld_scripts.each do |script|
        begin
          json_data = JSON.parse(script.content)
          if json_data['datePublished'] && !@talk_data[:date]
            @talk_data[:date] = Date.parse(json_data['datePublished']).strftime("%Y-%m-%d")
            puts "SUCCESS Date extracted from JSON-LD: #{@talk_data[:date]}"
          end
          if json_data.dig('publication', 'name') && !@talk_data[:conference]
            @talk_data[:conference] = json_data['publication']['name']
            puts "SUCCESS Conference extracted from JSON-LD: #{@talk_data[:conference]}"
          end
        rescue JSON::ParserError => e
          puts "❌ JSON-LD parsing failed: #{e.message}"
        end
      end
    end
    
    
    # Fallback to text parsing if structured extraction didn't work
    unless @talk_data[:date]
      @errors << "No date found in page"
      return false
    end
    
    unless @talk_data[:conference]
      @errors << "No conference found in page"
      return false
    end
    
    # Extract speakers (look for author/speaker information)
    # This is a simplification - may need refinement
    @talk_data[:speaker] = extract_speakers_from_url
    
    # Extract location from subhead or other sources
    extract_location_from_page
    
    # Extract abstract/description using precise selector
    desc_section = @doc.css('#desc .presentation-description')
    if desc_section.any?
      # Get all paragraph text from the description section
      description_parts = desc_section.css('p').map { |p| p.text.strip }.reject(&:empty?)
      @talk_data[:abstract] = description_parts.join("\n\n")
      puts "SUCCESS Description extracted from #desc section (#{@talk_data[:abstract].length} chars)"
    else
      # Try the main #desc element directly as mentioned by user
      desc_element = @doc.css('#desc')
      if desc_element.any?
        # Get text content directly from #desc, excluding child elements we don't want
        desc_text = desc_element.first.text.strip
        # Try to extract meaningful content (longer than presentation context)
        if desc_text.length > 200  # Longer than typical presentation context
          @talk_data[:abstract] = desc_text
          puts "SUCCESS Description extracted from #desc element directly (#{@talk_data[:abstract].length} chars)"
        else
          # Fallback to finding long paragraphs
          abstract_elem = @doc.css('p').find { |p| p.text.length > 100 }
          @talk_data[:abstract] = abstract_elem ? abstract_elem.text.strip : ""
          puts "SUCCESS Description extracted from fallback method"
        end
      else
        # Fallback to finding long paragraphs
        abstract_elem = @doc.css('p').find { |p| p.text.length > 100 }
        @talk_data[:abstract] = abstract_elem ? abstract_elem.text.strip : ""
        puts "SUCCESS Description extracted from fallback method"
      end
    end
    
    puts "SUCCESS Metadata extracted:"
    puts "   Title: #{@talk_data[:title]}"
    puts "   Date: #{@talk_data[:date]}"
    puts "   Conference: #{@talk_data[:conference]}"
    puts "   Speaker: #{@talk_data[:speaker]}"
    
    true
  end
  
  def extract_all_resources
    puts "\n3️⃣ Extracting ALL resources..."
    
    # Use precise selector for Notist resources section
    resources_section = @doc.css('#resources .resource-list')
    
    if resources_section.empty?
      puts "⚠️  No resources section found - talk has no additional resources"
      @resources = []
      return true
    end
    
    # Extract resources from the structured list - use precise selector
    resource_links = []
    
    resources_section.css('li h3 a').each do |link|
      url = link['href']
      title = link.text.strip
      
      if url && url.start_with?('http')
        resource_links << {
          'url' => url,
          'title' => title,
          'type' => determine_resource_type(url),
          'description' => ""
        }
      end
    end
    
    if resource_links.empty?
      puts "⚠️  No valid resources found in resources section - talk has no additional resources"
      @resources = []
      return true
    end
    
    @resources = resource_links
    
    puts "SUCCESS Found #{@resources.length} resources"
    @resources.each_with_index do |res, i|
      puts "   #{i+1}. #{res['type']}: #{res['url']}"
    end
    
    true
  end
  
  def handle_pdf
    puts "\n4️⃣ Handling PDF..."
    
    # First check if slides exist but aren't downloadable
    if slides_exist_but_not_downloadable?
      @errors << "❌ SLIDES EXIST BUT NOT DOWNLOADABLE: Slides are embedded but download is not enabled on Notist"
      @errors << "   📝 ACTION REQUIRED: Go to #{@talk_url} and enable 'Allow download' in slide settings"
      @errors << "   🔧 This prevents incomplete migrations - fix the source and re-run migration"
      return false
    end
    
    # Look for PDF links in the page or resources
    pdf_urls = find_pdf_urls
    
    if pdf_urls.empty?
      puts "⚠️  No PDF found"
      return true
    end
    
    pdf_url = pdf_urls.first
    puts "FILE Found PDF: #{pdf_url}"
    
    # Download PDF
    pdf_filename = generate_pdf_filename
    local_pdf_path = "pdfs/#{pdf_filename}"
    
    unless download_file(pdf_url, local_pdf_path)
      @errors << "Failed to download PDF from #{pdf_url}"
      return false
    end
    
    # Upload to Google Drive (REQUIRED - migration fails if this fails)
    upload_result = upload_to_google_drive(local_pdf_path)
    unless upload_result
      @errors << "Failed to upload PDF to Google Drive"
      return false
    end
    
    drive_url = upload_result[:url]
    drive_file_id = upload_result[:file_id]
    
    # Add PDF as slides resource with Google Drive URL
    pdf_resource = {
      'type' => 'slides',
      'title' => extract_pdf_title,
      'url' => drive_url,
      'description' => "Complete slide deck (PDF)"
    }
    @talk_data[:pdf_url] = drive_url
    
    @resources.unshift(pdf_resource) # Add at beginning
    
    # Download thumbnail for local hosting using Notist slide deck image
    thumbnail_result = download_thumbnail_for_slides()
    unless thumbnail_result
      puts "❌ ABORTING: Thumbnail download failed - cannot proceed"
      return false
    end
    
    puts "SUCCESS PDF processed and uploaded"
    true
  end
  
  def find_video
    puts "\n5️⃣ Finding video..."
    
    # Use precise selector for Notist video section
    video_iframe = @doc.css('#video iframe[src*="notist.ninja"]').first
    if video_iframe
      notist_video_url = video_iframe['src']
      puts "📹 Found Notist embedded video: #{notist_video_url}"
      
      # Extract the actual YouTube/Vimeo URL from the Notist embed
      actual_video_url = extract_actual_video_url(notist_video_url)
      if actual_video_url
        puts "SUCCESS Extracted actual video URL: #{actual_video_url}"
        
        # Add video resource with actual video URL
        video_resource = {
          'type' => 'video',
          'title' => 'Presentation Video',
          'url' => actual_video_url,
          'description' => 'Video recording of the talk'
        }
        @resources << video_resource
        @talk_data[:video_url] = actual_video_url
        @talk_data[:status] = "completed"
        
        puts "SUCCESS Video found and added to resources"
        return true
      else
        puts "⚠️  Could not extract actual video URL from Notist embed, using Notist URL"
        # Fallback to Notist URL
        video_resource = {
          'type' => 'video',
          'title' => 'Presentation Video',
          'url' => notist_video_url,
          'description' => 'Video recording of the talk'
        }
        @resources << video_resource
        @talk_data[:video_url] = notist_video_url
        @talk_data[:status] = "completed"
        
        puts "SUCCESS Video found and added to resources"
        return true
      end
    end
    
    # Fallback: Look for YouTube URLs (direct links and embeds)
    youtube_patterns = [
      /https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/,
      /https?:\/\/youtu\.be\/([a-zA-Z0-9_-]+)/,
      /https?:\/\/(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)/
    ]
    
    page_text = @doc.to_s
    
    # Check for direct YouTube URLs
    youtube_patterns.each do |pattern|
      match = page_text.match(pattern)
      if match
        video_id = match[1]
        # Convert all YouTube URLs to standard watch format
        video_url = "https://www.youtube.com/watch?v=#{video_id}"
        @talk_data[:video_url] = video_url
        @talk_data[:status] = "completed"
        
        # Add video resource
        video_resource = {
          'type' => 'video',
          'title' => 'Full Presentation Video',
          'url' => video_url,
          'description' => 'Complete video recording'
        }
        
        # Add after slides but before other resources
        slides_index = @resources.find_index { |r| r['type'] == 'slides' }
        insert_index = slides_index ? slides_index + 1 : 0
        @resources.insert(insert_index, video_resource)
        
        puts "SUCCESS Video found: #{video_url}"
        return true
      end
    end
    
    # Look for Notist video embeds
    notist_embed_pattern = /https?:\/\/notist\.ninja\/embed\/([a-zA-Z0-9_-]+)/
    notist_match = page_text.match(notist_embed_pattern)
    if notist_match
      embed_url = notist_match[0]
      embed_id = notist_match[1]
      
      # Try to resolve the actual video URL from the embed
      begin
        embed_doc = fetch_page(embed_url)
        if embed_doc
          embed_text = embed_doc.to_s
          # Look for YouTube URL in the embed page
          youtube_patterns.each do |pattern|
            match = embed_text.match(pattern)
            if match
              video_id = match[1]
              # Convert to standard watch format
              video_url = "https://www.youtube.com/watch?v=#{video_id}"
              @talk_data[:video_url] = video_url
              @talk_data[:status] = "completed"
              
              # Add video resource
              video_resource = {
                'type' => 'video',
                'title' => 'Full Presentation Video',
                'url' => video_url,
                'description' => 'Complete video recording'
              }
              
              # Add after slides but before other resources
              slides_index = @resources.find_index { |r| r['type'] == 'slides' }
              insert_index = slides_index ? slides_index + 1 : 0
              @resources.insert(insert_index, video_resource)
              
              puts "SUCCESS Video found via Notist embed: #{video_url}"
              return true
            end
          end
        end
      rescue => e
        puts "⚠️  Could not resolve Notist embed: #{e.message}"
      end
      
      puts "⚠️  Found Notist embed but could not resolve to YouTube URL: #{embed_url}"
    end
    
    puts "⚠️  No video found - setting status to video-pending"
    @talk_data[:status] = "video-pending"
    true
  end
  
  def generate_jekyll_file
    puts "\n6️⃣ Generating Jekyll file..."
    
    # Generate filename with intelligent length management
    date_part = @talk_data[:date]
    
    # Smart conference slug generation - extract key terms
    conference_slug = generate_smart_conference_slug(@talk_data[:conference])
    
    # Smart title slug generation - extract key terms
    title_slug = generate_smart_title_slug(@talk_data[:title])
    
    # Ensure reasonable total length (prefer under 80 characters)
    base_length = date_part.length + 1 + conference_slug.length + 1 + 3  # date + - + conference + - + .md
    available_for_title = 75 - base_length  # Leave some buffer
    
    if title_slug.length > available_for_title && available_for_title > 15
      # Truncate at word boundary
      truncated = title_slug[0...available_for_title]
      last_dash = truncated.rindex('-')
      if last_dash && last_dash > available_for_title * 0.6
        title_slug = truncated[0...last_dash]
      else
        title_slug = truncated.gsub(/-+$/, '')
      end
    end
    
    @jekyll_file = "_talks/#{date_part}-#{conference_slug}-#{title_slug}.md"
    
    # Generate minimal YAML front matter (clean format)
    yaml_data = {
      'layout' => 'talk'
    }
    
    # Note: We no longer add extracted_abstract and extracted_description to YAML
    # Instead, we add an ## Abstract section in markdown that the plugin will parse
    
    # Generate clean markdown content with source tracking
    content = "---\n#{yaml_data.to_yaml.gsub(/^---\n/, '')}---\n\n"
    content += "<!-- Source: #{@talk_url} -->\n"
    content += generate_clean_markdown_body
    
    # Write file
    File.write(@jekyll_file, content)
    puts "SUCCESS Jekyll file generated: #{@jekyll_file}"
    
    true
  end

  def validate_resource_sources
    puts "\n6.5️⃣ Validating resource sources..."
    
    @resources.each_with_index do |resource, index|
      url = resource['url']
      type = resource['type']
      
      case type
      when 'slides'
        # Slides MUST be from Google Drive, not Notist
        unless url.include?('drive.google.com') || url.include?('docs.google.com')
          if url.include?('notist.cloud') || url.include?('speaking.jbaru.ch')
            @errors << "SLIDES FROM NOTIST: Resource #{index + 1} '#{resource['title']}' uses Notist slides: #{url}. Slides must be uploaded to Google Drive."
            return false
          else
            @errors << "INVALID SLIDES SOURCE: Resource #{index + 1} '#{resource['title']}' slides not from Google Drive: #{url}"
            return false
          end
        end
        
      when 'video'
        # Videos can be from YouTube or Notist embedded videos
        if url.include?('youtube.com') || url.include?('youtu.be')
          # YouTube videos are preferred
        elsif url.include?('notist.ninja/embed/')
          # Notist embedded videos are acceptable
          puts "   ℹ️  Notist embedded video: #{url}"
        elsif url.include?('notist.cloud') || url.include?('speaking.jbaru.ch')
          @errors << "VIDEO FROM NOTIST: Resource #{index + 1} '#{resource['title']}' uses Notist video: #{url}. Videos must be on YouTube."
          return false
        else
          @errors << "INVALID VIDEO SOURCE: Resource #{index + 1} '#{resource['title']}' video not from accepted sources: #{url}"
          return false
        end
        
      when 'link'
        # Links to other talks CAN be Notist (for now, will be migrated later)
        # Other external links are fine
        if url.include?('speaking.jbaru.ch')
          puts "   ℹ️  Notist talk link (will migrate later): #{url}"
        end
      end
    end
    
    puts "SUCCESS Resource sources validated - no Notist dependencies for slides/videos"
    true
  end

  def validate_migration
    puts "\n7️⃣ Validating migration..."
    
    # Check file exists and is readable
    unless File.exist?(@jekyll_file)
      @errors << "Generated Jekyll file does not exist"
      return false
    end
    
    # Parse and validate content
    begin
      content = File.read(@jekyll_file)
      
      # Validate YAML front matter exists
      yaml_match = content.match(/\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m)
      unless yaml_match
        @errors << "Invalid YAML front matter"
        return false
      end
      
      parsed_yaml = YAML.safe_load(yaml_match[1])
      
      # Validate required YAML fields
      unless parsed_yaml['layout'] == 'talk'
        @errors << "Missing or incorrect layout field"
        return false
      end
      
      # Extract markdown content after YAML
      markdown_content = content.sub(/\A---.*?---\n/m, '')
      
      # Validate title (H1 heading)
      unless markdown_content.match(/^# .+/)
        @errors << "Missing title (H1 heading)"
        return false
      end
      
      # Validate required markdown sections
      required_sections = [
        /\*\*Conference:\*\* .+/,
        /\*\*Date:\*\* \d{4}-\d{2}-\d{2}/,
        /\*\*Slides:\*\* \[.+\]\(.+\)/
      ]
      
      required_sections.each_with_index do |pattern, index|
        unless markdown_content.match(pattern)
          section_names = ['Conference', 'Date', 'Slides']
          @errors << "Missing required section: #{section_names[index]}"
          return false
        end
      end
      
      # Validate Resources section exists (only if non-slides/video resources were found)
      other_resources = @resources.reject { |r| r['type'] == 'slides' || r['type'] == 'video' }
      if other_resources.any?
        unless markdown_content.match(/## Resources/)
          @errors << "Missing Resources section (expected due to #{other_resources.length} resources)"
          return false
        end
      else
        # For talks with no additional resources, Resources section is optional
        puts "   No additional resources found - Resources section not required"
      end
      
      puts "SUCCESS Migration validation passed"
      puts "   Title: ✓"
      puts "   Conference, Date, Slides: ✓"
      puts "   Resources section: ✓"
      puts "   YAML structure: ✓"
      
      true
    rescue => e
      @errors << "Validation error: #{e.message}"
      return false
    end
  end
  
  def report_failure(message)
    puts "FAIL MIGRATION FAILED: #{message}"
    puts "\n🔍 ERRORS:"
    @errors.each_with_index do |error, i|
      puts "   #{i+1}. #{error}"
    end
    puts "\nFIX THESE ISSUES AND TRY AGAIN"
  end
  
  def run_migration_tests
    puts "\n🧪 Running migration tests..."
    
    # Change to project root for running tests (since this script is in root)
    project_root = Dir.pwd
    Dir.chdir(project_root) do
      puts "📍 Running from: #{Dir.pwd}"
      
      # For migration, test only the migrated talk for faster feedback
      talk_filename = File.basename(@jekyll_file, '.md') if @jekyll_file
      
      if talk_filename
        puts "🎯 Running focused tests for: #{talk_filename}"
        
        # Set environment variable for single talk testing
        ENV['TEST_SINGLE_TALK'] = talk_filename
        
        # Run focused migration tests
        test_command = "bundle exec ruby test/migration/migration_test.rb"
        puts "🚀 #{test_command}"
        
        test_success = system(test_command)
        
        # Clear environment variable
        ENV.delete('TEST_SINGLE_TALK')
      else
        puts "⚠️  No talk file specified, running full test suite"
        test_command = "bundle exec rake test:migration"
        puts "🚀 #{test_command}"
        
        test_success = system(test_command)
      end
      
      test_success = $?.success?
      
      if test_success
        puts "\n✅ Migration tests PASSED"
        if talk_filename
          puts "   ✓ #{talk_filename} validated successfully"
        end
      else
        puts "\n❌ Migration tests FAILED"
        puts "   This indicates the migration may be incomplete"
        puts "   Check test output above for specific issues"
      end
      
      test_success
    end
  end
  
  def build_and_test_site
    puts "\n🏗️  Building Jekyll site and testing integration..."
    
    # Change to project root for building Jekyll
    project_root = Dir.pwd
    Dir.chdir(project_root) do
      puts "📍 Building from: #{Dir.pwd}"
      
      # Build Jekyll site
      puts "🚀 bundle exec jekyll build"
      build_success = system("bundle exec jekyll build --quiet")
      
      unless build_success
        puts "❌ Jekyll build FAILED"
        puts "   The new talk may have syntax errors or missing data"
        return false
      end
      
      puts "✅ Jekyll build successful"
      
      # Run site integration tests to verify the new talk appears correctly
      puts "\n🧪 Running site integration tests..."
      puts "🚀 bundle exec ruby test/run_tests.rb -c integration"
      
      test_success = system("bundle exec ruby test/run_tests.rb -c integration")
      
      unless test_success
        puts "❌ Site integration tests FAILED"
        puts "   The new talk may not be displaying correctly on the site"
        puts "   Check if it appears on the main page with correct metadata"
        return false
      end
      
      puts "✅ Site integration tests PASSED"
      puts "   New talk is properly integrated and displaying correctly"
      
      true
    end
  end

  def rebuild_jekyll_site
    puts "\n🏗️  Rebuilding Jekyll site to include migrated content..."
    
    # Change to project root for building Jekyll
    project_root = Dir.pwd
    Dir.chdir(project_root) do
      puts "📍 Building from: #{Dir.pwd}"
      
      # Build Jekyll site
      puts "🚀 bundle exec jekyll build"
      build_success = system("bundle exec jekyll build --quiet")
      
      unless build_success
        puts "❌ Jekyll build FAILED"
        puts "   The new talk may have syntax errors or missing data"
        return false
      end
      
      puts "✅ Jekyll build successful"
      puts "   Migrated content is now available in the rendered site"
      
      true
    end
  end

  def run_site_integration_tests
    puts "\n🧪 Running site integration tests..."
    
    # Change to project root for running tests
    project_root = Dir.pwd
    Dir.chdir(project_root) do
      puts "🚀 bundle exec ruby test/run_tests.rb -c integration"
      
      test_success = system("bundle exec ruby test/run_tests.rb -c integration")
      
      unless test_success
        puts "❌ Site integration tests FAILED"
        puts "   The new talk may not be displaying correctly on the site"
        puts "   Check if it appears on the main page with correct metadata"
        return false
      end
      
      puts "✅ Site integration tests PASSED"
      puts "   New talk is properly integrated and displaying correctly"
      
      true
    end
  end

  # Helper methods
  
  def determine_resource_type(url)
    case url
    when /github\.com/
      'code'
    when /docs\.google\.com\/presentation/
      'slides'  
    when /drive\.google\.com.*\.pdf/
      'slides'
    when /youtube\.com|youtu\.be/
      'video'
    else
      'link'
    end
  end
  
  def extract_speakers_from_url
    # Extract speaker info from URL pattern
    if @talk_url.include?('speaking.jbaru.ch')
      'Baruch Sadogursky'
    else
      'Unknown Speaker'
    end
  end
  
  def extract_location_from_page
    # Try to extract location from various sources
    
    # Method 1: Look for location in subhead text
    subhead = @doc.css('.presentation-header .subhead').first
    if subhead
      subhead_text = subhead.text
      # Pattern: "A presentation at Conference in Month Year in Location"
      location_match = subhead_text.match(/in\s+\w+\s+\d{4}\s+in\s+(.+?)(?:\s+by|$)/i)
      if location_match
        @talk_data[:location] = location_match[1].strip
        puts "SUCCESS Location extracted from subhead: #{@talk_data[:location]}"
        return
      end
    end
    
    # Method 2: Look in JSON-LD structured data
    json_ld_scripts = @doc.css('script[type="application/ld+json"]')
    json_ld_scripts.each do |script|
      begin
        json_data = JSON.parse(script.content)
        if json_data.dig('location', 'name')
          @talk_data[:location] = json_data['location']['name']
          puts "SUCCESS Location extracted from JSON-LD: #{@talk_data[:location]}"
          return
        elsif json_data.dig('location', 'address', 'addressLocality')
          locality = json_data['location']['address']['addressLocality']
          country = json_data.dig('location', 'address', 'addressCountry')
          @talk_data[:location] = country ? "#{locality}, #{country}" : locality
          puts "SUCCESS Location extracted from JSON-LD address: #{@talk_data[:location]}"
          return
        end
      rescue JSON::ParserError => e
        puts "❌ JSON-LD parsing failed for location: #{e.message}"
      end
    end
    
    @talk_data[:location] = ""
  end
  
  def extract_resource_count_from_page
    # Look for "X Resources" text pattern
    match = @doc.text.match(/(\d+)\s+Resources?/i)
    match ? match[1].to_i : nil
  end
  
  def slides_exist_but_not_downloadable?
    # Check if slides are embedded (slide images present)
    slides_present = @doc.css('.slide-image, .deck .slide').any?
    
    # Check if download links are available
    pdf_urls = find_pdf_urls
    download_available = !pdf_urls.empty?
    
    slides_present && !download_available
  end
  
  def find_pdf_urls
    pdf_urls = []
    
    # Use precise selector for Notist download links
    @doc.css('a[download*=".pdf"]').each do |link|
      pdf_urls << link['href'] if link['href']
    end
    
    # Fallback: Look for direct PDF links
    @doc.css('a[href$=".pdf"]').each do |link|
      pdf_urls << link['href']
    end
    
    # Look for notist cloud PDF pattern
    page_text = @doc.to_s
    notist_match = page_text.match(/https?:\/\/on\.notist\.cloud\/pdf\/[^"'\s]+\.pdf/)
    pdf_urls << notist_match[0] if notist_match
    
    pdf_urls.uniq
  end
  
  def extract_actual_video_url(notist_embed_url)
    begin
      puts "   🔍 Fetching Notist embed to extract actual video URL..."
      
      uri = URI.parse(notist_embed_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      
      response = http.get(uri.path)
      
      unless response.code.to_i.between?(200, 299)
        puts "   ⚠️  Failed to fetch Notist embed: HTTP #{response.code}"
        return nil
      end
      
      embed_html = response.body
      
      # Look for YouTube URLs in the embed
      youtube_patterns = [
        /https?:\/\/(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)/,
        /https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/,
        /https?:\/\/youtu\.be\/([a-zA-Z0-9_-]+)/
      ]
      
      youtube_patterns.each do |pattern|
        match = embed_html.match(pattern)
        if match
          video_id = match[1]
          actual_url = "https://www.youtube.com/watch?v=#{video_id}"
          puts "   ✅ Extracted YouTube video: #{actual_url}"
          return actual_url
        end
      end
      
      # Look for Vimeo URLs
      vimeo_pattern = /https?:\/\/(?:www\.)?vimeo\.com\/(?:video\/)?(\d+)/
      vimeo_match = embed_html.match(vimeo_pattern)
      if vimeo_match
        video_id = vimeo_match[1]
        actual_url = "https://vimeo.com/#{video_id}"
        puts "   ✅ Extracted Vimeo video: #{actual_url}"
        return actual_url
      end
      
      puts "   ⚠️  No YouTube or Vimeo URL found in Notist embed"
      return nil
      
    rescue => e
      puts "   ⚠️  Error extracting video URL: #{e.message}"
      return nil
    end
  end

  def generate_pdf_filename
    date_part = @talk_data[:date]
    conference_slug = @talk_data[:conference].downcase.gsub(/[^a-z0-9]+/, '-')
    title_slug = @talk_data[:title].downcase.gsub(/[^a-z0-9]+/, '-')[0..30]
    "#{date_part}-#{conference_slug}-#{title_slug}.pdf"
  end
  
  def download_file(url, local_path)
    require 'fileutils'
    require 'open-uri'
    FileUtils.mkdir_p(File.dirname(local_path))
    
    begin
      # Use open-uri which handles redirects and headers better than Net::HTTP
      options = {
        'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language' => 'en-US,en;q=0.9',
        'Accept-Encoding' => 'gzip, deflate, br',
        'Connection' => 'keep-alive',
        'Upgrade-Insecure-Requests' => '1'
      }
      
      URI.open(url, options) do |file|
        File.open(local_path, 'wb') do |output|
          output.write(file.read)
        end
        
        return true
      end
    rescue => e
      puts "   ❌ Download failed: #{e.message}"
      false
    end
  end
  
  def download_thumbnail_for_slides()
    puts "   Downloading thumbnail for slides..."
    
    # Extract thumbnail from Notist page og:image meta tag
    og_image = @doc.css('meta[property="og:image"]').first
    thumbnail_url = og_image ? og_image['content'] : nil

    unless thumbnail_url
      puts "   ❌ FATAL: Could not find og:image thumbnail on Notist page"
      return false
    end

    # Verify it's a Notist slide deck URL
    unless thumbnail_url.include?('on.notist.cloud/slides/')
      puts "   ❌ FATAL: og:image is not a Notist slide deck thumbnail: #{thumbnail_url}"
      return false
    end

    puts "   ✅ Found Notist slide deck thumbnail: #{thumbnail_url}"

    # Generate local thumbnail filename based on talk slug
    talk_slug = generate_talk_slug
    thumbnail_filename = "#{talk_slug}-thumbnail.png"
    local_thumbnail_path = "assets/images/thumbnails/#{thumbnail_filename}"

    # Create directory if it doesn't exist
    require 'fileutils'
    FileUtils.mkdir_p('assets/images/thumbnails')

    # Download thumbnail using dedicated function
    if download_thumbnail_file(thumbnail_url, local_thumbnail_path)
      puts "   ✅ Thumbnail downloaded: #{local_thumbnail_path}"
      
      # Verify file exists and has content
      if File.exist?(local_thumbnail_path) && File.size(local_thumbnail_path) > 0
        return local_thumbnail_path
      else
        puts "   ❌ FATAL: Thumbnail file missing or empty after download"
        return false
      end
    else
      puts "   ❌ FATAL: Failed to download thumbnail from: #{thumbnail_url}"
      return false
    end
  end  # Dedicated thumbnail download function using proven working method
  def download_thumbnail_file(url, local_path)
    require 'net/http'
    require 'fileutils'
    
    puts "   THUMBNAIL DOWNLOAD: Starting download of #{url}"
    puts "   THUMBNAIL DOWNLOAD: Target path: #{local_path}"
    puts "   THUMBNAIL DOWNLOAD: URL length: #{url.length} chars"
    
    FileUtils.mkdir_p(File.dirname(local_path))
    
    begin
      uri = URI.parse(url)
      puts "   THUMBNAIL DOWNLOAD: Parsed URI - Host: #{uri.host}, Path: #{uri.path}"
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.read_timeout = 30
      http.open_timeout = 10
      
      response = http.get(uri.path)
      puts "   THUMBNAIL DOWNLOAD: Response code: #{response.code}"
      puts "   THUMBNAIL DOWNLOAD: Content-Type: #{response['content-type']}"
      puts "   THUMBNAIL DOWNLOAD: Content-Length: #{response['content-length']}"
      
      if response.code == '200'
        File.open(local_path, 'wb') { |f| f.write(response.body) }
        file_size = File.size(local_path)
        puts "   THUMBNAIL DOWNLOAD: File written successfully, size: #{file_size} bytes"
        return true
      else
        puts "   THUMBNAIL DOWNLOAD: HTTP error - Code: #{response.code}"
        return false
      end
    rescue => e
      puts "   THUMBNAIL DOWNLOAD: Exception: #{e.class}: #{e.message}"
      puts "   THUMBNAIL DOWNLOAD: Backtrace: #{e.backtrace.first(3).join(', ')}"
      return false
    end
  end
  
  def extract_file_id_from_drive_url(url)
    match = url.match(/\/d\/([a-zA-Z0-9_-]+)/)
    match ? match[1] : nil
  end
  
  def generate_talk_slug
    # Generate a slug similar to the Jekyll filename
    date_part = @talk_data[:date]
    conference_slug = generate_smart_conference_slug(@talk_data[:conference])
    title_slug = generate_smart_title_slug(@talk_data[:title])
    
    # Combine parts to create a consistent slug
    "#{date_part}-#{conference_slug}-#{title_slug}"
  end
  
  def setup_google_drive_service
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = 'Shownotes Migration'
    
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('Google API.json'),
      scope: ['https://www.googleapis.com/auth/drive']
    )
    
    service
  end
  
  def find_shared_drive_root
    service = setup_google_drive_service
    
    # List all shared drives accessible by the service account
    drives_response = service.list_drives
    
    if drives_response.drives.empty?
      puts "⚠️  No shared drives found. Service account may not have access to any shared drives."
      return nil
    end
    
    # Use the first available shared drive
    shared_drive = drives_response.drives.first
    puts "📁 Using shared drive: #{shared_drive.name} (ID: #{shared_drive.id})"
    
    # Return the shared drive ID as the parent folder
    shared_drive.id
  end

  def upload_to_google_drive(local_path)
    begin
      service = setup_google_drive_service
      
      # Find shared drive root folder dynamically
      shared_drive_id = find_shared_drive_root
      unless shared_drive_id
        puts "⚠️  Could not find accessible shared drive"
        return nil
      end
      
      file_metadata = Google::Apis::DriveV3::File.new(
        name: File.basename(local_path),
        parents: [shared_drive_id]
      )
      
      # Upload with support_all_drives to work with shared drives
      uploaded_file = service.create_file(
        file_metadata, 
        upload_source: local_path,
        supports_all_drives: true
      )
      
      # Make public
      permission = Google::Apis::DriveV3::Permission.new(role: 'reader', type: 'anyone')
      service.create_permission(uploaded_file.id, permission, supports_all_drives: true)
      
      # Get detailed file metadata including thumbnail information
      detailed_file = service.get_file(
        uploaded_file.id, 
        fields: 'id,name,webViewLink,thumbnailLink,mimeType', 
        supports_all_drives: true
      )
      
      puts "   DEBUG: File metadata - ID: #{detailed_file.id}, thumbnailLink: #{detailed_file.thumbnail_link}"
      
      # Return both URL and metadata for thumbnail generation
      {
        url: "https://drive.google.com/file/d/#{uploaded_file.id}/view",
        file_id: uploaded_file.id,
        thumbnail_link: detailed_file.thumbnail_link
      }
    rescue => e
      puts "⚠️  Google Drive upload failed: #{e.message}"
      nil
    end
  end
  
  def extract_pdf_title
    "#{@talk_data[:title]} - Slides"
  end
  
  def generate_description
    "Presentation from #{@talk_data[:conference]}"
  end
  
  def generate_clean_markdown_body
    # Generate clean markdown content matching existing format
    content = "# #{@talk_data[:title]}\n\n"
    
    # Conference and date info
    content += "**Conference:** #{@talk_data[:conference]}  \n"
    content += "**Date:** #{@talk_data[:date]}  \n"
    
    # Slides and video (if available)
    slides_resource = @resources.find { |r| r['type'] == 'slides' }
    if slides_resource
      content += "**Slides:** [View Slides](#{slides_resource['url']})  \n"
    end
    
    video_resource = @resources.find { |r| r['type'] == 'video' }
    if video_resource
      content += "**Video:** [Watch Video](#{video_resource['url']})  \n"
    end
    
    content += "\n"
    
    # Presentation context with dynamic speaker reference
    content += generate_presentation_context
    
    # Abstract/description as a markdown section
    if @talk_data[:abstract] && !@talk_data[:abstract].empty?
      content += "## Abstract\n\n#{@talk_data[:abstract]}\n\n"
    end
    
    # Other resources as markdown list
    other_resources = @resources.reject { |r| r['type'] == 'slides' || r['type'] == 'video' }
    if other_resources.any?
      content += "## Resources\n\n"
      other_resources.each do |resource|
        title = resource['title'] || resource['url']
        content += "- [#{title}](#{resource['url']})\n"
      end
    end
    
    content
  end

  def generate_presentation_context
    # Generate presentation context with dynamic speaker reference
    context = "A presentation at #{@talk_data[:conference]}"
    
    # Add location and date information if available
    if @talk_data[:location] && !@talk_data[:location].empty?
      # Extract date parts for readable format
      begin
        date_obj = Date.parse(@talk_data[:date])
        month_year = date_obj.strftime("%B %Y")
        
        context += " in\n"
        context += "                    #{month_year} in\n"
        context += "                    #{@talk_data[:location]} by \n"
        context += "                    {{ site.speaker.display_name | default: site.speaker.name }}\n\n"
      rescue => e
        puts "DEBUG Date parsing failed for presentation context: #{e.message}"
        # Fallback without date formatting
        context += " in\n"
        context += "                    #{@talk_data[:location]} by \n"
        context += "                    {{ site.speaker.display_name | default: site.speaker.name }}\n\n"
      end
    else
      # Fallback if no location info
      context += " by \n"
      context += "                    {{ site.speaker.display_name | default: site.speaker.name }}\n\n"
    end
    
    context
  end

  def generate_smart_conference_slug(conference)
    # Extract key terms from conference name for a concise slug
    slug = conference.downcase
    
    # Remove common conference words to shorten
    slug = slug.gsub(/\b(conference|days?|summit|tech|technology|developers?|dev|meetup|event|annual|international|world|global)\b/, '')
    
    # Clean up and extract meaningful parts
    slug = slug.gsub(/[^a-z0-9\s]+/, ' ').strip.gsub(/\s+/, '-')
    
    # Split into parts and take meaningful ones
    parts = slug.split('-').reject(&:empty?)
    
    # Smart selection of parts (prefer location/brand over year/generic terms)
    selected_parts = []
    year_pattern = /^20\d{2}$/
    
    parts.each do |part|
      next if part.length < 2  # Skip very short parts
      next if part.match(year_pattern) && selected_parts.length >= 2  # Skip year if we have enough parts
      selected_parts << part
      break if selected_parts.length >= 3  # Limit to 3 parts max
    end
    
    selected_parts.join('-')
  end

  def generate_smart_title_slug(title)
    # Extract key terms from title for a readable slug
    slug = title.downcase
    
    # Remove common stop words but keep technical terms
    stop_words = %w[a an and the or but in on at to for of with from by is are was were be been being have has had do does did will would could should can may might must shall why how what when where who]
    
    # Clean and split into words
    words = slug.gsub(/[^a-z0-9\s]+/, ' ').strip.split(/\s+/)
    
    # Keep important words (not stop words, or if they're technical terms)
    important_words = words.select do |word|
      word.length > 2 && (!stop_words.include?(word) || word.length > 8)  # Keep longer words even if they're stop words
    end
    
    # If we filtered too aggressively, keep some stop words
    if important_words.length < 2 && words.length > important_words.length
      important_words = words.reject { |w| stop_words.include?(w) && w.length <= 3 }
    end
    
    # Take first 2 key words to keep URL concise and readable
    selected_words = important_words.first(2)
    selected_words.join('-')
  end
end

class SpeakerMigrator
  def initialize(speaker_url)
    @speaker_url = speaker_url
    @migrated_talks = []
    @failed_talks = []
    @failed_talk_details = {} # Store failure details for reporting
  end
  
  def migrate_all_talks
    puts "STARTING SPEAKER MIGRATION"
    puts "=" * 50
    puts "Speaker URL: #{@speaker_url}"
    
    # Step 1: Discover all talks for the speaker
    talk_urls = discover_speaker_talks
    if talk_urls.empty?
      puts "❌ No talks found for speaker"
      return false
    end
    
    puts "📋 Found #{talk_urls.length} talks to migrate:"
    talk_urls.each_with_index do |url, i|
      puts "   #{i+1}. #{url}"
    end
    puts
    
    # Step 2: Migrate each talk (skip individual tests for batch efficiency)
    talk_urls.each_with_index do |talk_url, index|
      puts "\n" + "🎯" * 20
      puts "MIGRATING TALK #{index + 1}/#{talk_urls.length}"
      puts "🎯" * 20
      
      migrator = TalkMigrator.new(talk_url, skip_tests: true)
      if migrator.migrate
        @migrated_talks << talk_url
        puts "✅ SUCCESS: #{talk_url}"
      else
        @failed_talks << talk_url
        @failed_talk_details[talk_url] = migrator.instance_variable_get(:@errors)
        puts "❌ FAILED: #{talk_url}"
        puts "   Error: #{migrator.instance_variable_get(:@errors).first}" if migrator.instance_variable_get(:@errors).any?
      end
      
      # Brief pause between migrations
      sleep(1)
    end
    
    # Step 3: Run comprehensive migration tests for all imported talks
    puts "\n" + "🧪" * 40
    puts "RUNNING COMPREHENSIVE TESTS FOR ALL MIGRATIONS"
    puts "🧪" * 40
    puts "📝 Testing all #{@migrated_talks.length} successfully migrated talks..."
    run_migration_tests
    
    # Step 4: Report summary
    report_migration_summary
    
    @failed_talks.empty?
  end
  
  private
  
  def discover_speaker_talks
    puts "\n🔍 Discovering talks for speaker..."
    
    begin
      uri = URI.parse(@speaker_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      
      path = uri.path.empty? ? '/' : uri.path
      response = http.get(path)
      unless response.code.to_i.between?(200, 299)
        puts "❌ Failed to fetch speaker page: HTTP #{response.code}"
        return []
      end
      
      doc = Nokogiri::HTML(response.body)
      talk_urls = []
      
      # Detect platform and use appropriate discovery strategy
      if uri.host.include?('speaking.jbaru.ch')
        talk_urls = discover_speaking_jbaru_ch_talks(doc, uri)
      elsif uri.host.include?('noti.st')
        talk_urls = discover_notist_talks(doc, uri)
      else
        # Generic discovery for other platforms
        talk_urls = discover_generic_talks(doc, uri)
      end
      
      # Remove duplicates and filter out already migrated talks
      talk_urls.uniq!
      
      # Filter out talks that already exist (using source URL check)
      original_count = talk_urls.length
      talk_urls = talk_urls.reject do |talk_url|
        TalkMigrator.new(talk_url).send(:talk_already_exists?)
      end
      
      skipped_count = original_count - talk_urls.length
      puts "✅ Found #{original_count} talks total"
      puts "⏭️  Skipping #{skipped_count} already migrated talks" if skipped_count > 0
      puts "🆕 #{talk_urls.length} new talks to migrate"
      
      talk_urls
    rescue => e
      puts "❌ Error discovering talks: #{e.message}"
      puts e.backtrace.first(3).map { |line| "   #{line}" }
      []
    end
  end
  
  def discover_speaking_jbaru_ch_talks(doc, uri)
    puts "🎯 Detected speaking.jbaru.ch platform"
    talk_urls = []
    
    # Look for talk links - speaking.jbaru.ch uses /XXXXXX/ patterns
    doc.css('a[href]').each do |link|
      href = link['href']
      next unless href
      
      # Convert relative URLs to absolute
      if href.start_with?('/')
        href = "#{uri.scheme}://#{uri.host}#{href}"
      end
      
      # Skip if not the same domain
      next unless href.include?(uri.host)
      
      # Skip if it's the home page or speaker profile itself
      next if href == @speaker_url
      next if href.match?(/^#{Regexp.escape(uri.to_s)}\/?$/)
      
      # Skip video URLs - these are not talks
      next if href.match?(/\/videos\//)
      
      # Look for talk-specific URL patterns (6-character IDs followed by slug)
      # Pattern: /XXXXXX/talk-title-slug
      if href.match?(/\/[a-zA-Z0-9]{6}\/[\w-]+$/i)
        talk_urls << href
        puts "   📝 Found talk: #{href}"
      end
    end
    
    talk_urls
  end
  
  def discover_notist_talks(doc, uri)
    puts "🎯 Detected Noti.st platform"
    talk_urls = []
    
    # Notist.io uses patterns like /abcDEF/talk-title-slug
    doc.css('a[href]').each do |link|
      href = link['href']
      next unless href
      
      # Convert relative URLs to absolute
      if href.start_with?('/')
        href = "#{uri.scheme}://#{uri.host}#{href}"
      end
      
      # Skip if not the same domain
      next unless href.include?(uri.host)
      
      # Skip if it's the speaker profile itself or general pages
      next if href == @speaker_url
      next if href.match?(/\/(about|contact|speaking)$/i)
      
      # Look for talk-specific URL patterns
      # Notist.io uses patterns like /abcDEF/talk-title-slug
      if href.match?(/\/[a-zA-Z0-9]{6}\/[\w-]+$/)
        talk_urls << href
        puts "   📝 Found talk: #{href}"
      end
    end
    
    talk_urls
  end
  
  def discover_generic_talks(doc, uri)
    puts "🎯 Using generic discovery strategy"
    talk_urls = []
    
    # Generic approach: look for links that might be talks
    # This is a best-effort approach for unknown platforms
    doc.css('a[href]').each do |link|
      href = link['href']
      next unless href
      
      # Convert relative URLs to absolute
      if href.start_with?('/')
        href = "#{uri.scheme}://#{uri.host}#{href}"
      end
      
      # Skip if not the same domain
      next unless href.include?(uri.host)
      
      # Skip obvious non-talk pages
      next if href == @speaker_url
      next if href.match?(/\/(about|contact|speaking|home|index)$/i)
      next if href.match?(/\.(pdf|jpg|png|gif|css|js)$/i)
      
      # Look for URLs that might be talks (contain meaningful paths)
      if href.match?(/\/[\w-]{3,}/) && !href.match?(/\.(html?|php)$/)
        talk_urls << href
        puts "   📝 Found potential talk: #{href}"
      end
    end
    
    talk_urls
  end
  
  def run_migration_tests
    puts "\n" + "🧪" * 20
    puts "RUNNING MIGRATION TESTS"
    puts "🧪" * 20
    puts
    
    # Change to project root for running tests (this script is in root)
    project_root = Dir.pwd
    Dir.chdir(project_root) do
      puts "📍 Running migration tests from: #{Dir.pwd}"
      
      # Run migration tests using rake
      test_command = "bundle exec rake test:migration"
      puts "🚀 #{test_command}"
      
      system(test_command)
      test_success = $?.success?
      
      if test_success
        puts "\n✅ Migration tests PASSED"
      else
        puts "\n❌ Migration tests FAILED"
        puts "   Check the test output above for specific failures"
        puts "   This may indicate incomplete migrations or missing resources"
      end
      
      test_success
    end
  end
  
  def report_migration_summary
    puts "\n" + "📊" * 20
    puts "MIGRATION SUMMARY"
    puts "📊" * 20
    
    total = @migrated_talks.length + @failed_talks.length
    puts "Total talks processed: #{total}"
    puts "✅ Successfully migrated: #{@migrated_talks.length}"
    puts "❌ Failed migrations: #{@failed_talks.length}"
    
    if @migrated_talks.any?
      puts "\n🎉 Successfully migrated talks:"
      @migrated_talks.each_with_index do |url, i|
        puts "   #{i+1}. #{url}"
      end
    end
    
    if @failed_talks.any?
      puts "\n💥 Failed to migrate:"
      @failed_talks.each_with_index do |url, i|
        puts "   #{i+1}. #{url}"
        if @failed_talk_details[url]
          @failed_talk_details[url].each do |error|
            puts "       #{error}"
          end
        end
      end
      
      # Special section for slides download issues
      slides_issues = @failed_talk_details.select do |url, errors|
        errors.any? { |error| error.include?("SLIDES EXIST BUT NOT DOWNLOADABLE") }
      end
      
      if slides_issues.any?
        puts "\n" + "🔧" * 40
        puts "ACTION REQUIRED: FIX NOTIST SLIDE SETTINGS"
        puts "🔧" * 40
        puts "The following talks have slides but download is not enabled:"
        puts
        slides_issues.each do |url, errors|
          puts "🎯 #{url}"
          puts "   1. Go to the Notist page"
          puts "   2. Edit the presentation"
          puts "   3. Enable 'Allow download' in slide settings"
          puts "   4. Save changes"
          puts "   5. Re-run migration"
          puts
        end
      end
      
      puts "\n🔧 Re-run individual talk migrations to debug specific failures"
    end
    
    success_rate = total > 0 ? (@migrated_talks.length.to_f / total * 100).round(1) : 0
    puts "\n📈 Success rate: #{success_rate}%"
    
    if success_rate == 100.0
      puts "🏆 Perfect migration! All talks successfully processed."
    elsif success_rate >= 80.0
      puts "🎯 Good migration! Most talks processed successfully."
    else
      puts "⚠️  Migration needs attention. Several talks failed."
    end
  end
end

# CLI usage
if __FILE__ == $0
  options = {}
  
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] <url>"
    opts.separator ""
    opts.separator "Modes:"
    opts.separator "  Single talk:    #{$0} <individual_talk_url>"
    opts.separator "  All speaker:    #{$0} --speaker <speaker_profile_url>"
    opts.separator ""
    opts.separator "Examples:"
    opts.separator "  # Migrate single talk"
    opts.separator "  #{$0} https://speaking.jbaru.ch/PjlHKD/robocoders-judgment-day-ai-ides-face-off"
    opts.separator ""
    opts.separator "  # Migrate all talks for a speaker"
    opts.separator "  #{$0} --speaker https://speaking.jbaru.ch"
    opts.separator ""
    opts.separator "Options:"
    
    opts.on("--speaker", "Migrate all talks for the speaker (URL should be speaker profile)") do
      options[:speaker_mode] = true
    end
    
    opts.on("--skip-tests", "Skip integration tests after migration") do
      options[:skip_tests] = true
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit 0
    end
    
    opts.on("--version", "Show version information") do
      puts "Migration Tool v2.0"
      puts "Supports single talk and bulk speaker migration"
      exit 0
    end
  end
  
  begin
    opt_parser.parse!
  rescue OptionParser::InvalidOption => e
    puts "Error: #{e}"
    puts opt_parser
    exit 1
  end
  
  if ARGV.length != 1
    puts "Error: Please provide a URL"
    puts opt_parser
    exit 1
  end
  
  url = ARGV[0]
  
  # Validate URL format
  unless url.match?(/^https?:\/\//)
    puts "Error: URL must start with http:// or https://"
    exit 1
  end
  
  success = if options[:speaker_mode]
    puts "🎯 SPEAKER MIGRATION MODE"
    puts "Will discover and migrate all talks for speaker"
    puts
    
    migrator = SpeakerMigrator.new(url)
    migrator.migrate_all_talks
  else
    puts "🎯 SINGLE TALK MIGRATION MODE"
    puts "Will migrate individual talk"
    puts
    
    migrator = TalkMigrator.new(url, skip_tests: options[:skip_tests] || false)
    migrator.migrate
  end
  
  exit success ? 0 : 1
end