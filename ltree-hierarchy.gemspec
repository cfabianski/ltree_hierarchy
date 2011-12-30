# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ltree_hierarchy/version"

Gem::Specification.new do |s|
  s.name        = "ltree-hierarchy"
  s.version     = Ltree::Hierarchy::VERSION
  s.authors     = ["Rob Worley"]
  s.email       = ["robert.worley@gmail.com"]
  s.homepage    = "http://github.com/robworley/ltree-hierarchy"
  s.summary     = "Organize ActiveRecord models into a tree using PostgreSQL's ltree datatype"
  s.description = "Organizes ActiveRecord models into a tree/hierarchy using a materialized path implementation based around PostgreSQL's ltree datatype. ltree's operators ensure that queries are fast and easily understood."

  s.rubyforge_project = "ltree-hierarchy"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '>= 3.1'
end
