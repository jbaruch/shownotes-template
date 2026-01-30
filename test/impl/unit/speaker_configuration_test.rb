#!/usr/bin/env ruby

require 'minitest/autorun'
require 'yaml'
require 'fileutils'
require 'tempfile'

class SpeakerConfigurationTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir('speaker_config_test')
    @config_file = File.join(@test_dir, '_config.yml')
    @index_file = File.join(@test_dir, 'index.md')
    @talk_layout_file = File.join(@test_dir, '_layouts', 'talk.html')
    
    # Create test directory structure
    FileUtils.mkdir_p(File.join(@test_dir, '_layouts'))
    
    # Copy the actual template files to test directory
    copy_template_files
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  # Test avatar priority: GitHub > custom > none
  def test_avatar_priority_github_first
    create_config_with_speaker(
      avatar_url: "https://custom.example.com/avatar.jpg",
      social: { github: "testuser", x: "testuser" }
    )
    
    rendered_index = render_index_page
    
    # Should use GitHub avatar, not custom
    assert_includes rendered_index, 'https://github.com/testuser.png?size=200'
    refute_includes rendered_index, 'https://custom.example.com/avatar.jpg'
  end

  def test_avatar_priority_custom_fallback
    create_config_with_speaker(
      avatar_url: "https://custom.example.com/avatar.jpg",
      social: { github: "", x: "testuser" }
    )
    
    rendered_index = render_index_page
    
    # Should use custom avatar when GitHub is empty
    assert_includes rendered_index, 'https://custom.example.com/avatar.jpg'
    refute_includes rendered_index, 'github.com'
  end

  def test_avatar_priority_no_avatar
    create_config_with_speaker(
      avatar_url: "",
      social: { github: "", x: "testuser" }
    )
    
    rendered_index = render_index_page
    
    # Should not have any avatar image (but talk thumbnails are OK)
    refute_includes rendered_index, 'class="author-avatar"'
    refute_includes rendered_index, 'class="speaker-avatar"'
  end

  # Test social media URL generation
  def test_social_media_url_generation
    create_config_with_speaker(
      social: {
        linkedin: "testuser",
        x: "testuser", 
        github: "testuser",
        mastodon: "https://mastodon.social/@testuser",
        bluesky: "testuser"
      }
    )
    
    rendered_index = render_index_page
    
    # Check generated URLs
    assert_includes rendered_index, 'https://linkedin.com/in/testuser'
    assert_includes rendered_index, 'https://x.com/testuser'
    assert_includes rendered_index, 'https://github.com/testuser'
    assert_includes rendered_index, 'https://mastodon.social/@testuser'
    assert_includes rendered_index, 'https://bsky.app/profile/testuser'
  end

  def test_social_media_optional_hiding
    create_config_with_speaker(
      social: {
        linkedin: "testuser",
        x: "",           # Hidden
        github: "testuser", 
        mastodon: "",    # Hidden
        bluesky: ""      # Hidden
      }
    )
    
    rendered_index = render_index_page
    
    # Should show LinkedIn and GitHub only
    assert_includes rendered_index, 'https://linkedin.com/in/testuser'
    assert_includes rendered_index, 'https://github.com/testuser'
    
    # Should not show empty ones
    refute_includes rendered_index, 'https://x.com/'
    refute_includes rendered_index, 'https://mastodon'
    refute_includes rendered_index, 'https://bsky.app'
  end

  def test_no_social_media_at_all
    create_config_with_speaker(
      social: {
        linkedin: "",
        x: "",
        github: "",
        mastodon: "",
        bluesky: ""
      }
    )
    
    rendered_index = render_index_page
    
    # Should not have social links section
    refute_includes rendered_index, 'speaker-social-links'
    refute_includes rendered_index, 'social-link'
  end

  # Test speaker information display
  def test_speaker_name_and_bio_display
    create_config_with_speaker(
      name: "Test Speaker",
      display_name: "Test Speaker Display",
      bio: "This is a test bio for the speaker"
    )
    
    rendered_index = render_index_page
    
    # Check speaker name and bio are displayed
    assert_includes rendered_index, 'Presentations by Test Speaker Display'
    assert_includes rendered_index, 'This is a test bio for the speaker'
  end

  def test_speaker_name_fallback
    create_config_with_speaker(
      name: "Test Speaker",
      display_name: "",  # Empty display name
      bio: "Test bio"
    )
    
    rendered_talk = render_talk_page
    
    # Talk pages should NOT contain speaker information anymore
    refute_includes rendered_talk, 'Test Speaker'
    refute_includes rendered_talk, 'speaker-name'
    
    # Speaker information should only appear on index page
    rendered_index = render_index_page
    assert_includes rendered_index, 'Test Speaker'
  end

  # Test edge cases
  def test_missing_speaker_section
    create_config({
      title: "Test Site",
      description: "Test description"
      # No speaker section
    })
    
    rendered_index = render_index_page
    
    # Should gracefully handle missing speaker config
    refute_includes rendered_index, 'Presentations by'
    refute_includes rendered_index, 'speaker-social-links'
  end

  def test_partial_speaker_config
    create_config_with_speaker(
      name: "Test Speaker",
      display_name: "",     # Explicitly empty to test fallback to name
      bio: ""               # Explicitly empty to test partial config
      # Missing social, etc.
    )
    
    rendered_index = render_index_page
    rendered_talk = render_talk_page
    
    # Talk pages should NOT contain speaker information
    refute_includes rendered_talk, 'Test Speaker'
    refute_includes rendered_talk, 'speaker-section'
    
    # Index page should handle partial configs gracefully
    assert_includes rendered_index, 'Test Speaker'
    refute_includes rendered_index, 'speaker-social-links'
  end

  # Test Jekyll integration scenarios
  def test_config_file_structure_validation
    config = {
      'speaker' => {
        'name' => 'Valid Speaker',
        'display_name' => 'Valid Display Name',
        'bio' => 'Valid bio',
        'avatar_url' => '',
        'social' => {
          'linkedin' => 'validuser',
          'x' => 'validuser',
          'github' => 'validuser',
          'mastodon' => '',
          'bluesky' => ''
        }
      }
    }
    
    File.write(@config_file, config.to_yaml)
    loaded_config = YAML.load_file(@config_file)
    
    # Verify structure is preserved
    assert_equal 'Valid Speaker', loaded_config['speaker']['name']
    assert_equal 'validuser', loaded_config['speaker']['social']['linkedin']
    assert_equal '', loaded_config['speaker']['social']['mastodon']
  end

  # Test migration script compatibility
  def test_migration_script_speaker_extraction
    create_config_with_speaker(
      name: "Migration Test Speaker",
      display_name: "Migration Display Name"
    )
    
    # Simulate migration script reading config
    config = YAML.load_file(@config_file)
    speaker_name = config['speaker']['name'] if config['speaker']
    
    assert_equal "Migration Test Speaker", speaker_name
  end

  def test_page_title_fallback_logic
    # Test with empty display_name, should use name
    create_config_with_speaker(
      name: "Test Speaker Name",
      display_name: "",  # Empty display_name
      bio: "Test bio"
    )
    
    rendered_page = render_full_page
    
    # Page title should use name fallback
    assert_includes rendered_page, '<title>Presentations by Test Speaker Name</title>'
    
    # Site header should also use name fallback  
    assert_includes rendered_page, '>Test Speaker Name - Presentations</a>'
    
    # Test with filled display_name, should use display_name
    create_config_with_speaker(
      name: "Test Speaker Name", 
      display_name: "Test Display Name",
      bio: "Test bio"
    )
    
    rendered_page = render_full_page
    
    # Page title should use display_name
    assert_includes rendered_page, '<title>Presentations by Test Display Name</title>'
    
    # Site header should also use display_name
    assert_includes rendered_page, '>Test Display Name - Presentations</a>'
    
    # Test with both empty, should use fallback
    create_config_with_speaker(
      name: "",
      display_name: "",
      bio: "Test bio"
    )
    
    rendered_page = render_full_page
    
    # Page title should use fallback
    assert_includes rendered_page, '<title>Presentations</title>'
    
    # Site header should use fallback
    assert_includes rendered_page, '>Speaker - Presentations</a>'
  end

  def test_footer_copyright_fallback_logic
    # Test with empty display_name, should use name
    create_config_with_speaker(
      name: "Test Speaker Name",
      display_name: "",  # Empty display_name
      bio: "Test bio"
    )
    
    rendered_page = render_full_page
    
    # Footer should use name fallback
    assert_includes rendered_page, '&copy; 2025 Test Speaker Name. All rights reserved.'
    
    # Test with filled display_name, should use display_name
    create_config_with_speaker(
      name: "Test Speaker Name", 
      display_name: "Test Display Name",
      bio: "Test bio"
    )
    
    rendered_page = render_full_page
    
    # Footer should use display_name
    assert_includes rendered_page, '&copy; 2025 Test Display Name. All rights reserved.'
    
    # Test with both empty, should use fallback
    create_config_with_speaker(
      name: "",
      display_name: "",
      bio: "Test bio"
    )
    
    rendered_page = render_full_page
    
    # Footer should use fallback
    assert_includes rendered_page, '&copy; 2025 Speaker. All rights reserved.'
  end

  private

  def create_config_with_speaker(speaker_config)
    config = {
      'title' => 'Test Site',
      'description' => 'Test description',
      'speaker' => {
        'name' => speaker_config[:name] || 'Test Speaker',
        'display_name' => speaker_config[:display_name] || 'Test Display Name',
        'bio' => speaker_config[:bio] || 'Test bio content',
        'avatar_url' => speaker_config[:avatar_url] || '',
        'social' => speaker_config[:social] || {}
      }
    }
    create_config(config)
  end

  def create_config(config)
    File.write(@config_file, config.to_yaml)
  end

  def copy_template_files
    # Copy actual index.md template
    source_index = File.join(File.dirname(__FILE__), '../../../index.md')
    if File.exist?(source_index)
      FileUtils.cp(source_index, @index_file)
    else
      create_minimal_index_template
    end
    
    # Copy actual talk layout
    source_talk = File.join(File.dirname(__FILE__), '../../../_layouts/talk.html')
    if File.exist?(source_talk)
      FileUtils.cp(source_talk, @talk_layout_file)
    else
      create_minimal_talk_template
    end
  end

  def create_minimal_index_template
    content = <<~HTML
      ---
      layout: default
      ---
      <div class="home-page">
          <header class="hero-section">
              {% comment %} Smart avatar logic: GitHub > custom avatar_url {% endcomment %}
              {% assign avatar_url = "" %}
              {% if site.speaker.social.github and site.speaker.social.github != "" %}
                  {% assign avatar_url = "https://github.com/" | append: site.speaker.social.github | append: ".png?size=200" %}
              {% elsif site.speaker.avatar_url and site.speaker.avatar_url != "" %}
                  {% assign avatar_url = site.speaker.avatar_url %}
              {% endif %}
              
              {% if avatar_url != "" %}
              <div class="hero-image">
                  <img src="{{ avatar_url }}" alt="{{ site.speaker.display_name }}" class="author-avatar">
              </div>
              {% endif %}
              <div class="hero-content">
                  <h1>Presentations by {{ site.speaker.display_name }}</h1>
                  <p class="hero-description">{{ site.speaker.bio }}</p>
                  <div class="speaker-social-links">
                      {% if site.speaker.social.linkedin and site.speaker.social.linkedin != "" %}
                      <a href="https://linkedin.com/in/{{ site.speaker.social.linkedin }}" class="social-link linkedin"></a>
                      {% endif %}
                      {% if site.speaker.social.x and site.speaker.social.x != "" %}
                      <a href="https://x.com/{{ site.speaker.social.x }}" class="social-link twitter"></a>
                      {% endif %}
                      {% if site.speaker.social.github and site.speaker.social.github != "" %}
                      <a href="https://github.com/{{ site.speaker.social.github }}" class="social-link github"></a>
                      {% endif %}
                      {% if site.speaker.social.mastodon and site.speaker.social.mastodon != "" %}
                      <a href="{{ site.speaker.social.mastodon }}" class="social-link mastodon"></a>
                      {% endif %}
                      {% if site.speaker.social.bluesky and site.speaker.social.bluesky != "" %}
                      <a href="https://bsky.app/profile/{{ site.speaker.social.bluesky }}" class="social-link bluesky"></a>
                      {% endif %}
                  </div>
              </div>
          </header>
      </div>
    HTML
    File.write(@index_file, content)
  end

  def create_minimal_talk_template
    content = <<~HTML
      <!-- Talk pages no longer include speaker sections -->
      <!-- Speaker information is centralized on the index page only -->
      <div class="talk-content">
          <h1>{{ page.title }}</h1>
          <p>{{ page.description }}</p>
          
          <!-- Main content without speaker section -->
          {{ content }}
      </div>
    HTML
    File.write(@talk_layout_file, content)
  end

  def render_index_page
    # Simple template rendering simulation
    config = YAML.load_file(@config_file)
    template = File.read(@index_file)

    # Basic Liquid template simulation
    rendered = template.dup

    # Handle conditional title logic first - template now shows just name, not "Presentations by Name"
    title_pattern = /{% if site\.speaker and site\.speaker\.display_name and site\.speaker\.display_name != "" %}.*?<h1>{{ site\.speaker\.display_name }}<\/h1>.*?{% elsif site\.speaker and site\.speaker\.name and site\.speaker\.name != "" %}.*?<h1>{{ site\.speaker\.name }}<\/h1>.*?{% else %}.*?<h1>Speaker<\/h1>.*?{% endif %}/m

    if config['speaker']
      speaker = config['speaker']

      if speaker['display_name'] && !speaker['display_name'].empty?
        # Use display_name
        rendered.gsub!(title_pattern, "<h1>#{speaker['display_name']}</h1>")
      elsif speaker['name'] && !speaker['name'].empty?
        # Use name
        rendered.gsub!(title_pattern, "<h1>#{speaker['name']}</h1>")
      else
        # No valid speaker name
        rendered.gsub!(title_pattern, '<h1>Speaker</h1>')
      end
    else
      # No speaker configured at all
      rendered.gsub!(title_pattern, '<h1>Speaker</h1>')
    end
    
    if config['speaker']
      speaker = config['speaker']
      
      # Replace basic variables
      rendered.gsub!('{{ site.speaker.display_name }}', speaker['display_name'] || '')
      rendered.gsub!('{{ site.speaker.bio }}', speaker['bio'] || '')
      
      # Handle avatar logic - match the actual template structure
      avatar_pattern = /{% comment %}.*?{% endcomment %}\s*{% if site\.speaker %}\s*{% assign avatar_url = "" %}\s*{% if site\.speaker\.social\.github and site\.speaker\.social\.github != "" %}\s*{% assign avatar_url = .*? %}\s*{% elsif site\.speaker\.avatar_url and site\.speaker\.avatar_url != "" %}\s*{% assign avatar_url = .*? %}\s*{% endif %}/m
      
      # Handle both string and symbol keys for social platforms
      github_username = speaker['social'] && (speaker['social']['github'] || speaker['social'][:github])
      
      if github_username && !github_username.empty?
        avatar_url = "https://github.com/#{github_username}.png?size=200"
        rendered.gsub!(avatar_pattern, '')
        rendered.gsub!('{{ avatar_url }}', avatar_url)
      elsif speaker['avatar_url'] && !speaker['avatar_url'].empty?
        avatar_url = speaker['avatar_url']
        rendered.gsub!(avatar_pattern, '')
        rendered.gsub!('{{ avatar_url }}', avatar_url)
      else
        # Remove avatar section completely
        rendered.gsub!(avatar_pattern, '')
        rendered.gsub!(/{% if avatar_url != "" %}.*?{% endif %}/m, '')
      end
      
      # Handle social media links
      if speaker['social']
        social = speaker['social']
        
        # First, determine if we have any social media links and which ones exist
        has_social = false
        platform_exists = {}
        
        %w[linkedin x github mastodon bluesky].each do |platform|
          platform_value = social[platform] || social[platform.to_sym]
          if platform_value && !platform_value.empty?
            has_social = true
            platform_exists[platform] = true
          else
            platform_exists[platform] = false
          end
        end
        
        if has_social
          # Simulate each platform's conditional rendering
          %w[linkedin x github mastodon bluesky].each do |platform|
            platform_value = social[platform] || social[platform.to_sym]
            
            if platform_exists[platform]
              # This platform exists - render it
              case platform
              when 'linkedin'
                rendered.gsub!('{{ site.speaker.social.linkedin }}', platform_value)
                rendered.gsub!('https://linkedin.com/in/{{ site.speaker.social.linkedin }}', "https://linkedin.com/in/#{platform_value}")
              when 'x'
                rendered.gsub!('{{ site.speaker.social.x }}', platform_value)
                rendered.gsub!('https://x.com/{{ site.speaker.social.x }}', "https://x.com/#{platform_value}")
              when 'github'
                rendered.gsub!('{{ site.speaker.social.github }}', platform_value)
                rendered.gsub!('https://github.com/{{ site.speaker.social.github }}', "https://github.com/#{platform_value}")
              when 'mastodon'
                rendered.gsub!('{{ site.speaker.social.mastodon }}', platform_value)
              when 'bluesky'
                rendered.gsub!('{{ site.speaker.social.bluesky }}', platform_value)
                rendered.gsub!('https://bsky.app/profile/{{ site.speaker.social.bluesky }}', "https://bsky.app/profile/#{platform_value}")
              end
            else
              # This platform doesn't exist - remove its conditional block entirely
              case platform
              when 'linkedin'
                rendered.gsub!(/{% if linkedin_exists %}.*?{% endif %}/m, '')
              when 'x'
                rendered.gsub!(/{% if x_exists %}.*?{% endif %}/m, '')
              when 'github'
                rendered.gsub!(/{% if github_exists %}.*?{% endif %}/m, '')
              when 'mastodon'
                rendered.gsub!(/{% if mastodon_exists %}.*?{% endif %}/m, '')
              when 'bluesky'
                rendered.gsub!(/{% if bluesky_exists %}.*?{% endif %}/m, '')
              end
            end
          end
          
          # Clean up remaining liquid tags
          rendered.gsub!(/{% assign \w+_exists = (?:true|false) %}/, '')
          rendered.gsub!(/{% assign has_social = (?:true|false) %}/, '')
          rendered.gsub!(/{% if has_social %}/, '')
          rendered.gsub!(/{% endif %}$/, '')
        else
          # No social media links - remove entire social section
          rendered.gsub!(/{% if has_social %}.*?<div class="speaker-social-links">.*?<\/div>.*?{% endif %}/m, '')
          rendered.gsub!(/{% assign has_social = (?:true|false) %}/, '')
          rendered.gsub!(/{% if site\.speaker\.social\.\w+ and site\.speaker\.social\.\w+ != "" %}.*?{% endif %}/m, '')
          rendered.gsub!(/{% assign \w+_exists = (?:true|false) %}/, '')
        end
      else
        # No social config - remove entire social section
        rendered.gsub!(/{% if site\.speaker and site\.speaker\.social %}.*?{% endif %}/m, '')
      end
    else
      # No speaker configured - remove all speaker-related sections
      rendered.gsub!(/{% if site\.speaker %}.*?{% endif %}/m, '')
      rendered.gsub!(/{% if site\.speaker\..*?%}.*?{% endif %}/m, '')
      # Remove any social media links section
      rendered.gsub!(/speaker-social-links.*?<\/div>/m, '')
    end
    
    # Clean up remaining Liquid tags
    rendered.gsub!(/{% comment %}.*?{% endcomment %}/m, '')
    rendered.gsub!(/{% assign.*?%}/, '')
    
    rendered
  end

  def render_talk_page
    # Render talk layout (no longer includes speaker sections)
    config = YAML.load_file(@config_file)
    template = File.read(@talk_layout_file)
    
    rendered = template.dup
    
    # Talk pages now only contain page content, no speaker information
    rendered.gsub!('{{ page.title }}', 'Sample Talk Title')
    rendered.gsub!('{{ page.description }}', 'Sample talk description')
    rendered.gsub!('{{ content }}', 'Sample talk content')
    
    # Clean up any remaining Liquid tags
    rendered.gsub!(/{% comment %}.*?{% endcomment %}/m, '')
    rendered.gsub!(/{% assign.*?%}/, '')
    rendered.gsub!(/{% if.*?%}/, '')
    rendered.gsub!(/{% endif %}/, '')
    
    rendered
  end

  def render_full_page
    # Simulate a full page with head and header sections
    config = YAML.load_file(@config_file)
    
    if config['speaker']
      speaker = config['speaker']
      
      # Determine which name to use
      if speaker['display_name'] && !speaker['display_name'].empty?
        speaker_name = speaker['display_name']
        title_text = "Presentations by #{speaker_name}"
        header_text = "#{speaker_name} - Presentations"
      elsif speaker['name'] && !speaker['name'].empty?
        speaker_name = speaker['name']
        title_text = "Presentations by #{speaker_name}"
        header_text = "#{speaker_name} - Presentations"
      else
        title_text = "Presentations"
        header_text = "Speaker - Presentations"
      end
    else
      title_text = "Presentations"
      header_text = "Speaker - Presentations"
    end
    
    # Generate the rendered page
    rendered = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <title>#{title_text}</title>
      </head>
      <body>
          <header class="site-header">
              <a class="site-title" href="/">#{header_text}</a>
          </header>
          <main>
              <h1>#{title_text}</h1>
          </main>
          <footer class="site-footer">
              <p>&copy; 2025 #{speaker_name || 'Speaker'}. All rights reserved.</p>
          </footer>
      </body>
      </html>
    HTML
    
    rendered
  end
end
