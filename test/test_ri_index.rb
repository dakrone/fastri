require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift "lib"
require 'fastri/ri_index'

class TestRiIndex < Test::Unit::TestCase
  INDEX_DATA =<<EOF
#{FastRI::RiIndex::MAGIC}
Sources:
system                          /usr/share/ri/system/
somegem-0.1.0                   /long/path/somegem-0.1.0
stuff-1.1.0                     /long/path/stuff-1.1.0
================================================================================
Namespaces:
ABC 0 1
ABC::DEF 0 1
ABC::DEF::Foo 1
ABC::Zzz 0
CDE 1 2
FGH 2
FGH::Adfdsf 2
================================================================================
Methods:
ABC::DEF.bar 0
ABC::DEF::Foo#baz 1
ABC::DEF::Foo#foo 1
ABC::Zzz.foo 0 1
ABC::Zzz#foo 0
CDE.foo 1 2
FGH::Adfdsf#foo 2
================================================================================
EOF
  INDEX_DATA2 =<<EOF
#{FastRI::RiIndex::MAGIC}
Sources:
system                          /usr/share/ri/system/
somegem-0.1.0                   /long/path/somegem-0.1.0
stuff-1.1.0                     /long/path/stuff-1.1.0
================================================================================
Namespaces:
ABC 0 1
ABCDEF 1 2
================================================================================
Methods:
ABC.bar 0
ABC#baz 1
ABCDEF#foo 1
ABCDEF.foo 1 2
================================================================================
EOF

  require 'stringio'
  def setup
    @index = FastRI::RiIndex.new_from_IO(StringIO.new(INDEX_DATA))
    @index2 = FastRI::RiIndex.new_from_IO(StringIO.new(INDEX_DATA2))
  end

  def test_dump
    s = StringIO.new("")
    @index.dump(s)
    assert_equal(INDEX_DATA, s.string)
  end

  def test_toplevel_namespace
    ret = @index.top_level_namespace
    assert_kind_of(Array, ret)
    assert_kind_of(FastRI::RiIndex::TopLevelEntry, ret[0])
  end

  def test_full_class_names
    assert_equal(["ABC", "ABC::DEF", "ABC::DEF::Foo", "ABC::Zzz", "CDE", "FGH", "FGH::Adfdsf"], @index.full_class_names)
    assert_equal(["ABC", "ABC::DEF", "ABC::Zzz"], @index.full_class_names(0))
    assert_equal(["ABC", "ABC::DEF", "ABC::DEF::Foo", "CDE"], @index.full_class_names(1))
    assert_equal(["CDE", "FGH", "FGH::Adfdsf"], @index.full_class_names(2))
    assert_equal(["CDE", "FGH", "FGH::Adfdsf"], @index.full_class_names("stuff-1.1.0"))
    assert_equal([], @index.full_class_names("nonexistent-1.1.0"))
  end

  def test_full_method_names
    assert_equal(["ABC::DEF.bar", "ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", 
                 "ABC::Zzz.foo", "ABC::Zzz#foo", "CDE.foo", "FGH::Adfdsf#foo"], 
                 @index.full_method_names)
    assert_equal(["ABC::DEF.bar", "ABC::Zzz.foo", "ABC::Zzz#foo"], 
                 @index.full_method_names(0))
    assert_equal(["ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", "ABC::Zzz.foo", "CDE.foo"], 
                 @index.full_method_names(1))
    assert_equal(["CDE.foo", "FGH::Adfdsf#foo"], @index.full_method_names(2))
    assert_equal(["CDE.foo", "FGH::Adfdsf#foo"], @index.full_method_names("stuff-1.1.0"))
    assert_equal([], @index.full_method_names("nonexistent-1.1.0"))
  end

  def test_all_names
    assert_equal(["ABC", "ABC::DEF", "ABC::DEF::Foo", "ABC::Zzz", "CDE", "FGH", 
                 "FGH::Adfdsf", "ABC::DEF.bar", "ABC::DEF::Foo#baz", 
                 "ABC::DEF::Foo#foo", "ABC::Zzz.foo", "ABC::Zzz#foo", 
                 "CDE.foo", "FGH::Adfdsf#foo"], @index.all_names)
    assert_equal(["ABC", "ABC::DEF", "ABC::Zzz", "ABC::DEF.bar", 
                 "ABC::Zzz.foo", "ABC::Zzz#foo"], @index.all_names(0))
    assert_equal(["ABC", "ABC::DEF", "ABC::DEF::Foo", "CDE", 
                 "ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", "ABC::Zzz.foo",
                 "CDE.foo"], @index.all_names(1))
    assert_equal(["CDE", "FGH", "FGH::Adfdsf", "CDE.foo", "FGH::Adfdsf#foo"],
                 @index.all_names(2))
    assert_equal(["ABC", "ABC::DEF", "ABC::DEF::Foo", "CDE", 
                 "ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", "ABC::Zzz.foo",
                 "CDE.foo"], @index.all_names("somegem-0.1.0"))
    assert_equal([], @index.all_names("notinstalled-1.0"))
  end

  def test_get_class_entry
    assert_nil(@index.get_class_entry("NONEXISTENT_FOO"))
    assert_equal("ABC", @index.get_class_entry("ABC", nil).full_name)
    assert_nil(@index.get_class_entry("ABC", nil).source_index)
    assert_nil(@index.get_class_entry("ABC::DEF::Foo", 0))
    assert_equal(1, @index.get_class_entry("ABC::DEF::Foo", 1).source_index)
    assert_equal(2, @index.get_class_entry("ABC::DEF::Foo", 1).index)
  end

  def test_get_method_entry
    assert_equal("ABC::DEF.bar", @index.get_method_entry("ABC::DEF.bar", nil).full_name)
    assert_equal(0, @index.get_method_entry("ABC::DEF.bar", 0).source_index)
    assert_nil(@index.get_method_entry("FGH::Adfdsf#foo", 1))
    assert_equal(6, @index.get_method_entry("FGH::Adfdsf#foo", 2).index)
    assert_equal(2, @index.get_method_entry("FGH::Adfdsf#foo", 2).source_index)
    assert_equal("FGH::Adfdsf#foo", @index.get_method_entry("FGH::Adfdsf#foo", 2).full_name)
  end

  def test_namespaces_under
    assert_kind_of(Array, @index.namespaces_under("ABC", true, nil))
    results = @index.namespaces_under("ABC", true, nil)
    assert_equal(3, results.size)
    assert_equal(["ABC::DEF", "ABC::DEF::Foo", "ABC::Zzz"], results.map{|x| x.full_name})
    results = @index.namespaces_under("ABC", false, nil)
    assert_equal(2, results.size)
    assert_equal(["ABC::DEF", "ABC::Zzz"], results.map{|x| x.full_name})
  end

  def test_namespaces_under_scoped
    results = @index.namespaces_under("ABC", false, 1)
    assert_kind_of(Array, results)
    assert_equal(["ABC::DEF"], results.map{|x| x.full_name})
    results = @index.namespaces_under("ABC", true, 1)
    assert_equal(2, results.size)
    assert_equal(["ABC::DEF", "ABC::DEF::Foo"], results.map{|x| x.full_name})
    results = @index.namespaces_under("ABC", true, "somegem-0.1.0")
    assert_equal(2, results.size)
    assert_equal(["ABC::DEF", "ABC::DEF::Foo"], results.map{|x| x.full_name})
    results = @index.namespaces_under("ABC", true, 0)
    assert_equal(2, results.size)
    assert_equal(["ABC::DEF", "ABC::Zzz"], results.map{|x| x.full_name})
  end

  def test_namespaces_under_toplevel
    toplevel = @index.top_level_namespace[0]
    assert_equal(["ABC", "CDE", "FGH"], 
                 @index.namespaces_under(toplevel, false, nil).map{|x| x.full_name})
    assert_equal(["ABC", "ABC::DEF", "ABC::DEF::Foo", "ABC::Zzz", 
                  "CDE", "FGH", "FGH::Adfdsf"], 
                 @index.namespaces_under(toplevel, true, nil).map{|x| x.full_name})
    assert_equal(["CDE", "FGH", "FGH::Adfdsf"], 
                 @index.namespaces_under(toplevel, true, "stuff-1.1.0").map{|x| x.full_name})
  end

  def test_source_paths_for_string
    assert_equal([], @index.source_paths_for(""))
    assert_equal([], @index.source_paths_for(nil))

    assert_equal(["/usr/share/ri/system/", "/long/path/somegem-0.1.0"], @index.source_paths_for("ABC::DEF"))
    assert_equal(["/long/path/somegem-0.1.0", "/long/path/stuff-1.1.0"], @index.source_paths_for("CDE.foo"))
  end

  def test_source_paths_for_entry
    assert_equal(["/usr/share/ri/system/", "/long/path/somegem-0.1.0"],
                 @index.source_paths_for(@index.get_class_entry("ABC::DEF")))
    assert_equal(["/long/path/somegem-0.1.0", "/long/path/stuff-1.1.0"],
                 @index.source_paths_for(@index.get_method_entry("CDE.foo")))
  end

  def test_methods_under_same_prefix
    results = @index2.methods_under("ABC", true, nil)
    results.map{|x| x.full_name}
    assert_equal(["ABC.bar", "ABC#baz"], results.map{|x| x.full_name})
  end

  def test_methods_under_scoped
    results = @index.methods_under("ABC", true, 1)
    assert_equal(["ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", "ABC::Zzz.foo"], results.map{|x| x.full_name})
    results = @index.methods_under("CDE", false, "stuff-1.1.0")
    assert_equal(["CDE.foo"], results.map{|x| x.full_name})
    results = @index.methods_under("ABC", true, nil)
    assert_equal(["ABC::DEF.bar", "ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", 
                 "ABC::Zzz.foo", "ABC::Zzz#foo"], results.map{|x| x.full_name})
    assert_equal(["ABC::DEF.bar", "ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", 
                 "ABC::Zzz.foo", "ABC::Zzz#foo", "CDE.foo", "FGH::Adfdsf#foo"], 
                 @index.methods_under("", true, nil).map{|x| x.full_name})
    assert_equal([], @index.methods_under("ABC", false, nil).map{|x| x.full_name})
    assert_equal(["CDE.foo"], 
                 @index.methods_under("CDE", false, nil).map{|x| x.full_name})
    assert_equal(["FGH::Adfdsf#foo"], 
                 @index.methods_under("FGH", true, nil).map{|x| x.full_name})
    assert_equal([], @index.methods_under("FGH", true, 0).map{|x| x.full_name})
    assert_equal(["FGH::Adfdsf#foo"], 
                 @index.methods_under("FGH", true, 2).map{|x| x.full_name})
    assert_equal([], @index.methods_under("FGH", false, 2).map{|x| x.full_name})
    assert_equal(["FGH::Adfdsf#foo"], 
                 @index.methods_under("FGH::Adfdsf", false, 2).map{|x| x.full_name})
    assert_equal(["FGH::Adfdsf#foo"], 
                 @index.methods_under("FGH::Adfdsf", true, 2).map{|x| x.full_name})
    assert_equal([], @index.methods_under("FGH::Adfdsf", false, 0).map{|x| x.full_name})
  end

  def test_lookup_namespace_in
    toplevel = @index.top_level_namespace
    res = @index.lookup_namespace_in("ABC", toplevel)
    assert_equal(["ABC"], res.map{|x| x.full_name})
    toplevel2 = @index.top_level_namespace(2)
    assert_equal([], @index.lookup_namespace_in("ABC", toplevel2))
    assert_equal(["FGH"], @index.lookup_namespace_in("FGH", toplevel2).map{|x| x.full_name})
  end

  def test_find_class_by_name
    class_entry = nil
    class << @index; self end.module_eval do
      define_method(:get_class){|x| class_entry = x}
    end
    @index.find_class_by_name("ABC")
    assert_kind_of(FastRI::RiIndex::ClassEntry, class_entry)
    assert_equal("ABC", class_entry.full_name)
    assert_nil(class_entry.source_index)
    assert_equal(0, class_entry.index)
    class_entry = nil
    @index.find_class_by_name("ABC::DEF::Foo")
    assert_kind_of(FastRI::RiIndex::ClassEntry, class_entry)
    assert_equal("ABC::DEF::Foo", class_entry.full_name)
    assert_nil(class_entry.source_index)
    assert_equal(2, class_entry.index)
    class_entry = nil
    @index.find_class_by_name("ABC::DEF::Foo", 1)
    assert_kind_of(FastRI::RiIndex::ClassEntry, class_entry)
    assert_equal("ABC::DEF::Foo", class_entry.full_name)
    assert_equal(1, class_entry.source_index)
    assert_equal(2, class_entry.index)
    class_entry = nil
    @index.find_class_by_name("ABC::DEF::Foo", 0)
    assert_nil(class_entry)
    @index.find_class_by_name("AB", nil)
    assert_nil(class_entry)
  end

  def test_find_method_by_name
    method_entry = nil
    class << @index; self end.module_eval do
      define_method(:get_method){|x| method_entry = x}
    end
    @index.find_method_by_name("ABC")
    assert_nil(method_entry)
    @index.find_method_by_name("ABC::DEF.bar")
    assert_equal("ABC::DEF.bar", method_entry.full_name)
    method_entry = nil
    @index.find_method_by_name("ABC::DEF::Foo#baz")
    assert_equal("ABC::DEF::Foo#baz", method_entry.full_name)
    assert_nil(method_entry.source_index)
    assert_equal(1, method_entry.index)
    method_entry = nil
    @index.find_method_by_name("ABC::DEF::Foo#baz", 1)
    assert_equal("ABC::DEF::Foo#baz", method_entry.full_name)
    assert_equal(1, method_entry.source_index)
    assert_equal(1, method_entry.index)
    method_entry = nil
    @index.find_method_by_name("CDE.foo", 2)
    assert_equal("CDE.foo", method_entry.full_name)
    assert_equal(5, method_entry.index)
    assert_equal(2, method_entry.source_index)
    method_entry = nil
    @index.find_method_by_name("ABC::DEF::Foo#ba", 1)
    assert_nil(method_entry)
    @index.find_method_by_name("ABC::DEF.bar", 1)
    assert_nil(method_entry)
  end

  def test_find_methods
    toplevel = @index.top_level_namespace
    assert_equal(["ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", 
                  "ABC::Zzz#foo", "FGH::Adfdsf#foo"], 
                 @index.find_methods("", false, toplevel).map{|x| x.full_name})
    assert_equal(["ABC::DEF.bar", "ABC::Zzz.foo", "CDE.foo"], 
                 @index.find_methods("", true, toplevel).map{|x| x.full_name})
    assert_equal([], @index.find_methods("ABC", true, toplevel).map{|x| x.full_name})
    assert_equal(["ABC::DEF::Foo#foo", "ABC::Zzz#foo", "FGH::Adfdsf#foo"], 
                 @index.find_methods("foo", false, toplevel).map{|x| x.full_name})
    assert_equal(["ABC::Zzz.foo", "CDE.foo"], 
                 @index.find_methods("foo", true, toplevel).map{|x| x.full_name})
    toplevel = @index.top_level_namespace(1)
    assert_equal(["ABC::DEF::Foo#foo"], @index.find_methods("foo", false, toplevel).map{|x| x.full_name})
    toplevel = @index.top_level_namespace("stuff-1.1.0")
    assert_equal(["CDE.foo"], @index.find_methods("foo", true, toplevel).map{|x| x.full_name})
  end

  def test_num_namespaces
    assert_equal(7, @index.num_namespaces)
  end

  def test_num_methods
    assert_equal(7, @index.num_methods)
  end

  #{{{ ClassEntry and MethodEntry
  def test_ClassEntry_contained_modules_matching
    toplevel = @index.top_level_namespace[0]
    assert_equal(["ABC"], toplevel.contained_modules_matching("ABC").map{|x| x.full_name})

    class_entry = @index.get_class_entry("ABC")
    assert_equal([], class_entry.contained_modules_matching("ABC").map{|x| x.full_name})
    assert_equal(["ABC::DEF", "ABC::Zzz"], class_entry.contained_modules_matching("").map{|x| x.full_name})
  end

  def test_ClassEntry_type
    class_entry = @index.get_class_entry("ABC")
    assert_equal(:namespace, class_entry.type)
  end

  def test_ClassEntry_path_names
    class_entry = @index.get_class_entry("ABC")
    assert_equal(["/usr/share/ri/system/ABC", "/long/path/somegem-0.1.0/ABC"], class_entry.path_names)

    class_entry = @index.get_class_entry("ABC", 0)
    assert_equal(["/usr/share/ri/system/ABC"], class_entry.path_names)
    class_entry = @index.get_class_entry("ABC", 1)
    assert_equal(["/long/path/somegem-0.1.0/ABC"], class_entry.path_names)
  end

  def test_ClassEntry_classes_and_modules
    class_entry = @index.get_class_entry("ABC")
    assert_equal(["ABC::DEF", "ABC::Zzz"], 
                 class_entry.classes_and_modules.map{|x| x.full_name})
    class_entry = @index.get_class_entry("ABC::DEF")
    assert_equal(["ABC::DEF::Foo"], class_entry.classes_and_modules.map{|x| x.full_name})
  end

  def test_ClassEntry_contained_class_named
    class_entry = @index.get_class_entry("ABC")
    class_entry = class_entry.contained_class_named("DEF")
    assert_equal("ABC::DEF", class_entry.full_name)
    assert_equal(1, class_entry.index)
    class_entry = class_entry.contained_class_named("Foo")
    assert_equal(2, class_entry.index)
    assert_nil(class_entry.contained_class_named("Bar"))
    assert_equal(3, @index.get_class_entry("ABC").contained_class_named("Zzz").index)
  end

  def test_ClassEntry_methods_matching
    class_entry = @index.get_class_entry("ABC::Zzz")
    assert_equal([], class_entry.methods_matching("nonexistent", false))
    assert_equal([3], class_entry.methods_matching("foo", true).map{|x| x.index})
    assert_equal([4], class_entry.methods_matching("foo", false).map{|x| x.index})
  end

  def test_ClassEntry_recursively_find_methods_matching
    class_entry = @index.get_class_entry("ABC")
    assert_equal(["ABC::DEF.bar", "ABC::Zzz.foo"], 
                 class_entry.recursively_find_methods_matching(//, true).map{|x| x.full_name})
    assert_equal(["ABC::DEF::Foo#baz", "ABC::DEF::Foo#foo", "ABC::Zzz#foo"], 
                 class_entry.recursively_find_methods_matching(//, false).map{|x| x.full_name})
    assert_equal([], class_entry.recursively_find_methods_matching(/nonono/, false).map{|x| x.full_name})
  end

  def test_ClassEntry_all_method_names
    class_entry = @index.get_class_entry("ABC")
    assert_equal([], class_entry.all_method_names)
    class_entry = @index.get_class_entry("ABC::Zzz")
    assert_equal(["ABC::Zzz.foo", "ABC::Zzz#foo"], class_entry.all_method_names)
  end

  def test_MethodEntry_path_name
    method_entry = @index.get_method_entry("CDE.foo")
    assert_equal("/long/path/somegem-0.1.0/CDE/foo-c.yaml", method_entry.path_name)

    method_entry = @index.get_method_entry("CDE.foo", 1)
    assert_equal("/long/path/somegem-0.1.0/CDE/foo-c.yaml", method_entry.path_name)
    method_entry = @index.get_method_entry("CDE.foo", 2)
    assert_equal("/long/path/stuff-1.1.0/CDE/foo-c.yaml", method_entry.path_name)
  end

  def test_MethodEntry_type
    method_entry = @index.get_method_entry("CDE.foo")
    assert_equal(:method, method_entry.type)
  end
end

