# frozen_string_literal: true

# SimpleCov must be started before application code is loaded.
if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/test/'
    add_filter '/vendor/'
    add_filter '/.bundle/'

    add_group 'Renderers', 'lib/*renderer*.rb'
    add_group 'Migration', 'migrate_talk.rb'
    add_group 'Utilities', 'lib/utils'
    add_group 'Models', 'lib/models'
    add_group 'Plugins', '_plugins'

    track_files '{lib,_plugins}/**/*.rb'
    track_files 'migrate_talk.rb'
  end
end

require 'minitest/autorun'

begin
  require 'minitest/reporters'
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
rescue LoadError
  # The default Minitest reporter remains available.
end

module TestHelpers
  def fixture_path(filename)
    File.join(__dir__, 'fixtures', filename)
  end

  def read_fixture(filename)
    File.read(fixture_path(filename))
  end
end

class Minitest::Test
  include TestHelpers
end
