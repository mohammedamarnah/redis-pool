require 'weakref'

class Reaper
  attr_reader :pool, :frequency

  def initialize(pool, frequency)
    @pool = pool
    @frequency = frequency
  end

  @mutex = Mutex.new
  @pools = {}
  @threads = {}

  class << self
    def register_pool(pool, frequency)
      @mutex.synchronize do
        unless @threads[frequency]&.alive?
          @threads[frequency] = spawn_thread(frequency)
        end
        @pools[frequency] ||= []
        @pools[frequency] << WeakRef.new(pool)
      end
    end

    private

    def spawn_thread(frequency)
      Thread.new(frequency) do |t|
        running = true
        while running
          sleep t
          @mutex.synchronize do
            @pools[frequency].select!(&:weakref_alive?)
            @pools[frequency].each do |p|
              begin
                p.reap
                p.flush
              rescue
                WeakRef::RefError
              end
            end

            if @pools[frequency].empty?
              @pools.delete(frequency)
              @threads.delete(frequency)
              running = false
            end
          end
        end
      end
    end
  end

  def run
    return unless frequency && frequency > 0
    self.class.register_pool(pool, frequency)
  end
end
