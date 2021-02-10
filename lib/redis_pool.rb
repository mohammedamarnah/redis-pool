require 'redis'
require_relative './redis_pool/connection_queue'
require_relative './redis_pool/reaper'

class RedisPool
  DEFAULT_REDIS_CONFIG = { host: 'localhost', port: 6379 }.freeze

  attr_reader :max_size, :connection_timeout, :idle_timeout,
              :reaping_frequency, :available

  def initialize(max_size: 5, connection_timeout: 5, idle_timeout: 100, reaping_frequency: 300, redis_config: {})
    @redis_config = DEFAULT_REDIS_CONFIG.merge(redis_config)

    @max_size = max_size
    @connection_timeout = connection_timeout
    @idle_timeout = idle_timeout
    @reaping_frequency = reaping_frequency

    @available = ConnectionQueue.new(@max_size, &redis_creation_block)
    @reaper = Reaper.new(self, @reaping_frequency, @idle_timeout)

    @key = :"pool-#{@available.object_id}"
    @key_count = :"pool-#{@available.object_id}-count"

    @reaper.reap
  end

  def with(timeout = nil)
    Thread.handle_interrupt(Exception => :never) do
      conn = checkout(timeout)
      begin
        Thread.handle_interrupt(Exception => :immediate) do
          yield conn.first
        end
      ensure
        checkin
      end
    end
  end
  alias with_conn with
  alias with_connection with

  def checkout(timeout = nil)
    if current_thread[@key]
      current_thread[@key_count] += 1
      current_thread[@key]
    else
      current_thread[@key_count] = 1
      current_thread[@key] = @available.poll(timeout || @connection_timeout)
    end
  end

  def checkin
    raise 'no connections are checked out' unless current_thread[@key]

    if current_thread[@key_count] == 1
      @available.add current_thread[@key]
      current_thread[@key] = nil
      current_thread[@key_count] = nil
    else
      current_thread[@key_count] -= 1
    end
  end

  def stats
    conn_stats = @available.queue.map do |conn|
      conn.last
    end
    pool_stats = {
      available_to_create: @available.available_to_create,
      total_available: @available.total_available,
      connections_stats: conn_stats
    }
  end

  private

  def current_thread
    Thread.current
  end

  def redis_creation_block
    -> { Redis.new(@redis_config) }
  end
end
