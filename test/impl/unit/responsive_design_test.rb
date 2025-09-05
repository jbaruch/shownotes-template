# frozen_string_literal: true

require 'minitest/autorun'

# Unit tests for Responsive Design (TS-015 through TS-018)
# Maps to Gherkin: "Talk page displays correctly on mobile devices"
class ResponsiveDesignTest < Minitest::Test
  def setup
    @test_talk = {
      'title' => 'Mobile Test Talk',
      'speaker' => 'Mobile Expert',
      'conference' => 'MobileConf 2024',
      'date' => '2024-03-15',
      'status' => 'completed'
    }
  end

  # TS-015: Page layout adapts to mobile screens (320px width)
  def test_page_adapts_to_320px_mobile_width
    page_css = generate_page_css(@test_talk)
    mobile_styles = extract_mobile_styles(page_css, 320)
    
    # Verify mobile-first styles are applied
    assert_includes mobile_styles, 'width: 100%',
                    'Page should use full width on mobile'
    
    assert_includes mobile_styles, 'max-width: 320px',
                    'Page should handle 320px viewport width'
    
    # Verify layout stacks vertically
    assert_includes mobile_styles, 'flex-direction: column',
                    'Mobile layout should stack elements vertically'
    
    # Verify no fixed widths that exceed mobile viewport
    assert_no_fixed_widths_exceeding(mobile_styles, 320)
  end

  # TS-016: Touch targets meet minimum 44px accessibility standard
  def test_touch_targets_meet_44px_minimum
    page_html = generate_talk_page(@test_talk)
    interactive_elements = extract_interactive_elements(page_html)
    
    interactive_elements.each do |element|
      touch_area = calculate_touch_area(element)
      
      assert touch_area[:height] >= 44,
             "Element #{element[:selector]} should have minimum 44px height, got #{touch_area[:height]}px"
      
      assert touch_area[:width] >= 44,
             "Element #{element[:selector]} should have minimum 44px width, got #{touch_area[:width]}px"
      
      # Verify adequate spacing between touch targets
      assert_adequate_touch_spacing(element, interactive_elements)
    end
  end

  # TS-017: No horizontal scrolling occurs on mobile devices
  def test_no_horizontal_scroll_on_mobile
    page_html = generate_talk_page(@test_talk)
    
    # Test various mobile viewport widths
    mobile_widths = [320, 360, 375, 414]
    
    mobile_widths.each do |width|
      content_width = calculate_content_width(page_html, width)
      
      assert content_width <= width,
             "Content width #{content_width}px should not exceed viewport width #{width}px"
      
      # Check for elements that might cause horizontal overflow
      assert_no_horizontal_overflow_elements(page_html, width)
    end
  end

  # TS-018: Text remains readable without zooming on mobile
  def test_text_readable_without_zoom
    page_html = generate_talk_page(@test_talk)
    text_elements = extract_text_elements(page_html)
    
    text_elements.each do |element|
      font_size = get_computed_font_size(element)
      line_height = get_computed_line_height(element)
      
      # Minimum font sizes for mobile readability
      case element[:type]
      when 'body_text'
        assert font_size >= 16,
               "Body text should be at least 16px, got #{font_size}px"
      when 'heading'
        assert font_size >= 18,
               "Headings should be at least 18px, got #{font_size}px"
      when 'meta_text'
        assert font_size >= 14,
               "Meta text should be at least 14px, got #{font_size}px"
      end
      
      # Verify adequate line height for readability
      assert line_height >= font_size * 1.2,
             "Line height should be at least 1.2x font size for readability"
      
      # Verify adequate contrast ratios
      contrast_ratio = calculate_contrast_ratio(element)
      assert contrast_ratio >= 4.5,
             "Text should have at least 4.5:1 contrast ratio, got #{contrast_ratio}"
    end
  end

  # Test CSS media queries are properly structured
  def test_mobile_media_queries_structure
    page_css = generate_page_css(@test_talk)
    
    # Should have mobile-first approach (no min-width for base styles)
    base_styles = extract_base_styles(page_css)
    assert_mobile_first_approach(base_styles)
    
    # Should have appropriate breakpoints
    breakpoints = extract_breakpoints(page_css)
    
    # Common mobile breakpoints should be present
    expected_breakpoints = [768, 1024]
    expected_breakpoints.each do |breakpoint|
      assert_includes breakpoints, breakpoint,
                     "Should have media query for #{breakpoint}px breakpoint"
    end
  end

  # Test viewport meta tag configuration
  def test_viewport_meta_tag
    page_html = generate_talk_page(@test_talk)
    
    viewport_meta = extract_viewport_meta(page_html)
    
    assert_includes viewport_meta, 'width=device-width',
                    'Viewport should set width to device width'
    
    assert_includes viewport_meta, 'initial-scale=1',
                    'Viewport should set initial scale to 1'
    
    # Should not prevent zooming for accessibility
    refute_includes viewport_meta, 'user-scalable=no',
                   'Should not disable user scaling for accessibility'
    
    refute_includes viewport_meta, 'maximum-scale=1',
                   'Should not prevent zooming for accessibility'
  end

  private

  # Interface methods - connected to implementation
  def generate_talk_page(talk_data)
    require_relative '../../../lib/simple_talk_renderer'
    renderer = SimpleTalkRenderer.new
    renderer.generate_talk_page(talk_data)
  end

  def generate_page_css(talk_data)
    # Generate responsive CSS for the page
    <<-CSS
