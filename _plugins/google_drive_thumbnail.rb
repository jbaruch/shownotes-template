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
        # Generate expected local thumbnail filename based on talk file
        talk_slug = File.basename(talk.basename, '.md')
        local_thumbnail_path = "/assets/images/thumbnails/#{talk_slug}-thumbnail.png"
        
        # Check if local thumbnail exists first (preferred to avoid CORB)
        if File.exist?("assets/images/thumbnails/#{talk_slug}-thumbnail.png")
          talk.data['thumbnail_url'] = local_thumbnail_path
          Jekyll.logger.info "Google Drive Thumbnail:", "Using local thumbnail for #{talk.data['title'] || talk.basename}"
        else
          # Look for Google Drive URLs in the markdown content for remote thumbnails
          content = talk.content
          if content && content.include?('drive.google.com')
            # Extract Google Drive URL from markdown links
            drive_match = content.match(/\[.*?\]\((https:\/\/drive\.google\.com\/file\/d\/[^\/]+\/[^)]*)\)/)
            if drive_match
              drive_url = drive_match[1]
              file_id = extract_file_id(drive_url)
              if file_id
                # Generate direct Google Drive thumbnail API URL (without size params to avoid 404s)
                thumbnail_url = "https://lh3.googleusercontent.com/d/#{file_id}"
                talk.data['thumbnail_url'] = thumbnail_url
                Jekyll.logger.info "Google Drive Thumbnail:", "Using remote thumbnail for #{talk.data['title'] || talk.basename} (CORB may block)"
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
  end
end
