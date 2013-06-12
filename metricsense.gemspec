$:.push File.expand_path('../lib', __FILE__)
require 'metricsense/version'

Gem::Specification.new do |s|
  s.name        = "metricsense"
  s.description = "MetricSense event collection API for Ruby"
  s.summary     = s.description
  s.homepage    = "https://github.com/treasure-data/metricsense"
  s.version     = MetricSense::VERSION
  s.authors     = ["Sadayuki Furuhashi"]
  s.email       = "sf@treasure-data.com"
  s.license     = "Apache 2.0"
  s.has_rdoc    = false
  s.require_paths = ['lib']
  #s.platform    = Gem::Platform::RUBY
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency "fluent-logger", ">= 0.4.5"
  s.add_development_dependency "rake", ">= 0.8.7"
  s.add_development_dependency 'bundler', ['>= 1.0.0']
  s.add_development_dependency "simplecov", ">= 0.5.4"
end
