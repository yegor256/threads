# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'concurrent'
require_relative '../lib/threads'

# Threads test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2026 Yegor Bugayenko

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
    assert_raises(StandardError) do
      Threads.new(3, log: log).assert(20) do
        this_code_is_broken
      end
    end
    assert_equal(3, log.logs.count)
  end

  def test_initialize_with_invalid_shutdown_timeout
    assert_equal(
      "shutdown_timeout can't be negative or zero: 0",
      assert_raises(RuntimeError) do
        Threads.new(3, shutdown_timeout: 0)
      end.message
    )
  end

  def test_initialize_with_invalid_task_timeout
    assert_equal(
      "task_timeout can't be negative or zero: -5",
      assert_raises(RuntimeError) do
        Threads.new(3, task_timeout: -5)
      end.message
    )
  end

  def test_custom_timeout_parameters
    assert_equal(
      "Can't stop the pool",
      assert_raises(RuntimeError) do
        Threads.new(1, task_timeout: 1, shutdown_timeout: 1).assert do
          sleep(3)
        end
      end.message
    )
  end

  def test_custom_timeout_parameters_for_assert
    assert_equal(
      "Can't stop the pool",
      assert_raises(RuntimeError) do
        Threads.new(1).assert(shutdown_timeout: 1, task_timeout: 1) do
          sleep(3)
        end
      end.message
    )
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
