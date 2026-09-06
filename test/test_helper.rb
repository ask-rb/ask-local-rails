# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../ask-local/lib", __dir__)

require "ask-local-rails"
require "minitest/autorun"
require "mocha/minitest"
require "tmpdir"
require "fileutils"
