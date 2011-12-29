require 'rubygems'
require 'active_record'
require 'test/unit'

require 'ltree_hierarchy'

class TreeNode < ActiveRecord::Base
  has_ltree_hierarchy
end

class HierarchyTest < Test::Unit::TestCase
  def setup
    db_config = YAML.load(File.open(File.join(File.dirname(__FILE__), 'database.yml')).read)['test']

    TreeNode.establish_connection(db_config)

    unless TreeNode.connection.select_value("SELECT proname FROM pg_proc WHERE proname = 'nlevel'")
      pg_sharedir = `pg_config --sharedir`.strip
      ltree_script_path = File.join(pg_sharedir, "contrib", "ltree.sql")
      TreeNode.connection.execute(File.read(ltree_script_path))
    end

    TreeNode.connection.create_table(:tree_nodes, :force => true) do |t|
      t.integer :parent_id
      t.column  :path, 'ltree'
      t.timestamps
    end
  end

  def test_sets_path_upon_creation
    root = TreeNode.create!
    child = TreeNode.create!(:parent => root)
    assert_equal "#{root.id}.#{child.id}", child.path
  end

  def test_cascades_path_changes_through_descendents
    acme_corp = TreeNode.create!
    uk = TreeNode.create!(:parent => acme_corp)
    london = TreeNode.create!(:parent => uk)

    # Insert intermediate TreeNode.
    emea = TreeNode.create!(:parent => acme_corp)
    uk.update_attributes!(:parent => emea)

    london.reload
    assert_equal "#{acme_corp.id}.#{emea.id}.#{uk.id}.#{london.id}", london.path
  end

  def test_prevents_circular_references
    root = TreeNode.create!
    child = TreeNode.create!(:parent => root)
    root.parent = child
    assert !root.save
    assert_equal 'is invalid', root.errors[:parent_id].join
  end

  def test_finds_roots
    root = TreeNode.create!
    child = TreeNode.create!(:parent => root)
    assert_equal [root], TreeNode.roots.all
  end

  def test_finds_ancestors
    root = TreeNode.create!
    child = TreeNode.create!(:parent => root)
    assert_equal [root], child.ancestors.all
  end

  def test_finds_self_and_ancestors
    root = TreeNode.create!
    child = TreeNode.create!(:parent => root)
    assert_equal [root, child], child.and_ancestors
  end

  def test_finds_siblings
    root = TreeNode.create!
    child1 = TreeNode.create!(:parent => root)
    child2 = TreeNode.create!(:parent => root)
    child3 = TreeNode.create!(:parent => root)
    grandchild1 = TreeNode.create!(:parent => child1)

    assert_equal [child2, child3], child1.siblings.order(:created_at).all
  end

  def test_finds_self_and_siblings
    root = TreeNode.create!
    child1 = TreeNode.create!(:parent => root)
    child2 = TreeNode.create!(:parent => root)
    child3 = TreeNode.create!(:parent => root)
    grandchild1 = TreeNode.create!(:parent => child1)

    assert_equal [child1, child2, child3], child1.and_siblings.order(:created_at).all
  end

  def test_finds_children
    root = TreeNode.create!
    child1 = TreeNode.create!(:parent => root)
    child2 = TreeNode.create!(:parent => root)
    child3 = TreeNode.create!(:parent => root)
    grandchild1 = TreeNode.create!(:parent => child1)

    assert_equal [child1, child2, child3], root.children.order(:created_at).all
  end

  def test_finds_self_and_children
    root = TreeNode.create!
    child1 = TreeNode.create!(:parent => root)
    child2 = TreeNode.create!(:parent => root)
    child3 = TreeNode.create!(:parent => root)
    grandchild1 = TreeNode.create!(:parent => child1)

    assert_equal [root, child1, child2, child3], root.and_children.order(:created_at).all
  end

  def test_finds_descendents
    root = TreeNode.create!
    child1 = TreeNode.create!(:parent => root)
    child2 = TreeNode.create!(:parent => root)
    child3 = TreeNode.create!(:parent => root)
    grandchild1 = TreeNode.create!(:parent => child1)

    assert_equal [child1, child2, child3, grandchild1], root.descendents.order(:created_at).all
  end

  def test_finds_self_and_descendents
    root = TreeNode.create!
    child1 = TreeNode.create!(:parent => root)
    child2 = TreeNode.create!(:parent => root)
    child3 = TreeNode.create!(:parent => root)
    grandchild1 = TreeNode.create!(:parent => child1)

    assert_equal [root, child1, child2, child3, grandchild1], root.and_descendents.order(:created_at).all
  end
end
