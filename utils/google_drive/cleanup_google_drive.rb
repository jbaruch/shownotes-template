#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

def cleanup_google_drive_files
  puts "🧹 Google Drive Cleanup Script"
  puts "=" * 50
  
  # Initialize Google Drive service
  service = Google::Apis::DriveV3::DriveService.new
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: Google::Apis::DriveV3::AUTH_DRIVE
  )
  
  puts "✅ Google Drive service initialized"
  
  begin
    # Simple approach: Get ALL files the service account has access to that are not trashed
    puts "\n� Finding all accessible non-trashed files..."
    
    all_files = service.list_files(
      q: "trashed=false",
      supports_all_drives: true,
      include_items_from_all_drives: true,
      fields: 'files(id, name, createdTime)'
    )
    
    puts "\n📋 Found #{all_files.files.length} files to move to trash:"
    all_files.files.each do |file|
      puts "   ID: #{file.id} - Name: #{file.name}"
    end
    
    if all_files.files.any?
      puts "\nMoving all files to trash..."
      all_files.files.each do |file|
        begin
          file_metadata = Google::Apis::DriveV3::File.new(trashed: true)
          service.update_file(file.id, file_metadata, supports_all_drives: true)
          puts "✅ Moved to trash: #{file.name} (#{file.id})"
        rescue Google::Apis::Error => e
          puts "❌ Error moving #{file.name} (#{file.id}) to trash: #{e.message}"
        end
      end
      
      puts "\n🎉 Cleanup complete! #{all_files.files.length} files processed."
    else
      puts "\n✨ No files found to clean up. Drive is already clean!"
    end
    
  rescue Google::Apis::Error => e
    puts "❌ Google Drive API Error: #{e.message}"
    puts "Full error: #{e.inspect}"
  rescue => e
    puts "❌ Unexpected error: #{e.message}"
    puts "Full error: #{e.inspect}"
  end
end

# Run the cleanup
cleanup_google_drive_files
