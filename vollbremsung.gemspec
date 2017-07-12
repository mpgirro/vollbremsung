# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vollbremsung/version'

Gem::Specification.new do |spec|
  spec.name          = "vollbremsung"
  spec.version       = Vollbremsung::VERSION
  spec.date          = "2017-07-11"
  spec.author        = "Maximilian Irro"
  spec.email         = "max@irro.at"

  spec.summary       = "Handbrake bulk encoding tool"
  spec.description   = "vollbremsung is a Handbrake bulk encoding tool, designed to reencode a file structure to a DLNA enabled TV compatible format comfortably."
  spec.homepage      = "https://github.com/mpgirro/vollbremsung"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = ["vollbremsung"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 1.9.3"
  spec.add_dependency "handbrake", "~> 0.4"
  spec.add_dependency "logger"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.post_install_message = "🚗 Ready to pull the brake!"

end
