Gem::Specification.new do |s|
  s.name        = 'bodhi-slam'
  s.version     = '0.1.0'
  s.date        = '2015-06-12'
  s.summary     = "Ruby bindings for the Bodhi API"
  s.description = "BodhiSlam is a tool for generating large datasets and uploading them to bodhi.space.  It provides an ActiveRecord esque interface to the collections defined in bodhi.space"
  s.authors     = ["Will Davis"]
  s.email       = 'will.davis@hotschedules.com'
  s.files       = `git ls-files`.split("\n").select{|file| file.match("lib/") && !file.match("spec/") }
  s.license     = 'MIT'
  s.add_runtime_dependency 'factory_girl', '~> 4.5'
  s.add_runtime_dependency 'faraday', '~> 0.9'
  s.add_runtime_dependency 'json', '~> 1.7'
  s.add_development_dependency "rspec"
  s.add_development_dependency "dotenv"
  s.add_development_dependency "simplecov"
end