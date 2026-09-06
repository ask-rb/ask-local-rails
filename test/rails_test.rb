# frozen_string_literal: true

require_relative "test_helper"

class RailsHelpersTest < Minitest::Test
  def setup
    @orig = ENV["ASK_LOCAL_URL"]
  end

  def teardown
    ENV["ASK_LOCAL_URL"] = @orig
  end

  def test_url_reads_env
    ENV["ASK_LOCAL_URL"] = "https://fix-ui.myapp.localhost"
    assert_equal "https://fix-ui.myapp.localhost", Ask::Local::Rails.url
    assert_equal "fix-ui.myapp.localhost", Ask::Local::Rails.host
    assert Ask::Local::Rails.proxied?
  end

  def test_fallbacks_without_env
    ENV.delete("ASK_LOCAL_URL")
    assert_equal "http://localhost:3000", Ask::Local::Rails.url
    assert_equal "localhost", Ask::Local::Rails.host
    refute Ask::Local::Rails.proxied?
  end

  def test_host_patterns_match_subdomains
    patterns = Ask::Local::Rails.host_patterns(tlds: ["localhost"])
    assert patterns.any? { |p| "myapp.localhost".match?(p) }
    assert patterns.any? { |p| "fix-ui.api.myapp.localhost".match?(p) }
    refute patterns.any? { |p| "myapp.test".match?(p) }
  end

  def test_cable_origins
    origins = Ask::Local::Rails.cable_origins(tlds: ["localhost"])
    assert origins.any? { |p| "https://myapp.localhost".match?(p) }
    refute origins.any? { |p| "https://evil.com".match?(p) }
  end

  def test_tld_defaults_from_env
    ENV["ASK_LOCAL_TLD"] = "preview.example.com,localhost"
    patterns = Ask::Local::Rails.host_patterns
    assert patterns.any? { |p| "myapp.preview.example.com".match?(p) }
    assert patterns.any? { |p| "myapp.localhost".match?(p) }
    refute patterns.any? { |p| "myapp.test".match?(p) }
  ensure
    ENV.delete("ASK_LOCAL_TLD")
  end

  def test_no_skill_shipped_here_lives_in_ask_local
    refute File.exist?(File.expand_path("../lib/ask/skills", __dir__)),
      "the ask-local skill ships in the ask-local gem, not here"
  end
end

class VersionTest < Minitest::Test
  def test_version_format
    assert_match(/\A\d+\.\d+\.\d+\z/, Ask::Local::Rails::VERSION)
  end

  def test_gemspec_valid
    spec = Gem::Specification.load(File.expand_path("../ask-local-rails.gemspec", __dir__))
    refute_nil spec
    assert_equal "ask-local-rails", spec.name
  end
end
