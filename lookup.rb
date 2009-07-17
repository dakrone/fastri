#!/usr/bin/env ruby
# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#
# Full-text searching using O(M * log N + P) binary search over the suffix
# array.
# This is the proof of concept that evolved into FastRI's full-text searching
# subsystem.

class FullTextSearcher
  MAX_WORD_SIZE = 20
  MAX_REGEXP_MATCH_SIZE = 255
  class Result
    attr_reader :path, :query, :index

    def initialize(searcher, query, index, path)
      @searcher = searcher
      @index    = index
      @query    = query
      @path     = path
    end

    def context(size)
      strip_markers(@searcher.fetch_data(@index, 2*size, -size), size)
    end

    def text(size)
      str = @searcher.fetch_data(@index, size, 0)
      str[0..(str.index("\0")||-1)]
    end

    private
    def strip_markers(str, size)
      first = (str.rindex("\0", -size) || -1) + 1
      last  = str.index("\0", size) || str.size
      str[first...last]
    end
  end

  def initialize(fulltext_file, index_file)
    @fulltext_file = File.expand_path(fulltext_file)
    @index_file    = File.expand_path(index_file)
  end

  def lookup(term)
    File.open(@fulltext_file, "rb") do |fulltextIO|
      File.open(@index_file, "rb") do |indexIO|
        index, offset = binary_search(indexIO, fulltextIO, term, 0, indexIO.stat.size / 4 - 1)
        if offset
          fulltextIO.pos = offset
          if path = find_path(fulltextIO)
            Result.new(self, term, index, path)
          else
            nil
          end
        else
          nil
        end
      end
    end
  end

  def next_match(result, term_or_regexp)
    case term_or_regexp
    when String;  size = [result.query.size, term_or_regexp.size].max
    when Regexp;  size = MAX_REGEXP_MATCH_SIZE
    end
    File.open(@fulltext_file, "rb") do |fulltextIO|
      File.open(@index_file, "rb") do |indexIO|
        loop do
          idx = result.index + 1
          str = get_string(indexIO, fulltextIO, idx, size)
          break unless str.index(result.term) == 0
          if str[term_or_regexp]
            fulltextIO.pos = index_to_offset(indexIO, idx)
            path = find_path(fulltextIO)
            return Result.new(self, result.query, idx, path) if path
          end
        end
      end
    end
  end

  def next_matches(result, term_or_regexp)
    case term_or_regexp
    when String;  size = [result.query.size, term_or_regexp.size].max
    when Regexp;  size = MAX_REGEXP_MATCH_SIZE
    end
    ret = []
    File.open(@fulltext_file, "rb") do |fulltextIO|
      File.open(@index_file, "rb") do |indexIO|
        idx = result.index
        loop do
          idx += 1
          str = get_string(indexIO, fulltextIO, idx, size)
          break unless str.index(result.query) == 0
          if str[term_or_regexp]
            fulltextIO.pos = index_to_offset(indexIO, idx)
            path = find_path(fulltextIO)
            ret << Result.new(self, result.query, idx, path) if path
          end
        end
      end
    end

    ret
  end

  def fetch_data(index, size, offset = 0)
    File.open(@fulltext_file, "rb") do |fulltextIO|
      File.open(@index_file, "rb") do |indexIO|
        get_string(indexIO, fulltextIO, index, size, offset)
      end
    end
  end

  private
  def index_to_offset(indexIO, index)
    indexIO.pos = index * 4
    indexIO.read(4).unpack("V")[0]
  end

  def find_path(fulltextIO)
    oldtext = ""
    loop do
      text = fulltextIO.read(4096)
      break unless text
      if md = /\0(.*?)\0/.match((oldtext[-300..-1]||"") + text)
        return md[1]
      end
      oldtext = text
    end
  end
  def get_string(indexIO, fulltextIO, index, size, off = 0)
    indexIO.pos = index * 4
    offset = indexIO.read(4).unpack("V")[0]
    fulltextIO.pos = offset + off
    fulltextIO.read(size)
  end

  def binary_search(indexIO, fulltextIO, term, from, to)
    #puts "BINARY   #{from}  --  #{to}"
    #left   = get_string(indexIO, fulltextIO, from)
    #right  = get_string(indexIO, fulltextIO, to)
    #puts "   #{left.inspect}  --  #{right.inspect}"
    middle = (from + to) / 2
    pivot = get_string(indexIO, fulltextIO, middle, MAX_WORD_SIZE)
    if from == to
      if pivot.index(term) == 0
        indexIO.pos = middle * 4
        [middle, indexIO.read(4).unpack("V")[0]]
      else
        nil
      end
    elsif term <= pivot
      binary_search(indexIO, fulltextIO, term, from, middle)
    elsif term > pivot
      binary_search(indexIO, fulltextIO, term, middle+1, to)
    end
  end
end

unless ARGV.size == 2
  puts <<EOF
ruby lookup.rb <fulltext> <index>
EOF
  exit
end

CONTEXT = 50
db = FullTextSearcher.new(ARGV[0], ARGV[1])

def display_result(result)
  puts "=" * 80
  puts "Found in #{result.path}:"
  puts result.context(50)
end

puts "Input term: "
until (term = $stdin.gets.chomp).empty?
  t = Time.new
  result = db.lookup(term)
  puts "Needed #{Time.new - t} seconds."
  if result
    all_results = [result]
    all_results.concat db.next_matches(result, term)
    coalesced = {}
    all_results.each{|result| coalesced[result.path] ||= result }
    coalesced.sort_by{|path, result| path}.each do |path, result|
      display_result(result)
    end
  else
    puts "Not found"
  end

  puts
  puts "Input term: "
end
