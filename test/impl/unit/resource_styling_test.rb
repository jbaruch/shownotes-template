# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'nokogiri'

# Test for resource styling on talk pages
class ResourceStylingTest < Minitest::Test
  def setup
    # Build Jekyll site for testing
    config = Jekyll.configuration({
      'source' => Dir.pwd,
      'destination' => File.join(Dir.pwd, '_test_site')
    })
    @site = Jekyll::Site.new(config)
    @site.process
  end

  def test_resources_have_proper_styling
    # Find a talk with resources
    talks_collection = @site.collections['talks']
    skip 'No talks collection found' unless talks_collection

    talk_with_resources = talks_collection.docs.find do |talk|
      talk.data['extracted_resources'] && !talk.data['extracted_resources'].empty?
    end
    skip 'No talk with resources found' unless talk_with_resources

    # Get the rendered talk page - collection docs are rendered as pages too
    talk_page = @site.pages.find { |page| page.url == talk_with_resources.url }
    if !talk_page
      # The talk might be rendered as a collection page, use the document directly
      talk_page = talk_with_resources
    end
    skip 'Talk page not found' unless talk_page

    html = talk_page.output
    doc = Nokogiri::HTML(html)

    # Check that resources section exists
    resources_section = doc.css('.talk-resources').first
    refute_nil resources_section, 'Resources section should exist'

    # Check that resource links have proper styling
    resource_links = doc.css('.talk-resources a')
    refute_empty resource_links, 'Should have resource links'

    # Each resource link should be in a properly styled list item
    resource_links.each do |link|
      # The link should be inside a list item within the resources list
      list_item = link.parent
      assert_equal 'li', list_item.name, "Resource link should be inside an li element"

      # The list item should have the proper styling applied via CSS
      # We can't directly test CSS application, but we can test the HTML structure
      assert list_item['class'].nil?, "List item should not have explicit classes (styled via CSS)"

      # The link should have proper attributes
      assert link['href'], "Resource link should have href attribute"
      refute_empty link.text.strip, "Resource link should have text content"
    end
  end

  def test_resources_section_structure
    # Find a talk with resources
    talks_collection = @site.collections['talks']
    skip 'No talks collection found' unless talks_collection

    talk_with_resources = talks_collection.docs.find do |talk|
      talk.data['extracted_resources'] && !talk.data['extracted_resources'].empty?
    end
    skip 'No talk with resources found' unless talk_with_resources

    # Get the rendered talk page - collection docs are rendered as pages too
    talk_page = @site.pages.find { |page| page.url == talk_with_resources.url }
    if !talk_page
      # The talk might be rendered as a collection page, use the document directly
      talk_page = talk_with_resources
    end
    skip 'Talk page not found' unless talk_page

    html = talk_page.output
    doc = Nokogiri::HTML(html)

    # Check that resources are in a proper list structure
    resources_section = doc.css('.talk-resources').first
    refute_nil resources_section, 'Resources section should exist'

    # Check that markdown-generated list structure is present
    # The markdownify filter generates <ul><li><a> structure
    resource_list = resources_section.css('ul').first
    refute_nil resource_list, 'Resources should be in a ul element'

    # Check that list items contain links
    list_items = resource_list.css('li')
    refute_empty list_items, 'Should have li elements'

    # Each list item should contain a link
    list_items.each do |item|
      link = item.css('a').first
      refute_nil link, 'Each list item should contain a link'
      assert link['href'], 'Link should have href attribute'
      refute_empty link.text.strip, 'Link should have text content'
    end
  end
end
