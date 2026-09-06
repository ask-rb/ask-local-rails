# frozen_string_literal: true

require_relative "lib/ask/local/rails/version"

Gem::Specification.new do |spec|
  spec.name = "ask-local-rails"
  spec.version = Ask::Local::Rails::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "Rails integration for ask-local"
  spec.description = "Railtie, install generator, and helpers wiring a Rails app " \
                     "into ask-local's stable .localhost URLs: host authorization, " \
                     "Action Cable origins, Procfile $PORT rewrite, and an " \
                     "agent skill for local development."
  spec.homepage = "https://github.com/ask-rb/ask-local-rails"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "ask-local", ">= 0.1.0"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 3.1"
  spec.add_development_dependency "rake", "~> 13.0"
end
