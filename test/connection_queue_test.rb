require 'minitest/autorun'
require 'redis'
require_relative '../lib/redis_pool/connection_queue'

class ConnectionQueueTest < Minitest::Test
  def redis_block
    -> { Redis.new({ host: 'localhost', port: 6372 }) }
  end

  def test_basic_initialization
    max_size = 5
    q = ConnectionQueue.new(max_size, &redis_block)
    assert_equal q.max_size, max_size
    assert_equal q.total_available, max_size
    assert_equal q.available_to_create, max_size
  end

  def test_checking_out_a_connection
    max_size = 5
    q = ConnectionQueue.new(max_size, &redis_block)
    q.poll
    assert_equal q.total_available, max_size - 1
    assert_equal q.available_to_create, max_size - 1
  end

  def test_checking_in_a_connection
    max_size = 5
    q = ConnectionQueue.new(max_size, &redis_block)
    conn = q.poll
    q.add conn
    assert_equal q.total_available, max_size
    assert_equal q.available_to_create, max_size - 1
  end

  def test_checking_out_with_timeout
    max_size = 1
    q = ConnectionQueue.new(max_size, &redis_block)
    q.poll
    assert_raises TimeoutError do
      q.poll 0
    end
  end

  def test_checking_out_then_in_with_timeout
    max_size = 1
    q = ConnectionQueue.new(max_size, &redis_block)
    conn = q.poll
    q.add conn
    q.poll 0
    assert_equal q.total_available, 0
    assert_equal q.available_to_create, 0
  end
end
