# encoding: utf-8

require "bundler/gem_tasks"
require "rake/clean"

Dir[File.expand_path("../tasks/**/*.rake", __FILE__)].each { |task| load task }

task :default => %w(spec)

CLEAN.include "pkg", "tmp", "rdoc"
