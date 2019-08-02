require 'rubygems'
require 'bundler'
require 'jettywrapper'
require 'yard'
require 'bundler/gem_tasks'

ZIP_URL = 'https://github.com/projecthydra/hydra-jetty/archive/v7.3.0.zip'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

# Get your spec rake tasks working in RSpec 2.0
require 'rspec/core/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  if ENV['COVERAGE'] && RUBY_VERSION =~ /^1.8/
    t.rcov = true
    t.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
  end
end

YARD::Rake::YardocTask.new do |yt|
  yt.files   = ['lib/**/*.rb']
  yt.options = ['--readme', 'README.md']
end

desc 'Open an irb session preloaded with this library'
task :console do
  sh 'irb -rubygems -I lib -r rubydora.rb'
end

desc 'Execute RSpec test suites with jetty-wrapper'
task :rspec => 'jetty:clean' do
  jetty_params = {
    :jetty_home   => File.expand_path(File.dirname(__FILE__) + '/jetty'),
    :quiet        => true,
    :jetty_port   => ENV['TEST_JETTY_PORT'] || 8983,
    :solr_home    => File.expand_path(File.dirname(__FILE__) + '/jetty/solr'),
    :fedora_home  => File.expand_path(File.dirname(__FILE__) + '/jetty/fedora/default'),
    :startup_wait => 90,
    :java_opts    => ['-Xmx256m', '-XX:MaxPermSize=128m']
  }
end

desc 'Execute specs against Fedora under Docker'
task 'docker:build' do
  system("docker build -t samveralabs/fcrepo3:latest .")
end

desc 'Execute specs against Fedora under Docker'
task 'docker:spec' do
  container = `docker run -d -p 8983:8983 samveralabs/fcrepo3:latest`.chomp
  puts "Waiting 10s for Fedora to start..."
  sleep 10
  Rake::Task['coverage'].invoke
  killed = `docker kill #{container}`.chomp
  unless container == killed
    puts "Container (#{container}) not cleaned up successfully..."
    puts "It is likely still running and binding port 8983."
  end
end

desc 'Execute specs with coverage'
task :coverage do
  ruby_engine = ENV['RUBY_TYPE'] || 'ruby'
  ENV['COVERAGE'] = 'true' unless ruby_engine =~ /jruby/
  Rake::Task['spec'].invoke
end

desc 'Execute Continuous Integration build'
task :ci do
  unless ENV['environment'] == 'test'
    exec('rake ci environment=test')
  end

  Rake::Task['coverage'].invoke
  Rake::Task['yard'].invoke
end

desc 'Default: run ci build.'
task :default => :ci
