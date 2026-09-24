# frozen_string_literal: true

require 'liquid'
require 'uri'

# Validates third-party resource URLs and exposes normalized player URLs to
# Liquid. Invalid and untrusted URLs return nil so the include can fail closed
# to its ordinary link fallback.
module ResourceEmbedFilters
  YOUTUBE_HOSTS = %w[youtube.com www.youtube.com m.youtube.com].freeze
  VIMEO_HOSTS = %w[vimeo.com www.vimeo.com player.vimeo.com].freeze
  NOTIST_HOSTS = %w[noti.st www.noti.st].freeze

  def youtube_resource(url)
    uri = resource_uri(url)
    return unless uri

    params = query_params(uri.query)
    video_id = if %w[youtu.be www.youtu.be].include?(uri.host.downcase)
                 uri.path.delete_prefix('/').split('/').first
               elsif YOUTUBE_HOSTS.include?(uri.host.downcase)
                 youtube_video_id(uri, params)
               end
    return unless video_id&.match?(/\A[A-Za-z0-9_-]{11}\z/)

    fragment_params = query_params(uri.fragment)
    timestamp = params['start'] || params['t'] || fragment_params['t']
    start = youtube_start_seconds(timestamp)
    embed_url = "https://www.youtube.com/embed/#{video_id}"
    embed_url += "?start=#{start}" unless start.nil?
    { 'video_id' => video_id, 'embed_url' => embed_url }
  rescue ArgumentError
    nil
  end

  def vimeo_resource(url)
    uri = resource_uri(url)
    return unless uri && VIMEO_HOSTS.include?(uri.host.downcase)

    segments = uri.path.split('/').reject(&:empty?)
    if uri.host.downcase == 'player.vimeo.com'
      return unless segments.shift == 'video'

      video_id = segments.shift
      path_hash = segments.shift
    else
      video_index = segments.index { |segment| segment.match?(/\A[1-9]\d*\z/) }
      return unless video_index

      video_id = segments[video_index]
      path_hash = segments[video_index + 1]
    end
    return unless video_id&.match?(/\A[1-9]\d*\z/)

    privacy_hash = query_params(uri.query)['h'] || path_hash
    privacy_hash = nil unless privacy_hash&.match?(/\A[A-Za-z0-9]+\z/)
    embed_url = "https://player.vimeo.com/video/#{video_id}"
    embed_url += "?h=#{privacy_hash}" if privacy_hash
    { 'video_id' => video_id, 'embed_url' => embed_url }
  rescue ArgumentError
    nil
  end

  def notist_embed_url(url, custom_domains = nil)
    uri = resource_uri(url)
    return unless uri

    host = uri.host.downcase
    segments = uri.path.split('/').reject(&:empty?)
    if NOTIST_HOSTS.include?(host)
      username, presentation_id = segments
      return unless username&.match?(/\A[A-Za-z0-9_-]+\z/)

      base_url = "https://noti.st/#{username}"
    elsif trusted_notist_domains(custom_domains).include?(host)
      presentation_id = segments.first
      base_url = "https://#{host}"
    else
      return
    end
    return unless presentation_id&.match?(/\A[A-Za-z0-9]{6}\z/)

    "#{base_url}/#{presentation_id}/embed"
  end

  def trusted_notist_origins(custom_domains)
    trusted_notist_domains(custom_domains).map { |host| "https://#{host}" }
  end

  private

  def resource_uri(url)
    uri = URI.parse(url.to_s)
    return unless %w[http https].include?(uri.scheme) && uri.host && !uri.userinfo
    default_port = uri.scheme == 'https' ? 443 : 80
    return unless uri.port == default_port

    uri
  rescue URI::InvalidURIError
    nil
  end

  def query_params(value)
    URI.decode_www_form(value.to_s).to_h
  end

  def youtube_video_id(uri, params)
    return params['v'] if uri.path == '/watch'

    uri.path.match(%r{\A/(?:live|shorts|embed)/([A-Za-z0-9_-]+)\z})&.[](1)
  end

  def youtube_start_seconds(timestamp)
    value = timestamp.to_s
    return value.to_i if value.match?(/\A\d+\z/)

    parts = value.match(/\A(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?\z/)
    return unless parts && !value.empty?

    parts[1].to_i * 3600 + parts[2].to_i * 60 + parts[3].to_i
  end

  def trusted_notist_domains(domains)
    Array(domains).filter_map do |domain|
      host = domain.to_s.downcase
      host if host.match?(/\A(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}\z/)
    end
  end
end

Liquid::Template.register_filter(ResourceEmbedFilters)
