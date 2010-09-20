require 'rubygems'
require './lib/cloudservers.rb'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "cloudservers"
    gemspec.summary = "Rackspace Cloud Servers Ruby API"
    gemspec.description = "A Ruby API to version 1.0 of the Rackspace Cloud Servers product."
    gemspec.email = "minter@lunenburg.org"
    gemspec.homepage = "http://github.com/rackspace/cloudservers"
    gemspec.authors = ["H. Wade Minter","Mike Mayo"]
    gemspec.add_dependency 'json'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

  Rake::TestTask.new(:test) do |t|
    t.pattern = 'test/*_test.rb'
    t.verbose = true
  end
  Rake::Task['test'].comment = "Unit"
