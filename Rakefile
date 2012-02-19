# encoding: utf-8

require "bundler/gem_tasks"
require "rake/clean"

Dir[File.expand_path("../tasks/**/*.rake", __FILE__)].each { |task| load task }

task :default => %w(spec)

CLEAN.include "pkg", "tmp"

# 
# require 'rubygems'
# require 'bundler'
# begin
#   Bundler.setup(:default, :development)
# rescue Bundler::BundlerError => e
#   $stderr.puts e.message
#   $stderr.puts "Run `bundle install` to install missing gems"
#   exit e.status_code
# end
# require 'rake'
# 
# 
# require 'rspec/core'
# require 'rspec/core/rake_task'
# RSpec::Core::RakeTask.new(:spec) do |spec|
#   spec.pattern = FileList['spec/**/*_spec.rb']
#   spec.rspec_opts = %w(-fs -c)
# end
# 
# require 'rake/testtask'
# Rake::TestTask.new(:test) do |test|
#   test.libs << 'lib' << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
# end
# 
# require 'rcov/rcovtask'
# Rcov::RcovTask.new do |test|
#   test.libs << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
#   test.rcov_opts << '--exclude "gems/*"'
# end
# 
# task :default => :test
# 
# require 'rdoc/task'
# Rake::RDocTask.new do |rdoc|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""
# 
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = "tapestry #{version}"
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end
