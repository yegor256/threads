# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
# Copyright:: Copyright (c) 2018-2025 Yegor Bugayenko
# License:: MIT
class Threads
  # Constructor.
  #
  # @param [Number] total How many threads to run
  # @param [Logger] log Where to print output
  # @param [Number] task_timeout How many seconds to wait for all tasks to finish
  # @param [Number] shutdown_timeout How many seconds to wait for the thread pool to shut down
  def initialize(total = Concurrent.processor_count * 8, log: $stdout, task_timeout: 10, shutdown_timeout: 30)
    raise "Total can't be nil" if total.nil?
    raise "Total can't be negative or zero: #{total}" unless total.positive?
    @total = total
    raise "Log can't be nil" if log.nil?
    @log = log
    validate('task_timeout', task_timeout)
    @task_timeout = task_timeout
    validate('shutdown_timeout', shutdown_timeout)
    @shutdown_timeout = shutdown_timeout
  end

  # Validate a timeout value.
  # @param [String] label Label to use in the error message
  # @param [Number] timeout Timeout value to validate
  def validate(label, timeout)
    raise "#{label} can't be nil" if timeout.nil?
    raise "#{label} can't be negative or zero: #{timeout}" unless timeout.positive?
  end

  # Run them all and assert that all of them finished successfully.
  #
  # For example, test a counter for thread safety:
  #
  #  counter = 0
  #  mutex = Mutex.new
  #  Threads.new(10).assert do |t|
  #    mutex.synchronize { counter += 1 }
  #  end
  #  puts "Final counter value: #{counter}"
  #
  # You can also access the repetition index:
  #
  #  Threads.new(4).assert(100) do |t, r|
  #    puts "Thread #{t}, repetition #{r}"
  #  end
  #
  # @param [Number] reps How many times to repeat the testing cycle
  # @param [Number] task_timeout How many seconds to wait for all tasks to finish
  # @param [Number] shutdown_timeout How many seconds to wait for the thread pool to shut down
  # @return nil
  def assert(reps = @total, task_timeout: @task_timeout, shutdown_timeout: @shutdown_timeout)
    raise "Repetition counter #{reps} can't be smaller than #{@total}" if reps < @total
    validate('task_timeout', task_timeout)
    validate('shutdown_timeout', shutdown_timeout)
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
    finish.wait(task_timeout)
    pool.shutdown
    raise "Can't stop the pool" unless pool.wait_for_termination(shutdown_timeout)
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
