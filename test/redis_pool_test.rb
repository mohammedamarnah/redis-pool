require 'minitest/autorun'
require_relative '../lib/redis_pool'

class RedisPoolTest < Minitest::Test
  def test_initialization
    pool = RedisPool.new
    assert_equal 5, pool.max_size
    assert_equal 5, pool.connection_timeout
    assert_equal 100, pool.idle_timeout
    assert_equal 300, pool.reaping_frequency
  end

  def test_custom_initialization
    pool = RedisPool.new(max_size: 1, idle_timeout: 20, reaping_frequency: 100)
    assert_equal pool.max_size, 1
    assert_equal pool.idle_timeout, 20
    assert_equal pool.reaping_frequency, 100
  end

  def test_using_a_connection
    pool = RedisPool.new
    pong = pool.with do |conn|
      conn.ping
    end
    assert_equal "PONG", pong
  end

  def test_checking_out_a_connection
    pool = RedisPool.new(max_size: 1)
    pool.checkout
    stats = pool.stats
    assert_equal 0, stats[:available_to_create]
    assert_equal 0, stats[:total_available]
    pool.checkin
    stats = pool.stats
    assert_equal 0, stats[:available_to_create]
    assert_equal 1, stats[:total_available]
  end
end
