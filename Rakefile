require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

# Get your spec rake tasks working in RSpec 2.0

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

  if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.8/
    t.rcov = true
    t.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
  end
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.options = ["--readme", "README.rdoc"]
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r rubydora.rb"
end

desc "Execute Continuous Integration build"
task :ci do
  unless ENV['environment'] == 'test'
    exec("rake ci environment=test") 
  end

  require 'jettywrapper'
  jetty_params = {
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/jetty'),
    :quiet => false,
    :jetty_port => ENV['TEST_JETTY_PORT'] || 8983,
    :solr_home => File.expand_path(File.dirname(__FILE__) + '/jetty/solr'),
    :fedora_home => File.expand_path(File.dirname(__FILE__) + '/jetty/fedora/default'),
    :startup_wait => 30,
    :java_opts => ['-Xmx256m', '-XX:MaxPermSize=128m']
  }

  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end


desc "Execute specs with coverage"
task :coverage do 
  # Put spec opts in a file named .rspec in root
  ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
  ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'


  Rake::Task['spec'].invoke
end

namespace :coverage do
desc "Execute ci build with coverage"
task :ci do 
  # Put spec opts in a file named .rspec in root
  ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
  ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'


  Rake::Task['ci'].invoke
end
end
