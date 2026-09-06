# frozen_string_literal: true

module Ask
  module Local
    # Helpers for app code that needs the stable local URL.
    # Never hardcode localhost:3000 — read the injected env instead.
    module Rails
      module_function

      # Full public URL, e.g. https://fix-ui.myapp.localhost
      def url(fallback: "http://localhost:3000")
        ENV["ASK_LOCAL_URL"] || fallback
      end

      # Bare hostname, e.g. fix-ui.myapp.localhost
      def host(fallback: "localhost")
        url(fallback: nil)&.sub(%r{\Ahttps?://}, "")&.split(":")&.first || fallback
      end

      # False outside ask-local (plain `rails s`).
      def proxied?
        !ENV["ASK_LOCAL_URL"].nil? && !ENV["ASK_LOCAL_URL"].empty?
      end

      # Host authorization patterns for config.hosts in development.
      # TLDs default to ASK_LOCAL_TLD (comma separated) or "localhost",
      # so custom-TLD setups work without regenerating config.
      def host_patterns(tlds: nil)
        tld_list(tlds).flat_map do |tld|
          [/\A.+\.#{Regexp.escape(tld)}\z/, /\A#{Regexp.escape(tld)}\z/]
        end
      end

      # Action Cable origin patterns for development.
      def cable_origins(tlds: nil)
        tld_list(tlds).map { |tld| %r{\Ahttps?://.+\.#{Regexp.escape(tld)}(:\d+)?\z} }
      end

      def tld_list(tlds)
        list = tlds || ENV["ASK_LOCAL_TLD"]&.split(",")&.map(&:strip)
        list = list.to_a.reject(&:nil?).map(&:to_s).reject(&:empty?)
        list.empty? ? ["localhost"] : list.map(&:downcase).uniq
      end
    end
  end
end
