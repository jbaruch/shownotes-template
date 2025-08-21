# frozen_string_literal: true

require 'minitest/autorun'
require 'capybara/minitest'
require 'selenium-webdriver'

# End-to-end tests for User Workflows
# Maps to Gherkin: "QR code verification workflow during presentation" + "Post-talk resource access workflow"
class UserWorkflowTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    setup_capybara
    start_test_server
  end

  def teardown
    Capybara.reset_sessions!
    stop_test_server
  end

  # Maps to Gherkin: QR code verification workflow during presentation
  def test_qr_code_verification_workflow_during_presentation
    # Simulate attendee scanning QR code during talk
    visit '/talks/jsconf-2024/modern-javascript-patterns/'
    
    # Page should load within reasonable time (simulate conference Wi-Fi)
    page_load_time = measure_page_load_time
    assert page_load_time < 5.0, "Page should load within 5 seconds, took #{page_load_time}s"
    
    # Verify correct content is displayed
    assert_selector 'h1.talk-title', text: 'Modern JavaScript Patterns',
                    'Talk title should be prominently displayed'
    
    assert_selector '.speaker', text: 'Jane Developer',
                    'Speaker name should be visible'
    
    assert_selector '.conference', text: 'JSConf 2024',
                    'Conference name should be displayed'
    
    # Verify page is bookmarkable
    current_url = page.current_url
    assert_match %r{/talks/jsconf-2024/modern-javascript-patterns/$}, current_url,
                 'URL should be clean and bookmarkable'
    
    # Verify URL is shareable (clean, meaningful)
    refute_match /[?&]/, current_url, 'URL should not contain query parameters'
    assert_match /talks/, current_url, 'URL should clearly indicate it\'s a talk page'
  end

  # Maps to Gherkin: Post-talk resource access workflow
  def test_post_talk_resource_access_workflow
    # Simulate user returning to bookmarked page after talk
    bookmark_url = '/talks/jsconf-2024/modern-javascript-patterns/'
    
    # Return to bookmarked page
    visit bookmark_url
    
    # Page should load reliably
    assert_selector 'h1.talk-title', 'Page should load reliably from bookmark'
    
    # Should easily find slides and presentation materials
    assert_selector '.resource-item.resource-slides', 'Slides section should be present'
    
    slides_link = find('.resource-item.resource-slides a')
    assert_includes slides_link[:href], 'slides.example.com',
                    'Slides link should point to slides URL'
    
    # Should see code repositories or demos
    assert_selector '.resource-item.resource-code', 'Code repository section should be present'
    
    code_link = find('.resource-item.resource-code a')
    assert_includes code_link[:href], 'github.com',
                    'Code link should point to GitHub repository'
    
    # Should find relevant links mentioned during talk
    assert_selector '.resource-item.resource-links', 'Additional links section should be present'
    
    # Resources should be organized in logical, scannable order
    resource_sections = all('.resource-item')
    assert resource_sections.length >= 2, 'Should have multiple organized resource sections'
    
    # Verify resource order makes sense (slides first, then code, then additional links)
    first_resource = resource_sections.first
    assert first_resource[:class].include?('resource-slides'), 'Slides should appear first'
  end

  # Test mobile responsiveness during user workflow
  def test_mobile_user_workflow
    # Simulate mobile device viewport
    resize_window_to_mobile
    
    visit '/talks/jsconf-2024/modern-javascript-patterns/'
    
    # Content should fit within mobile viewport
    page_width = page.evaluate_script('document.documentElement.scrollWidth')
    viewport_width = page.evaluate_script('window.innerWidth')
    
    assert page_width <= viewport_width, 'Content should fit within mobile viewport without horizontal scroll'
    
    # Touch targets should be appropriately sized
    links = all('a')
    links.each do |link|
      link_height = link.evaluate_script('this.offsetHeight')
      assert link_height >= 44, 'Touch targets should be at least 44px for accessibility'
    end
    
    # Text should be readable without zooming
    body_font_size = page.evaluate_script('window.getComputedStyle(document.body).fontSize')
    font_size_px = body_font_size.to_f
    assert font_size_px >= 16, 'Body text should be at least 16px for mobile readability'
  end

  # Test sharing workflow
  def test_sharing_workflow
    visit '/talks/jsconf-2024/modern-javascript-patterns/'
    
    # Verify social media meta tags for proper sharing
    assert_selector 'meta[property="og:title"]', visible: false
    assert_selector 'meta[property="og:description"]', visible: false
    assert_selector 'meta[property="og:type"]', visible: false
    
    # Verify page title is formatted for sharing
    page_title = page.title
    assert_includes page_title, 'Modern JavaScript Patterns'
    assert_includes page_title, 'Jane Developer'
    assert_includes page_title, 'JSConf 2024'
  end

  # Test accessibility during user workflow
  def test_accessibility_user_workflow
    visit '/talks/jsconf-2024/modern-javascript-patterns/'
    
    # Test keyboard navigation
    page.execute_script('document.querySelector("a").focus()')
    
    # Tab through interactive elements
    send_keys :tab
    focused_element = page.evaluate_script('document.activeElement.tagName')
    assert %w[A BUTTON INPUT].include?(focused_element), 'Tab should move focus to interactive elements'
    
    # Verify screen reader accessibility
    assert_selector 'h1', 'Page should have proper heading structure'
    assert_selector '[role], main, article, section', 'Page should use semantic HTML or ARIA roles'
    
    # Check for alt text on images
    images = all('img')
    images.each do |img|
      assert img[:alt], 'All images should have alt text'
    end
  end

  # Test error handling in user workflow
  def test_error_handling_user_workflow
    # Test 404 handling
    visit '/talks/nonexistent-conference/nonexistent-talk/'
    
    # Should show helpful 404 page
    assert_text '404', '404 page should be displayed for nonexistent talks'
    assert_text 'not found', '404 page should indicate page not found'
    
    # Should provide recovery options
    assert_link 'Home', 'Should provide link back to home page'
  end

  private

  def setup_capybara
    Capybara.app_host = 'http://localhost:4000'
    Capybara.default_driver = :selenium_chrome_headless
    Capybara.default_max_wait_time = 10
  end

  def start_test_server
    # Interface method - implementation will start Jekyll server
    fail 'start_test_server method not implemented yet'
  end

  def stop_test_server
    # Interface method - implementation will stop Jekyll server
    fail 'stop_test_server method not implemented yet'
  end

  def measure_page_load_time
    # Interface method - implementation will measure page load performance
    fail 'measure_page_load_time method not implemented yet'
  end

  def resize_window_to_mobile
    # Resize to mobile viewport (375x667 - iPhone SE)
    page.driver.browser.manage.window.resize_to(375, 667)
  end
end