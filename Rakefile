$:.unshift "lib" if File.directory? "lib"
require 'rake/testtask'

desc "Run the functional and unit tests."
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

require 'rcov/rcovtask'
desc "Run rcov."
Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/test_*.rb'].to_a.reject{|x| /test_functional/ =~ x}
  t.verbose = true
end

desc "Save current coverage state for later comparisons."
Rcov::RcovTask.new(:rcovsave) do |t|
  t.rcov_opts << "--save"
  t.test_files = FileList['test/test_*.rb'].to_a.reject{|x| /test_functional/ =~ x}
  t.verbose = true
end

task :default => :test

# vim: set sw=2 ft=ruby:
