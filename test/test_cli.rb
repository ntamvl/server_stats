# frozen_string_literal: true

require_relative "test_helper"
require_relative "test_server_stats"
require "server_stats/cli"

class CLITest
  include TestRunner

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def run
    puts "\nRunning CLITest..."

    # Use MockProvider for deterministic output
    original_collector = ServerStats.collector
    ServerStats.collector = ServerStats::Collector.new(provider: MockProvider.new)

    # Test CLI --json
    cli = ServerStats::CLI.new(["--json"])
    cli.parse_options
    out = capture_stdout { cli.execute_command }
    parsed = JSON.parse(out)
    assert parsed.key?("cpu")
    assert parsed.key?("memory")
    assert_equal 4, parsed["cpu"]["cores"]

    # Test CLI --cpu --json
    cli = ServerStats::CLI.new(["--cpu", "--json"])
    cli.parse_options
    out = capture_stdout { cli.execute_command }
    parsed = JSON.parse(out)
    assert_equal 4, parsed["cores"]
    assert_equal 22.5, parsed["usage_percent"]

    # Test CLI --memory
    cli = ServerStats::CLI.new(["--memory"])
    cli.parse_options
    out = capture_stdout { cli.execute_command }
    assert_match(/RAM Total:\s+8.00 GB/, out)

    # Test CLI --disk /data
    cli = ServerStats::CLI.new(["--disk", "/data"])
    cli.parse_options
    out = capture_stdout { cli.execute_command }
    assert_match(/Mount Path:\s+\/data/, out)
    assert_match(/Disk Total:\s+50.00 GB/, out)

    # Test CLI --system
    cli = ServerStats::CLI.new(["--system"])
    cli.parse_options
    out = capture_stdout { cli.execute_command }
    assert_match(/OS:\s+MockOS 1.0/, out)
    assert_match(/Hostname:\s+mock-host/, out)

    # Test CLI default summary
    cli = ServerStats::CLI.new([])
    cli.parse_options
    out = capture_stdout { cli.execute_command }
    assert_match(/SERVER STATS REPORT/, out)
    assert_match(/MockOS/, out)

    # Restore collector
    ServerStats.collector = original_collector
  end
end
