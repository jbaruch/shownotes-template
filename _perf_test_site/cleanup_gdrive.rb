#!/usr/bin/env ruby

# Load required gems (same ones used in migrate_talk.rb)
require 'bundler/setup'
require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'fileutils'
require 'nokogiri'

# Load the Google Drive upload module from migrate_talk.rb
require_relative 'migrate_talk'

# Create a minimal migrator instance just to access the Google Drive methods
class DriveCleanup
  def initialize
    # Copy the Google Drive setup from TalkMigrator
    setup_google_drive
  end
  
  private
  
  def setup_google_drive
    require 'google/apis/drive_v3'
    require 'googleauth'

    @drive_service = Google::Apis::DriveV3::DriveService.new
    @drive_service.client_options.application_name = 'Shownotes Migration'

    # Load service account credentials
    scope = Google::Apis::DriveV3::AUTH_DRIVE
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('Google API.json'),
      scope: scope
    )
    @drive_service.authorization = authorizer
    
    # Find the shared drive folder for presentations
    @presentations_folder_id = find_presentations_folder
    
    puts "✅ Google Drive setup complete. Presentations folder: #{@presentations_folder_id}"
  end
  
  def find_presentations_folder
    # Search for the "Presentations" folder in shared drives
    folders = @drive_service.list_files(
      q: "name='Presentations' and mimeType='application/vnd.google-apps.folder'",
      supports_all_drives: true,
      include_items_from_all_drives: true
    )
    
    if folders.files.empty?
      raise "No 'Presentations' folder found in accessible drives"
    end
    
    folders.files.first.id
  end
  
  public
  
  def cleanup_all_pdfs
    puts "🗑️  Cleaning up all PDFs from Google Drive..."
    
    # List all PDFs in the presentations folder
    files = @drive_service.list_files(
      q: "'#{@presentations_folder_id}' in parents and mimeType='application/pdf'",
      supports_all_drives: true,
      include_items_from_all_drives: true
    )
    
    puts "Found #{files.files.size} PDFs to delete"
    
    # Move each PDF to trash
    files.files.each do |file|
      puts "Trashing: #{file.name}"
      @drive_service.update_file(
        file.id, 
        Google::Apis::DriveV3::File.new(trashed: true),
        supports_all_drives: true
      )
    end
    
    puts "✅ All #{files.files.size} PDFs moved to trash"
  end
end

# Run the cleanup
begin
  cleanup = DriveCleanup.new
  cleanup.cleanup_all_pdfs
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
end
