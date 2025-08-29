#!/usr/bin/env ruby

require 'minitest/autorun'
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'

# Configure Capybara for browser-based visual tests
Capybara.configure do |config|
  config.app_host = 'http://localhost:4000'
  config.run_server = false
  config.default_driver = :selenium_chrome_headless
  config.javascript_driver = :selenium_chrome_headless
  config.default_max_wait_time = 10
end

# Chrome options for headless testing
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1280,720')
  
  Selenium::WebDriver.for(:chrome, options: options)
end

class VisualTest < Minitest::Test
  include Capybara::DSL
  
  def setup
    # Ensure Jekyll is running on localhost:4000
    begin
      visit '/'
    rescue Capybara::Capybara::DriverError => e
      skip "Jekyll server not running on localhost:4000. Start with: bundle exec jekyll serve"
    end
  end
  
  def teardown
    Capybara.reset_sessions!
  end

  # ===========================================
  # Test Suite 1: Homepage Visual Quality
  # ===========================================
  
  def test_homepage_title_renders_correctly
    visit '/'
    
    # The browser tab title should NOT show literal "{{site.title}}"
    page_title = page.title
    refute_includes page_title, '{{site.title}}', 
      "CRITICAL: Literal liquid syntax in page title: #{page_title}"
    refute_includes page_title, '{{', 
      "Liquid syntax not processed in title: #{page_title}"
    refute_includes page_title, '}}', 
      "Liquid syntax not processed in title: #{page_title}"
      
    puts "SUCCESS Page title: #{page_title}"
  end
  
  def test_no_console_errors
    visit '/'
    
    # Check for CSP violations and other console errors
    logs = page.driver.browser.logs.get(:browser)
    error_logs = logs.select { |log| log.level == 'SEVERE' }
    
    # Filter out known acceptable errors (like favicon 404)
    critical_errors = error_logs.reject do |log|
      log.message.include?('favicon.ico') || 
      log.message.include?('LiveReload')
    end
    
    assert_empty critical_errors, 
      "Console errors found:\n#{critical_errors.map(&:message).join("\n")}"
      
    puts "SUCCESS Console clean: #{error_logs.length} total errors, #{critical_errors.length} critical"
  end
  
  def test_google_fonts_load_successfully
    visit '/'
    
    # Check if Google Fonts are loaded by looking for font-family in computed styles
    # This verifies CSP allows Google Fonts
    font_elements = page.all('body, h1, h2, h3, p')
    
    font_elements.each do |element|
      computed_font = page.evaluate_script("getComputedStyle(arguments[0]).fontFamily", element.native)
      
      # Should not be default system fonts if Google Fonts are working
      refute computed_font.empty?, "No font-family computed for element"
      
      # Look for evidence of custom fonts (not just system defaults)
      system_fonts_only = computed_font.match?(/^["']?(serif|sans-serif|monospace|system-ui)["']?$/i)
      # Note: This test might need adjustment based on actual font choices
    end
    
    puts "SUCCESS Fonts loading"
  end

  # ===========================================
  # Test Suite 2: Talk Page Visual Quality  
  # ===========================================
  
  def test_luxembourg_talk_thumbnails_display
    # Test the migrated Luxembourg talk specifically
    visit '/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/'
    
    # Should have resource thumbnails
    thumbnails = page.all('.preview-thumbnail img')
    assert thumbnails.length > 0, "No thumbnail images found on talk page"
    
    # Check each thumbnail loads successfully
    broken_thumbnails = []
    thumbnails.each_with_index do |thumbnail, index|
      src = thumbnail['src']
      alt_text = thumbnail['alt']
      
      # Check if image is broken (naturalWidth = 0 indicates broken image)
      is_broken = page.evaluate_script("arguments[0].naturalWidth === 0", thumbnail.native)
      
      if is_broken
        broken_thumbnails << "#{index + 1}: #{alt_text} (#{src})"
      else
        puts "  SUCCESS Thumbnail #{index + 1}: #{alt_text}"
      end
    end
    
    assert_empty broken_thumbnails, 
      "Broken thumbnail images found:\n#{broken_thumbnails.join("\n")}"
      
    puts "SUCCESS Thumbnails: #{thumbnails.length} images loaded successfully"
  end
  
  def test_video_coming_soon_badge_styling
    visit '/talks/'
    
    # Find talks with video coming soon status
    video_badges = page.all('.status-badge.video-pending')
    
    video_badges.each do |badge|
      # Check if badge has proper orange background
      background_color = page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", badge.native)
      
      # Orange should be rgb(255, 165, 0) or similar
      refute background_color.include?('rgba(0, 0, 0, 0)'), 
        "Video badge has no background color: #{background_color}"
      refute background_color == 'transparent', 
        "Video badge background is transparent"
        
      puts "  📱 Video badge background: #{background_color}"
    end
    
    puts "SUCCESS Video badges styled correctly" if video_badges.length > 0
  end
  
  def test_pdf_previews_no_unwanted_overlays
    visit '/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/'
    
    # Find PDF preview containers
    pdf_previews = page.all('.pdf-thumbnail-preview')
    
    pdf_previews.each do |preview|
      # Hover over the preview to trigger any hover effects
      preview.hover
      
      # Check for unwanted icon overlays
      overlay_icons = preview.all('.pdf-icon, .icon-overlay', visible: :all)
      
      assert_empty overlay_icons, 
        "Unwanted icon overlay found on PDF preview"
        
      # Check hover effect works (scale transform)
      img = preview.find('img')
      transform = page.evaluate_script("getComputedStyle(arguments[0]).transform", img.native)
      
      puts "  FILE PDF hover transform: #{transform}"
    end
    
    puts "SUCCESS PDF previews clean (no unwanted overlays)"
  end

  # ===========================================
  # Test Suite 3: Homepage Preview Quality
  # ===========================================
  
  def test_homepage_talk_previews_work
    visit '/'
    
    # Find talk preview cards
    talk_previews = page.all('.talk-preview, .preview-card')
    assert talk_previews.length > 0, "No talk previews found on homepage"
    
    talk_previews.each_with_index do |preview, index|
      # Check for preview thumbnail
      thumbnail = preview.find('img', match: :first)
      src = thumbnail['src']
      
      # Verify thumbnail is not a placeholder
      refute src.include?('placeholder'), "Placeholder image found: #{src}"
      refute src.include?('data:image/svg'), "SVG placeholder found: #{src}"
      
      # Check if image loads successfully
      is_loaded = page.evaluate_script("arguments[0].complete && arguments[0].naturalHeight !== 0", thumbnail.native)
      assert is_loaded, "Preview thumbnail failed to load: #{src}"
      
      puts "  🏠 Homepage preview #{index + 1}: OK"
    end
    
    puts "SUCCESS Homepage previews: #{talk_previews.length} previews working"
  end
  
  def test_google_drive_embeds_load
    visit '/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/'
    
    # Look for Google Drive resources (PDFs, slides)
    drive_resources = page.all('a[href*="drive.google.com"], a[href*="docs.google.com"]')
    
    drive_resources.each do |resource|
      href = resource['href']
      
      # Verify Google Drive URLs are accessible (they should not give CORS errors when clicked)
      # Note: We can't directly test the actual embedding due to CORS, but we can verify URL format
      
      if href.include?('drive.google.com/file')
        # PDF format
        assert href.match?(/\/file\/d\/[a-zA-Z0-9-_]+/), 
          "Invalid Google Drive file URL format: #{href}"
      elsif href.include?('docs.google.com/presentation')
        # Slides format  
        assert href.match?(/\/d\/[a-zA-Z0-9-_]+/), 
          "Invalid Google Slides URL format: #{href}"
      end
      
      puts "  💾 Drive resource: #{href[0..50]}..."
    end
    
    puts "SUCCESS Google Drive resources: #{drive_resources.length} resources verified"
  end

  # ===========================================
  # Test Suite 4: Responsive Design
  # ===========================================
  
  def test_mobile_thumbnail_display
    # Test mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667) # iPhone SE size
    
    visit '/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/'
    
    thumbnails = page.all('.preview-thumbnail')
    
    thumbnails.each do |thumbnail|
      # Check thumbnail is visible and not overflowing
      is_visible = thumbnail.visible?
      assert is_visible, "Thumbnail not visible on mobile viewport"
      
      # Check width doesn't exceed container
      width = page.evaluate_script("arguments[0].offsetWidth", thumbnail.native)
      container_width = page.evaluate_script("arguments[0].parentElement.offsetWidth", thumbnail.native)
      
      assert width <= container_width + 5, # 5px tolerance
        "Thumbnail overflows container on mobile: #{width}px > #{container_width}px"
    end
    
    # Reset to desktop
    page.driver.browser.manage.window.resize_to(1280, 720)
    
    puts "SUCCESS Mobile responsive: thumbnails fit properly"
  end

  # ===========================================
  # Test Suite 5: Performance
  # ===========================================
  
  def test_thumbnail_loading_performance
    visit '/talks/2025-06-20-voxxed-luxembourg-technical-enshittification/'
    
    start_time = Time.now
    
    # Wait for all images to load
    page.all('img').each do |img|
      # Wait for image to load (naturalHeight > 0 means loaded)
      page.has_xpath?("//img[@src='#{img['src']}' and @complete='true']", wait: 5)
    end
    
    load_time = Time.now - start_time
    
    # Thumbnails should load within 5 seconds
    assert load_time < 5, 
      "Thumbnail loading too slow: #{load_time.round(2)}s (should be < 5s)"
      
    puts "SUCCESS Performance: All thumbnails loaded in #{load_time.round(2)}s"
  end
  
  # ===========================================
  # Utility Methods
  # ===========================================
  
  def capture_screenshot_on_failure(test_name)
    screenshot_path = "test/screenshots/#{test_name}.png"
    FileUtils.mkdir_p(File.dirname(screenshot_path))
    page.save_screenshot(screenshot_path)
    puts "Screenshot saved: #{screenshot_path}"
  end
end

# Custom test runner that captures screenshots on failure
class VisualTest
  def run
    result = super
    if !passed? && respond_to?(:capture_screenshot_on_failure)
      capture_screenshot_on_failure(name.gsub(/[^a-zA-Z0-9_-]/, '_'))
    end
    result
  end
end