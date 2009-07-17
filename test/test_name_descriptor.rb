# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift "lib"
require 'fastri/name_descriptor'

class TestNameDescriptor < Test::Unit::TestCase
  include FastRI
  def helper(text)
    desc = NameDescriptor.new(text)
    [desc.class_names, desc.method_name, desc.is_class_method]
  end

  def test_unqualified_methods
    assert_equal([[], "foo", nil], helper("foo"))
    assert_equal([[], "foo", false], helper("#foo"))
    assert_equal([[], "foo", nil], helper(".foo"))
    assert_equal([[], "foo", true], helper("::foo"))
  end

  def test_qualified_methods
    assert_equal([["Foo"], "bar", nil], helper("foo.bar"))
    assert_equal([["Foo"], "bar", true], helper("foo::bar"))
    assert_equal([["Foo"], "bar", false], helper("foo#bar"))
    assert_equal([["Foo", "Bar"], "baz", true], helper("foo::bar::baz"))
  end

  def test_namespaces
    assert_equal([["Foo"], nil, nil], helper("Foo"))
    assert_equal([["Foo", "Bar"], nil, nil], helper("foo::Bar"))
    assert_equal([["Foo", "Bar", "Baz"], nil, nil], helper("Foo::Bar::Baz"))
  end
end
