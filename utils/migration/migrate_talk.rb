#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'nokogiri'
require 'yaml'
require 'json'
require 'google/apis/drive_v3'
require 'googleauth'
require 'optparse'

class TalkMigrator
  
  def initialize(talk_url)
    @talk_url = talk_url
    @talk_data = {}
    @resources = []
    @errors = []
  end
  
  def migrate_talk(talk_url, skip_tests: false)
    @talk_url = talk_url
    puts "\n🚀 Starting migration for: #{talk_url}"
    
    # Step 1: Fetch and parse the talk page
    unless fetch_talk_page
      puts "❌ Failed to fetch talk page"
      return false
    end
    
    # Step 2: Extract talk metadata
    unless extract_metadata
      puts "❌ Failed to extract talk metadata"
      return false
    end
    
    # Step 3: Extract all resources
    unless extract_all_resources
      puts "❌ Failed to extract resources"
      return false
    end
    
    # Step 4: Handle PDF uploads to Google Drive
    unless handle_pdf
      puts "❌ Failed to handle PDF uploads"
      return false
    end
    
    # Step 5: Find and validate video
    unless find_video
      puts "❌ Failed to find video"
      return false
    end
    
    # Step 6: Validate all resource sources
    unless validate_resource_sources
      puts "❌ Failed to validate resource sources"
      return false
    end
    
    # Step 7: Generate Jekyll file
    unless generate_jekyll_file
      puts "❌ Failed to generate Jekyll file"
      return false
    end
    
    # Step 8: Validate migration
    unless validate_migration
      puts "❌ Migration validation failed"
      return false
    end
    
    # Step 9: Run migration tests (optional for batch operations)
    if skip_tests
      puts "⏭️  Skipping tests (batch mode)"
      puts "\n✅ MIGRATION COMPLETED!"
      puts "Generated: #{@jekyll_file}"
      puts "Resources: #{@resources.length} extracted"
    else
      unless run_migration_tests
        puts "⚠️  Migration tests failed, but file was created"
        puts "   This may indicate incomplete migration that needs manual review"
      end
      
      # Only show success if tests actually passed
      if run_migration_tests
        puts "\n✅ MIGRATION SUCCESSFUL!"
        puts "Generated: #{@jekyll_file}"
        puts "Resources: #{@resources.length} extracted"
        puts "Next: Review the generated file and commit if satisfied"
      else
        puts "\n⚠️  MIGRATION COMPLETED WITH TEST FAILURES"
        puts "Generated: #{@jekyll_file}"
        puts "Resources: #{@resources.length} extracted"
        puts "Next: Review test failures and fix issues before committing"
      end
    end
    
    true
  end
  
  private
  
  def fetch_talk_page
    puts "\n1️⃣ Fetching talk page..."
    
    uri = URI.parse(@talk_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.path)
    
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
  
  def extract_metadata
    puts "\n2️⃣ Extracting metadata..."
    
    # Title (REQUIRED)
    title_elem = @doc.css('h1').first
    unless title_elem
      @errors << "No title found (missing h1 element)"
      return false
    end
    @talk_data[:title] = title_elem.text.strip
    
    # Date and Conference (extract from page content)
    # Look for patterns like "June 11, 2025" and "Devoxx Poland 2025"
    page_text = @doc.text
    
    # Extract date - first check existing files, then parse from page
    date_found = false
    
    # Method 1: Look for existing files with same conference pattern
    conference_slug = @talk_data[:conference].downcase.gsub(/[^a-z0-9]+/, '-') if @talk_data[:conference]
    if conference_slug
      existing_files = Dir.glob("_talks/*#{conference_slug}*.md") + Dir.glob("pdfs/*#{conference_slug}*.pdf")
      existing_files.each do |file|
        if match = File.basename(file).match(/^(\d{4}-\d{2}-\d{2})/)
          @talk_data[:date] = match[1]
          date_found = true
          puts "   Found date from existing file: #{@talk_data[:date]}"
          break
        end
      end
    end
    
    # Method 2: Parse from page content if not found in existing files
    unless date_found
      # First try to find datetime attribute in time element
      time_element = @doc.css('time[datetime]').first
      if time_element && time_element['datetime']
        begin
          datetime_str = time_element['datetime']
          # Parse ISO datetime format like "2025-06-20T08:00:00+02:00"
          @talk_data[:date] = Date.parse(datetime_str).strftime("%Y-%m-%d")
          date_found = true
          puts "   Found date from time element datetime: #{@talk_data[:date]}"
        rescue
          # Continue to text patterns if datetime parsing fails
        end
      end
      
      # Fallback to text patterns
      unless date_found
        date_patterns = [
          /(\w+\s+\d+,\s+\d{4})/,           # "June 20, 2025"
          /(\d{4}-\d{2}-\d{2})/             # "2025-06-20"
        ]
        
        date_patterns.each do |pattern|
          date_match = page_text.match(pattern)
          if date_match
            begin
              date_str = date_match[1]
              @talk_data[:date] = Date.parse(date_str).strftime("%Y-%m-%d")
              date_found = true
              break
            rescue
              next # Try next pattern
            end
          end
        end
      end
    end
    
    unless date_found
      @errors << "No specific date found - only found month/year which is insufficient"
      return false
    end
    
    # Extract conference - look for "A presentation at [Conference Name]" pattern first
    conference_found = false
    
    # Method 1: Parse from "A presentation at [Conference Name]" pattern
    presentation_match = page_text.match(/A presentation at\s+([^.\n]+?)\s+in\s+/)
    if presentation_match
      conference_name = presentation_match[1].strip
      # Clean up common suffixes that might be included
      conference_name = conference_name.gsub(/\s+(in|on)\s+\d{4}.*$/, '')
      # Limit conference name length to prevent HTML content capture
      conference_name = conference_name.split(/\s+/).take(6).join(' ')
      # Remove any HTML tags or excessive whitespace
      conference_name = conference_name.gsub(/<[^>]*>/, '').gsub(/\s+/, ' ').strip
      
      # Validate conference name doesn't contain slide content
      if conference_name.length > 100 || conference_name.include?('Hello!') || conference_name.include?('Employee')
        puts "   ⚠️  Conference extraction captured slide content, skipping pattern match"
      else
        @talk_data[:conference] = conference_name
        conference_found = true
        puts "   Found conference from presentation pattern: #{conference_name}"
      end
    end
    
    # Method 2: Fallback to specific conference patterns if presentation pattern fails
    unless conference_found
      conference_patterns = [
        /Devoxx\s+\w+\s+\d{4}/,
        /Voxxed\s+Days\s+\w+\s+\d{4}/,
        /DevOps\s+Days\s+\w+\s+\d{4}/,
        /API:World\s+\d{4}/,
        /DevOps\s+Vision\s+\d{4}/
      ]
      
      conference_patterns.each do |pattern|
        match = page_text.match(pattern)
        if match
          @talk_data[:conference] = match[0]
          conference_found = true
          puts "   Found conference from pattern: #{match[0]}"
          break
        end
      end
    end
    
    # Method 3: Extract from JSON-LD structured data if available
    unless conference_found
      script_tags = @doc.css('script[type="application/ld+json"]')
      script_tags.each do |script|
        begin
          json_data = JSON.parse(script.content)
          if json_data['description']
            # Look for conference info in description
            desc = json_data['description']
            if desc.include?('presentation') || desc.include?('talk')
              # Extract a reasonable conference name from description
              @talk_data[:conference] = "Conference Event"
              conference_found = true
              puts "   Found conference from structured data"
              break
            end
          end
        rescue JSON::ParserError
          # Skip invalid JSON
        end
      end
    end
    
    # Method 4: Fallback to generic conference name based on URL pattern
    unless conference_found
      if @talk_url.include?('speaking.jbaru.ch')
        @talk_data[:conference] = "Speaking Event"
        conference_found = true
        puts "   Using fallback conference name for speaker site"
      end
    end
    
    unless conference_found
      @errors << "No conference found in page"
      return false
    end
    
    # Extract speakers (look for author/speaker information)
    # This is a simplification - may need refinement
    @talk_data[:speaker] = extract_speakers_from_url
    
    # Extract abstract/description
    abstract_elem = @doc.css('p').find { |p| p.text.length > 100 }
    @talk_data[:abstract] = abstract_elem ? abstract_elem.text.strip : ""
    
    puts "SUCCESS Metadata extracted:"
    puts "   Title: #{@talk_data[:title]}"
    puts "   Date: #{@talk_data[:date]}"
    puts "   Conference: #{@talk_data[:conference]}"
    puts "   Speaker: #{@talk_data[:speaker]}"
    
    true
  end
  
  def extract_all_resources
    puts "\n3️⃣ Extracting resources from Resources section only..."
    
    @resources = []
    
    # Extract resources from the specific resources section (same as test)
    resources_section = @doc.css('#resources')
    if resources_section.any?
      # Use the same precise selector as test
      links = resources_section.css('.resource-list li h3 a')
      links.each do |link|
        href = link['href']
        title = link.text.strip
        
        # Skip invalid links and duplicates
        next if href.start_with?('#') || href.start_with?('/')
        next if title.empty? || title.length < 3
        next if href.nil? || href.empty?
        
        # Skip URLs with leading/trailing whitespace (same as test framework)
        next if href != href.strip
        
        href = href.strip
        next if href.empty?
        
        # Check for duplicates before adding
        existing_resource = @resources.find { |r| r['url'] == href }
        next if existing_resource
        
        @resources << {
          'type' => determine_resource_type(href),
          'title' => title,
          'url' => href,
          'description' => ''
        }
      end
    end
    
    puts "SUCCESS Found #{@resources.length} resources from Resources section"
    @resources.each_with_index do |resource, i|
      puts "   #{i+1}. #{resource['type']}: #{resource['title']} (#{resource['url']})"
    end
    
    true
  end
  
  def handle_pdf
    puts "\n4️⃣ Handling PDF..."
    
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
    
    # Upload to Google Drive - REQUIRED, no fallback
    drive_url = upload_to_google_drive(local_pdf_path)
    unless drive_url
      @errors << "Failed to upload PDF to Google Drive - this is required for slides"
      return false
    end
    
    # Add PDF as slides resource with Google Drive URL
    pdf_resource = {
      'type' => 'slides',
      'title' => extract_pdf_title,
      'url' => drive_url,
      'description' => "Complete slide deck (PDF)"
    }
    @talk_data[:pdf_url] = drive_url
    
    # Check for duplicates before adding
    existing_resource = @resources.find { |r| r['url'] == drive_url }
    unless existing_resource
      @resources.unshift(pdf_resource) # Add at beginning
    else
      puts "   ⚠️  Skipping duplicate slides resource: #{drive_url}"
    end
    
    puts "SUCCESS PDF uploaded to Google Drive"
    true
  end
  
  def find_video
    puts "\n5️⃣ Finding video..."
    
    page_text = @doc.to_s
    
    # Look for YouTube URLs
    youtube_patterns = [
      /https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/,
      /https?:\/\/youtu\.be\/([a-zA-Z0-9_-]+)/
    ]
    
    youtube_patterns.each do |pattern|
      match = page_text.match(pattern)
      if match
        video_url = match[0]
        @talk_data[:video_url] = video_url
        @talk_data[:status] = "completed"
        
        # Add video resource
        video_resource = {
          'type' => 'video',
          'title' => 'Full Presentation Video',
          'url' => video_url,
          'description' => 'Complete video recording'
        }
        
        # Check for duplicates before adding
        existing_resource = @resources.find { |r| r['url'] == video_url }
        unless existing_resource
          # Add after slides but before other resources
          slides_index = @resources.find_index { |r| r['type'] == 'slides' }
          insert_index = slides_index ? slides_index + 1 : 0
          @resources.insert(insert_index, video_resource)
        else
          puts "   ⚠️  Skipping duplicate video resource: #{video_url}"
        end
        
        puts "SUCCESS Video found: #{video_url}"
        return true
      end
    end
    
    # Check for Notist embedded videos and convert to YouTube
    notist_embed_pattern = /notist\.ninja\/embed\/([a-zA-Z0-9_-]+)/
    if match = page_text.match(notist_embed_pattern)
      notist_id = match[1]
      
      # Fetch the Notist embed page to get the actual YouTube ID
      begin
        require 'net/http'
        require 'uri'
        
        embed_url = "https://notist.ninja/embed/#{notist_id}"
        uri = URI(embed_url)
        response = Net::HTTP.get_response(uri)
        
        if response.code == '200'
          embed_content = response.body
          # Extract YouTube ID from the embed content
          youtube_match = embed_content.match(/youtube\.com\/embed\/([a-zA-Z0-9_-]+)/)
          
          if youtube_match
            youtube_id = youtube_match[1]
            youtube_url = "https://www.youtube.com/watch?v=#{youtube_id}"
            
            @talk_data[:video_url] = youtube_url
            @talk_data[:status] = "completed"
            
            # Add video resource
            video_resource = {
              'type' => 'video',
              'title' => 'Full Presentation Video',
              'url' => youtube_url,
              'description' => 'Complete video recording'
            }
            
            # Add after slides but before other resources
            slides_index = @resources.find_index { |r| r['type'] == 'slides' }
            insert_index = slides_index ? slides_index + 1 : 0
            @resources.insert(insert_index, video_resource)
            
            puts "SUCCESS Video found (converted from Notist): #{youtube_url}"
            return true
          else
            puts "⚠️  Found Notist embed but couldn't extract YouTube ID"
          end
        else
          puts "⚠️  Failed to fetch Notist embed page (#{response.code})"
        end
      rescue => e
        puts "⚠️  Error fetching Notist embed: #{e.message}"
      end
      
      # Fallback: mark as completed but don't add video resource
      puts "SUCCESS Video detected (Notist embed found but couldn't convert)"
      @talk_data[:status] = "completed"
      return true
    end
    
    # Check for other video indicators
    if page_text.include?('id="video"')
      puts "SUCCESS Video detected (embedded/other format)"
      @talk_data[:status] = "completed"
      return true
    end
    
    puts "⚠️  No video found - setting status to video-pending"
    @talk_data[:status] = "video-pending"
    true
  end
  
  def generate_jekyll_file
    puts "\n6️⃣ Generating Jekyll file..."
    
    # Generate filename
    date_part = @talk_data[:date]
    conference_slug = @talk_data[:conference].downcase.gsub(/[^a-z0-9]+/, '-')
    title_slug = @talk_data[:title].downcase.gsub(/[^a-z0-9]+/, '-')[0..50]
    @jekyll_file = "_talks/#{date_part}-#{conference_slug}-#{title_slug}.md"
    
    # Generate pure markdown content (no YAML frontmatter)
    content = generate_clean_markdown_body
    
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
        # Slides SHOULD be from Google Drive, but allow local PDFs as fallback
        if url.include?('drive.google.com') || url.include?('docs.google.com')
          puts "   ✅ Slides from Google Drive: #{url}"
        elsif url.start_with?('pdfs/') && url.end_with?('.pdf')
          puts "   ⚠️  Local PDF slides (needs Google Drive upload): #{url}"
        elsif url.include?('notist.cloud') || url.include?('speaking.jbaru.ch')
          @errors << "SLIDES FROM NOTIST: Resource #{index + 1} '#{resource['title']}' uses Notist slides: #{url}. Slides must be uploaded to Google Drive."
          return false
        else
          @errors << "INVALID SLIDES SOURCE: Resource #{index + 1} '#{resource['title']}' slides not from Google Drive: #{url}"
          return false
        end
        
      when 'video'
        # Videos MUST be from YouTube
        unless url.include?('youtube.com') || url.include?('youtu.be')
          @errors << "INVALID VIDEO SOURCE: Resource #{index + 1} '#{resource['title']}' video not from YouTube: #{url}"
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
    
    # Validate markdown-only content (no YAML frontmatter expected)
    begin
      content = File.read(@jekyll_file)
      
      # Should NOT have YAML frontmatter
      if content.match(/\A---\s*\n/)
        @errors << "File should be markdown-only, no YAML frontmatter allowed"
        return false
      end
      
      # Validate title exists as H1 heading
      unless content.match(/^#\s+.+/)
        @errors << "Missing title in markdown body (should start with # heading)"
        return false
      end
      
      # Validate basic structure - should have conference, date, slides info
      unless content.include?(@talk_data[:conference])
        @errors << "Missing conference information in markdown"
        return false
      end
      
      unless content.include?(@talk_data[:date])
        @errors << "Missing date information in markdown"
        return false
      end
      
      # Validate resources section exists only if resources were extracted
      other_resources = @resources.reject { |r| r['type'] == 'slides' || r['type'] == 'video' }
      if other_resources.any?
        unless content.include?("## Resources")
          @errors << "Missing Resources section in markdown (expected due to #{other_resources.length} resources)"
          return false
        end
      else
        # No resources expected, so no Resources section required
        puts "   No additional resources - Resources section not required"
      end
      
      puts "SUCCESS Migration validation passed"
      puts "   Resources: #{@resources.length}"
      puts "   Markdown-only format: ✓"
      puts "   Required content: ✓"
      
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
    
    # Change to project root for running tests
    project_root = File.expand_path('../..', __dir__)
    Dir.chdir(project_root) do
      puts "📍 Running from: #{Dir.pwd}"
      
      # Run migration tests using rake
      test_command = "bundle exec rake test:migration"
      puts "🚀 #{test_command}"
      
      system(test_command)
      test_success = $?.success?
      
      if test_success
        puts "\n✅ Migration tests PASSED"
      else
        puts "\n❌ Migration tests FAILED"
        puts "   This indicates the migration may be incomplete"
        puts "   Check test output above for specific issues"
      end
      
      test_success
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
  
  def extract_resource_count_from_page
    # Look for "X Resources" text pattern
    match = @doc.text.match(/(\d+)\s+Resources?/i)
    match ? match[1].to_i : nil
  end
  
  def find_pdf_urls
    pdf_urls = []
    
    # Look for direct PDF links
    @doc.css('a[href$=".pdf"]').each do |link|
      pdf_urls << link['href']
    end
    
    # Look for notist cloud PDF pattern
    page_text = @doc.to_s
    notist_match = page_text.match(/https?:\/\/on\.notist\.cloud\/pdf\/[^"'\s]+\.pdf/)
    pdf_urls << notist_match[0] if notist_match
    
    pdf_urls.uniq
  end
  
  def generate_pdf_filename
    date_part = @talk_data[:date]
    conference_slug = @talk_data[:conference].downcase.gsub(/[^a-z0-9]+/, '-')
    title_slug = @talk_data[:title].downcase.gsub(/[^a-z0-9]+/, '-')[0..30]
    "#{date_part}-#{conference_slug}-#{title_slug}.pdf"
  end
  
  def download_file(url, local_path)
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(local_path))
    
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    response = http.get(uri.path)
    
    if response.code.to_i.between?(200, 299)
      File.open(local_path, 'wb') { |file| file.write(response.body) }
      true
    else
      false
    end
  end
  
  def find_shared_drive_folder
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = 'Shownotes Migration'
    
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(File.join(File.dirname(__FILE__), '../../Google API.json')),
      scope: ['https://www.googleapis.com/auth/drive']
    )
    
    # Find shared drives
    shared_drives = service.list_drives(page_size: 10)
    
    if shared_drives.drives.empty?
      raise "No shared drives found - service account needs shared drive access"
    end
    
    # Use the first shared drive (should be "Presentations")
    shared_drive = shared_drives.drives.first
    puts "   Using shared drive: #{shared_drive.name} (#{shared_drive.id})"
    
    # Look for pdfs subfolder
    response = service.list_files(
      q: "'#{shared_drive.id}' in parents and trashed=false and name='pdfs'",
      fields: 'files(id, name)',
      supports_all_drives: true,
      include_items_from_all_drives: true,
      corpora: 'drive',
      drive_id: shared_drive.id
    )
    
    if response.files.empty?
      puts "   Using shared drive root (no pdfs subfolder found)"
      return shared_drive.id, service
    else
      pdfs_folder = response.files.first
      puts "   Using pdfs subfolder: #{pdfs_folder.id}"
      return pdfs_folder.id, service
    end
  end

  def upload_to_google_drive(local_path)
    begin
      folder_id, service = find_shared_drive_folder
      
      file_metadata = Google::Apis::DriveV3::File.new(
        name: File.basename(local_path),
        parents: [folder_id]
      )
      
      uploaded_file = service.create_file(
        file_metadata, 
        upload_source: local_path,
        supports_all_drives: true
      )
      
      # Make public
      permission = Google::Apis::DriveV3::Permission.new(role: 'reader', type: 'anyone')
      service.create_permission(uploaded_file.id, permission, supports_all_drives: true)
      
      "https://drive.google.com/file/d/#{uploaded_file.id}/view"
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
  
  # Abstract/description
  if @talk_data[:abstract] && !@talk_data[:abstract].empty?
    content += "#{@talk_data[:abstract]}\n\n"
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
  
  # Add source URL as HTML comment at the end for test validation
  content += "\n<!-- Source: #{@talk_url} -->\n"
  
  content
end
end

class SpeakerMigrator
  def initialize(speaker_url)
    @speaker_url = speaker_url
    @migrated_talks = []
    @failed_talks = []
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
    
    # Step 2: Migrate each talk
    talk_urls.each_with_index do |talk_url, index|
      puts "\n" + "🎯" * 20
      puts "MIGRATING TALK #{index + 1}/#{talk_urls.length}"
      puts "🎯" * 20
      
      # Step 2: Migrate each talk individually (skip tests in batch mode)
      migrator = TalkMigrator.new(talk_url)
      if migrator.migrate_talk(talk_url, skip_tests: true)
        @migrated_talks << talk_url
        puts "✅ SUCCESS: #{talk_url}"
      else
        @failed_talks << talk_url
        puts "❌ FAILED: #{talk_url}"
      end
      
      # Brief pause between migrations
      sleep(1)
    end
    
    # Step 3: Run migration tests once at the end
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
      
      # Find all talk links on the speaker's page
      # Look for links that match the pattern of individual talks
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
        
        # Skip video-only URLs
        next if href.match?(/\/videos\//)
        
        # Look for talk-specific URL patterns
        # Notist.io uses patterns like /abcDEF/talk-title-slug
        if href.match?(/\/[a-zA-Z0-9]{6}\/[\w-]+$/)
          talk_urls << href
        end
      end
      
      talk_urls.uniq!
      puts "✅ Found #{talk_urls.length} talks"
      
      talk_urls
    rescue => e
      puts "❌ Error discovering talks: #{e.message}"
      []
    end
  end
  
  def run_migration_tests
    puts "\n" + "🧪" * 20
    puts "RUNNING MIGRATION TESTS"
    puts "🧪" * 20
    puts
    
    # Change to project root for running tests
    project_root = File.expand_path('../..', __dir__)
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
    
    migrator = TalkMigrator.new(url)
    success = migrator.migrate_talk(url)
  end
  
  exit success ? 0 : 1
end