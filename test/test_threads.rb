# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018-2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'concurrent'
require_relative '../lib/threads'

# Threads test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2024 Yegor Bugayenko
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
