# frozen_string_literal: true

require_relative "test_helper"

class ProcfileRewriteTest < Minitest::Test
  PW = Ask::Local::Rails::ProcfileRewrite

  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def path(name = "Procfile.dev")
    File.join(@dir, name)
  end

  def test_hardcoded_port_rewritten
    File.write(path, "web: bin/rails server -p 3000\n")
    events = []
    assert PW.rewrite(path) { |s, m| events << [s, m] }
    assert_equal "web: bin/rails server -p $PORT\n", File.read(path)
    assert_includes events, [:rewrite, path]
  end

  def test_real_fixture_shape
    # Copy of the ask-local-apps fixture: mixed web + worker lines.
    src = File.expand_path("../../ask-local-apps/rails8-hardcoded-port/Procfile.dev", __dir__)
    if File.file?(src)
      FileUtils.cp(src, path)
      PW.rewrite(path)
      content = File.read(path)
      assert_includes content, "web: bin/rails server -p $PORT"
      assert_includes content, "worker: bundle exec sidekiq"
    else
      skip "fixture fleet not present"
    end
  end

  def test_idempotent_second_run
    File.write(path, "web: bin/rails s --port=3000\n")
    assert PW.rewrite(path)
    refute PW.rewrite(path)
    assert_equal "web: bin/rails s -p $PORT\n", File.read(path)
  end

  def test_already_dollar_port_untouched
    original = "web: bin/rails server -p $PORT\n"
    File.write(path, original)
    refute PW.rewrite(path)
    assert_equal original, File.read(path)
  end

  def test_compound_lines_left_alone_with_warning
    File.write(path, "web: bin/rails s -p 3000 && bin/rails log:clear\nworker: sidekiq | grep -v hb\n")
    events = []
    refute PW.rewrite(path) { |s, m| events << [s, m] }
    assert_equal 2, events.count { |s, _| s == :skip }
    assert_includes File.read(path), "-p 3000"
  end

  def test_comments_and_blanks_untouched
    original = "# comment\n\nworker: bundle exec sidekiq\n"
    File.write(path, original)
    refute PW.rewrite(path)
    assert_equal original, File.read(path)
  end

  def test_worker_line_without_port_untouched
    original = "web: bin/rails s -p 3000\nworker: bundle exec sidekiq\n"
    File.write(path, original)
    assert PW.rewrite(path)
    assert_includes File.read(path), "worker: bundle exec sidekiq"
  end

  def test_missing_file_returns_false
    refute PW.rewrite(File.join(@dir, "nope"))
  end
end
