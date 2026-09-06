# frozen_string_literal: true

require "rails/generators"

module AskLocal
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Wires a Rails app into ask-local: Cable origins, initializer, config/local.yml"

      class_option :tld, type: :string, default: "localhost",
        desc: "TLD ask-local serves this app under"

      def create_initializer
        template "initializer.rb", "config/initializers/ask_local.rb"
      end

      def patch_action_cable
        tld = options[:tld]
        sentinel = "Ask::Local::Rails.cable_origins"
        path = app_path("config/environments/development.rb")
        return unless File.file?(path)

        content = File.read(path)
        return if content.include?(sentinel)

        inject_into_file path,
          "\n  # ask-local: allow Action Cable connections from .#{tld} origins.\n" \
          "  config.action_cable.allowed_request_origins ||= []\n" \
          "  config.action_cable.allowed_request_origins.concat(Ask::Local::Rails.cable_origins(tlds: [#{tld.dump}]))\n",
          after: "Rails.application.configure do\n"
      end

      # Emit config/local.yml — the mandatory Kamal-style config.
      # web process boots the Rails app through puma on $PORT so
      # ask-local can route to it. Only writes when absent.
      def create_local_config
        path = app_path("config/local.yml")
        return if File.file?(path)

        @service = app_service_name
        @tld = options[:tld]
        template "local.yml", "config/local.yml"
      end

      # Derive the service name from the app module when possible.
      def app_service_name
        return File.basename(destination_root).downcase.gsub(/[^a-z0-9-]/, "-") unless defined?(::Rails::Application)

        app_const = ::Rails.application.class
        if app_const.respond_to?(:module_parent_name) && app_const.module_parent_name
          app_const.module_parent_name.underscore.dasherize
        else
          File.basename(destination_root).downcase.gsub(/[^a-z0-9-]/, "-")
        end
      rescue StandardError
        File.basename(destination_root).downcase.gsub(/[^a-z0-9-]/, "-")
      end

      private

      # Generators may run with a destination_root different from the
      # process cwd (test harnesses, custom destinations) — resolve file
      # checks against destination_root, which is the app root in real
      # Rails usage.
      def app_path(relative)
        File.expand_path(relative, destination_root)
      end
    end
  end
end
