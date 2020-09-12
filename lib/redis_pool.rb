require 'redis'
require 'concurrent'

require_relative 'reaper.rb'
require_relative 'queue.rb'

class RedisPool
  class ConnectionTimeoutError < StandardError; end

  attr_accessor :automatic_reconnect, :checkout_timeout
  attr_reader :redis_spec, :pool_spec, :size, :reaper

  DEFAULT_REDIS_SPEC = {
    host: 'localhost',
    port: 6379
  }

  def initialize(redis_spec = {}, pool_spec = {})
    @redis_spec = DEFAULT_REDIS_SPEC.merge(redis_spec)

    @size = (pool_spec[:size] && pool_spec[:size].to_i) || 5

    @thread_cached_conns = Concurrent::Map.new(initial_capacity: @size)

    @connections = []
    @automatic_reconnect = pool_spec[:automatic_reconnect] || true

    @now_connecting = 0

    @threads_blocking_new_connections = 0

    @available = ConnectionLeasingQueue.new(self)

    @lock_thread = false

    reaping_frequency = pool_spec[:reaping_frequency]
    @reaper = Repear.new(self, reaping_frequency && reaping_frequency.to_f)
    @reaper.run
  end
end

# r = RedisPool.new

#   def method_missing(meth, *args)
#     run { |conn| conn.send(meth, *args) }
#   end
#
#   def run
#     begin
#       if @pool.empty?
#         open_new_connection()
#       end
#       conn = nil
#       Timeout::timeout(2, ConnectionTimeoutError) do
#         conn = @pool.pop
#       end
#       @open_connections += 1
#       yield conn
#     ensure
#       @open_connections -= 1
#       @pool << conn if conn
#     end
#   end
#
#   def open_new_connection
#     if @open_connections < max_pool_size
#       @pool << Redis.new(@redis_spec)
#     end
#   end
#
#   def close_idle_connections
#     while @pool.size() > @min_pool_size
#       @pool.pop
#     end
#   end
# end
#
# r = RedisWrapper.new
# while true
#   val = r.get('bla')
#   puts val
#   sleep 0.05
# end
