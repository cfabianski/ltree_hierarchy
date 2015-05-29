# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ltree_hierarchy/version"

Gem::Specification.new do |s|
  s.name = "ltree_hierarchy"
  s.version = Ltree::Hierarchy::VERSION
  s.authors = ["Rob Worley", "Leadformance"]
  s.email = ["dev@leadformance.com"]
  s.homepage = "https://github.com/Leadformance/ltree_hierarchy"
  s.summary = "Organize ActiveRecord models into a tree using PostgreSQL's ltree datatype"
  s.description = "Organizes ActiveRecord models into a tree/hierarchy using a materialized path implementation based around PostgreSQL's ltree datatype. ltree's operators ensure that queries are fast and easily understood."

  s.rubyforge_project = "ltree_hierarchy"

  s.files = Dir["{lib/**/*,[A-Z]*}"]
  s.platform = Gem::Platform::RUBY
  s.license = "MIT"
  s.require_paths = ["lib"]

  if RUBY_PLATFORM == "java"
    s.add_dependency "activerecord-jdbcpostgresql-adapter"
  else
    s.add_dependency "pg"
  end

  s.add_dependency "activerecord", ">= 3.1.0"

  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
end
