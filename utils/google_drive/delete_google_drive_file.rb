#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

def permanently_delete_all_files
  puts "🗑️  Permanently deleting ALL files from Google Drive..."
  
  # Initialize Google Drive service
  service = Google::Apis::DriveV3::DriveService.new
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: Google::Apis::DriveV3::AUTH_DRIVE
  )
  
  # Get all files (including trashed ones)
  puts "🔍 Finding all files (including trashed)..."
  files = service.list_files(
    q: "",  # No filter - get everything
    supports_all_drives: true,
    include_items_from_all_drives: true,
    page_size: 1000
  )
  
  puts "📋 Found #{files.files.length} files to permanently delete"
  
  deleted_count = 0
  files.files.each do |file|
    begin
      puts "🗑️  Permanently deleting: #{file.name} (#{file.id})"
      service.delete_file(file.id, supports_all_drives: true)
      deleted_count += 1
      puts "✅ Permanently deleted: #{file.name}"
    rescue Google::Apis::Error => e
      puts "❌ Error deleting #{file.name}: #{e.message}"
    end
  end
  
  puts "\n🎯 Permanent cleanup complete: #{deleted_count}/#{files.files.length} files deleted"
end

permanently_delete_all_files
