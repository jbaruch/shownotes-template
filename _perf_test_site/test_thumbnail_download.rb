#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'

def download_file_debug(url, local_path)
  require 'fileutils'
  FileUtils.mkdir_p(File.dirname(local_path))
  
  puts "DEBUG: Downloading #{url}"
  puts "DEBUG: To #{local_path}"
  
  uri = URI.parse(url)
  puts "DEBUG: Host: #{uri.host}"
  puts "DEBUG: Request URI: #{uri.request_uri}"
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if uri.scheme == 'https'
  
  request_path = uri.request_uri
  puts "DEBUG: Making request to: #{request_path}"
  
  response = http.get(request_path)
  puts "DEBUG: Response code: #{response.code}"
  puts "DEBUG: Response message: #{response.message}"
  puts "DEBUG: Content-Type: #{response['content-type']}"
  puts "DEBUG: Content-Length: #{response['content-length']}"
  
  if response.code.to_i.between?(200, 299)
    File.open(local_path, 'wb') { |file| file.write(response.body) }
    puts "DEBUG: File written successfully"
    true
  else
    puts "DEBUG: Download failed"
    false
  end
end

# Test the thumbnail download
drive_url = "https://drive.google.com/file/d/18mUB9575k5tDnztKJS3f1hztsgV_neND/view"
file_id = drive_url.match(/\/d\/([a-zA-Z0-9_-]+)/)[1]
thumbnail_url = "https://lh3.googleusercontent.com/d/#{file_id}=w400-h300"
local_path = "assets/images/thumbnails/test-thumbnail.png"

puts "Testing thumbnail download..."
puts "Drive URL: #{drive_url}"
puts "File ID: #{file_id}"
puts "Thumbnail URL: #{thumbnail_url}"

result = download_file_debug(thumbnail_url, local_path)
puts "Result: #{result}"

if result && File.exist?(local_path)
  puts "File size: #{File.size(local_path)} bytes"
end
