require 'monitor'
require 'concurrent'

#
# A thread-safe LIFO queue implementation.
# Initializes a monitor lock, and a condi-
# tional variable.
#
# - Defines add, delete, clear,
# and any_waiting? as the main functions.
#
# - Defines `pop` to get the first available
# connection from the queue. If there's a
# free available connection it returns it
# without waiting. Otherwise it waits for
# `timeout` for a connection to be free and
# returns or returns a ConnectionTimeoutError
# if it fails.
#

class Queue
  class ConnectionTimeoutError < StandardError; end

  def initialize(lock = Monitor.new)
    @lock = lock

    # defines a new condition variable that is used to
    # signal and wait on the lock.
    @cond = @lock.new_cond

    # holds the number of threads currently waiting
    # for a connection to be available.
    @num_waiting = 0

    @queue = []
  end

  def any_waiting?
    synchronize do
      @num_waiting > 0
    end
  end

  def num_waiting
    synchronize do
      @num_waiting
    end
  end

  def add(element)
    synchronize do
      @queue.push(element)
      @cond.signal
    end
  end

  def pop(timeout = nil)
    synchronize do
      internal_pop(timeout)
    end
  end

  def delete(element)
    synchronize do
      @queue.delete(element)
    end
  end

  def clear
    synchronize do
      @queue.clear
    end
  end

  private

  def internal_pop(timeout)
    pop_without_wait() || (timeout && wait_pop(timeout))
  end

  def synchronize(&block)
    @lock.synchronize(&block)
  end

  def any?
    !queue.empty?
  end

  def can_remove_without_wait?
    @queue.size > @num_waiting
  end

  def remove
    @queue.pop
  end

  def pop_without_wait
    remove if can_remove_without_wait?
  end

  def wait_pop(timeout)
    begin
      @num_waiting += 1

      t0 = Concurrent.monotonic_time
      elapsed = 0

      loop do
        return remove if any?

        elapsed = Concurrent.monotonic_time - t0
        if elapsed >= timeout
          msg = 'Could not obtain a connection from the pool within the timeout'
          raise ConnectionTimeoutError, msg
        end
      end
    ensure
      @num_waiting -= 1
    end
  end
end
