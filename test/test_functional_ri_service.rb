require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'fastri/ri_service'
require 'fastri/ri_index'

class TestFunctionalRiService < Test::Unit::TestCase
  # only created once, since it takes a long time
  @@ri = FastRI::RiService.new(FastRI::RiIndex.new_from_paths(::RDoc::RI::Paths.path(true, true, true, true)))
  def setup
    @ri = @@ri
  end

  def assert_include(arr, actual)
    arr.each{|w| assert(actual.include?(w), "#{w} should be included in #{actual}") }
  end

  def test_completion_list
    completion_each = %w[each_pair each_byte each_key each_value]
    assert_include(completion_each, @ri.completion_list("each_"))
    assert_kind_of(Array, @ri.completion_list("each_"))

    assert_include(%w[Array Fixnum Hash String], @ri.completion_list(""))
    assert_kind_of(Array, @ri.completion_list(""))

    assert_include(%w[Array ArgumentError], @ri.completion_list("Ar"))
  end

  def test_info
    assert_include(%w[collect collect! compact compact! concat],
                    @ri.info("Array"))
    assert_include(%w[each each_key each_pair each_value empty],
                    @ri.info("Hash"))
    assert_kind_of(String, @ri.info("Hash"))
  end

  def test_args
    assert_match(/map\s+\{\|\s*\w+\s*\|\s+block\s+\}/, 
                 @ri.args("map"))
    assert_kind_of(String,@ri.args("map"))
  end

  def test_class_list
    assert_include(%w[StringIO Range Array Hash String Struct],
                   @ri.class_list("each"))
    assert_kind_of(Array, @ri.class_list("each"))
    assert_include(%w[Hash Struct],
                   @ri.class_list("each_pair"))
    assert_equal(nil, @ri.class_list("__super_bogus_method___"))
  end

  def test_class_list_with_flag
    assert_include(%w[StringIO# Range# Array# Hash# String# Struct#],
                   @ri.class_list_with_flag("each"))
    assert_include(%w[Hash# Struct#],
                   @ri.class_list_with_flag("each_pair"))
    assert_equal(nil, @ri.class_list_with_flag("__super_bogus_method___"))
  end
end


