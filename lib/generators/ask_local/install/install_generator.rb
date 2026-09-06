# frozen_string_literal: true

require "rails/generators"

module AskLocal
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Wires a Rails app into ask-local: hosts, Cable origins, Procfile $PORT, initializer"

      class_option :tld, type: :string, default: "localhost",
        desc: "TLD ask-local serves this app under"

      def create_initializer
        template "initializer.rb", "config/initializers/ask_local.rb"
      end

      def patch_development_hosts
        tld = options[:tld]
        sentinel = "Ask::Local::Rails.host_patterns"
        path = app_path("config/environments/development.rb")
        return unless File.file?(path)

        content = File.read(path)
        return if content.include?(sentinel)

        inject_into_file path,
          "\n  # ask-local: allow stable .#{tld} URLs (https://<app>.#{tld}).\n" \
          "  config.hosts.concat(Ask::Local::Rails.host_patterns(tlds: [#{tld.dump}]))\n",
          after: "Rails.application.configure do\n"
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

      def rewrite_procfile_ports
        %w[Procfile.dev Procfile].each do |file|
          path = app_path(file)
          next unless File.file?(path)

          Ask::Local::Rails::ProcfileRewrite.rewrite(path) do |status, message|
            say_status status, message, status == :rewrite ? :green : :yellow
          end
        end
      end

      def create_ask_local_config
        return if File.file?(app_path("ask-local.json"))

        create_file "ask-local.json", "{}\n"
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
