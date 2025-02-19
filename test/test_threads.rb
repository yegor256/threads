# frozen_string_literal: true

# (The MIT License)
#
# SPDX-FileCopyrightText: Copyright (c) 2018-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'concurrent'
require_relative '../lib/threads'

# Threads test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2025 Yegor Bugayenko
# License:: MIT
class ThreadsTest < Minitest::Test
  def test_multiple_threads
    done = Concurrent::AtomicFixnum.new
    Threads.new(10).assert do
      done.increment
    end
    assert_equal(10, done.value)
  end

  def test_multiple_threads_with_cap
    done = Concurrent::AtomicFixnum.new
    Threads.new(3).assert(20) do
      done.increment
    end
    assert_equal(20, done.value)
  end

  def test_slow_threads
    done = Concurrent::AtomicFixnum.new
    Threads.new(3).assert(20) do
      sleep(0.1)
      done.increment
    end
    assert_equal(20, done.value)
  end

  def test_multiple_threads_with_errors
    log = FakeLog.new
    assert_raises do
      Threads.new(3, log: log).assert(20) do
        this_code_is_broken
      end
    end
    assert_equal(3, log.logs.count)
  end

  class FakeLog
    attr_reader :logs

    def initialize
      @logs = []
    end

    def error(msg)
      @logs << msg
    end
  end
end
