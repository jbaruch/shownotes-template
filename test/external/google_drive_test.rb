#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'

# Test Google Drive API access
begin
  service = Google::Apis::DriveV3::DriveService.new
  service.client_options.application_name = 'Shownotes Migration Test'
  
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open('Google API.json'),
    scope: ['https://www.googleapis.com/auth/drive']
  )
  
  folder_id = '1rE43G9IvgMg0S9frwA7TaEc-XEDUL8ib'
  
  puts "Testing Google Drive API access..."
  
  # Try to list files in the folder
  response = service.list_files(
    q: "'#{folder_id}' in parents",
    page_size: 10,
    fields: 'nextPageToken, files(id, name, createdTime, parents)'
  )
  
  puts "Files in folder #{folder_id}:"
  response.files.each do |file|
    puts "  #{file.name} (#{file.id}) - #{file.created_time}"
  end
  
  # Try to get folder info
  folder_info = service.get_file(folder_id, fields: 'id, name, permissions, owners')
  puts "\nFolder info:"
  puts "  Name: #{folder_info.name}"
  puts "  ID: #{folder_info.id}"
  
  # Try to upload a small test file
  puts "\nTesting file upload..."
  
  file_metadata = Google::Apis::DriveV3::File.new(
    name: 'test_upload.txt',
    parents: [folder_id]
  )
  
  uploaded_file = service.create_file(file_metadata, upload_source: 'test_upload.txt')
  puts "SUCCESS: Test file uploaded with ID: #{uploaded_file.id}"
  
  # Clean up - delete the test file
  service.delete_file(uploaded_file.id)
  puts "Test file cleaned up"
  
rescue => e
  puts "ERROR: #{e.message}"
  puts "Full error: #{e.inspect}"
end
