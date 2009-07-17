#!/usr/bin/env ruby
require 'fileutils'

FileUtils.cp "bin/fri", "bin/qri"

if /win/ =~ RUBY_PLATFORM and /darwin|cygwin/ !~ RUBY_PLATFORM
  %w[fri qri fastri-server ri-emacs].each do |fname|
    FileUtils.mv "bin/#{fname}", "bin/#{fname}.rb", :force => true
  end
end

