
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "audit/version"

Gem::Specification.new do |spec|
  spec.name          = "audit"
  spec.version       = Audit::VERSION
  spec.authors       = ["vrushaliw"]
  spec.email         = ["vrushali@amuratech.com"]

  spec.summary       = %q{Audit for mongodb.}
  spec.description   = %q{Audit for mongodb.}
  spec.homepage      = "https://github.com/vrushaliw/todo"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.3.1"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "google-cloud", "~> 0.35.0"
  spec.add_development_dependency "request_store", "~> 1.4.1"
  spec.add_development_dependency "mongoid"
  spec.add_development_dependency "rails"

  spec.add_dependency "rails", ">= 5"
  spec.add_dependency "bundler", "~> 1.16"
  spec.add_dependency "rake", "~> 12.3.1"
  spec.add_dependency "rspec", "~> 3.0"
  spec.add_dependency "google-cloud", "~> 0.35.0"
  spec.add_dependency "request_store", "~> 1.4.1"
  spec.add_dependency "mongoid"
end
