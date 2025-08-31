#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

# Test Google Drive upload with new permissions
begin
  service = Google::Apis::DriveV3::DriveService.new
  service.client_options.application_name = 'Shownotes Migration Test'
  
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: ['https://www.googleapis.com/auth/drive']
  )
  
  folder_id = '1rE43G9IvgMg0S9frwA7TaEc-XEDUL8ib'
  
  puts "Testing Google Drive upload with new permissions..."
  
  # Create a small test file
  File.write('test_upload.txt', 'Test file for Google Drive upload')
  
  file_metadata = Google::Apis::DriveV3::File.new(
    name: 'test_permissions.txt',
    parents: [folder_id]
  )
  
  uploaded_file = service.create_file(file_metadata, upload_source: 'test_upload.txt')
  puts "SUCCESS: Test file uploaded with ID: #{uploaded_file.id}"
  puts "URL: https://drive.google.com/file/d/#{uploaded_file.id}/view"
  
  # Clean up
  service.delete_file(uploaded_file.id)
  File.delete('test_upload.txt')
  puts "Test completed and cleaned up"
  
rescue => e
  puts "ERROR: #{e.message}"
  File.delete('test_upload.txt') if File.exist?('test_upload.txt')
end