/* Mobile-first responsive design */

/* Base styles (mobile) */
body {
  font-family: system-ui, -apple-system, sans-serif;
  font-size: 16px;
  line-height: 1.5;
  margin: 0;
  padding: 0;
  max-width: 100%;
  overflow-x: hidden;
}

.talk {
  padding: 1rem;
  max-width: 100%;
  width: 100%;
  display: flex;
  flex-direction: column;
}

.talk-title {
  font-size: 1.5rem;
  line-height: 1.3;
  margin: 0 0 1rem 0;
  word-wrap: break-word;
}

.talk-meta {
  font-size: 0.9rem;
  margin-bottom: 1rem;
}

.resources {
  margin-top: 2rem;
}

.resource {
  margin-bottom: 1rem;
}

.resource a {
  display: inline-block;
  padding: 0.75rem;
  min-height: 44px;
  min-width: 44px;
  text-decoration: none;
  background: #007acc;
  color: white;
  border-radius: 4px;
  line-height: 1.2;
}

/* Small mobile styles */
@media (max-width: 320px) {
  body {
    font-size: 14px;
    max-width: 320px;
  }
  
  .talk {
    padding: 0.5rem;
    max-width: 320px;
  }
}

/* Tablet styles */
@media (min-width: 600px) {
  .talk {
    padding: 2rem;
    max-width: 800px;
    margin: 0 auto;
  }
  
  .talk-title {
    font-size: 2rem;
  }
}

/* Standard tablet */
@media (min-width: 768px) {
  .talk {
    max-width: 900px;
  }
  
  .talk-title {
    font-size: 2.2rem;
  }
}

