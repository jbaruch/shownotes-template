# frozen_string_literal: true

require 'minitest/autorun'
require 'jekyll'
require 'nokogiri'
require 'tmpdir'
require 'fileutils'
require_relative '../../../_plugins/markdown_parser'
require_relative '../../../_plugins/skill_processor'

resource_filters = File.expand_path('../../../_plugins/resource_embed_filters', __dir__)
require resource_filters if File.exist?("#{resource_filters}.rb")

class LlmsTxtTest < Minitest::Test
  ROOT = File.expand_path('../../..', __dir__)
  SKILL_STEM = 'DEMO-ai-coding-assistants-2025'
  RECORDING = 'https://www.youtube.com/watch?v=sTcx0EvILr4&t=18039s'

  def setup
    @dir = Dir.mktmpdir('llms_txt_test')
    %w[_layouts _includes _config.yml index.md llms.txt].each do |path|
      source = File.join(ROOT, path)
      FileUtils.cp_r(source, @dir) if File.exist?(source)
    end
    %w[_talks _skills].each { |path| FileUtils.cp_r(File.join(ROOT, path), @dir) }

    talk_path = File.join(@dir, '_talks', "#{SKILL_STEM}.md")
    raw = File.read(talk_path).sub('layout: talk', "layout: talk\npermalink: /custom-talk/")
    raw = raw.sub('**Date:** 2025-04-08', "**Date:** 2025-04-08\n**Video:** [Recording](#{RECORDING})")
    File.write(talk_path, raw)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  ['', '/preview'].each do |baseurl|
    define_method("test_index_and_discovery_with_#{baseurl.empty? ? 'root' : 'subpath'}_hosting") do
      site, text = build(baseurl)
      origin = "https://example.com#{baseurl}"
      entries = text.split('## Talks — newest first', 2).last.lines.grep(/^- \[/)

      assert text.start_with?('# ')
      refute_match(/\{%|\{\{|<html|<!DOCTYPE/, text)
      assert_equal 3, entries.size
      assert_includes text, "[Recording](#{RECORDING})"
      assert_equal 2, text.scan("#{origin}/skills/#{SKILL_STEM}/SKILL.md").size
      assert_includes text, "#{origin}/custom-talk/"
      assert_includes text, 'Prefer the matching Agent Skill'
      assert_includes text, 'retrieve the transcript or captions'

      site.collections['talks'].docs.each do |talk|
        entry = entries.find { |line| line.include?("(#{origin}#{talk.url})") }
        refute_nil entry, "missing talk #{talk.url}"
        assert_equal !!talk.data['skill'], entry.include?('[Agent Skill]')
      end

      pages = site.pages.select { |page| page.name == 'index.md' }.map(&:output)
      pages.concat(site.collections['talks'].docs.map(&:output))
      pages.each do |html|
        link = Nokogiri::HTML(html).at_css('head link[rel="describedby"]')
        refute_nil link
        assert_equal "#{baseurl}/llms.txt", link['href']
      end
    end
  end

  def test_site_without_skills_still_lists_all_talks
    FileUtils.rm_rf(File.join(@dir, '_skills'))
    _, text = build('')

    refute_includes text, '## Agent Skills'
    refute_includes text, '[Agent Skill]'
    assert_equal 3, text.split('## Talks — newest first', 2).last.lines.grep(/^- \[/).size
  end

  private

  def build(baseurl)
    site = Jekyll::Site.new(Jekyll.configuration(
      'source' => @dir,
      'destination' => File.join(@dir, '_site'),
      'url' => 'https://example.com',
      'baseurl' => baseurl,
      'quiet' => true
    ))
    site.process
    [site, File.read(File.join(site.dest, 'llms.txt'))]
  end
end
