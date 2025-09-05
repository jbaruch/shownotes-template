#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

# Test Google Drive API access with shared drives
begin
  service = Google::Apis::DriveV3::DriveService.new
  service.client_options.application_name = 'Shownotes Migration Test'
  
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: ['https://www.googleapis.com/auth/drive']
  )
  
  puts "Testing Google Drive API access..."
  
  # First, find shared drives accessible to the service account
  puts "Finding shared drives..."
  shared_drives = service.list_drives(page_size: 10)
  
  if shared_drives.drives.empty?
    puts "No shared drives found. Testing with regular folder..."
    folder_id = '1rE43G9IvgMg0S9frwA7TaEc-XEDUL8ib'
    supports_all_drives = false
  else
    puts "Found #{shared_drives.drives.length} shared drive(s):"
    shared_drives.drives.each do |drive|
      puts "  #{drive.name} (#{drive.id})"
    end
    
    # Use the first shared drive for testing
    shared_drive = shared_drives.drives.first
    folder_id = shared_drive.id
    supports_all_drives = true
    puts "Using shared drive: #{shared_drive.name}"
  end
  
  # Try to list files in the folder/drive
  response = service.list_files(
    q: "'#{folder_id}' in parents",
    page_size: 10,
    fields: 'nextPageToken, files(id, name, createdTime, parents)',
    supports_all_drives: supports_all_drives,
    include_items_from_all_drives: supports_all_drives
  )
  
  puts "Files in #{supports_all_drives ? 'shared drive' : 'folder'} #{folder_id}:"
  response.files.each do |file|
    puts "  #{file.name} (#{file.id}) - #{file.created_time}"
  end
  
  # Try to get folder/drive info
  if supports_all_drives
    drive_info = service.get_drive(folder_id)
    puts "\nShared drive info:"
    puts "  Name: #{drive_info.name}"
    puts "  ID: #{drive_info.id}"
    
    # Find the pdfs folder within the shared drive for testing
    pdfs_folder = response.files.find { |file| file.name == 'pdfs' }
    if pdfs_folder
      folder_id = pdfs_folder.id
      puts "Using pdfs subfolder: #{pdfs_folder.id}"
    end
  else
    folder_info = service.get_file(folder_id, fields: 'id, name, permissions, owners')
    puts "\nFolder info:"
    puts "  Name: #{folder_info.name}"
    puts "  ID: #{folder_info.id}"
  end
  
  # Try to upload a small test file
  puts "\nTesting file upload..."
  
  # Create a unique test file for this test run
  test_filename = "test_upload_#{Time.now.to_i}.txt"
  test_content = "Test file created at #{Time.now} for Google Drive API testing"
  File.write(test_filename, test_content)
  
  file_metadata = Google::Apis::DriveV3::File.new(
    name: "test_migration_#{Time.now.to_i}.txt",
    parents: [folder_id]
  )
  
  uploaded_file = service.create_file(
    file_metadata, 
    upload_source: test_filename,
    supports_all_drives: supports_all_drives
  )
  puts "SUCCESS: Test file uploaded with ID: #{uploaded_file.id}"
  
  # Clean up - try to move to trash first, then delete
  cleanup_success = false
  3.times do |attempt|
    begin
      sleep(2) # Wait for propagation
      
      # Try moving to trash first (less aggressive)
      if attempt == 0
        puts "Moving file to trash..."
        trash_metadata = Google::Apis::DriveV3::File.new(trashed: true)
        service.update_file(uploaded_file.id, trash_metadata, supports_all_drives: supports_all_drives)
        puts "Test file moved to trash successfully"
        cleanup_success = true
        break
      else
        # Try permanent deletion on retries
        puts "Attempting permanent deletion..."
        service.delete_file(uploaded_file.id, supports_all_drives: supports_all_drives)
        puts "Test file deleted permanently"
        cleanup_success = true
        break
      end
    rescue => cleanup_error
      puts "Cleanup attempt #{attempt + 1} failed: #{cleanup_error.message}"
      if attempt == 2
        puts "ERROR: Failed to clean up test file after 3 attempts"
        puts "File ID: #{uploaded_file.id} needs manual cleanup"
      end
    end
  end
  
  # Clean up local test file
  File.delete(test_filename) if File.exist?(test_filename)
  
rescue => e
  if e.message.include?('storageQuotaExceeded')
    puts "WARNING: Upload test skipped - service account needs shared drive access"
    puts "The service account can read files but needs a shared drive to upload"
  else
    puts "ERROR: #{e.message}"
    puts "Full error: #{e.inspect}"
  end
  # Clean up local test file even on error
  test_filename = Dir.glob("test_upload_*.txt").first
  File.delete(test_filename) if test_filename && File.exist?(test_filename)
end
