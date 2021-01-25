##
# A reaper class that initializes a thread running in the
# background, that kills all connections in `pool` that
# has been idle for more than `idle_timeout`.
#
class Reaper
  attr_reader :frequency, :idle_timeout

  def initialize(pool, frequency, idle_timeout)
    @frequency = frequency
    @idle_timeout = idle_timeout
    @pool = pool
    @lock = Mutex.new
  end

  def reap
    Thread.new do
      loop do
        @pool.available.queue.each do |conn|
          idle_since = conn.last[:last_used_at] - Time.now.utc

          next unless idle_since >= @idle_timeout

          @lock.synchronize do
            @pool.available.delete conn
            conn.first.disconnect!
          end
        end
        sleep @frequency
      end
    end.run
  end
end
