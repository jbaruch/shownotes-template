#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

def force_delete_files
  puts "Force deleting Google Drive files..."
  
  # Initialize Google Drive service
  service = Google::Apis::DriveV3::DriveService.new
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: Google::Apis::DriveV3::AUTH_DRIVE
  )
  
  file_ids = [
    '1qm-knGzfJSw-quDgBs9-dNfSkQBoh76D',
    '1FqbktQtRdgYDcsP37kM4uwpYc2r2jh7w'
  ]
  
  file_ids.each do |file_id|
    begin
      # Try to get file info first
      file_info = service.get_file(file_id, supports_all_drives: true)
      puts "Found file: #{file_info.name}"
      
      # Try to move to trash first
      file_object = Google::Apis::DriveV3::File.new(trashed: true)
      service.update_file(file_id, file_object, supports_all_drives: true)
      puts "✅ Moved to trash: #{file_id}"
      
      # Then permanently delete
      service.delete_file(file_id, supports_all_drives: true)
      puts "✅ Permanently deleted: #{file_id}"
      
    rescue Google::Apis::ClientError => e
      puts "❌ Error with #{file_id}: #{e.message}"
    end
  end
end

force_delete_files
