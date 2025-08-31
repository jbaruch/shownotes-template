# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'

# Unit tests for Collection Access Patterns (TS-211 through TS-220)
# Maps to Gherkin: "Jekyll collections are accessible with correct data access patterns"
class CollectionAccessTest < Minitest::Test
  def setup
    # Build Jekyll site for testing
    config = Jekyll.configuration({
      'source' => Dir.pwd,
      'destination' => File.join(Dir.pwd, '_test_site')
    })
    @site = Jekyll::Site.new(config)
    @site.process
  end

  # TS-211: Talks collection is accessible via site.talks
  def test_talks_collection_accessible_via_site_talks
    refute_nil @site.talks, 'site.talks should be accessible'
    assert_kind_of Array, @site.talks, 'site.talks should be an array'
  end

  # TS-212: Talks collection contains expected documents
  def test_talks_collection_contains_documents
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    assert_kind_of Jekyll::Document, talk, 'Talk should be a Jekyll Document'
    assert_equal 'talks', talk.collection.label, 'Talk should belong to talks collection'
  end

  # TS-213: Talk documents have extracted metadata available
  def test_talk_documents_have_extracted_metadata
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first

    # Check that extracted data is available
    assert talk.data.key?('extracted_title'), 'Talk should have extracted_title'
    assert talk.data.key?('extracted_conference'), 'Talk should have extracted_conference'
    assert talk.data.key?('extracted_date'), 'Talk should have extracted_date'

    # Check that extracted data has reasonable values
    refute_empty talk.data['extracted_title'], 'extracted_title should not be empty'
    refute_nil talk.data['extracted_conference'], 'extracted_conference should not be nil'
    refute_nil talk.data['extracted_date'], 'extracted_date should not be nil'
  end

  # TS-214: Template data access patterns work correctly
  def test_template_data_access_patterns
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first

    # Test that we can access data in templates
    assert_equal talk.data['extracted_title'], talk['extracted_title'],
                 'Direct access should work: talk.extracted_title'

    assert_equal talk.data['extracted_conference'], talk['extracted_conference'],
                 'Direct access should work: talk.extracted_conference'

    assert_equal talk.data['extracted_date'], talk['extracted_date'],
                 'Direct access should work: talk.extracted_date'
  end

  # TS-215: Collection size matches expected number of talk files
  def test_collection_size_matches_files
    talks_dir = File.join(Dir.pwd, '_talks')
    return unless Dir.exist?(talks_dir)

    markdown_files = Dir.glob(File.join(talks_dir, '*.md')).count
    collection_size = @site.talks.size

    assert_equal markdown_files, collection_size,
                 "Collection size (#{collection_size}) should match markdown files (#{markdown_files})"
  end

  # TS-216: Collection documents have correct URLs
  def test_collection_documents_have_correct_urls
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first
    assert talk.url, 'Talk should have a URL'
    assert talk.url.start_with?('/talks/'), 'Talk URL should start with /talks/'
  end

  # TS-217: Collection is sortable by extracted_date
  def test_collection_sortable_by_extracted_date
    skip 'No talks found' if @site.talks.empty?

    # This should not raise an error
    sorted_talks = @site.talks.sort_by { |talk| talk.data['extracted_date'] || '' }
    assert_kind_of Array, sorted_talks, 'Talks should be sortable by extracted_date'
    assert_equal @site.talks.size, sorted_talks.size, 'Sorted array should have same size'
  end

  # TS-218: site.collections.talks.docs alternative access works
  def test_alternative_collection_access
    # Test alternative access patterns that might be used in templates
    talks_collection = @site.collections['talks']
    refute_nil talks_collection, 'site.collections[\'talks\'] should work'

    if talks_collection
      docs = talks_collection.docs
      refute_nil docs, 'talks_collection.docs should work'
      assert_kind_of Array, docs, 'talks_collection.docs should be an array'
    end
  end

  # TS-219: Collection data is preserved during site processing
  def test_collection_data_preservation
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first

    # Verify that all expected data fields are present
    expected_fields = [
      'extracted_title', 'extracted_conference', 'extracted_date',
      'extracted_slides', 'extracted_video', 'extracted_description'
    ]

    expected_fields.each do |field|
      assert talk.data.key?(field),
             "Talk should preserve #{field} during site processing"
    end
  end

  # TS-220: Collection access works in Liquid templates
  def test_liquid_template_access
    skip 'No talks found' if @site.talks.empty?

    talk = @site.talks.first

    # Simulate Liquid template access patterns
    liquid_context = {
      'talk' => talk,
      'site' => @site
    }

    # Test that we can access talk data as if in a Liquid template
    assert_equal talk.data['extracted_title'], liquid_context['talk']['extracted_title']
    assert_equal talk.data['extracted_conference'], liquid_context['talk']['extracted_conference']
    assert_equal talk.data['extracted_date'], liquid_context['talk']['extracted_date']
  end
end
