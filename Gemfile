# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Local development: use the sibling checkout until ask-local is published.
gem "ask-local", path: "../ask-local" if File.directory?(File.expand_path("../ask-local", __dir__))

group :test do
  gem "minitest", "~> 5.25"
  gem "mocha", "~> 3.1"
  gem "rake", "~> 13.0"
  gem "simplecov", "~> 0.22"
end
