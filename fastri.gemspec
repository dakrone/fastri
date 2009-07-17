# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fastri}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mauricio Fernandez", "Lee Hinman"]
  s.date = %q{2009-07-17}
  s.default_executable = %q{fri}
  s.description = %q{Fastri is RI, fast.}
  s.email = %q{lee@writequit.org}
  s.executables = ["fastri-server", "fri", "ri-emacs"]
  s.extra_rdoc_files = [
    "README.en"
  ]
  s.files = [
    "fastri.gemspec",
    "Rakefile",
    "README.en",
    "THANKS",
    "CHANGES",
    "COPYING",
    "LEGAL",
    "LICENSE",
    "bin/fastri-server",
    "bin/fri",
    "bin/ri-emacs",
    "lib/fastri/full_text_index.rb",
    "lib/fastri/full_text_indexer.rb",
    "lib/fastri/name_descriptor.rb",
    "lib/fastri/ri_index.rb",
    "lib/fastri/ri_service.rb",
    "lib/fastri/util.rb",
    "lib/fastri/version.rb",
    "indexer.rb",
    "lookup.rb",
    "pre-install.rb",
    "setup.rb",
    "indexer.rb",
    "test/test_full_text_index.rb",
    "test/test_full_text_indexer.rb",
    "test/test_functional_ri_service.rb",
    "test/test_integration_full_text_index.rb",
    "test/test_name_descriptor.rb",
    "test/test_ri_index.rb",
    "test/test_util.rb"
  ]
  s.homepage = %q{http://github.com/dakrone/fastri}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{0.3.1}
  s.summary = %q{Fastri is RI, fast.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
