# frozen_string_literal: true

require 'minitest/autorun'
require 'liquid'
require 'uri'

RESOURCE_FILTER_PATH = File.expand_path('../../../_plugins/resource_embed_filters', __dir__)
require RESOURCE_FILTER_PATH if File.exist?("#{RESOURCE_FILTER_PATH}.rb")

# Exercises the Liquid include used by talk and archive pages rather than the
# parallel renderer helpers under lib/.
class EmbeddedResourceIncludeTest < Minitest::Test
  INCLUDE_PATH = File.expand_path('../../../_includes/embedded_resource.html', __dir__)
  LAYOUT_PATH = File.expand_path('../../../_layouts/default.html', __dir__)
  CUSTOM_NOTIST_HOST = 'slides.example.test'

  module JekyllFilterStubs
    def relative_url(input)
      input.to_s
    end
  end
  Liquid::Template.register_filter(JekyllFilterStubs)

  def setup
    @template = Liquid::Template.parse(File.read(INCLUDE_PATH))
  end

  def render(url, type: 'video', custom_domains: [], **extra)
    assigns = {
      'include' => { 'url' => url, 'type' => type }.merge(extra.transform_keys(&:to_s)),
      'site' => { 'resource_embeds' => { 'notist_custom_domains' => custom_domains } }
    }
    html = @template.render(assigns)
    assert_empty @template.errors, "Liquid errors while rendering #{url}"
    html
  end

  def test_vimeo_url_shapes_render_normalized_player_embeds
    urls = {
      'https://vimeo.com/1223667266' => 'https://player.vimeo.com/video/1223667266',
      'https://vimeo.com/1223667266?fl=pl&fe=sh' => 'https://player.vimeo.com/video/1223667266',
      'https://vimeo.com/1223667266/9f3c1ab2de' => 'https://player.vimeo.com/video/1223667266?h=9f3c1ab2de',
      'https://player.vimeo.com/video/1223667266?h=9f3c1ab2de&autoplay=1' =>
        'https://player.vimeo.com/video/1223667266?h=9f3c1ab2de',
      'https://vimeo.com/channels/staffpicks/1223667266' => 'https://player.vimeo.com/video/1223667266'
    }

    urls.each do |source, expected|
      html = render(source)
      assert_includes html, %(src="#{expected}"), source
      assert_includes html, 'video-embed', source
      refute_includes html, 'resource-fallback', source
    end
  end

  def test_vimeo_preview_uses_placeholder_and_no_iframe
    html = render('https://vimeo.com/1223667266', preview_mode: true, talk_url: '/talks/demo/')

    assert_includes html, 'src="/assets/images/placeholder-thumbnail.svg"'
    assert_includes html, 'href="/talks/demo/"'
    assert_includes html, 'play-overlay'
    refute_includes html, '<iframe'
  end

  def test_vimeo_lookalikes_and_invalid_ids_fall_back
    [
      'https://example.com/vimeo.com/1223667266',
      'https://vimeo.com.example.com/1223667266',
      'https://vimeo.com/not-a-video',
      'https://user:password@vimeo.com/1223667266'
    ].each do |url|
      html = render(url)
      assert_includes html, 'resource-fallback', url
      refute_includes html, '<iframe', url
    end
  end

  def test_youtube_timestamp_formats_and_url_shapes
    urls = [
      'https://www.youtube.com/watch?v=fi_mGfiBs4M&t=14345',
      'https://www.youtube.com/watch?t=14345&v=fi_mGfiBs4M',
      'https://m.youtube.com/watch?v=fi_mGfiBs4M&t=14345s',
      'https://youtu.be/fi_mGfiBs4M?t=3h59m5s',
      'https://www.youtube.com/live/fi_mGfiBs4M?si=tracking&t=14345',
      'https://www.youtube.com/shorts/fi_mGfiBs4M?start=14345',
      'https://www.youtube.com/embed/fi_mGfiBs4M?start=14345',
      'https://youtu.be/fi_mGfiBs4M#t=3h59m5s'
    ]

    urls.each do |url|
      assert_includes render(url), 'src="https://www.youtube.com/embed/fi_mGfiBs4M?start=14345"', url
    end
  end

  def test_youtube_start_precedence_invalid_timestamps_and_preview
    assert_includes render('https://youtu.be/fi_mGfiBs4M?t=10&start=0'), '?start=0'

    %w[-1 1.5 12oops 1m2h].each do |timestamp|
      html = render("https://youtu.be/fi_mGfiBs4M?t=#{timestamp}")
      assert_includes html, 'src="https://www.youtube.com/embed/fi_mGfiBs4M"'
      refute_includes html, '?start='
    end

    preview = render('https://youtu.be/fi_mGfiBs4M?t=14345', preview_mode: true)
    assert_includes preview, 'https://img.youtube.com/vi/fi_mGfiBs4M/maxresdefault.jpg'
    refute_includes preview, '<iframe'
  end

  def test_youtube_lookalikes_and_invalid_ids_fall_back
    [
      'https://example.com/youtube.com/watch?v=fi_mGfiBs4M',
      'https://youtube.com.example.com/watch?v=fi_mGfiBs4M',
      'https://youtu.be/invalid',
      'https://www.youtube.com/live/fi_mGfiBs4M%22'
    ].each do |url|
      html = render(url)
      assert_includes html, 'resource-fallback', url
      refute_includes html, '<iframe', url
    end
  end

  def test_canonical_notist_url_embeds_and_strips_share_data
    html = render('https://noti.st/demo/sUTmZl/talk-title?share=true#slide-3', type: 'slides')

    assert_includes html, 'src="https://noti.st/demo/sUTmZl/embed"'
    assert_includes html, 'slides-embed'
    refute_includes html, 'resource-fallback'
  end

  def test_configured_custom_notist_domain_embeds
    html = render("https://#{CUSTOM_NOTIST_HOST}/sUTmZl/talk-title", type: 'slides',
                  custom_domains: [CUSTOM_NOTIST_HOST])

    assert_includes html, %(src="https://#{CUSTOM_NOTIST_HOST}/sUTmZl/embed")
  end

  def test_unconfigured_or_invalid_notist_urls_fall_back
    [
      'https://slides.example.test/sUTmZl/talk-title',
      'https://noti.st/',
      'https://noti.st/sUTmZl',
      'https://noti.st/demo/invalid-id'
    ].each do |url|
      html = render(url, type: 'slides')
      assert_includes html, 'resource-fallback', url
      refute_includes html, '<iframe', url
    end
  end

  def test_notist_preview_uses_local_thumbnail_and_no_iframe
    html = render('https://noti.st/demo/sUTmZl/talk-title', type: 'slides', preview_mode: true,
                  talk: { 'path' => '_talks/example-talk.md' }, talk_url: '/talks/example-talk/')

    assert_includes html, 'src="/assets/images/thumbnails/example-talk-thumbnail.png"'
    assert_includes html, 'href="/talks/example-talk/"'
    refute_includes html, '<iframe'
  end

  def test_embed_origins_are_allowed_only_by_frame_policy
    expected_origins = %W[
      https://www.youtube.com
      https://player.vimeo.com
      https://noti.st
      https://#{CUSTOM_NOTIST_HOST}
    ]

    %w[development production].each do |environment|
      policy = rendered_policy(environment)
      directives = policy.split(';').map(&:split).reject(&:empty?).to_h { |name, *sources| [name, sources] }

      expected_origins.each do |origin|
        assert_includes directives.fetch('frame-src'), origin, "#{environment}: #{origin}"
        directives.reject { |name, _| name == 'frame-src' }.each do |name, sources|
          refute_includes sources, origin, "#{origin} must not expand #{name}"
        end
      end
      refute_includes directives.fetch('frame-src'), '*'
    end
  end

  def test_invalid_custom_notist_domains_cannot_expand_frame_policy
    policy = rendered_policy('production', [
      'https://slides.example.test',
      'slides.example.test/path',
      'slides.example.test; script-src *',
      CUSTOM_NOTIST_HOST
    ])
    directives = policy.split(';').map(&:split).reject(&:empty?).to_h { |name, *sources| [name, sources] }

    assert_equal 1, directives.fetch('frame-src').count("https://#{CUSTOM_NOTIST_HOST}")
    refute_includes policy, 'script-src *'
    refute_includes policy, '/path'
  end

  def test_existing_google_drive_embed_still_renders
    html = render('https://drive.google.com/file/d/1M0JDvLyqiVkRDN7dk5ENjWsJDaAfXFWe/preview', type: 'slides')

    assert_includes html, 'pdf-embed'
  end

  private

  def rendered_policy(environment, custom_domains = [CUSTOM_NOTIST_HOST])
    head = File.read(LAYOUT_PATH).split('</head>', 2).first
    template = Liquid::Template.parse(head)
    html = template.render(
      'jekyll' => { 'environment' => environment },
      'site' => {
        'speaker' => {}, 'ui_theme' => {},
        'resource_embeds' => { 'notist_custom_domains' => custom_domains }
      },
      'page' => {}
    )
    assert_empty template.errors
    html.match(/http-equiv="Content-Security-Policy" content="([^"]+)"/)[1]
  end
end
