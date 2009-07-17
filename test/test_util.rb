# Copyright (C) 2006  Mauricio Fernandez <mfp@acm.org>
#

require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift "lib"
require 'fastri/util'

class TestUtil < Test::Unit::TestCase
  data = <<EOF
foo 0.1.1 /usr/local/lib/ruby/gems/1.8/doc/foo-0.1.1/ri
foo 1.1.1 /usr/local/lib/ruby/gems/1.8/doc/foo-1.1.1/ri
bar 0.1.1 /usr/local/lib/ruby/gems/1.8/doc/bar-0.1.1/ri
baz 0.1.1 /usr/local/lib/ruby/gems/1.8/doc/baz-0.1.1/ri
EOF
  GEM_DIR_INFO = data.split(/\n/).map{|l| l.split(/\s+/)}

  include FastRI::Util
  def test_gem_info_for_path
    assert_equal(["foo", "0.1.1", "/usr/local/lib/ruby/gems/1.8/doc/foo-0.1.1/ri"],
                 gem_info_for_path("/usr/local/lib/ruby/gems/1.8/doc/foo-0.1.1/ri/Array/cdesc-Array.yaml", GEM_DIR_INFO))
    assert_equal(["foo", "1.1.1", "/usr/local/lib/ruby/gems/1.8/doc/foo-1.1.1/ri"],
                 gem_info_for_path("/usr/local/lib/ruby/gems/1.8/doc/foo-1.1.1/ri/Array/cdesc-Array.yaml", GEM_DIR_INFO))
    assert_equal(["bar", "0.1.1", "/usr/local/lib/ruby/gems/1.8/doc/bar-0.1.1/ri"],
                 gem_info_for_path("/usr/local/lib/ruby/gems/1.8/doc/bar-0.1.1/ri/Array/cdesc-Array.yaml", GEM_DIR_INFO))
    assert_equal(["baz", "0.1.1", "/usr/local/lib/ruby/gems/1.8/doc/baz-0.1.1/ri"],
                 gem_info_for_path("/usr/local/lib/ruby/gems/1.8/doc/baz-0.1.1/ri/Array/cdesc-Array.yaml", GEM_DIR_INFO))
    assert_nil(gem_info_for_path("/usr/lib/ruby/gems/1.8/doc/baz-1.1.1/ri/Array/cdesc-Array.yaml", GEM_DIR_INFO))
  end

  def test_gem_relpath_to_full_name
    assert_equal("Array", gem_relpath_to_full_name("Array/cdesc-Array.yaml"))
    assert_equal("String", gem_relpath_to_full_name("String/cdesc-String.yaml"))
    assert_equal("Foo::Bar::String", gem_relpath_to_full_name("Foo/Bar/String/cdesc-String.yaml"))
    assert_equal("Foo::Bar#eql?", gem_relpath_to_full_name("Foo/Bar/eql%3f-i.yaml"))
    assert_equal("Foo::Bar.eql?", gem_relpath_to_full_name("Foo/Bar/eql%3f-c.yaml"))
  end

  def test_change_query_method_type
    assert_equal(".foo", change_query_method_type(".foo"))
    assert_equal("::foo", change_query_method_type("#foo"))
    assert_equal("#foo", change_query_method_type("::foo"))
    assert_equal("A::B.foo", change_query_method_type("A::B.foo"))
    assert_equal("A::B::foo", change_query_method_type("A::B#foo"))
    assert_equal("A::B#foo", change_query_method_type("A::B::foo"))
  end
end

class TestUtilMagicHelp < Test::Unit::TestCase
  include FastRI::Util::MagicHelp
  module TestModule
    def foo; end
    module_function :foo

    def self.bar; end
    def bar; end
  end

  def test_magic_help
    assert_equal("IO::readlines", magic_help("IO::readlines"))
    assert_equal("IO::readlines", magic_help("IO.readlines"))

    assert_equal("Enumerable#inject", magic_help("File#inject"))
    assert_equal("Enumerable#inject", magic_help("File.inject"))

    assert_equal("IO::readlines", magic_help("File.readlines"))
    assert_equal("IO::readlines", magic_help("File::readlines"))
  end

  def test_magic_help_nested_namespaces
    assert_equal("TestUtilMagicHelp::TestModule#foo", 
                 magic_help("TestUtilMagicHelp::TestModule.foo"))
    assert_equal("TestUtilMagicHelp::TestModule::bar", 
                 magic_help("TestUtilMagicHelp::TestModule.bar"))
  end

  def test_magic_help__new
    assert_equal("Array::new", magic_help("Array::new"))
    assert_equal("Array::new", magic_help("Array.new"))
    assert_equal("Struct::new", magic_help("Struct.new"))
    assert_equal("Struct::new", magic_help("Struct::new"))
  end

  def test_magic_help__Kernel_public_instance_methods
    # It is mysterious.
    # Object.instance_method(:object_id) # => #<UnboundMethod: Object(Kernel)#object_id>
    assert_equal("Object#object_id", magic_help("Object.object_id"))
    assert_equal("Object#object_id", magic_help("Object#object_id"))
  end

end
