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

require 'concurrent'
require 'backtrace'

# Threads.
#
# This class may help you test your code for thread-safety by running
# it multiple times in a few parallel threads:
#
#  require 'threads'
#  Threads.new(5).assert do |i|
#    puts "Hello from the thread no.#{i}"
#  end
#
# Here, the message will be printed to the console five times, once in every
# thread.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2024 Yegor Bugayenko
# License:: MIT
class Threads
  # Constructor.
  #
  # @param [Number] total How many threads to run
  # @param [Logger] log Where to print output
  def initialize(total = Concurrent.processor_count * 8, log: $stdout)
    raise "Total can't be nil" if total.nil?
    raise "Total can't be negative or zero: #{total}" unless total.positive?
    @total = total
    raise "Log can't be nil" if log.nil?
    @log = log
  end

  # Run them all and assert that all of them finished successfully.
  #
  # @param [Number] reps How many times to repeat the testing cycle
  # @return nil
  def assert(reps = @total)
    raise "Repetition counter #{reps} can't be smaller than #{@total}" if reps < @total
    done = Concurrent::AtomicFixnum.new
    rep = Concurrent::AtomicFixnum.new
    pool = Concurrent::FixedThreadPool.new(@total)
    latch = Concurrent::CountDownLatch.new(1)
    finish = Concurrent::CountDownLatch.new(@total)
    @total.times do |t|
      pool.post do
        Thread.current.name = "assert-thread-#{t}"
        latch.wait(10)
        begin
          loop do
            r = rep.increment
            break if r > reps
            begin
              yield(t, r - 1)
            rescue StandardError => e
              print(Backtrace.new(e))
              raise e
            end
          end
          done.increment
        ensure
          finish.count_down
        end
      end
    end
    latch.count_down
    finish.wait(10)
    pool.shutdown
    raise "Can't stop the pool" unless pool.wait_for_termination(30)
    return if done.value == @total
    raise "Only #{done.value} out of #{@total} threads completed successfully"
  end

  private

  def print(msg)
    if @log.respond_to?(:error)
      @log.error(msg)
    elsif @log.respond_to?(:puts)
      @log.puts(msg)
    end
  end
end
