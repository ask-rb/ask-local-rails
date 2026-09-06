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
      %w[create_initializer patch_action_cable
        create_local_config].each { |step| gen.send(step) }
    end
  end

  def test_creates_initializer_and_local_config
    quiet_io { run_generator }
    assert File.file?(File.join(@dir, "config", "initializers", "ask_local.rb"))
    assert File.file?(File.join(@dir, "config", "local.yml"))
    refute File.file?(File.join(@dir, "ask-local.json")),
      "old ask-local.json must not be created"
  end

  def test_local_config_has_service_and_web_process
    quiet_io { run_generator }
    content = File.read(File.join(@dir, "config", "local.yml"))
    assert_includes content, "service:"
    assert_includes content, "web:"
    assert_includes content, "puma -b tcp://127.0.0.1:$PORT"
    assert_includes content, "proxy: true"
  end

  def test_local_config_idempotent
    quiet_io { run_generator }
    first = File.read(File.join(@dir, "config", "local.yml"))
    quiet_io { run_generator }
    assert_equal first, File.read(File.join(@dir, "config", "local.yml"))
  end

  def test_injects_cable_origins_only
    quiet_io { run_generator }
    dev = File.read(File.join(@dir, "config", "environments", "development.rb"))
    assert_includes dev, "allowed_request_origins.concat"
    refute_includes dev, "config.hosts.concat",
      "hosts patch is obsolete — RAILS_DEVELOPMENT_HOSTS handles it"
    # Idempotent: second run does not duplicate.
    quiet_io { run_generator }
    dev2 = File.read(File.join(@dir, "config", "environments", "development.rb"))
    assert_equal dev.scan("allowed_request_origins").length,
      dev2.scan("allowed_request_origins").length
  end

  def quiet_io
    orig = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = orig
  end
end
