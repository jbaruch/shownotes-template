# frozen_string_literal: true

require_relative '../lib/talk_renderer'

# Liquid filter to render embedded resources
module Jekyll
  module EmbedResourcesFilter
    def render_embedded_resources(resources)
      return '' if resources.nil? || resources.empty?
      
      renderer = TalkRenderer.new
      renderer.generate_resources_html(resources)
    end
  end
end

# Register the filter with Jekyll/Liquid
if defined?(Liquid)
  Liquid::Template.register_filter(Jekyll::EmbedResourcesFilter)
end