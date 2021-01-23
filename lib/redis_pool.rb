require 'redis'
require_relative './redis_pool/connection_queue'

class RedisPool
  DEFAULT_POOL_OPTS = {
    max_size: 5,
    connection_timeout: 5,
    idle_timeout: 100
  }.freeze

  DEFAULT_REDIS_CONFIG = { host: 'localhost', port: 6379 }.freeze

  attr_reader :max_size, :connection_timeout, :idle_timeout

  def initialize(options = {}, redis_config = {})
    options = DEFAULT_POOL_OPTS.merge(options)

    @redis_config = DEFAULT_REDIS_CONFIG.merge(redis_config)

    @max_size = options[:max_size]
    @connection_timeout = options[:connection_timeout]
    @idle_timeout = options[:idle_timeout]

    @available = ConnectionQueue.new(@max_size, &redis_creation_block)
    @key = :"pool-#{@available.object_id}"
    @key_count = :"pool-#{@available.object_id}-count"
  end

  def with(timeout = nil)
    Thread.handle_interrupt(Exception => :never) do
      conn = checkout(timeout)
      begin
        Thread.handle_interrupt(Exception => :immediate) do
          yield conn
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

  private

  def current_thread
    Thread.current
  end

  def redis_creation_block
    -> { Redis.new(@redis_config) }
  end
end
