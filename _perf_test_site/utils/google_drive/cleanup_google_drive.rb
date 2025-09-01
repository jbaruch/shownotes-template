#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

def list_google_drive_files
  puts "Listing Google Drive files..."
  
  # Initialize Google Drive service
  service = Google::Apis::DriveV3::DriveService.new
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('../../Google API.json'),
    scope: Google::Apis::DriveV3::AUTH_DRIVE
  )
  
  begin
    # List files in the shared drive folder
    folder_id = '1Q8Auh_XnZtrDsdnKe_rFOnx3mZVhphLn'
    
    files = service.list_files(
      q: "'#{folder_id}' in parents",
      supports_all_drives: true,
      include_items_from_all_drives: true,
      fields: 'files(id, name, createdTime)'
    )
    
    puts "Files in Google Drive folder:"
    files.files.each do |file|
      puts "ID: #{file.id}"
      puts "Name: #{file.name}"
      puts "Created: #{file.created_time}"
      puts "---"
    end
    
    # Look for RoboCoders files specifically
    robocoders_files = files.files.select { |f| f.name.downcase.include?('robocoders') || f.name.downcase.include?('judgment') || f.name.downcase.include?('devoxx') }
    
    if robocoders_files.any?
      puts "\nRoboCoders related files found:"
      robocoders_files.each do |file|
        puts "ID: #{file.id} - Name: #{file.name}"
      end
      
      puts "\nDeleting RoboCoders files..."
      robocoders_files.each do |file|
        begin
          service.delete_file(file.id, supports_all_drives: true)
          puts "✅ Deleted: #{file.name} (#{file.id})"
        rescue Google::Apis::Error => e
          puts "❌ Error deleting #{file.name} (#{file.id}): #{e.message}"
        end
      end
    else
      puts "\nNo RoboCoders files found"
    end
    
  rescue Google::Apis::Error => e
    puts "❌ Error: #{e.message}"
  end
end

list_google_drive_files
