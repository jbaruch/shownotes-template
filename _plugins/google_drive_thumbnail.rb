require 'net/http'
require 'uri'

module Jekyll
  class GoogleDriveThumbnailGenerator < Generator
    safe true
    priority :lowest

    THUMBNAIL_WIDTH = 400
    THUMBNAIL_HEIGHT = 300

    def generate(site)
      # Cache for extracted thumbnail URLs
      @thumbnail_cache = {}
      
      # Process all talks and extract Google Drive viewer URLs
      talks_collection = site.collections['talks']
      return unless talks_collection && talks_collection.docs
      
      talks_collection.docs.each do |talk|
        # Look for Google Drive URLs in the markdown content
        content = talk.content
        if content && content.include?('drive.google.com')
          # Extract Google Drive URL from markdown links
          drive_match = content.match(/\[.*?\]\((https:\/\/drive\.google\.com\/file\/d\/[^\/]+\/[^)]*)\)/)
          if drive_match
            drive_url = drive_match[1]
            file_id = extract_file_id(drive_url)
            if file_id
              viewer_url = extract_viewer_url(file_id)
              if viewer_url
                talk.data['thumbnail_url'] = viewer_url
                Jekyll.logger.info "Google Drive Thumbnail:", "Set thumbnail for #{talk.data['title'] || talk.basename}"
              end
            end
          end
        end
      end
    end

    private

    def extract_file_id(url)
      match = url.match(/\/d\/([a-zA-Z0-9_-]+)/)
      match ? match[1] : nil
    end

    def extract_viewer_url(file_id)
      return @thumbnail_cache[file_id] if @thumbnail_cache[file_id]

      local_thumbnail_dir = File.join('assets', 'images', 'thumbnails')
      Dir.mkdir(local_thumbnail_dir) unless Dir.exist?(local_thumbnail_dir)
      local_thumbnail_path = File.join(local_thumbnail_dir, "#{file_id}.jpg")

      if File.exist?(local_thumbnail_path)
        Jekyll.logger.info 'Google Drive Thumbnail:', "Using cached thumbnail for #{file_id}"
        return "/#{local_thumbnail_path}"
      end

      viewer_url = "https://lh3.googleusercontent.com/d/#{file_id}=w#{THUMBNAIL_WIDTH}-h#{THUMBNAIL_HEIGHT}"
      
      begin
        uri = URI.parse(viewer_url)
        response = nil
        limit = 5 # Max 5 redirects

        while limit > 0
          response = Net::HTTP.get_response(uri)
          
          if response.is_a?(Net::HTTPRedirection)
            # The 'location' header contains the new URL
            location = response['location']
            # Create a new URI object from the location header
            uri = URI.parse(location)
            limit -= 1
          else
            # Not a redirect, break the loop
            break
          end
        end

        if response.is_a?(Net::HTTPSuccess)
          File.open(local_thumbnail_path, 'wb') do |file|
            file.write(response.body)
          end
          Jekyll.logger.info 'Google Drive Thumbnail:', "Downloaded thumbnail for #{file_id}"
          @thumbnail_cache[file_id] = "/#{local_thumbnail_path}"
          return "/#{local_thumbnail_path}"
        else
          Jekyll.logger.warn 'Google Drive Thumbnail:', "Failed to download thumbnail for #{file_id} after following redirects. Final status: #{response.code}"
          return nil # Or a fallback image path
        end
      rescue StandardError => e
        Jekyll.logger.error 'Google Drive Thumbnail:', "Error downloading thumbnail for #{file_id}: #{e.message}"
        return nil # Or a fallback image path
      end
    end
  end
end
