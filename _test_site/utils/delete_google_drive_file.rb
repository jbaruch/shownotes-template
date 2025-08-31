#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

def delete_google_drive_file(file_id)
  puts "Deleting Google Drive file: #{file_id}"
  
  # Initialize Google Drive service
  service = Google::Apis::DriveV3::DriveService.new
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: Google::Apis::DriveV3::AUTH_DRIVE
  )
  
  begin
    service.delete_file(file_id, supports_all_drives: true)
    puts "✅ Successfully deleted file from Google Drive"
  rescue Google::Apis::Error => e
    puts "❌ Error deleting file: #{e.message}"
  end
end

if ARGV.length != 1
  puts "Usage: ruby delete_google_drive_file.rb FILE_ID"
  exit 1
end

delete_google_drive_file(ARGV[0])
