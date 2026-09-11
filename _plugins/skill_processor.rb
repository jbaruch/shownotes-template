# frozen_string_literal: true

require_relative '../lib/utils/html_sanitizer'

module Jekyll
  # Serves a talk's SKILL.md byte-for-byte at /skills/{stem}/SKILL.md.
  #
  # Skill files live in _skills/, which Jekyll's reader ignores (underscore
  # directory), so nothing is served unless this plugin registers it.
  class SkillRawFile < StaticFile
    def initialize(site, stem, relative_source_path)
      @stem = stem
      super(site, site.source, File.dirname(relative_source_path), File.basename(relative_source_path))
    end

    def url
      "/skills/#{@stem}/SKILL.md"
    end

    def destination(dest)
      @site.in_dest_dir(dest, 'skills', @stem, 'SKILL.md')
    end
  end

  # Discovers _skills/{stem}/SKILL.md, validates it, renders the body, and
  # attaches `skill` to the talk document whose filename stem matches.
  #
  # Any validation failure raises Jekyll::Errors::FatalException naming the
  # file, so a broken skill file fails the build instead of shipping a
  # broken page. Orphan skill files (no talk with that stem) are skipped.
  class SkillProcessor < Generator
    include HtmlSanitizer

    safe true
    priority :high

    SKILLS_DIR = '_skills'
    SKILL_FILENAME = 'SKILL.md'
    NAME_PATTERN = /\A[a-z0-9]+(-[a-z0-9]+)*\z/
    NAME_MAX_LENGTH = 64
    DESCRIPTION_MAX_LENGTH = 1024
    HEADING_DEMOTION = 2
    NAME_RULE = "'name' must be lowercase letters, digits and hyphens (used as the install directory)"

    def generate(site)
      docs_by_stem = talk_docs_by_stem(site)

      skill_paths(site).each do |path|
        relative = path.delete_prefix("#{site.source}/")
        stem = File.basename(File.dirname(path))
        skill = parse_skill(File.read(path, encoding: 'utf-8'), relative)

        doc = docs_by_stem[stem]
        unless doc
          Jekyll.logger.info 'SkillProcessor:', "orphan skill #{relative} has no talk '#{stem}'; skipped"
          next
        end

        doc.data['skill'] = build_skill_data(site, skill, stem, relative)
        site.static_files << SkillRawFile.new(site, stem, relative)
        Jekyll.logger.info 'SkillProcessor:', "attached skill '#{skill['name']}' to talk '#{stem}'"
      end
    end

    private

    def talk_docs_by_stem(site)
      talks = site.collections['talks']
      return {} unless talks

      talks.docs.to_h { |doc| [File.basename(doc.path, '.md'), doc] }
    end

    def skill_paths(site)
      Dir.glob(File.join(site.source, SKILLS_DIR, '*', SKILL_FILENAME)).sort
    end

    # Returns { 'name' => String, 'description' => String, 'body' => String }
    # or raises Jekyll::Errors::FatalException with the source path.
    def parse_skill(raw, relative)
      match = raw.match(Jekyll::Document::YAML_FRONT_MATTER_REGEXP)
      fail_skill(relative, 'missing front matter (file must start with ---)') unless match

      data = load_front_matter(match[1], relative)
      name = required_string(data, 'name', relative)
      description = required_string(data, 'description', relative)
      fail_skill(relative, NAME_RULE) unless name.match?(NAME_PATTERN) && name.length <= NAME_MAX_LENGTH
      if description.length > DESCRIPTION_MAX_LENGTH
        fail_skill(relative, "'description' must be at most #{DESCRIPTION_MAX_LENGTH} characters")
      end

      { 'name' => name, 'description' => description, 'body' => match.post_match }
    end

    def load_front_matter(yaml, relative)
      data = begin
        SafeYAML.load(yaml)
      rescue Psych::SyntaxError => e
        fail_skill(relative, "front matter is not valid YAML: #{e.message}")
      end
      fail_skill(relative, 'front matter is not valid YAML: expected a mapping') unless data.is_a?(Hash)
      data
    end

    def required_string(data, key, relative)
      value = data[key]
      fail_skill(relative, "missing required field '#{key}'") unless value.is_a?(String) && !value.strip.empty?
      value.strip
    end

    def fail_skill(relative, reason)
      raise Jekyll::Errors::FatalException, "Skill #{relative}: #{reason}"
    end

    def build_skill_data(site, skill, stem, relative)
      {
        'name' => skill['name'],
        'description' => skill['description'],
        'html' => render_body(site, skill['body']),
        'url' => "/skills/#{stem}/SKILL.md",
        'source_path' => relative,
        'install_dir' => "~/.claude/skills/#{skill['name']}"
      }
    end

    # Markdown -> HTML through the site's own converter (same settings as the
    # `markdownify` filter), then the shared sanitizer, then heading demotion
    # so the body sits below the section's own <h2> in the page outline.
    def render_body(site, body)
      return '' if body.nil? || body.strip.empty?

      converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      demote_headings(sanitize_html(converter.convert(body)))
    end

    def demote_headings(html)
      html.gsub(%r{<(/?)h([1-6])\b}i) do
        level = [Regexp.last_match(2).to_i + HEADING_DEMOTION, 6].min
        "<#{Regexp.last_match(1)}h#{level}"
      end
    end
  end
end
