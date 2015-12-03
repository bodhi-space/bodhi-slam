Gem::Specification.new do |s|
  s.name        = 'bodhi-slam'
  s.version     = '0.5.3'
  s.date        = '2015-12-03'
  s.summary     = "Ruby bindings for the Bodhi API & factories for random data generation"
  s.authors     = ["willdavis"]
  s.email       = 'will.davis@hotschedules.com'
  s.files       = Dir['lib/**/*']
  s.license     = 'MIT'
  s.add_runtime_dependency 'faraday', '~> 0.9'
  s.add_runtime_dependency 'faraday_middleware', '~> 0.10'
  s.add_runtime_dependency 'net-http-persistent', '~> 2.9'
  s.add_runtime_dependency 'json', '~> 1.7'
  s.add_runtime_dependency 'regexp-examples', '~> 1.1'
  s.add_development_dependency "rspec"
  s.add_development_dependency "dotenv"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "bump"
end