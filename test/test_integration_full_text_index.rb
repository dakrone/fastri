# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift "lib"
require 'fastri/full_text_indexer'
require 'fastri/full_text_index'

class TestIntegrationFullTextIndex < Test::Unit::TestCase
  include FastRI
  def setup
    @indexer = FullTextIndexer.new(20)
  end

  require 'stringio'
  def get_index
    fulltextIO = StringIO.new("")
    suffixIO   = StringIO.new("")
    @indexer.build_index(fulltextIO, suffixIO)
    FullTextIndex.new_from_ios(fulltextIO, suffixIO)
  end

  def test_basic_matching
    @indexer.add_document("first.txt", "this is the first document: foo")
    @indexer.add_document("second.txt", "this is the second document: bar")
    index = get_index
    assert_equal("first.txt", index.lookup("foo").path)
    assert_equal("second.txt", index.lookup("bar").path)
  end

  def test_metadata
    @indexer.add_document("first.txt", "this is the first document: foo",
                          :type => "text/plain", :foo => 'baz')
    @indexer.add_document("second.doc", "this is the second document: bar",
                          :type => "application/msword", :bar => "foo")
    index = get_index
    assert_equal("first.txt", index.lookup("foo").path)
    assert_equal("second.doc", index.lookup("bar").path)
    assert_equal({:foo=>"baz", :type=>"text/plain", :size => 31}, index.lookup("foo").metadata)
    assert_equal({:bar=>"foo", :type=>"application/msword", :size => 32}, index.lookup("bar").metadata)
  end
end
