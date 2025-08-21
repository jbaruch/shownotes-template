# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'fileutils'
require 'tmpdir'

# Integration tests for Jekyll Build Process (TS-028 through TS-031, TS-056 through TS-067)
# Maps to Gherkin: "Jekyll processes talk collection correctly" + "Site deploys automatically via GitHub Pages"
class JekyllBuildTest < Minitest::Test
  def setup
    @test_site_path = Dir.mktmpdir('jekyll_test')
    @original_dir = Dir.pwd
    Dir.chdir(@test_site_path)
    
    setup_test_site
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_site_path)
  end

  # TS-028: Site builds successfully with Jekyll
  def test_site_builds_without_errors
    build_result = run_jekyll_build
    
    assert build_result.success?, 'Jekyll build should complete successfully'
    assert_empty build_result.errors, 'Jekyll build should not produce errors'
    
    # Verify _site directory is created
    assert_path_exists '_site', 'Build should create _site directory'
    
    # Verify essential files are generated
    assert_path_exists '_site/index.html', 'Build should generate index.html'
  end

  # TS-029: Liquid templating processes talk data correctly
  def test_liquid_templates_process_talk_data
    create_test_talk_file
    build_result = run_jekyll_build
    
    assert build_result.success?, 'Build with talk data should succeed'
    
    # Verify talk page is generated
    talk_page_path = '_site/talks/testconf-2024/test-talk/index.html'
    assert_path_exists talk_page_path, 'Talk page should be generated'
    
    # Verify Liquid variables are processed
    talk_content = File.read(talk_page_path)
    assert_includes talk_content, 'Test Talk Title', 'Talk title should be processed by Liquid'
    assert_includes talk_content, 'Test Speaker', 'Speaker name should be processed by Liquid'
    assert_includes talk_content, 'Test Conference 2024', 'Conference should be processed by Liquid'
  end

  # TS-030: Collections organize talks properly
  def test_collections_organize_talks
    create_multiple_test_talks
    build_result = run_jekyll_build
    
    assert build_result.success?, 'Build with multiple talks should succeed'
    
    # Verify all talk pages are generated in correct structure
    assert_path_exists '_site/talks/testconf-2024/first-talk/index.html'
    assert_path_exists '_site/talks/testconf-2024/second-talk/index.html'
    assert_path_exists '_site/talks/anotherconf-2024/third-talk/index.html'
    
    # Verify talks collection is accessible
    site_data = extract_site_data
    assert site_data.key?('talks'), 'Site should have talks collection'
    assert_equal 3, site_data['talks'].length, 'Should have 3 talks in collection'
  end

  # TS-031: Site deploys to GitHub Pages without errors
  def test_github_pages_compatibility
    build_result = run_jekyll_build(github_pages: true)
    
    assert build_result.success?, 'GitHub Pages compatible build should succeed'
    
    # Verify GitHub Pages specific requirements
    assert_no_unsupported_plugins
    assert_proper_base_url_handling
    
    # Verify generated site structure is GitHub Pages compatible
    assert_github_pages_structure
  end

  # TS-064: Builds complete within 5 minutes
  def test_build_performance_within_time_limit
    start_time = Time.now
    
    # Create a reasonable number of talks to test performance
    create_performance_test_talks(50)
    
    build_result = run_jekyll_build
    build_time = Time.now - start_time
    
    assert build_result.success?, 'Performance test build should succeed'
    assert build_time < 300, "Build should complete within 5 minutes, took #{build_time} seconds"
  end

  # TS-065: Incremental builds work when possible
  def test_incremental_builds
    # Initial build
    initial_build = run_jekyll_build
    initial_time = initial_build.duration
    
    # Modify a single file
    modify_test_file
    
    # Incremental build
    incremental_build = run_jekyll_build(incremental: true)
    incremental_time = incremental_build.duration
    
    assert incremental_build.success?, 'Incremental build should succeed'
    assert incremental_time < initial_time, 'Incremental build should be faster than initial build'
  end

  # TS-066: Build failures are handled gracefully
  def test_build_failure_handling
    create_malformed_talk_file
    
    build_result = run_jekyll_build
    
    # Build should fail but not crash
    refute build_result.success?, 'Build with malformed content should fail'
    assert_includes build_result.errors, 'YAML', 'Error should indicate YAML parsing issue'
    
    # Error should be informative
    assert build_result.errors.any? { |error| error.include?('malformed-talk.md') },
           'Error should identify the problematic file'
  end

  # TS-067: Error messaging is clear
  def test_clear_error_messaging
    create_invalid_frontmatter_talk
    
    build_result = run_jekyll_build
    
    refute build_result.success?, 'Build with invalid frontmatter should fail'
    
    # Error messages should be helpful
    error_message = build_result.errors.first
    assert_includes error_message, 'line', 'Error should include line number'
    assert_includes error_message, 'invalid-talk.md', 'Error should include filename'
  end

  private

  def setup_test_site
    # Create basic Jekyll site structure
    create_jekyll_config
    create_basic_layouts
    create_basic_content
  end

  def create_jekyll_config
    config = <<~YAML
      title: "Test Shownotes Site"
      description: "Test site for shownotes platform"
      
      collections:
        talks:
          output: true
          permalink: /talks/:path/
      
      markdown: kramdown
      highlighter: rouge
      
      plugins:
        - jekyll-feed
        - jekyll-sitemap
    YAML
    
    File.write('_config.yml', config)
  end

  def create_basic_layouts
    FileUtils.mkdir_p('_layouts')
    
    # Default layout
    default_layout = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>{{ page.title | default: site.title }}</title>
      </head>
      <body>
        {{ content }}
      </body>
      </html>
    HTML
    File.write('_layouts/default.html', default_layout)
    
    # Talk layout
    talk_layout = <<~HTML
      ---
      layout: default
      ---
      <article class="talk">
        <header class="talk-header">
          <h1 class="talk-title">{{ page.title }}</h1>
          <div class="talk-meta">
            <span class="speaker">{{ page.speaker }}</span>
            <span class="conference">{{ page.conference }}</span>
            <time class="date">{{ page.date | date: "%B %d, %Y" }}</time>
          </div>
        </header>
        <div class="talk-content">
          {{ content }}
        </div>
      </article>
    HTML
    File.write('_layouts/talk.html', talk_layout)
  end

  def create_basic_content
    # Index page
    index_content = <<~MARKDOWN
      ---
      title: "Home"
      ---
      
      # Welcome to Shownotes
      
      This is the test site homepage.
    MARKDOWN
    File.write('index.md', index_content)
    
    # Talks directory
    FileUtils.mkdir_p('_talks')
  end

  def create_test_talk_file
    talk_content = <<~MARKDOWN
      ---
      layout: talk
      title: "Test Talk Title"
      speaker: "Test Speaker"
      conference: "Test Conference 2024"
      date: "2024-03-15"
      status: "completed"
      ---
      
      This is the test talk content.
    MARKDOWN
    
    File.write('_talks/test-talk.md', talk_content)
  end

  def create_multiple_test_talks
    talks = [
      {
        filename: 'first-talk.md',
        title: 'First Talk',
        conference: 'TestConf 2024'
      },
      {
        filename: 'second-talk.md',
        title: 'Second Talk',
        conference: 'TestConf 2024'
      },
      {
        filename: 'third-talk.md',
        title: 'Third Talk',
        conference: 'AnotherConf 2024'
      }
    ]
    
    talks.each do |talk|
      content = <<~MARKDOWN
        ---
        layout: talk
        title: "#{talk[:title]}"
        speaker: "Test Speaker"
        conference: "#{talk[:conference]}"
        date: "2024-03-15"
        status: "completed"
        ---
        
        Content for #{talk[:title]}.
      MARKDOWN
      
      File.write("_talks/#{talk[:filename]}", content)
    end
  end

  # Interface methods - implementations will be created later
  def run_jekyll_build(options = {})
    fail 'run_jekyll_build method not implemented yet'
  end

  def extract_site_data
    fail 'extract_site_data method not implemented yet'
  end

  def assert_no_unsupported_plugins
    fail 'assert_no_unsupported_plugins method not implemented yet'
  end

  def assert_proper_base_url_handling
    fail 'assert_proper_base_url_handling method not implemented yet'
  end

  def assert_github_pages_structure
    fail 'assert_github_pages_structure method not implemented yet'
  end

  def create_performance_test_talks(count)
    fail 'create_performance_test_talks method not implemented yet'
  end

  def modify_test_file
    fail 'modify_test_file method not implemented yet'
  end

  def create_malformed_talk_file
    fail 'create_malformed_talk_file method not implemented yet'
  end

  def create_invalid_frontmatter_talk
    fail 'create_invalid_frontmatter_talk method not implemented yet'
  end

  def assert_path_exists(path, message = nil)
    assert File.exist?(path), message || "Expected #{path} to exist"
  end

  # Interface class for build results
  class BuildResult
    def success?
      fail 'BuildResult#success? method not implemented yet'
    end

    def errors
      fail 'BuildResult#errors method not implemented yet'
    end

    def duration
      fail 'BuildResult#duration method not implemented yet'
    end
  end
end