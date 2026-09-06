# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/generators/ask_local/install/install_generator"

class InstallGeneratorTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    # Fake Rails app tree: enough for the generator's file operations.
    FileUtils.mkdir_p(File.join(@dir, "config", "environments"))
    File.write(File.join(@dir, "config", "environments", "development.rb"),
      <<~RUBY)
        require "rails"

        Rails.application.configure do
          config.cache_classes = false
        end
      RUBY
    File.write(File.join(@dir, "Procfile.dev"),
      "web: bin/rails server -p 3000\nworker: bundle exec sidekiq\n")
    File.write(File.join(@dir, "Gemfile"), "gem \"rails\"\n")
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def run_generator
    AskLocal::Generators::InstallGenerator.new([], { tld: "localhost" },
      destination_root: @dir).tap do |gen|
      %w[create_initializer patch_development_hosts patch_action_cable
        rewrite_procfile_ports create_ask_local_config].each { |step| gen.send(step) }
    end
  end

  def test_creates_initializer_and_config
    quiet_io { run_generator }
    assert File.file?(File.join(@dir, "config", "initializers", "ask_local.rb"))
    assert File.file?(File.join(@dir, "ask-local.json"))
  end

  def test_injects_hosts_and_cable_origins
    quiet_io { run_generator }
    dev = File.read(File.join(@dir, "config", "environments", "development.rb"))
    assert_includes dev, "config.hosts.concat(Ask::Local::Rails.host_patterns"
    assert_includes dev, "allowed_request_origins.concat"
    # Idempotent: second run does not duplicate.
    quiet_io { run_generator }
    dev2 = File.read(File.join(@dir, "config", "environments", "development.rb"))
    assert_equal dev.scan("host_patterns").length, dev2.scan("host_patterns").length
  end

  def test_rewrites_procfile_ports
    quiet_io { run_generator }
    procfile = File.read(File.join(@dir, "Procfile.dev"))
    assert_includes procfile, "web: bin/rails server -p $PORT"
    assert_includes procfile, "worker: bundle exec sidekiq"
  end

  def quiet_io
    orig = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = orig
  end
end
