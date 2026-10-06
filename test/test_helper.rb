# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "server_stats"
require "fileutils"
require "stringio"

# Lightweight, zero-dependency assertion library
module TestRunner
  class << self
    attr_accessor :passed, :failed, :failures

    def reset!
      @passed = 0
      @failed = 0
      @failures = []
    end

    def report
      puts "\n" + "=" * 50
      puts "Test Results: #{@passed} passed, #{@failed} failed."
      if @failed.positive?
        puts "\nFailures:"
        @failures.each { |f| puts " - #{f}" }
      end
      puts "=" * 50
      @failed.zero?
    end
  end

  def assert(condition, message = "Expected condition to be truthy")
    if condition
      TestRunner.passed += 1
      print "."
    else
      TestRunner.failed += 1
      TestRunner.failures << message
      print "F"
    end
  end

  def assert_equal(expected, actual, message = nil)
    msg = message || "Expected #{expected.inspect}, got #{actual.inspect}"
    assert(expected == actual, msg)
  end

  def assert_in_delta(expected, actual, delta = 0.01, message = nil)
    msg = message || "Expected #{expected} +- #{delta}, got #{actual}"
    assert((expected - actual).abs <= delta, msg)
  end

  def assert_match(pattern, actual, message = nil)
    msg = message || "Expected #{actual.inspect} to match #{pattern.inspect}"
    assert(pattern.match?(actual.to_s), msg)
  end

  def refute(condition, message = "Expected condition to be falsy")
    assert(!condition, message)
  end
end

TestRunner.reset!
