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
  # Put spec opts in a file named .rspec in root
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rubydora #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
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
    :jetty_port => 8983,
    :solr_home => File.expand_path(File.dirname(__FILE__) + '/jetty/solr'),
    :fedora_home => File.expand_path(File.dirname(__FILE__) + '/jetty/fedora/default'),
    :startup_wait => 30
  }

  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end
