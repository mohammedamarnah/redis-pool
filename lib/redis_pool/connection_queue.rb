require 'monitor'
require 'concurrent'

##
# A thread-safe implementation of a connection queue.
# Supports adding, removing, and polling a connection
# synchronously, and doesn't create more than `max_size`
# elements.
# All connections are created lazily (only when needed).
#
class ConnectionQueue
  attr_reader :max_size, :queue

  def initialize(max_size = 0, &block)
    @create_block = block
    @created = 0
    @queue = []
    @max_size = max_size
    @lock = Monitor.new
    @lock_cond = @lock.new_cond
  end

  ##
  # Adds (or returns) a connection to the available queue, synchronously.
  #
  def add(element)
    synchronize do
      @queue.push element
      @lock_cond.signal
    end
  end
  alias << add
  alias push add

  ##
  # Fetches any available connection from the queue. If a connection
  # is not available, waits for +timeout+ until a connection is
  # available or raises a TimeoutError.
  #
  def poll(timeout = 5)
    t0 = Concurrent.monotonic_time
    elapsed = 0
    synchronize do
      loop do
        return get_connection if connection_available?

        connection = create_connection
        return connection if connection

        elapsed = Concurrent.monotonic_time - t0
        raise TimeoutError, 'could not obtain connection' if elapsed >= timeout

        @lock_cond.wait(timeout - elapsed)
      end
    end
  end
  alias pop poll

  ##
  # Removes an idle connection from the queue
  # synchronously.
  #
  def delete(element)
    synchronize do
      @queue.delete element
    end
  end

  ##
  # Returns the total available connections to be used. This
  # takes into account the number of connections that can be
  # created as well. So it is all connections that can be used
  # AND created.
  #
  def total_available
    @max_size - @created + @queue.length
  end

  ##
  # Returns the number of available connections to create.
  #
  def available_to_create
    @max_size - @created
  end

  private

  def synchronize(&block)
    @lock.synchronize(&block)
  end

  def connection_available?
    !@queue.empty?
  end

  def get_connection
    conn = @queue.pop
    conn.last[:last_used_at] = Time.now.utc
    conn
  end

  def create_connection
    return unless @created < @max_size

    conn = @create_block.call
    # TODO: add more stats.
    stats = {
      id: @created,
      alive_since: Time.now.utc,
      last_used_at: Time.now.utc
    }
    @created += 1
    [conn, stats]
  end
end
