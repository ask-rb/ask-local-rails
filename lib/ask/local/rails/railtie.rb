# frozen_string_literal: true

module Ask
  module Local
    module Rails
      class Railtie < ::Rails::Railtie
        # Warn at boot when Host Authorization would reject the .localhost
        # origin the proxy serves. The generator normally adds the patterns;
        # this catches apps that skipped it or run custom TLDs.
        initializer "ask_local_rails.hosts" do |app|
          next unless ::Rails.env.development?
          next unless Ask::Local::Rails.proxied?

          host = Ask::Local::Rails.host
          begin
            authorized = app.config.hosts.any? do |pattern|
              pattern.is_a?(Regexp) ? host.match?(pattern) : pattern == host
            end
            unless authorized
              ::Rails.logger&.warn(
                "[ask-local] Host #{host} is not in config.hosts. " \
                "Run: rails generate ask_local:install"
              )
            end
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
