#!/usr/bin/env ruby
# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#
# Full-text indexing of the RI documentation.
# This is the proof of concept that evolved into FastRI's full-text searching
# subsystem.

class IndexBuilder
  MAXWORD_SIZE = 20
  def initialize(fulltext_file, index_file)
    @fulltext_file = fulltext_file
    @index_file    = index_file
    @fulltext      = ""
  end

  def add_document(name, contents)
    @fulltext << preprocess(contents)
    @fulltext << "\0#{name}\0"
  end

  require 'strscan'
  require 'enumerator'
  def finish
    File.open(@fulltext_file, "w"){|f| f.puts @fulltext }
    scanner = StringScanner.new(@fulltext)

    count = 0
    suffixes = []
    until scanner.eos?
      count += 1
      if count == 100
        print "%3d%%\r" % (100 * scanner.pos / @fulltext.size)
        $stdout.flush
        count = 0
      end
      start = scanner.pos
      text = scanner.scan_until(/\0.*?\0/)
      text = text.sub(/\0.*?\0$/,"")
      suffixes.concat find_suffixes(text, start)
      scanner.terminate if !text
    end
    puts "Suffixes: #{suffixes.size}"
    t0 = Time.new
    sorted = suffixes.sort_by{|x| @fulltext[x,MAXWORD_SIZE]}
    File.open(@index_file, "w") do |f|
      sorted.each_slice(10000){|x| f.write x.pack("V*")}
    end
    File.open("suffixes", "w"){|f| sorted.each{|i| f.puts @fulltext[i,MAXWORD_SIZE].inspect}}
    puts "Processed in #{Time.new - t0} seconds"
  end

  require 'strscan'
  def find_suffixes(string, offset)
    suffixes = []
    sc = StringScanner.new(string)
    until sc.eos?
      sc.skip(/([^A-Za-z_]|\n)*/)
      len = string.size
      loop do
        break if sc.pos == len
        suffixes << offset + sc.pos
        break unless sc.skip(/[A-Za-z0-9_]+([^A-Za-z0-9_]|\n)*/)
      end
    end
    suffixes
  end

  private
  def preprocess(str)
    str.gsub(/\0/,"")
  end
end

def linearize(comment)
  case s = comment["body"]
  when String; s
  else 
    if Array === (y = comment["contents"])
      y.map{|z| linearize(z)}.join("\n")
    elsif s = comment["text"]
      s
    else
      nil
    end
  end
end

require 'rdoc/ri/ri_paths'
require 'yaml'
$:.unshift "lib"
require 'fastri/util'

#paths = RI::Paths::PATH
gem_paths = FastRI::Util.gem_directories_unique.map{|_,_,path| path}
paths = [ RI::Paths::SYSDIR, RI::Paths::SITEDIR, RI::Paths::HOMEDIR ].find_all do |p|
  p && File.directory?(p)
end
paths.concat gem_paths
indexer = IndexBuilder.new("test_FULLTEXT", "test_INDEX")
bad = 0
paths.each do |path|
  Dir["#{path}/**/*.yaml"].each do |yamlfile|
    yaml = File.read(yamlfile)
    begin
      data = YAML.load(yaml.gsub(/ \!.*/, ''))
    rescue Exception
      bad += 1
      puts "Couldn't load #{yamlfile}"
      #puts "=" * 80
      #puts yaml
      next
    end

    desc = (data['comment']||[]).map{|x| linearize(x)}.join("\n")
    desc.gsub!(/<\/?(em|b|tt|ul|ol|table)>/, "")
    desc.gsub!(/&quot;/, "'")
    desc.gsub!(/&lt;/, "<")
    desc.gsub!(/&gt;/, ">")
    desc.gsub!(/&amp;/, "&")
=begin
    puts "=" * 80
    puts yamlfile
    puts "-" * 80
    puts yaml
    puts "-" * 80
    puts desc
    $stdin.gets
=end
    unless desc.empty?
      indexer.add_document(yamlfile, desc) 
    end
  end
end
puts "BAD files: #{bad}"
indexer.finish
