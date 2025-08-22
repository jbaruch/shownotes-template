# frozen_string_literal: true

require 'minitest/autorun'
require 'json'

# Unit tests for Site Metadata (TS-032 through TS-034, TS-039 through TS-044)
# Maps to Gherkin: "Talk page includes proper metadata" + "Talk page includes social media metadata"
class SiteMetadataTest < Minitest::Test
  def setup
    @test_talk = {
      'title' => 'Metadata Test Talk',
      'speaker' => 'Meta Expert',
      'conference' => 'MetaConf 2024',
      'date' => '2024-03-15',
      'status' => 'completed',
      'description' => 'A comprehensive test of metadata generation',
      'topics' => ['testing', 'metadata']
    }
  end

  # TS-032: Page title follows format: "Talk Title - Speaker Name - Conference"
  def test_page_title_format
    page_html = generate_talk_page(@test_talk)
    page_title = extract_page_title(page_html)
    
    expected_title = "#{@test_talk['title']} - #{@test_talk['speaker']} - #{@test_talk['conference']}"
    assert_equal expected_title, page_title,
                'Page title should follow specified format'
    
    # Verify title length is reasonable for SEO
    assert page_title.length <= 60,
           'Page title should be 60 characters or less for SEO'
  end

  # TS-033: Meta description summarizes talk content
  def test_meta_description
    page_html = generate_talk_page(@test_talk)
    meta_description = extract_meta_description(page_html)
    
    refute_nil meta_description, 'Page should have meta description'
    refute_empty meta_description, 'Meta description should not be empty'
    
    # Should be appropriate length for SEO
    assert meta_description.length >= 120,
           'Meta description should be at least 120 characters'
    assert meta_description.length <= 160,
           'Meta description should be 160 characters or less'
    
    # Should include key information
    assert_includes meta_description, @test_talk['speaker'],
                    'Meta description should mention speaker'
    assert_includes meta_description, @test_talk['conference'],
                    'Meta description should mention conference'
  end

  # TS-034: Canonical URL prevents duplicate content issues
  def test_canonical_url
    page_html = generate_talk_page(@test_talk)
    canonical_url = extract_canonical_url(page_html)
    
    refute_nil canonical_url, 'Page should have canonical URL'
    
    # Should be absolute URL
    assert_match URI::regexp(['http', 'https']), canonical_url,
                'Canonical URL should be absolute'
    
    # Should not have query parameters or fragments
    uri = URI.parse(canonical_url)
    assert_nil uri.query, 'Canonical URL should not have query parameters'
    assert_nil uri.fragment, 'Canonical URL should not have fragments'
  end

  # TS-039: Open Graph tags enable rich social sharing
  def test_open_graph_tags
    page_html = generate_talk_page(@test_talk)
    og_tags = extract_open_graph_tags(page_html)
    
    # Required Open Graph tags
    required_og_tags = %w[og:title og:description og:url og:type]
    required_og_tags.each do |tag|
      assert og_tags.key?(tag), "Should have #{tag} Open Graph tag"
      refute_empty og_tags[tag], "#{tag} should not be empty"
    end
    
    # Verify content quality
    assert_equal @test_talk['title'], og_tags['og:title'],
                'og:title should match talk title'
    
    assert_equal 'website', og_tags['og:type'],
                'og:type should be website'
    
    assert_includes og_tags['og:description'], @test_talk['speaker'],
                    'og:description should mention speaker'
  end

  # TS-040: Twitter Card tags optimize Twitter sharing
  def test_twitter_card_tags
    page_html = generate_talk_page(@test_talk)
    twitter_tags = extract_twitter_card_tags(page_html)
    
    # Required Twitter Card tags
    required_twitter_tags = %w[twitter:card twitter:title twitter:description]
    required_twitter_tags.each do |tag|
      assert twitter_tags.key?(tag), "Should have #{tag} Twitter Card tag"
      refute_empty twitter_tags[tag], "#{tag} should not be empty"
    end
    
    # Verify card type
    assert_equal 'summary', twitter_tags['twitter:card'],
                'Twitter card should be summary type'
    
    # Verify content matches Open Graph where appropriate
    og_tags = extract_open_graph_tags(page_html)
    assert_equal og_tags['og:title'], twitter_tags['twitter:title'],
                'Twitter title should match Open Graph title'
  end

  # TS-041: Schema.org structured data improves search results
  def test_schema_structured_data
    page_html = generate_talk_page(@test_talk)
    structured_data = extract_structured_data(page_html)
    
    refute_empty structured_data, 'Page should have structured data'
    
    # Should use appropriate schema.org types
    talk_schema = find_schema_by_type(structured_data, 'Event')
    refute_nil talk_schema, 'Should have Event schema for the talk'
    
    # Verify required Event properties
    required_properties = %w[name description startDate location organizer]
    required_properties.each do |property|
      assert talk_schema.key?(property), 
             "Event schema should have #{property} property"
    end
    
    # Verify property content
    assert_equal @test_talk['title'], talk_schema['name'],
                'Event name should match talk title'
  end

  # TS-042: JSON-LD format is used for structured data
  def test_json_ld_format
    page_html = generate_talk_page(@test_talk)
    json_ld_scripts = extract_json_ld_scripts(page_html)
    
    refute_empty json_ld_scripts, 'Page should have JSON-LD scripts'
    
    json_ld_scripts.each do |script|
      # Verify valid JSON
      parsed_data = JSON.parse(script)
      
      # Handle array of structured data
      data_array = parsed_data.is_a?(Array) ? parsed_data : [parsed_data]
      
      data_array.each do |data|
        # Should have @context
        assert data['@context'], 'JSON-LD should have @context'
        assert_includes data['@context'], 'schema.org',
                       '@context should reference schema.org'
        
        # Should have @type
        assert data['@type'], 'JSON-LD should have @type'
      end
    end
  end

  # TS-043: Meta tags include conference and speaker information
  def test_conference_speaker_meta_tags
    page_html = generate_talk_page(@test_talk)
    meta_tags = extract_meta_tags(page_html)
    
    # Conference information
    conference_tag = meta_tags.find { |tag| tag[:name] == 'conference' }
    refute_nil conference_tag, 'Should have conference meta tag'
    assert_equal @test_talk['conference'], conference_tag[:content]
    
    # Speaker information  
    speaker_tag = meta_tags.find { |tag| tag[:name] == 'speaker' }
    refute_nil speaker_tag, 'Should have speaker meta tag'
    assert_equal @test_talk['speaker'], speaker_tag[:content]
    
    # Keywords should include topics
    keywords_tag = meta_tags.find { |tag| tag[:name] == 'keywords' }
    if keywords_tag && @test_talk['topics']
      @test_talk['topics'].each do |topic|
        assert_includes keywords_tag[:content], topic,
                       "Keywords should include topic: #{topic}"
      end
    end
  end

  # TS-044: Viewport meta tag ensures proper mobile rendering
  def test_viewport_meta_tag
    page_html = generate_talk_page(@test_talk)
    viewport_meta = extract_viewport_meta(page_html)
    
    refute_nil viewport_meta, 'Page should have viewport meta tag'
    
    # Should set device width
    assert_includes viewport_meta, 'width=device-width',
                    'Viewport should set width to device width'
    
    # Should set initial scale
    assert_includes viewport_meta, 'initial-scale=1',
                    'Viewport should set initial scale to 1'
    
    # Should not prevent zooming (accessibility)
    refute_includes viewport_meta, 'user-scalable=no',
                   'Should not disable user scaling'
    refute_includes viewport_meta, 'maximum-scale=1',
                   'Should not prevent zooming'
  end

  private

  # Interface methods - connected to implementation
  def generate_talk_page(talk_data)
    require_relative '../../../lib/simple_talk_renderer'
    renderer = SimpleTalkRenderer.new
    renderer.generate_talk_page(talk_data)
  end

  def extract_page_title(html)
    match = html.match(/<title[^>]*>(.*?)<\/title>/m)
    match ? match[1].strip : nil
  end

  def extract_meta_description(html)
    match = html.match(/<meta[^>]*name="description"[^>]*content="([^"]+)"[^>]*>/)
    match ? match[1] : nil
  end

  def extract_canonical_url(html)
    match = html.match(/<link[^>]*rel="canonical"[^>]*href="([^"]+)"[^>]*>/)
    match ? match[1] : nil
  end

  def extract_open_graph_tags(html)
    og_tags = {}
    html.scan(/<meta[^>]*property="(og:[^"]+)"[^>]*content="([^"]+)"[^>]*>/) do |property, content|
      og_tags[property] = content
    end
    og_tags
  end

  def extract_twitter_card_tags(html)
    twitter_tags = {}
    html.scan(/<meta[^>]*name="(twitter:[^"]+)"[^>]*content="([^"]+)"[^>]*>/) do |name, content|
      twitter_tags[name] = content
    end
    twitter_tags
  end

  def extract_structured_data(html)
    scripts = extract_json_ld_scripts(html)
    structured_data = []
    
    scripts.each do |script|
      begin
        data = JSON.parse(script)
        if data.is_a?(Array)
          structured_data.concat(data)
        else
          structured_data << data
        end
      rescue JSON::ParserError
        # Skip invalid JSON
      end
    end
    
    structured_data
  end

  def extract_json_ld_scripts(html)
    scripts = []
    html.scan(/<script[^>]*type="application\/ld\+json"[^>]*>(.*?)<\/script>/m) do |content|
      scripts << content[0].strip
    end
    scripts
  end

  def extract_meta_tags(html)
    meta_tags = []
    
    # Extract standard meta tags
    html.scan(/<meta[^>]*name="([^"]+)"[^>]*content="([^"]+)"[^>]*>/) do |name, content|
      meta_tags << { name: name, content: content }
    end
    
    # Extract property meta tags (like Open Graph)
    html.scan(/<meta[^>]*property="([^"]+)"[^>]*content="([^"]+)"[^>]*>/) do |property, content|
      meta_tags << { property: property, content: content }
    end
    
    meta_tags
  end

  def extract_viewport_meta(html)
    match = html.match(/<meta[^>]*name="viewport"[^>]*content="([^"]+)"[^>]*>/)
    match ? match[1] : nil
  end

  def find_schema_by_type(structured_data, type)
    structured_data.find { |data| data['@type'] == type }
  end
end