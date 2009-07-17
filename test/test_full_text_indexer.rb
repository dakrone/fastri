require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift "lib"
require 'fastri/full_text_indexer'

class TestFullTextIndexer < Test::Unit::TestCase
  require 'stringio'
  include FastRI
  def setup
    @indexer = FullTextIndexer.new(20)
  end

  DATA1 =  "this is a test " * 1000
  DATA2 =  "this is another test " * 1000
  def test_add_document
    @indexer.add_document("foo.txt", DATA1)
    assert_equal(["foo.txt"], @indexer.documents)
    assert_equal(DATA1, @indexer.data("foo.txt"))
    @indexer.add_document("foo.txt", DATA2)
    assert_equal(["foo.txt"], @indexer.documents)
    assert_equal(DATA2, @indexer.data("foo.txt"))
    @indexer.add_document("bar.txt", DATA2)
    assert_equal(["foo.txt", "bar.txt"], @indexer.documents)
    assert_equal(DATA2, @indexer.data("bar.txt"))
  end

  def test_preprocess
    data = "this is a \0foo bar\0 bla"
    assert_equal("this is a foo bar bla", @indexer.preprocess(data))
  end

  def test_find_suffixes_simple
    data = <<EOF
this is a simple test with these words: Aaaa01 0.1 _asdA1
EOF
    assert_equal([0, 5, 8, 10, 17, 22, 27, 33, 40, 47, 49, 51], 
                 @indexer.find_suffixes_simple(data, /[A-Za-z0-9_]+/, /[^A-Za-z0-9_]+/,0))
    assert_equal([0, 5, 8, 10, 17, 22, 27, 33, 40, 52], 
                 @indexer.find_suffixes_simple(data, /[A-Za-z]+/, /[^A-Za-z]+/, 0))
    assert_equal([0, 5, 8, 10, 17, 22, 27, 33, 40, 52].map{|x| x+10}, 
                 @indexer.find_suffixes_simple(data, /[A-Za-z]+/, /[^A-Za-z]+/, 10))
    assert_equal([0, 1, 2, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 
                 22, 23, 24, 25, 27, 28, 29, 30, 31, 33, 34, 35, 36, 37,
    
                 40, 41, 42, 43, 52, 53, 54, 55], 
                 @indexer.find_suffixes_simple(data, /[A-Za-z]/, /[^A-Za-z]+/, 0))
    assert_equal([0, 5], @indexer.find_suffixes_simple("abcd\ndefg", /\S+/, /\s+/, 0))
    assert_equal([1, 6], @indexer.find_suffixes_simple("abcd\ndefg", /\S+/, /\s+/, 1))
  end

  def test_build_index_trivial
    @indexer.add_document("foo.txt", DATA1)
    fulltext    = StringIO.new("")
    suffixarray = StringIO.new("")
    @indexer.build_index(fulltext, suffixarray)
    assert_equal(["\000\027\000\000\000foo.txt\000\004\b{\006:\tsizei\002\230:\000"], 
                 fulltext.string[-200..-1].scan(/\0.*$/))
    assert_equal(4000 * 4, suffixarray.string.size)
  end

  def build_index_test_helper(data, suffixes)
    @indexer.add_document("foo.txt", data)
    offset = FullTextIndexer::MAGIC.size
    suffixes = suffixes.map{|x| x + offset}
    sorted   = suffixes.sort_by{|i| data[i - offset]}
    f_io  = StringIO.new("")
    sa_io = StringIO.new("")
    @indexer.build_index(f_io, sa_io)
    assert_equal(sorted, sa_io.string.scan(/..../m).map{|x| x.unpack("V")[0]})
  end

  def test_build_index_harder
    data = <<EOF
a bcd efghi jklmn opqrst
EOF
    suffixes = [0, 2, 6, 12, 18]
    build_index_test_helper(data, suffixes)
    data = <<EOF
e xcd afghi zklmn bpqrst
EOF
    suffixes = [0, 2, 6, 12, 18]
    build_index_test_helper(data, suffixes)
  end
end
