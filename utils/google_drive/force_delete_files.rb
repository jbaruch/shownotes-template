#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

def force_delete_all_pdfs
  puts "Force deleting ALL PDF files from Google Drive..."
  
  # Initialize Google Drive service
  service = Google::Apis::DriveV3::DriveService.new
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: Google::Apis::DriveV3::AUTH_DRIVE
  )
  
  # Find all PDF files
  puts "🔍 Searching for all PDF files..."
  files = service.list_files(
    q: "mimeType='application/pdf'",
    supports_all_drives: true,
    include_items_from_all_drives: true,
    page_size: 1000
  )
  
  puts "📋 Found #{files.files.length} PDF files to delete"
  
  deleted_count = 0
  files.files.each do |file|
    begin
      puts "🗑️  Deleting: #{file.name} (#{file.id})"
      service.delete_file(file.id, supports_all_drives: true)
      deleted_count += 1
      puts "✅ Deleted: #{file.name}"
    rescue Google::Apis::ClientError => e
      puts "❌ Error deleting #{file.name}: #{e.message}"
    end
  end
  
  puts "\n🎯 Cleanup complete: #{deleted_count}/#{files.files.length} files deleted"
end

force_delete_all_pdfs
