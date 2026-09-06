# frozen_string_literal: true

require_relative "ask/local/rails/version"
require_relative "ask/local/rails/helpers"
require_relative "ask/local/rails/procfile_rewrite"
require_relative "ask/local/rails/railtie" if defined?(::Rails::Railtie)

module Ask
  module Local
    module Rails
    end
  end
end
