# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
require File.join(File.dirname(__FILE__), "lib/rubydora/version")
Gem::Specification.new do |s|
  s.name = "rubydora"
  s.version = Rubydora::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Chris Beer"]
  s.email = ["chris@cbeer.info"]
  s.summary = %q{Fedora Commons REST API ruby library }
  s.description = %q{Fedora Commons REST API ruby library}
  s.homepage = "http://github.com/cbeer/rubydora"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "fastercsv"
  s.add_dependency "rest-client"
  s.add_dependency "nokogiri"
  s.add_dependency "equivalent-xml"
  s.add_dependency "mime-types"
  s.add_dependency "activesupport"
  s.add_dependency "activemodel"
  s.add_dependency "hooks"
  s.add_dependency "deprecation"

  s.add_development_dependency("rake")
  s.add_development_dependency("shoulda")
  s.add_development_dependency("bundler", ">= 1.0.14")
  s.add_development_dependency("rspec")
  s.add_development_dependency("yard")
  s.add_development_dependency("jettywrapper")
end
