# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ltree_hierarchy/version"

Gem::Specification.new do |s|
  s.name = "ltree_hierarchy"
  s.version = Ltree::Hierarchy::VERSION
  s.authors = ["Rob Worley", "Cédric Fabianski"]
  s.email = ["dev@leadformance.com"]
  s.homepage = "https://github.com/cfabianski/ltree_hierarchy"
  s.summary = "Organize ActiveRecord models into a tree using PostgreSQL's ltree datatype"
  s.description = "Organizes ActiveRecord models into a tree/hierarchy using a materialized path implementation based around PostgreSQL's ltree datatype. ltree's operators ensure that queries are fast and easily understood."

  s.files = Dir["{lib/**/*,[A-Z]*}"]
  s.platform = Gem::Platform::RUBY
  s.license = "MIT"
  s.require_paths = ["lib"]

  s.add_dependency "pg", "~> 1.1.0"

  s.add_dependency "activerecord", ">= 5.2.0"

  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
end
