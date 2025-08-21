# frozen_string_literal: true

require 'minitest/autorun'

# Unit tests for Navigation (TS-022 through TS-027)
# Maps to Gherkin: "Talk page includes basic navigation elements"
class NavigationTest < Minitest::Test
  def setup
    @test_talk = {
      'title' => 'Navigation Test Talk',
      'speaker' => 'Nav Expert',
      'conference' => 'NavConf 2024',
      'date' => '2024-03-15',
      'status' => 'completed'
    }
  end

  # TS-022: Site header contains home/back link
  def test_site_header_contains_home_link
    page_html = generate_talk_page(@test_talk)
    
    header = extract_site_header(page_html)
    home_link = find_home_link(header)
    
    refute_nil home_link, 'Site header should contain home/back link'
    
    assert_equal '/', home_link[:href],
                 'Home link should point to root path'
    
    assert_includes home_link[:text].downcase, 'home',
                    'Home link should contain "home" text'
  end

  # TS-023: Navigation breadcrumbs show current page location
  def test_navigation_breadcrumbs
    page_html = generate_talk_page(@test_talk)
    
    breadcrumbs = extract_breadcrumbs(page_html)
    refute_empty breadcrumbs, 'Page should have breadcrumb navigation'
    
    # Should start with home
    assert_equal 'Home', breadcrumbs.first[:text]
    assert_equal '/', breadcrumbs.first[:href]
    
    # Should end with current talk
    assert_equal @test_talk['title'], breadcrumbs.last[:text]
    assert_nil breadcrumbs.last[:href], 'Current page should not be a link'
    
    # Verify breadcrumb markup uses proper schema
    breadcrumb_markup = extract_breadcrumb_markup(page_html)
    assert_includes breadcrumb_markup, 'itemtype="https://schema.org/BreadcrumbList"'
  end

  # TS-024: Footer contains conference/speaker attribution
  def test_footer_attribution
    page_html = generate_talk_page(@test_talk)
    
    footer = extract_site_footer(page_html)
    refute_nil footer, 'Page should have footer'
    
    # Should attribute conference
    assert_includes footer[:content], @test_talk['conference'],
                    'Footer should mention conference'
    
    # Should attribute speaker
    assert_includes footer[:content], @test_talk['speaker'],
                    'Footer should mention speaker'
    
    # Should have proper copyright/attribution format
    assert_match(/©.*\d{4}/, footer[:content],
                'Footer should contain copyright notice')
  end

  # TS-025: Skip navigation links improve keyboard accessibility
  def test_skip_navigation_accessibility
    page_html = generate_talk_page(@test_talk)
    
    skip_links = extract_skip_links(page_html)
    refute_empty skip_links, 'Page should have skip navigation links'
    
    # Should be first focusable elements
    first_focusable = get_first_focusable_element(page_html)
    assert_equal 'skip-link', first_focusable[:class]
    
    # Should jump to main content
    main_skip_link = skip_links.find { |link| link[:text].include?('main') }
    refute_nil main_skip_link, 'Should have skip to main content link'
    
    # Verify skip link targets exist
    skip_links.each do |skip_link|
      target_id = skip_link[:href].gsub('#', '')
      target = find_element_by_id(page_html, target_id)
      refute_nil target, "Skip link target #{target_id} should exist"
    end
  end

  # TS-026: Site navigation works without JavaScript
  def test_navigation_without_javascript
    page_html = generate_talk_page_without_javascript(@test_talk)
    
    # All navigation links should be functional
    nav_links = extract_navigation_links(page_html)
    nav_links.each do |link|
      assert_valid_href(link[:href]),
             "Navigation link should have valid href: #{link[:href]}"
      
      refute_includes link[:href], 'javascript:',
                     'Navigation should not depend on JavaScript'
    end
    
    # Forms should submit without JavaScript
    nav_forms = extract_navigation_forms(page_html)
    nav_forms.each do |form|
      assert form[:action], 'Forms should have action attribute'
      assert form[:method], 'Forms should have method attribute'
    end
  end

  # TS-027: Navigation state indicates current page
  def test_navigation_current_page_indication
    page_html = generate_talk_page(@test_talk)
    
    nav_items = extract_navigation_items(page_html)
    current_nav_item = find_current_navigation_item(nav_items)
    
    refute_nil current_nav_item, 'Current page should be indicated in navigation'
    
    # Should have visual indicator
    assert_includes current_nav_item[:classes], 'current',
                    'Current nav item should have "current" class'
    
    # Should have semantic indicator for screen readers
    assert current_nav_item[:aria_current],
           'Current nav item should have aria-current attribute'
    
    assert_equal 'page', current_nav_item[:aria_current],
                'aria-current should be set to "page"'
  end

  private

  # Interface methods - implementations will be created later
  def generate_talk_page(talk_data)
    fail 'generate_talk_page method not implemented yet'
  end

  def generate_talk_page_without_javascript(talk_data)
    fail 'generate_talk_page_without_javascript method not implemented yet'
  end

  def extract_site_header(html)
    fail 'extract_site_header method not implemented yet'
  end

  def extract_site_footer(html)
    fail 'extract_site_footer method not implemented yet'
  end

  def extract_breadcrumbs(html)
    fail 'extract_breadcrumbs method not implemented yet'
  end

  def extract_skip_links(html)
    fail 'extract_skip_links method not implemented yet'
  end

  def extract_navigation_links(html)
    fail 'extract_navigation_links method not implemented yet'
  end

  def extract_navigation_forms(html)
    fail 'extract_navigation_forms method not implemented yet'
  end

  def extract_navigation_items(html)
    fail 'extract_navigation_items method not implemented yet'
  end

  def find_home_link(header)
    fail 'find_home_link method not implemented yet'
  end

  def find_current_navigation_item(nav_items)
    fail 'find_current_navigation_item method not implemented yet'
  end

  def get_first_focusable_element(html)
    fail 'get_first_focusable_element method not implemented yet'
  end

  def find_element_by_id(html, id)
    fail 'find_element_by_id method not implemented yet'
  end

  def extract_breadcrumb_markup(html)
    fail 'extract_breadcrumb_markup method not implemented yet'
  end

  def assert_valid_href(href)
    fail 'assert_valid_href method not implemented yet'
  end
end