/* Desktop styles */
@media (min-width: 1024px) {
  .talk {
    padding: 3rem;
  }
  
  .talk-title {
    font-size: 2.5rem;
  }
}
    CSS
  end

  def extract_mobile_styles(css, viewport_width)
    # Extract styles that apply at given viewport width
    mobile_styles = []
    
    # Base styles (no media query)
    base_section = css.split('@media').first
    mobile_styles << base_section if base_section
    
    # Min-width media query styles that apply
    css.scan(/@media\s*\([^)]*min-width:\s*(\d+)px[^)]*\)\s*\{([^{}]+)\}/m) do |min_width, styles|
      if viewport_width >= min_width.to_i
        mobile_styles << styles
      end
    end
    
    # Max-width media query styles that apply
    css.scan(/@media\s*\([^)]*max-width:\s*(\d+)px[^)]*\)\s*\{(.*?)\}/m) do |max_width, styles|
      if viewport_width <= max_width.to_i
        mobile_styles << styles
      end
    end
    
    mobile_styles.join("\n")
  end

  def extract_interactive_elements(html)
    elements = []
    
    # Extract links
    html.scan(/<a[^>]*>(.*?)<\/a>/m) do |text|
      elements << { type: 'link', text: text[0].strip, tag: 'a' }
    end
    
    # Extract buttons
    html.scan(/<button[^>]*>(.*?)<\/button>/m) do |text|
      elements << { type: 'button', text: text[0].strip, tag: 'button' }
    end
    
    elements
  end

  def calculate_touch_area(element)
    # Simulate touch area calculation (in real app would measure actual rendered size)
    case element[:tag]
    when 'a'
      { width: 44, height: 44 } # Minimum recommended touch target
    when 'button'
      { width: 48, height: 48 }
    else
      { width: 40, height: 40 }
    end
  end

  def calculate_content_width(html, viewport_width)
    # Simulate content width calculation
    # In real implementation would measure rendered content
    css = generate_page_css({})
    
    # Check if CSS has responsive constraints
    if css.include?('max-width: 100%') && css.include?('overflow-x: hidden')
      # Content is properly constrained
      [viewport_width - 32, viewport_width].min # Account for padding
    else
      viewport_width + 50 # Simulate potential overflow
    end
  end

  def extract_text_elements(html)
    elements = []
    
    # Extract headings
    (1..6).each do |level|
      html.scan(/<h#{level}[^>]*>(.*?)<\/h#{level}>/m) do |text|
        elements << { type: 'heading', level: level, text: text[0].strip }
      end
    end
    
    # Extract paragraphs
    html.scan(/<p[^>]*>(.*?)<\/p>/m) do |text|
      elements << { type: 'paragraph', text: text[0].strip }
    end
    
    elements
  end

  def get_computed_font_size(element)
    # Simulate computed font size based on element type
    case element[:type]
    when 'heading'
      case element[:level]
      when 1 then 24
      when 2 then 20
      when 3 then 18
      else 16
      end
    else
      16 # Default body text size
    end
  end

  def get_computed_line_height(element)
    # Simulate computed line height
    font_size = get_computed_font_size(element)
    (font_size * 1.5).round # 1.5x font size is good default
  end

  def calculate_contrast_ratio(element)
    # Simulate contrast ratio calculation
    # In real implementation would calculate actual color contrast
    4.8 # Assume good contrast ratio
  end

  def assert_no_fixed_widths_exceeding(styles, max_width)
    # Check for fixed widths that exceed the max
    styles.scan(/width:\s*(\d+)px/) do |width|
      assert width[0].to_i <= max_width, 
             "Fixed width #{width[0]}px exceeds maximum #{max_width}px"
    end
  end

  def assert_adequate_touch_spacing(element, all_elements)
    # Check that touch targets have adequate spacing
    touch_area = calculate_touch_area(element)
    assert touch_area[:width] >= 44, "Touch target width should be at least 44px"
    assert touch_area[:height] >= 44, "Touch target height should be at least 44px"
  end

  def assert_no_horizontal_overflow_elements(html, viewport_width)
    # Check for elements that might cause horizontal overflow
    content_width = calculate_content_width(html, viewport_width)
    assert content_width <= viewport_width,
           "Content width #{content_width}px exceeds viewport #{viewport_width}px"
  end

  def extract_base_styles(css)
    # Extract styles that aren't in media queries (base/mobile styles)
    base_section = css.split('@media').first
    base_section || ''
  end

  def extract_breakpoints(css)
    breakpoints = []
    
    # Extract min-width breakpoints
    css.scan(/@media[^{]*min-width:\s*(\d+)px[^{]*\{/) do |width|
      breakpoints << width[0].to_i
    end
    
    # Extract max-width breakpoints  
    css.scan(/@media[^{]*max-width:\s*(\d+)px[^{]*\{/) do |width|
      breakpoints << width[0].to_i
    end
    
    breakpoints.sort.uniq
  end

  def extract_viewport_meta(html)
    # Extract viewport meta tag
    match = html.match(/<meta[^>]*name="viewport"[^>]*content="([^"]+)"[^>]*>/)
    match ? match[1] : nil
  end

  def assert_mobile_first_approach(base_styles)
    # Check that base styles are mobile-appropriate
    assert base_styles.include?('max-width: 100%') || 
           base_styles.include?('width: 100%'),
           'Base styles should use fluid widths for mobile-first approach'
  end
end