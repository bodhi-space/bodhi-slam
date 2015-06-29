Gem::Specification.new do |s|
  s.name        = 'bodhi-slam'
  s.version     = '0.2.0'
  s.date        = '2015-06-29'
  s.summary     = "Ruby bindings for the Bodhi API"
  s.description = "BodhiSlam is an ORM for the Bodhi API and helps with randomly generating."
  s.authors     = ["willdavis"]
  s.email       = 'will.davis@hotschedules.com'
  s.files       = Dir['lib/**/*']
  s.license     = 'MIT'
  s.add_runtime_dependency 'net-http-persistent', '~> 2.9'
  s.add_runtime_dependency 'faraday', '~> 0.9'
  s.add_runtime_dependency 'json', '~> 1.7'
  s.add_development_dependency "rspec"
  s.add_development_dependency "dotenv"
  s.add_development_dependency "simplecov"
end