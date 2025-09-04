#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'uri'
require 'selenium-webdriver'
require 'fileutils'

class VisualTest < Minitest::Test
  JEKYLL_BASE_URL = 'http://localhost:4000'
  
  def setup
    # Test if Jekyll server is running, start it if not
    begin
      uri = URI.parse(JEKYLL_BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 5
      response = http.get('/')
      @server_running = response.code.to_i.between?(200, 399)
    rescue
      @server_running = false
    end
    
    # Start Jekyll server if not running
    unless @server_running
      puts "Building and starting Jekyll server for visual tests..."
      
      # First, build the site to ensure all content is generated
      puts "Building Jekyll site..."
      build_result = system('bundle exec jekyll build --config _config_test.yml --quiet')
      assert build_result, "Failed to build Jekyll site"
      
      # Then start the server
      puts "Starting Jekyll server..."
      port = URI.parse(JEKYLL_BASE_URL).port
      @jekyll_pid = spawn("bundle exec jekyll serve --config _config_test.yml --port #{port} --detach --skip-initial-build", 
                         :out => '/dev/null', :err => '/dev/null')
      
      # Wait for server to start (up to 30 seconds)
      30.times do
        sleep 1
        begin
          uri = URI.parse(JEKYLL_BASE_URL)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 2
          response = http.get('/')
          if response.code.to_i.between?(200, 399)
            @server_running = true
            puts "Jekyll server started successfully"
            break
          end
        rescue
          # Continue waiting
        end
      end
      
      assert @server_running, "Failed to start Jekyll server after 30 seconds"
    end
  end
  
  def teardown
    # Clean up Jekyll server if we started it
    if @jekyll_pid
      begin
        Process.kill('TERM', @jekyll_pid)
        Process.wait(@jekyll_pid)
      rescue
        # Process may have already exited
      end
    end
  end

  # ===========================================
  # Test Suite 1: Homepage Accessibility
  # ===========================================
  
  def test_homepage_loads_successfully
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    assert response.code.to_i.between?(200, 399), 
      "Homepage failed to load: HTTP #{response.code}"
      
    # Check that the response contains expected content
    refute response.body.include?('{{site.title}}'), 
      "CRITICAL: Literal liquid syntax found in homepage HTML"
    refute response.body.include?('{{'), 
      "Unprocessed liquid syntax found in homepage"
      
    puts "SUCCESS Homepage loads successfully (HTTP #{response.code})"
  end
  
  def test_any_talk_page_loads
    # Find any available talk page dynamically
    talk_url = find_any_talk_url
    
    if talk_url.nil?
      skip "❌ SKIPPED: No talk pages found - repository has no talks"
      return
    end
    
    uri = URI.parse("#{JEKYLL_BASE_URL}#{talk_url}")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert response.code.to_i.between?(200, 399), 
      "Talk page failed to load: HTTP #{response.code} for #{talk_url}"
      
    # Check for basic expected content structure
    assert response.body.include?('<title>'), 
      "Talk page missing title tag"
    assert response.body.length > 100, 
      "Talk page content seems too short"
      
    puts "SUCCESS Talk page loads successfully (HTTP #{response.code}) for #{talk_url}"
  end

  # ===========================================
  # Test Suite 2: Resource Links Work
  # ===========================================
  
  def test_talk_list_page_loads
    uri = URI.parse("#{JEKYLL_BASE_URL}/talks/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    assert response.code.to_i.between?(200, 399), 
      "Talks list page failed to load: HTTP #{response.code}"
      
    # Verify that the page contains redirect content
    assert response.body.include?('window.location.replace'), 
      "Talks page should contain JavaScript redirect"
      
    puts "SUCCESS Talks list page loads and redirects (HTTP #{response.code})"
  end

  # ===========================================
  # Test Suite 3: Content Quality Checks
  # ===========================================
  
  def test_no_error_pages
    # Base pages that should always exist
    base_test_pages = [
      '/',
      '/talks/',  # Now always exists with redirect
    ]
    
    # Add any specific talk pages that exist
    specific_talk_pages = find_all_talk_urls
    
    test_pages = base_test_pages + specific_talk_pages
    
    test_pages.each do |page_path|
      uri = URI.parse("#{JEKYLL_BASE_URL}#{page_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.path)
      
      refute response.code.to_i.between?(400, 599), 
        "Error page found: #{page_path} returned HTTP #{response.code}"
        
      puts "  SUCCESS #{page_path}: HTTP #{response.code}"
    end
    
    if specific_talk_pages.empty?
      puts "  INFO: No talk pages found - tested base pages only"
    else
      puts "  INFO: Tested #{specific_talk_pages.length} talk page(s)"
    end
    
    puts "SUCCESS All test pages load without errors"
  end
  
  def test_html_structure_validity
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    # Basic HTML structure checks
    assert response.body.include?('<!DOCTYPE html>'), 
      "Missing HTML5 doctype"
    assert response.body.include?('<html'), 
      "Missing html tag"
    assert response.body.include?('<head>'), 
      "Missing head section"
    assert response.body.include?('<body>'), 
      "Missing body section"
      
    puts "SUCCESS HTML structure is valid"
  end

  # ===========================================
  # Test Suite 4: Resource Integration
  # ===========================================
  
  def test_no_liquid_template_errors_in_html
    test_pages = ['/']
    
    # Add any available talk pages
    talk_urls = find_all_talk_urls
    test_pages += talk_urls
    
    test_pages.each do |page_path|
      uri = URI.parse("#{JEKYLL_BASE_URL}#{page_path}")
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.path)
      
      # Check for unprocessed liquid syntax in HTML
      liquid_errors = response.body.scan(/\{\{[^}]+\}\}|\{%[^%]+%\}/)
      
      assert_empty liquid_errors, 
        "Unprocessed liquid syntax found in #{page_path}: #{liquid_errors}"
        
      puts "  SUCCESS #{page_path}: No liquid template errors"
    end
    
    puts "SUCCESS No liquid template errors in generated HTML"
  end
  
  def test_local_thumbnails_are_displayed
    # Check homepage for local thumbnails (where previews are shown)
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    # Look for local thumbnail URLs in the HTML
    local_thumbnails = response.body.scan(/\/assets\/images\/thumbnails\/[^"]+\.png/)
    placeholder_thumbnails = response.body.scan(/\/assets\/images\/placeholder-thumbnail\.svg/)
    
    thumbnail_count = local_thumbnails.length + placeholder_thumbnails.length
    
    # If no thumbnails on homepage, check if any talk page exists and check it
    if thumbnail_count == 0
      talk_url = find_any_talk_url
      
      if talk_url
        uri = URI.parse("#{JEKYLL_BASE_URL}#{talk_url}")
        response = http.get(uri.path)
        local_thumbnails = response.body.scan(/\/assets\/images\/thumbnails\/[^"]+\.png/)
        placeholder_thumbnails = response.body.scan(/\/assets\/images\/placeholder-thumbnail\.svg/)
        thumbnail_count = local_thumbnails.length + placeholder_thumbnails.length
      else
        # No talks exist, skip the test
        skip "❌ SKIPPED: No talks found - cannot test thumbnails without content"
        return
      end
    end
    
    assert thumbnail_count > 0, 
      "No local thumbnail or placeholder URLs found in homepage or talk page HTML"
      
    puts "SUCCESS Found #{local_thumbnails.length} local thumbnails and #{placeholder_thumbnails.length} placeholders in generated HTML"
  end

  def test_no_remote_thumbnail_urls
    # This test ensures we're using local thumbnails only (no remote dependencies)
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    # Check for any remote thumbnail URLs that could cause CORS/loading issues
    remote_thumbnails = response.body.scan(/https:\/\/[^\/]+\/.*\.(png|jpg|jpeg|gif|webp)/)
    
    # Also check any talk page if one exists
    talk_url = find_any_talk_url
    if talk_url
      uri = URI.parse("#{JEKYLL_BASE_URL}#{talk_url}")
      talk_response = http.get(uri.path)
      remote_thumbnails += talk_response.body.scan(/https:\/\/[^\/]+\/.*\.(png|jpg|jpeg|gif|webp)/)
    end
    
    # Filter out known safe external images (not thumbnails)
    problematic_remotes = remote_thumbnails.reject do |url|
      url.include?('gravatar.com') || # Profile images
      url.include?('github.com/') ||  # GitHub assets
      url.include?('raw.githubusercontent.com') # GitHub raw files
    end
    
    assert_equal 0, problematic_remotes.length,
      "❌ Found #{problematic_remotes.length} remote thumbnail URLs that could cause loading issues: #{problematic_remotes.join(', ')}"
    
    puts "SUCCESS Using only local thumbnails and safe external assets"
  end

  def test_thumbnail_structure_and_accessibility
    # Check homepage for proper thumbnail structure
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    html = response.body
    
    # Count talk items that should have thumbnails
    talk_items = html.scan(/<article class="talk-list-item">/).length
    
    # Skip if no talks
    if talk_items == 0
      skip "❌ SKIPPED: No talks found - cannot test thumbnail structure"
      return
    end
    
    # Count actual thumbnail images
    thumbnail_images = html.scan(/<img[^>]+class="[^"]*preview-image[^"]*"/).length
    pdf_thumbnails = html.scan(/<div class="pdf-thumbnail-preview">/).length
    
    # Each talk should have either a thumbnail image or a placeholder
    assert thumbnail_images > 0 || pdf_thumbnails > 0,
      "❌ THUMBNAIL STRUCTURE MISSING: Found #{talk_items} talks but no thumbnail images or containers"
    
    # Check for proper thumbnail container structure
    preview_containers = html.scan(/<div class="talk-preview-small">/).length
    assert preview_containers >= talk_items * 0.8, # Allow some talks without previews
      "❌ PREVIEW CONTAINERS MISSING: Expected ~#{talk_items} preview containers, found #{preview_containers}"
    
    # Check for accessible thumbnail images (alt attributes)
    thumbnail_imgs_with_alt = html.scan(/<img[^>]+alt="[^"]*"[^>]*class="[^"]*preview-image[^"]*"/).length +
                              html.scan(/<img[^>]+class="[^"]*preview-image[^"]*"[^>]+alt="[^"]*"/).length
    if thumbnail_images > 0
      assert thumbnail_imgs_with_alt >= thumbnail_images * 0.9, # Allow some missing alt tags
        "❌ ACCESSIBILITY ISSUE: #{thumbnail_images} thumbnails found but only #{thumbnail_imgs_with_alt} have alt attributes"
    end
    
    puts "SUCCESS Thumbnail structure validated: #{thumbnail_images} images, #{pdf_thumbnails} PDF containers, #{preview_containers} preview containers"
  end

  def test_featured_talks_have_thumbnails
    # Check that featured talks section specifically has thumbnails
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    html = response.body
    
    # Look for featured talks section
    featured_section_match = html.match(/<section[^>]*featured-talks[^>]*>(.*?)<\/section>/m)
    
    if featured_section_match
      featured_html = featured_section_match[1]
      
      # Count featured talk cards
      featured_cards = featured_html.scan(/<article class="talk-card featured">/).length
      
      if featured_cards > 0
        # Count thumbnails in featured section
        featured_thumbnails = featured_html.scan(/drive\.google\.com\/thumbnail/).length
        featured_images = featured_html.scan(/<img[^>]+class="[^"]*preview-image[^"]*"/).length
        
        assert featured_thumbnails > 0 || featured_images > 0,
          "❌ FEATURED TALKS MISSING THUMBNAILS: Found #{featured_cards} featured talks but no thumbnails"
        
        puts "SUCCESS Featured talks have thumbnails: #{featured_cards} cards, #{featured_thumbnails} Drive thumbnails, #{featured_images} images"
      else
        puts "INFO No featured talk cards found - may be using different layout"
      end
    else
      puts "INFO No featured talks section found - checking regular talk list"
    end
  end

  # ===========================================
  # Performance and Basic Quality
  # ===========================================
  
  def test_reasonable_page_size
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    page_size_kb = response.body.length / 1024.0
    
    # Homepage should be reasonably sized (not bloated)
    assert page_size_kb < 500, 
      "Homepage too large: #{page_size_kb.round(1)}KB (should be < 500KB)"
      
    puts "SUCCESS Homepage size reasonable: #{page_size_kb.round(1)}KB"
  end
  
  def test_no_common_broken_links
    # Test the homepage for broken link patterns
    uri = URI.parse(JEKYLL_BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get('/')
    
    # Also test any available talk page if one exists
    talk_url = find_any_talk_url
    if talk_url
      talk_uri = URI.parse("#{JEKYLL_BASE_URL}#{talk_url}")
      talk_response = http.get(talk_uri.path)
      response.body += "\n" + talk_response.body # Combine both for testing
    end
    
    # Check for common broken link patterns in HTML
    broken_patterns = [
      'href="http://http://',
      'href="https://https://',
      'src="http://http://',
      'src="https://https://',
      'href="#"',
      'href="javascript:void(0)"'
    ]
    
    broken_patterns.each do |pattern|
      refute response.body.include?(pattern), 
        "Broken link pattern found: #{pattern}"
    end
    
    puts "SUCCESS No common broken link patterns found"
  end

  def test_capture_thumbnail_screenshots
    # Ensure screenshot directory exists
    screenshots_dir = "test/screenshots/thumbnails"
    FileUtils.mkdir_p(screenshots_dir)

    # Set up Selenium WebDriver with Chrome in headless mode
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1280,720')

    begin
      driver = Selenium::WebDriver.for(:chrome, options: options)
      driver.get(JEKYLL_BASE_URL)

      # Wait for thumbnails to be potentially loaded
      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { driver.find_elements(css: '.talk-preview-small, .talk-preview-normal').any? }

      # Find all thumbnail preview containers
      thumbnails = driver.find_elements(css: '.talk-preview-small, .talk-preview-normal')

      assert_operator thumbnails.length, :>, 0, "No thumbnails found to screenshot"

      # Take a screenshot of the page showing all thumbnails
      screenshot_path = File.join(screenshots_dir, "thumbnails_page.png")
      driver.save_screenshot(screenshot_path)
      puts "  SUCCESS Captured page screenshot with #{thumbnails.length} thumbnails: #{screenshot_path}"
      
      # Verify each thumbnail is visible and properly loaded
      thumbnails.each_with_index do |thumbnail, i|
        assert thumbnail.displayed?, "Thumbnail #{i + 1} is not displayed"
        
        # Check if thumbnail has loaded content (look for img elements or background images)
        img_elements = thumbnail.find_elements(tag_name: 'img')
        background_style = thumbnail.style('background-image')
        
        has_content = img_elements.any? { |img| img.attribute('src') && !img.attribute('src').empty? } ||
                     (background_style && background_style != 'none')
        
        if has_content
          puts "  SUCCESS Thumbnail #{i + 1} has visual content"
        else
          puts "  WARNING Thumbnail #{i + 1} may not have loaded visual content"
        end
      end
      
      puts "SUCCESS Verified #{thumbnails.length} thumbnails on page."
    rescue Selenium::WebDriver::Error::WebDriverError => e
      skip "Chrome WebDriver not available: #{e.message}"
    ensure
      driver&.quit
    end
  end

private

  def find_any_talk_url
    # /talks/ now has a meta redirect to homepage where talks are properly formatted
    # Look for talk links on the homepage since /talks/ redirects there
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    # Look for talk links in the homepage HTML
    talk_links = response.body.scan(/href="(\/talks\/[^"]+)"/).flatten
    talk_links.first # Return the first talk URL found, or nil if none
  end

  def find_all_talk_urls
    # /talks/ now has a meta redirect to homepage where talks are properly formatted
    # Look for talk links on the homepage since /talks/ redirects there
    uri = URI.parse("#{JEKYLL_BASE_URL}/")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.get(uri.path)
    
    # Look for talk links in the homepage HTML
    talk_links = response.body.scan(/href="(\/talks\/[^"]+)"/).flatten
    talk_links.uniq # Return all unique talk URLs found
  end
end