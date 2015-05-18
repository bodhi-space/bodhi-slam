Gem::Specification.new do |s|
  s.name        = 'bodhi-slam'
  s.version     = '0.0.5'
  s.date        = '2015-05-14'
  s.summary     = "Generate data and push to the Bodhi API"
  s.description = "Generate data and push to the Bodhi API"
  s.authors     = ["Will Davis"]
  s.email       = 'will.davis@hotschedules.com'
  s.files       = ["lib/bodhi-slam.rb", "lib/bodhi-slam/context.rb", "lib/bodhi-slam/errors.rb", "lib/bodhi-slam/resource.rb"].flatten
  s.license     = 'MIT'
  #s.add_runtime_dependency 'faker', '~> 1.4'
  s.add_runtime_dependency 'factory_girl', '~> 4.5'
  s.add_runtime_dependency 'faraday', '~> 0.9'
  s.add_runtime_dependency 'json', '~> 1.7'
  s.add_development_dependency "rspec"
end