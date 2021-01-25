# redis_pool [![Build Status][gh-actions-image]][gh-actions-link]
A simple redis dynamic-sized connection pool.
There are several implementations of connection pools in ruby, but none of them supports dynamic sizes. Any connection pool would open a static amount of connections and would never kill them even if they are idle and not being used.
What if you need a large number of connections in very rare cases, but normally will not use more than a couple of ones? This pool is a great choice!

## Usage
Easily create a pool:
```ruby
pool = RedisPool.new()
# You can set the maximum size of the pool
pool = RedisPool.new({max_size: 10})
```
You can set several options for the pool. i.e:
`connection_timeout`: raises a TimeoutError after `connection_timeout` of trying to get hold of a connection.
`reaping_frequency`: checks every `reaping_frequency` for any idle connections to kill.
`idle_timeout`: kills any connection that has been idle for `idle_timeout`.

Use the connections using `with_conn`:
```ruby
pool = RedisPool.new({max_size: 10, connection_timeout: 5, idle_timeout: 300})
pool.with_conn { |conn|
    conn.get('hello')
}
```
You can override the default `connection_timeout` using `with_conn(timeout)`:
```ruby
pool = RedisPool.new()
pool.with_conn(5) { |conn|
    conn.get('hello')
}
```
## Pool Stats
You can also get stats about all connections that are currently alive in the pool. Stats include the id of each connection, when it was created `alive_since` and when it was last used at `last_used_at`.
```ruby
pool = RedisPool.new()
pool.with_conn { |conn| conn.get('hello') }
pool.stats # {:available_to_create=>4, :total_available=>5, :connections_stats=>[{:id=>0, :alive_since=>2021-01-25 13:41:12.749529574 UTC, :last_used_at=>2021-01-25 13:41:12.749532585 UTC}]}
```
## Redis Configuration
You can specify custom redis configuration when initializing the pool.
```ruby
pool = RedisPool.new(redis_config: {host: 'localhost', port: 5000, db: 10})
```
