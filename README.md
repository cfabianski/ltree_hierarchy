[![Gem Version](https://badge.fury.io/rb/ltree_hierarchy.svg)](https://badge.fury.io/rb/ltree_hierarchy)
[![Build Status](https://travis-ci.org/cfabianski/ltree_hierarchy.svg?branch=master)](https://travis-ci.org/cfabianski/ltree_hierarchy)

# Ltree Hierarchy

A simplistic gem that allows ActiveRecord models to be organized in a tree or hierarchy. It uses a materialized path implementation based around PostgreSQL's [ltree](http://www.postgresql.org/docs/current/static/ltree.html) data type, associated functions and operators.

## Why might you want to use it?

- You want to be able to construct optimized hierarchical queries with ease, both from Ruby AND raw SQL.
- You want to be able to compose complex arel expressions from pre-defined building blocks.
- You prefer PostgreSQL over other relational DBs.

## Installation

Add this line to your application's Gemfile:

    gem 'ltree_hierarchy'

And then execute:

    $ bundle

Add ltree extension to PostgreSQL:

    $ psql -U postgres -d my_database
    -> CREATE EXTENSION IF NOT EXISTS ltree;

Update your table:

``` ruby
class AddLtreeToLocations < ActiveRecord::Migration
  def self.up
    add_column :locations, :parent_id, :integer
    add_column :locations, :path, :ltree

    add_index :locations, :parent_id
  end

  def self.down
    remove_index :locations, :parent_id
    remove_column :locations, :parent_id
    remove_column :locations, :path
  end
end
```

Run migrations:

    $ bundle exec rake db:migrate

## Usage

``` ruby
  class Location < ActiveRecord::Base
    has_ltree_hierarchy
  end

  root     = Location.create!(name: 'UK')
  child    = Location.create!(name: 'London', parent: root)
  subchild = Location.create!(name: 'Hackney', parent: child)

  root.parent   # => nil
  child.parent # => root
  root.children # => [child]
  root.children.first.children.first # => subchild
  subchild.root # => root
```

- `.roots`
- `.leaves`
- `.at_depth(n)`
- `.lowest_common_ancestors(scope)`
- `#parent`
- `#ancestors`
- `#self_and_ancestors`
- `#siblings`
- `#self_and_siblings`
- `#children`
- `#self_and_children`
- `#descendants`
- `#self_and_descendants`
- `#leaves`

## TODO

- [ ] Better error message for circular references.
- [ ] Don't neglect i18n.
