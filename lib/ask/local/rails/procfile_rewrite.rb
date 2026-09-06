# frozen_string_literal: true

module Ask
  module Local
    module Rails
      # Rewrites hardcoded ports in Procfile lines to -p $PORT so the
      # ask-local runner's injected PORT wins. Pure file logic, no Rails
      # dependency, so it is unit-testable without a Rails app context.
      module ProcfileRewrite
        COMPOUND = /&&|\|\||[|;]/.freeze
        HARDCODED_PORT = /(?:-p|--port)[=\s]+\d+/.freeze

        module_function

        # Returns true when the file changed. Yields (status, message)
        # pairs for say_status. Compound lines it cannot classify are
        # left alone with a warning — the portless lesson: never
        # silently rewrite what you cannot parse.
        def rewrite(path)
          lines = File.readlines(path, chomp: true)
          changed = false
          skipped = []
          updated = lines.map do |line|
            stripped = line.strip
            if stripped.empty? || stripped.start_with?("#") || !stripped.include?(":")
              line
            elsif stripped.match?(COMPOUND)
              skipped << line
              line
            else
              rewritten = line.gsub(HARDCODED_PORT, '-p $PORT')
              changed ||= (rewritten != line)
              rewritten
            end
          end
          File.write(path, "#{updated.join("\n")}\n") if changed
          if block_given?
            skipped.each { |l| yield(:skip, "#{path}: compound line left alone: #{l.strip}") }
            yield(:rewrite, path) if changed
          end
          changed
        rescue SystemCallError
          false
        end
      end
    end
  end
end
