# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018 Yegor Bugayenko
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

require 'concurrent'

# Threads.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
class Threads
  def initialize(total = Concurrent.processor_count * 8)
    @total = total
  end

  def assert(reps = 0)
    done = Concurrent::AtomicFixnum.new
    cycles = Concurrent::AtomicFixnum.new
    pool = Concurrent::FixedThreadPool.new(@total)
    latch = Concurrent::CountDownLatch.new(1)
    @total.times do |t|
      pool.post do
        Thread.current.name = "assert-thread-#{t}"
        latch.wait(10)
        loop do
          begin
            yield t
          rescue StandardError => e
            puts Backtrace.new(e)
            raise e
          end
          cycles.increment
          break if cycles.value > reps
        end
        done.increment
      end
    end
    latch.count_down
    pool.shutdown
    raise "Can't stop the pool" unless pool.wait_for_termination(30)
    return if done.value == @total
    raise "Only #{done.value} out of #{@total} threads completed successfully"
  end
end
