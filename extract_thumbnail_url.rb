#!/usr/bin/env ruby

require 'net/http'
require 'uri'

def extract_thumbnail_url(file_id)
  begin
    uri = URI("https://drive.google.com/file/d/#{file_id}/view")
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      # Extract the drive-viewer URL from the HTML
      match = response.body.match(/drive-viewer\/([^"]+)/)
      if match
        return "https://drive.google.com/drive-viewer/#{match[1]}"
      end
    end
  rescue => e
    puts "Error extracting thumbnail for #{file_id}: #{e.message}"
  end
  
  nil
end

# Test with the file ID
file_id = "1j6zGFgkd-G1YsDiHLPra085nVsD8mw2m"
thumbnail_url = extract_thumbnail_url(file_id)
puts "Thumbnail URL: #{thumbnail_url}"
