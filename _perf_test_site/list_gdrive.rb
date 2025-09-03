#!/usr/bin/env ruby

require 'bundler/setup'
require 'google/apis/drive_v3'
require 'googleauth'

# Setup Google Drive
service = Google::Apis::DriveV3::DriveService.new
service.client_options.application_name = 'Shownotes Migration'

scope = Google::Apis::DriveV3::AUTH_DRIVE
authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open('Google API.json'),
  scope: scope
)
service.authorization = authorizer

puts "🔍 Listing all accessible folders..."

# List all folders
folders = service.list_files(
  q: "mimeType='application/vnd.google-apps.folder'",
  supports_all_drives: true,
  include_items_from_all_drives: true,
  page_size: 100
)

puts "Found #{folders.files.size} folders:"
folders.files.each do |folder|
  puts "  - #{folder.name} (ID: #{folder.id})"
end

puts "\n🔍 Looking for any PDFs in the drive..."

# List all PDFs
pdfs = service.list_files(
  q: "mimeType='application/pdf'",
  supports_all_drives: true,
  include_items_from_all_drives: true,
  page_size: 100
)

puts "Found #{pdfs.files.size} PDFs:"
pdfs.files.each do |pdf|
  puts "  - #{pdf.name} (ID: #{pdf.id})"
end
