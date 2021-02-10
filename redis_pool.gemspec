Gem::Specification.new do |s|
  s.name = 'redis_pool'
  s.version = '0.1.0'
  s.summary = 'Redis Dynamic Pool'
  s.description = 'A simple dynamic-sized redis connection pool.'
  s.authors = ['Mohammed Amarnah']
  s.email = 'm.amarnah@gmail.com'
  s.homepage = 'https://github.com/mohammedamarnah/redis-pool'
  s.date = '2021-01-25'
  s.files = [
    'lib/redis_pool.rb',
    'lib/redis_pool/connection_queue.rb',
    'lib/redis_pool/reaper.rb'
  ]
  s.require_paths = ['lib']
  s.add_development_dependency 'concurrent-ruby'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'redis'
  s.required_ruby_version = '>= 2.2.0'
  s.license = 'MIT'
end
