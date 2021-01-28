# redis-pool [![Build Status][gh-actions-image]][gh-actions-link]
A simple redis dynamic-sized connection pool.
There are several implementations of connection pools in ruby, but none of them supports dynamic sizes. Any connection pool would open a static amount of connections and would never kill them even if they are idle and not being used.
What if you need a large number of connections in very rare cases, but normally will not use more than a couple of ones? This pool is a great choice!

## Why redis-pool?
Imagine that you have an application that in very rare cases (let's say X minutes-hours per day) gets a huge amount of traffic that needs a high number of connections, but all the other times you would need only a couple of ones open. Having a big amount of connections open (while the connections are idle) is a memory consuming operations.

I took inspiration from where I work: we have **N servers**, each server instantiates **M puma instances** (ruby on rails server) and each instance fires up **K redis connections** on boot-up. This makes the total open connections **N x M x K redis connections**!. Imagine adding one instance? or one server!
This gem was implemented heavily based on two main implementations:

1- [mperham's connection_pool](https://github.com/mperham/connection_pool)

2- [rails' ActiveRecord Connection Pool](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html)

The former provides an efficient connection pool implementation that creates connections lazily (only upon actual need of that connection), but keeps the connections alive once they're opened.

The latter provides a connection pool implementation (specific for rails' database interfaces) that supports a dynamic size of the connection pool.
Here's a chart that shows the difference between normal connection-pools and redis-pool:
![difference](https://user-images.githubusercontent.com/11768502/106142062-ae693680-6179-11eb-9b40-4fa32d641904.jpeg)
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
[gh-actions-image]: https://github.com/mohammedamarnah/redis-pool/workflows/Ruby/badge.svg
[gh-actions-link]:  https://github.com/mohammedamarnah/redis-pool/actions
