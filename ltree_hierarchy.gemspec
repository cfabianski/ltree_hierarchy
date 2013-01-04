# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ltree_hierarchy/version"

Gem::Specification.new do |s|
  s.name              = "ltree_hierarchy"
  s.version           = Ltree::Hierarchy::VERSION
  s.authors           = ["Rob Worley"]
  s.email             = ["robert.worley@gmail.com"]
  s.homepage          = "http://github.com/robworley/ltree_hierarchy"
  s.summary           = "Organize ActiveRecord models into a tree using PostgreSQL's ltree datatype"
  s.description       = "Organizes ActiveRecord models into a tree/hierarchy using a materialized path implementation based around PostgreSQL's ltree datatype. ltree's operators ensure that queries are fast and easily understood."

  s.rubyforge_project = "ltree_hierarchy"

  s.files             = Dir['{lib/**/*,[A-Z]*}']
  s.platform          = Gem::Platform::RUBY
  s.require_paths     = ["lib"]

  s.add_dependency 'activerecord', ENV["ACTIVE_RECORD_VERSION"]
  s.add_dependency 'pg'

  s.add_development_dependency 'rake'
end
