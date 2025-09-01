#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

# Check for credentials in environment variable first (CI), then local file
def load_credentials
  if ENV['GOOGLE_API_CREDENTIALS_JSON'] && !ENV['GOOGLE_API_CREDENTIALS_JSON'].empty?
    # Create temporary file from environment variable (CI environment)
    require 'tempfile'
    temp_file = Tempfile.new(['google_api', '.json'])
    temp_file.write(ENV['GOOGLE_API_CREDENTIALS_JSON'])
    temp_file.rewind
    temp_file
  elsif File.exist?('Google API.json')
    # Use local file (development environment)
    File.open('Google API.json')
  else
    nil
  end
end

credentials_file = load_credentials

unless credentials_file
  puts "⚠️  SKIPPING Google Drive tests: No credentials available"
  puts "   - For CI: Set GOOGLE_API_CREDENTIALS as a GitHub secret"
  puts "   - For local: Ensure 'Google API.json' exists in project root"
  puts "✅ External tests completed (skipped due to missing credentials)"
  exit 0
end

# Comprehensive Google Drive API integration test
begin
  service = Google::Apis::DriveV3::DriveService.new
  service.client_options.application_name = 'Shownotes Migration Test'
  
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: credentials_file,
    scope: ['https://www.googleapis.com/auth/drive']
  )
  
  puts "Testing Google Drive API access..."
  
  # First, find shared drives accessible to the service account
  puts "Finding shared drives..."
  shared_drives = service.list_drives(page_size: 10)
  
  if shared_drives.drives.empty?
    puts "WARNING: No shared drives found - testing with regular folder (limited functionality)"
    folder_id = '1rE43G9IvgMg0S9frwA7TaEc-XEDUL8ib'
    supports_all_drives = false
    drive_name = "Regular Folder"
  else
    puts "Found #{shared_drives.drives.length} shared drive(s):"
    shared_drives.drives.each do |drive|
      puts "  #{drive.name} (#{drive.id})"
    end
    
    # Use the first shared drive for testing
    shared_drive = shared_drives.drives.first
    folder_id = shared_drive.id
    supports_all_drives = true
    drive_name = shared_drive.name
    
    puts "Using shared drive: #{shared_drive.name}"
    
    # Find the pdfs folder within the shared drive for migration testing
    response = service.list_files(
      q: "'#{shared_drive.id}' in parents and trashed=false",
      fields: 'files(id, name, mimeType, createdTime)',
      supports_all_drives: true,
      include_items_from_all_drives: true,
      corpora: 'drive',
      drive_id: shared_drive.id
    )
    
    pdfs_folder = response.files.find { |file| file.name == 'pdfs' }
    if pdfs_folder
      pdfs_folder_id = pdfs_folder.id
      puts "Using pdfs subfolder: #{pdfs_folder.id}"
    else
      pdfs_folder_id = folder_id
      puts "No 'pdfs' subfolder found, using root of shared drive"
    end
  end
  
  # Test 1: List files to verify read access
  puts "\nTesting file listing..."
  response = service.list_files(
    q: "'#{folder_id}' in parents and trashed=false",
    fields: 'files(id, name, mimeType, createdTime)',
    supports_all_drives: supports_all_drives,
    include_items_from_all_drives: supports_all_drives,
    **(supports_all_drives ? { corpora: 'drive', drive_id: folder_id } : {})
  )
  
  puts "Files in #{drive_name} #{folder_id}:"
  if response.files.empty?
    puts "  (No files found)"
  else
    response.files.each do |file|
      puts "  #{file.name} (#{file.id}) - #{file.created_time}"
    end
  end
  
  puts "\nShared drive info:"
  puts "  Name: #{drive_name}"
  puts "  ID: #{folder_id}"
  if defined?(pdfs_folder_id)
    puts "Using pdfs subfolder: #{pdfs_folder_id}"
  end
  
  # Test 2: File upload to main location
  puts "\nTesting file upload..."
  test_filename = "test_migration_#{Time.now.to_i}.txt"
  File.write(test_filename, "Test file created at #{Time.now}")
  
  uploaded_file = service.create_file(
    { name: File.basename(test_filename), parents: [folder_id] },
    upload_source: test_filename,
    supports_all_drives: supports_all_drives
  )
  puts "SUCCESS: Test file uploaded with ID: #{uploaded_file.id}"
  puts "URL: https://drive.google.com/file/d/#{uploaded_file.id}/view"
  
  # Test cleanup for uploaded file
  cleanup_success = false
  begin
    puts "Moving file to trash..."
    trash_metadata = Google::Apis::DriveV3::File.new(trashed: true)
    
    3.times do |attempt|
      begin
        service.update_file(uploaded_file.id, trash_metadata, supports_all_drives: supports_all_drives)
        puts "Test file moved to trash successfully"
        cleanup_success = true
        break
      rescue Google::Apis::Error => e
        puts "Trash attempt #{attempt + 1} failed: #{e.message}"
        sleep(1) if attempt < 2
      end
    end
    
    unless cleanup_success
      puts "Trash failed, attempting direct delete..."
      service.delete_file(uploaded_file.id, supports_all_drives: supports_all_drives)
      puts "Test file deleted directly"
      cleanup_success = true
    end
  rescue => e
    puts "CLEANUP FAILED: #{e.message}"
    puts "File ID: #{uploaded_file.id} needs manual cleanup"
  end
  
  # Test 3: File upload to pdfs subfolder (if available and for migration testing)
  if defined?(pdfs_folder_id) && pdfs_folder_id != folder_id
    puts "\nTesting file upload to pdfs subfolder..."
    pdf_test_filename = "test_pdf_migration_#{Time.now.to_i}.txt"
    File.write(pdf_test_filename, "PDF test file created at #{Time.now}")
    
    uploaded_pdf_file = service.create_file(
      { name: File.basename(pdf_test_filename), parents: [pdfs_folder_id] },
      upload_source: pdf_test_filename,
      supports_all_drives: supports_all_drives
    )
    puts "SUCCESS: PDF test file uploaded with ID: #{uploaded_pdf_file.id}"
    puts "URL: https://drive.google.com/file/d/#{uploaded_pdf_file.id}/view"
    
    # Cleanup PDF test file
    begin
      puts "Moving PDF test file to trash..."
      service.update_file(uploaded_pdf_file.id, trash_metadata, supports_all_drives: supports_all_drives)
      puts "PDF test file moved to trash successfully"
    rescue => e
      puts "PDF cleanup failed: #{e.message}"
      puts "PDF File ID: #{uploaded_pdf_file.id} needs manual cleanup"
    end
    
    # Clean up temporary file
    File.delete(pdf_test_filename) if File.exist?(pdf_test_filename)
  end
  
  puts "\n✅ Test suite completed"
  
  unless shared_drives.drives.empty?
    puts "✅ Google Drive integration fully functional"
    puts "✅ Migration upload capability confirmed"
  else
    puts "⚠️  Limited functionality - service account needs shared drive access for full migration support"
  end

rescue Google::Apis::AuthorizationError => e
  puts "❌ AUTHORIZATION ERROR: #{e.message}"
  puts "Check that 'Google API.json' contains valid service account credentials"
  exit 1
rescue Google::Apis::Error => e
  puts "❌ GOOGLE API ERROR: #{e.message}"
  exit 1
rescue Errno::ENOENT => e
  puts "❌ FILE NOT FOUND: #{e.message}"
  puts "Make sure 'Google API.json' exists in the project root"
  exit 1
rescue => e
  puts "❌ UNEXPECTED ERROR: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
ensure
  # Clean up any temporary test files
  test_filename = Dir.glob("test_migration_*.txt").first
  File.delete(test_filename) if test_filename && File.exist?(test_filename)
  
  pdf_test_filename = Dir.glob("test_pdf_migration_*.txt").first
  File.delete(pdf_test_filename) if pdf_test_filename && File.exist?(pdf_test_filename)
end
