module Jekyll
  class GoogleDriveThumbnailGenerator < Generator
    safe true
    priority :lowest

    THUMBNAIL_WIDTH = 400
    THUMBNAIL_HEIGHT = 300

    def generate(site)
      # Process all talks and extract Google Drive thumbnail URLs
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
              # Generate direct Google Drive thumbnail API URL
              thumbnail_url = "https://lh3.googleusercontent.com/d/#{file_id}=w#{THUMBNAIL_WIDTH}-h#{THUMBNAIL_HEIGHT}"
              talk.data['thumbnail_url'] = thumbnail_url
              Jekyll.logger.info "Google Drive Thumbnail:", "Set thumbnail for #{talk.data['title'] || talk.basename}"
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
  end
end
